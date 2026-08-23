import { useState } from "react";
import { Navigation, MapPin, Truck, Phone, Radio, ShieldCheck, Gauge, Clock, ChevronRight } from "lucide-react";
import type { ShipmentItem } from "../lib/shipmentStore";

interface LiveTrackingMapProps {
  shipments: ShipmentItem[];
  selectedShipmentId?: string;
  onSelectShipment?: (shipment: ShipmentItem) => void;
}

export default function LiveTrackingMap({ shipments, selectedShipmentId, onSelectShipment }: LiveTrackingMapProps) {
  const activeShipments = shipments.filter(s => s.status !== "Delivered");
  const [currentId, setCurrentId] = useState<string>(selectedShipmentId || (activeShipments[0]?.id || shipments[0]?.id || ""));

  const activeShipment = shipments.find(s => s.id === currentId) || shipments[0];

  if (!activeShipment) return null;

  return (
    <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-5 text-slate-900 dark:text-white">
      {/* Map Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 border-b border-slate-100 dark:border-slate-800 pb-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 text-[10px] font-black mb-1">
            <Radio size={12} className="text-emerald-500 animate-pulse" />
            <span>LIVE GPS TELEMETRY &bull; 4G AIS-140 SATELLITE TRACKER</span>
          </div>
          <h3 className="text-base font-black tracking-tight">
            Live Highway Corridor Tracking
          </h3>
        </div>

        {/* Active Shipments Selector */}
        {activeShipments.length > 1 && (
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-slate-400 font-bold">Active Load:</span>
            <select
              value={currentId}
              onChange={(e) => {
                setCurrentId(e.target.value);
                const chosen = shipments.find(s => s.id === e.target.value);
                if (chosen && onSelectShipment) onSelectShipment(chosen);
              }}
              className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-1.5 text-xs font-bold"
            >
              {activeShipments.map(s => (
                <option key={s.id} value={s.id}>
                  {s.id} ({s.origin.split(" ")[0]} ➔ {s.destination.split(" ")[0]})
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Interactive Map Visual */}
      <div className="relative rounded-2xl overflow-hidden bg-slate-950 border border-slate-800 h-80 sm:h-96 flex items-center justify-center p-4">
        {/* SVG Route Visualization with Highway Canvas */}
        <svg viewBox="0 0 800 360" className="w-full h-full">
          <defs>
            <linearGradient id="routeGradient" x1="0%" y1="100%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#10B981" />
              <stop offset="50%" stopColor="#F59E0B" />
              <stop offset="100%" stopColor="#EF4444" />
            </linearGradient>
            <radialGradient id="pulseGlow" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#FFC800" stopOpacity="0.8" />
              <stop offset="100%" stopColor="#FFC800" stopOpacity="0" />
            </radialGradient>
            <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#1E293B" strokeWidth="1" />
            </pattern>
          </defs>

          {/* Grid Map Background */}
          <rect width="100%" height="100%" fill="url(#grid)" />

          {/* Major Indian Highway Corridors Map Path */}
          {/* Western Corridor Curve (Mumbai -> Gujarat -> Rajasthan -> Delhi) */}
          <path
            d="M 120 300 C 220 280, 260 200, 420 180 C 540 160, 600 120, 680 70"
            fill="none"
            stroke="#334155"
            strokeWidth="8"
            strokeLinecap="round"
          />
          {/* Active Highlighted Trajectory Path */}
          <path
            d="M 120 300 C 220 280, 260 200, 420 180 C 540 160, 600 120, 680 70"
            fill="none"
            stroke="url(#routeGradient)"
            strokeWidth="4"
            strokeDasharray="8 4"
            strokeLinecap="round"
            className="animate-dash"
          />

          {/* Checkpoint Toll Plaza Badges */}
          <g transform="translate(280, 230)">
            <circle cx="0" cy="0" r="4" fill="#94A3B8" />
            <text x="8" y="4" fill="#94A3B8" fontSize="10" fontFamily="sans-serif" fontWeight="bold">Surat Toll</text>
          </g>
          <g transform="translate(520, 160)">
            <circle cx="0" cy="0" r="4" fill="#94A3B8" />
            <text x="8" y="4" fill="#94A3B8" fontSize="10" fontFamily="sans-serif" fontWeight="bold">Jaipur Bypass</text>
          </g>

          {/* 1. Origin Node (Pickup) */}
          <g transform="translate(120, 300)">
            <circle cx="0" cy="0" r="14" fill="#10B981" fillOpacity="0.2" />
            <circle cx="0" cy="0" r="8" fill="#10B981" />
            <text x="-30" y="-14" fill="#10B981" fontSize="11" fontFamily="sans-serif" fontWeight="900">
              🟢 PICKUP: {activeShipment.origin.split(" ")[0]}
            </text>
          </g>

          {/* 2. Destination Node (Delivery) */}
          <g transform="translate(680, 70)">
            <circle cx="0" cy="0" r="14" fill="#EF4444" fillOpacity="0.2" />
            <circle cx="0" cy="0" r="8" fill="#EF4444" />
            <text x="-30" y="-14" fill="#EF4444" fontSize="11" fontFamily="sans-serif" fontWeight="900">
              🔴 DROP: {activeShipment.destination.split(" ")[0]}
            </text>
          </g>

          {/* 3. Live Animated Vehicle Location */}
          {/* Interpolated position around ~65% of the route */}
          <g transform="translate(420, 180)">
            <circle cx="0" cy="0" r="28" fill="url(#pulseGlow)" className="animate-ping" />
            <circle cx="0" cy="0" r="16" fill="#0F172A" stroke="#FFC800" strokeWidth="3" />
            <text x="-8" y="5" fontSize="14">🚛</text>

            {/* Floating Live Telemetry Tooltip */}
            <g transform="translate(-75, -55)">
              <rect width="150" height="42" rx="8" fill="#0F172A" stroke="#FFC800" strokeWidth="1.5" />
              <text x="75" y="16" fill="#FFC800" fontSize="10" fontFamily="sans-serif" fontWeight="900" textAnchor="middle">
                {activeShipment.truckRegNo} • {activeShipment.speedKmph || 58} km/h
              </text>
              <text x="75" y="32" fill="#FFFFFF" fontSize="9" fontFamily="sans-serif" fontWeight="bold" textAnchor="middle">
                Driver: {activeShipment.driverName}
              </text>
            </g>
          </g>
        </svg>

        {/* Live Speed & Distance Telemetry HUD Floating Card */}
        <div className="absolute bottom-4 left-4 right-4 bg-slate-900/90 backdrop-blur-md border border-slate-700/80 rounded-2xl p-3.5 flex flex-wrap items-center justify-between gap-3 text-white text-xs">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-black">
              <Truck size={20} />
            </div>
            <div>
              <span className="font-black text-sm block">{activeShipment.truckModel}</span>
              <span className="text-[11px] text-amber-400 font-mono font-black">{activeShipment.truckRegNo}</span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div>
              <span className="text-[10px] text-slate-400 uppercase block">Telemetry Speed</span>
              <span className="font-black text-sm text-emerald-400">{activeShipment.speedKmph || 58} km/h</span>
            </div>
            <div>
              <span className="text-[10px] text-slate-400 uppercase block">ETA Status</span>
              <span className="font-black text-xs text-amber-300">{activeShipment.etaText}</span>
            </div>
          </div>

          <a
            href={`tel:${activeShipment.driverPhone}`}
            className="bg-emerald-600 hover:bg-emerald-500 text-white font-black px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-md transition"
          >
            <Phone size={13} />
            <span>Call Driver ({activeShipment.driverName})</span>
          </a>
        </div>
      </div>
    </div>
  );
}
