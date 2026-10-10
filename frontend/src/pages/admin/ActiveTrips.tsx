import { useState, useEffect } from "react";
import { 
  Activity, Navigation, MapPin, Truck, AlertTriangle, Clock, 
  Search, RefreshCw, Eye, ArrowRight, Phone, ShieldCheck, Gauge
} from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../components/ui";

interface TripItem {
  booking_id: string;
  shipment_id: string;
  origin: string;
  destination: string;
  distance_km: number;
  cargo_type: string;
  weight_tons: number;
  agreed_price_inr: number;
  trip_status: string;
  truck_id: string;
  registration_number: string;
  truck_type: string;
  driver_name: string;
  driver_phone?: string;
  shipper_name: string;
  shipper_phone?: string;
  current_lat: number;
  current_lng: number;
  speed_kmh: number;
  heading_deg: number;
  eta: string;
  is_stale: boolean;
  is_delayed: boolean;
  last_ping: string;
}

export default function ActiveTrips() {
  const [trips, setTrips] = useState<TripItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTrip, setSelectedTrip] = useState<TripItem | null>(null);

  const fetchTrips = async () => {
    setLoading(true);
    try {
      const data = await api.get<TripItem[]>("/admin/trips");
      setTrips(data || []);
    } catch (err) {
      console.error("Error fetching trips:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTrips();
    const interval = setInterval(fetchTrips, 15000); // 15s live refresh
    return () => clearInterval(interval);
  }, []);

  const filteredTrips = trips.filter((t) => {
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        t.origin.toLowerCase().includes(q) ||
        t.destination.toLowerCase().includes(q) ||
        t.registration_number.toLowerCase().includes(q) ||
        t.driver_name.toLowerCase().includes(q) ||
        t.shipment_id.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Active Trips & Corridor Operations"
            sub="Real-time telematics oversight for moving commercial freight across national corridors."
          />
          <Button
            variant="secondary"
            onClick={fetchTrips}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Sync Live Telemetry</span>
          </Button>
        </div>

        {/* Telemetry Summary Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div className="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800">
            <span className="text-[10px] text-slate-400 font-bold uppercase">Moving Freight</span>
            <div className="text-xl font-black text-amber-400 mt-0.5">{trips.length} Active Trips</div>
            <span className="text-[10px] text-slate-500">Live GPS tracking active</span>
          </div>

          <div className="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800">
            <span className="text-[10px] text-slate-400 font-bold uppercase">Stale Signal Check</span>
            <div className="text-xl font-black text-emerald-400 mt-0.5">
              {trips.filter(t => t.is_stale).length === 0 ? "0 Warnings" : `${trips.filter(t => t.is_stale).length} Stale Signals`}
            </div>
            <span className="text-[10px] text-slate-500">&gt; 30m ping SLA compliant</span>
          </div>

          <div className="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800">
            <span className="text-[10px] text-slate-400 font-bold uppercase">Aggregated Payload</span>
            <div className="text-xl font-black text-sky-400 mt-0.5">
              {trips.reduce((acc, t) => acc + (t.weight_tons || 0), 0).toFixed(1)} Tons
            </div>
            <span className="text-[10px] text-slate-500">In transit payload</span>
          </div>

          <div className="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800">
            <span className="text-[10px] text-slate-400 font-bold uppercase">Freight Escrow Value</span>
            <div className="text-xl font-black text-emerald-400 mt-0.5">
              ₹{trips.reduce((acc, t) => acc + (t.agreed_price_inr || 0), 0).toLocaleString("en-IN")}
            </div>
            <span className="text-[10px] text-slate-500">Locked in settlement vault</span>
          </div>
        </div>

        {/* Search Input */}
        <div className="relative">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search active trip by corridor, truck plate, or driver name..."
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        {/* Trips Table & Drawer */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <div className={selectedTrip ? "lg:col-span-7" : "lg:col-span-12"}>
            <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
              {loading && trips.length === 0 ? (
                <div className="p-6"><CardSkeleton /></div>
              ) : filteredTrips.length === 0 ? (
                <div className="text-center py-12 text-slate-500 text-xs">
                  No trips currently in transit.
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                      <tr>
                        <th className="py-3 px-4">Corridor & Route</th>
                        <th className="py-3 px-4">Vehicle</th>
                        <th className="py-3 px-4">Driver</th>
                        <th className="py-3 px-4">Speed / Telemetry</th>
                        <th className="py-3 px-4">ETA</th>
                        <th className="py-3 px-4">Status</th>
                        <th className="py-3 px-4 text-right">Inspect</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/60">
                      {filteredTrips.map((t) => {
                        const isSelected = selectedTrip?.booking_id === t.booking_id;
                        return (
                          <tr
                            key={t.booking_id}
                            onClick={() => setSelectedTrip(t)}
                            className={`cursor-pointer transition ${
                              isSelected ? "bg-amber-500/10" : "hover:bg-slate-800/40"
                            }`}
                          >
                            <td className="py-3 px-4">
                              <div className="font-bold text-white">{t.origin} → {t.destination}</div>
                              <div className="text-[10px] text-slate-400">{t.distance_km} km • {t.weight_tons} Tons ({t.cargo_type})</div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="font-mono font-bold text-amber-400">{t.registration_number}</div>
                              <div className="text-[10px] text-slate-500">{t.truck_type}</div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="text-slate-200 font-semibold">{t.driver_name}</div>
                              <div className="text-[10px] text-slate-500 font-mono">
                                {t.driver_phone ? t.driver_phone.replace(/(\+91\d{2})\d{4}(\d{4})/, "$1••••$2") : "—"}
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="flex items-center gap-1.5 font-mono text-slate-300">
                                <Gauge size={12} className="text-emerald-400" />
                                <span>{t.speed_kmh} km/h</span>
                              </div>
                              {t.is_stale ? (
                                <span className="text-[9px] font-black text-rose-400 flex items-center gap-0.5">
                                  <AlertTriangle size={10} />
                                  <span>SIGNAL STALE</span>
                                </span>
                              ) : (
                                <span className="text-[9px] font-bold text-emerald-400">LIVE GPS</span>
                              )}
                            </td>
                            <td className="py-3 px-4 text-slate-300 font-bold">
                              {t.eta}
                            </td>
                            <td className="py-3 px-4">
                              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-amber-500/15 text-amber-400 border border-amber-500/30">
                                {t.trip_status.replace("_", " ")}
                              </span>
                            </td>
                            <td className="py-3 px-4 text-right">
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setSelectedTrip(t);
                                }}
                                className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition"
                              >
                                <Eye size={14} />
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </Card>
          </div>

          {/* Trip Drawer */}
          {selectedTrip && (
            <div className="lg:col-span-5">
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900 sticky top-20 shadow-2xl space-y-4">
                <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Trip Telemetry Control</span>
                    <h3 className="text-base font-black text-white">{selectedTrip.origin} → {selectedTrip.destination}</h3>
                    <p className="text-xs text-slate-400">Shipment #{selectedTrip.shipment_id?.slice(-8)}</p>
                  </div>
                  <span className="px-2.5 py-1 rounded-full text-[10px] font-black uppercase bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                    {selectedTrip.trip_status.replace("_", " ")}
                  </span>
                </div>

                {/* GPS Telemetry */}
                <div className="p-3 rounded-xl bg-slate-950/70 border border-slate-800 space-y-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-400 flex items-center gap-1.5">
                      <MapPin size={13} className="text-amber-400" />
                      <span>Current Lat / Lng</span>
                    </span>
                    <span className="font-mono text-slate-200">
                      {selectedTrip.current_lat.toFixed(4)}, {selectedTrip.current_lng.toFixed(4)}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-400">Current Velocity</span>
                    <span className="font-mono font-bold text-emerald-400">{selectedTrip.speed_kmh} km/h</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-400">Estimated Arrival (ETA)</span>
                    <span className="font-bold text-amber-400">{selectedTrip.eta}</span>
                  </div>
                </div>

                {/* Assigned Commercial Truck & Driver */}
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Commercial Truck</span>
                    <span className="font-mono font-bold text-white">{selectedTrip.registration_number}</span>
                    <span className="text-[10px] text-slate-400 block">{selectedTrip.truck_type}</span>
                  </div>
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Driver Partner</span>
                    <span className="font-semibold text-white">{selectedTrip.driver_name}</span>
                    <span className="text-[10px] text-slate-500 block font-mono">{selectedTrip.driver_phone || "No phone"}</span>
                  </div>
                </div>

                {/* Shipper Details & Fare */}
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Shipper</span>
                    <span className="font-semibold text-white">{selectedTrip.shipper_name}</span>
                  </div>
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Agreed Freight Price</span>
                    <span className="font-bold text-emerald-400">₹{selectedTrip.agreed_price_inr.toLocaleString("en-IN")}</span>
                  </div>
                </div>

                {/* Dispatch Override Link */}
                <div className="pt-2 border-t border-slate-800 flex justify-end">
                  <button
                    onClick={() => setSelectedTrip(null)}
                    className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold"
                  >
                    Close Panel
                  </button>
                </div>
              </Card>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}
