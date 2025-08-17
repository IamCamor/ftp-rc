import fs from "fs";
import path from "path";
import express from "express";

const isProd = process.env.NODE_ENV === "production";

async function createServer(root = process.cwd(), hmrPort?: number) {
  const app = express();
  const resolve = (p: string) => path.resolve(root, p);

  let template: string;
  let vite: any;
  if (!isProd) {
    const { createServer } = await import("vite");
    vite = await createServer({
      root: resolve("frontend"),
      server: { middlewareMode: true, hmr: { port: hmrPort || 5173 } },
      appType: "custom",
    });
    app.use(vite.middlewares);
    template = fs.readFileSync(resolve("frontend/index.html"), "utf-8");
  } else {
    template = fs.readFileSync(resolve("frontend/dist/client/index.html"), "utf-8");
    app.use("/assets", express.static(resolve("frontend/dist/client/assets")));
  }

  async function render(url: string, ctx: any = {}) {
    let tpl = template;
    let renderFn: any;
    if (!isProd) {
      tpl = await vite.transformIndexHtml(url, tpl);
      renderFn = (await vite.ssrLoadModule("/src/entry-server.tsx")).render;
    } else {
      renderFn = (await import("../dist/server/entry-server.js")).render;
    }
    const appHtml = await renderFn(url, ctx);
    return tpl.replace(`<!--app-html-->`, appHtml.html).replace(`<!--app-head-->`, appHtml.head || "");
  }

  app.use("*", async (req, res) => {
    try {
      const html = await render(req.originalUrl, {});
      res.status(200).set({ "Content-Type": "text/html" }).end(html);
    } catch (e: any) {
      if (!isProd && vite) vite.ssrFixStacktrace(e);
      console.error(e);
      res.status(500).end(e.message);
    }
  });

  return { app };
}

createServer().then(({ app }) => {
  const port = Number(process.env.PORT || 5174);
  app.listen(port, () => console.log(`SSR on http://127.0.0.1:${port}`));
});
