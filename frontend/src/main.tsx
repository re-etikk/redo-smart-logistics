import React from "react";
import ReactDOM from "react-dom/client";
import "leaflet/dist/leaflet.css";
import App from "./App";
import "./styles.css";

// Dynamically load Google Maps Places API if API key is present in environment
const mapsKey = import.meta.env?.VITE_GOOGLE_MAPS_API_KEY;
if (mapsKey && !document.getElementById("google-maps-script")) {
  const script = document.createElement("script");
  script.id = "google-maps-script";
  script.src = `https://maps.googleapis.com/maps/api/js?key=${mapsKey}&libraries=places`;
  script.async = true;
  document.head.appendChild(script);
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
