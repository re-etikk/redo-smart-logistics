import { useEffect, useRef, useState } from "react";
import { Skeleton } from "../components/ui";

export const CITIES: Record<string, [number, number]> = {
  Delhi: [28.6139, 77.209], Mumbai: [19.076, 72.8777], Pune: [18.5204, 73.8567],
  Jaipur: [26.9124, 75.7873], Surat: [21.1702, 72.8311],
  Bengaluru: [12.9716, 77.5946], Hyderabad: [17.385, 78.4867],
};

export default function MapPanel({ origin, destination, position, heightClass = "h-64 md:h-80" }: {
  origin: string; destination: string; position?: [number, number] | null; heightClass?: string;
}) {
  const el = useRef<HTMLDivElement>(null);
  const mapRef = useRef<any>(null);
  const markerRef = useRef<any>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const L = (await import("leaflet")).default;
      if (cancelled || !el.current) return;
      const a = CITIES[origin] ?? [22, 78];
      const b = CITIES[destination] ?? [22, 79];
      const map = L.map(el.current, { zoomControl: false });
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "© OpenStreetMap contributors",
      }).addTo(map);
      L.polyline([a, b], { color: "#2952E3", weight: 3, dashArray: "6 8" }).addTo(map);
      const dot = (latlng: [number, number], label: string) =>
        L.circleMarker(latlng, { radius: 6, color: "#16212D", fillColor: "#16212D", fillOpacity: 1 })
          .addTo(map).bindTooltip(label, { permanent: true, direction: "top", offset: [0, -8] });
      dot(a, origin); dot(b, destination);
      map.fitBounds(L.latLngBounds([a, b]).pad(0.25));
      mapRef.current = { map, L };
      setReady(true);
    })();
    return () => { cancelled = true; mapRef.current?.map.remove(); mapRef.current = null; markerRef.current = null; };
  }, [origin, destination]);

  useEffect(() => {
    if (!mapRef.current || !position) return;
    const { map, L } = mapRef.current;
    if (!markerRef.current) {
      markerRef.current = L.circleMarker(position, { radius: 8, color: "#12805C", fillColor: "#12805C", fillOpacity: 0.9 })
        .addTo(map).bindTooltip("Truck (simulated)", { direction: "top", offset: [0, -8] });
    } else markerRef.current.setLatLng(position);
  }, [position]);

  return (
    <div className={`relative ${heightClass} rounded-xl overflow-hidden border border-line`}>
      {!ready && <Skeleton className="absolute inset-0 rounded-none" />}
      <div ref={el} className="absolute inset-0" aria-label={`Map of route from ${origin} to ${destination}`} />
    </div>
  );
}
