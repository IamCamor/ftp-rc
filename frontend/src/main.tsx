import React from "react";
import { createRoot } from "react-dom/client";
import * as AppModule from "./App";

// Берём default, либо именованный App/Root, чтобы сборка не падала
const Picked =
  (AppModule as any).default ??
  (AppModule as any).App ??
  (AppModule as any).Root ??
  (() => React.createElement("div", { style:{padding:16,fontFamily:"system-ui"} }, "❗ App component not found in ./App.tsx"));

const el = document.getElementById("root");
if (!el) {
  const div = document.createElement("div");
  div.id = "root";
  document.body.appendChild(div);
  createRoot(div).render(React.createElement(Picked));
} else {
  createRoot(el).render(React.createElement(Picked));
}
