import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./styles/app.css";

declare global {
  interface Window { API_BASE?: string }
}

// Позволяет при деплое переопределить базу API из <script>.
if (!window.API_BASE) {
  window.API_BASE = (location.protocol + "//" + location.host + "/api/v1");
}

const el = document.getElementById("root")!;
createRoot(el).render(
  <React.StrictMode>
    <BrowserRouter>
      <App/>
    </BrowserRouter>
  </React.StrictMode>
);
