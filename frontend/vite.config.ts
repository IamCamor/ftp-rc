import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
export default defineConfig({
  plugins:[react()],
  build:{ outDir:"dist", assetsDir:"assets", sourcemap:true, chunkSizeWarningLimit:1000 },
  server:{ host:true, port:5173 },
  preview:{ host:true, port:4173 }
});

