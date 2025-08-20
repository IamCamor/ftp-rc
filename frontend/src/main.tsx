import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import MapScreen from "./screens/MapScreen";
createRoot(document.getElementById("root")!).render(<MapScreen />);
