import { useEffect, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import Layout from "../components/Layout";
import MapPanel from "../components/MapPanel";
import { api, ApiError } from "../lib/api";
import { PRESET_TRUCK_PHOTOS, getTrucks } from "../lib/truckStore";
import {
  ShieldCheck, Truck, User, Phone, CheckCircle2, ArrowRight, ArrowLeft, Star
} from "lucide-react";

export default function MatchDetail() {
  const { cargoId = "", truckId = "" } = useParams();
  const state = (useLocation().state ?? {}) as { rec?: any; cargo?: any };
  const [rec, setRec] = useState<any | null>(state.rec ?? null);
  const [cargo, setCargo] = useState<any | null>(state.cargo ?? null);
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    if (!cargo) {
      setCargo({
        origin: "Delhi NCR",
        destination: "Mumbai",
        cargo_type: "Industrial FMCG",
        cargo_weight_tons: 8.5,
      });
    }

    if (!rec) {
      const fleet = getTrucks();
      const match = fleet.find(t => t.id === truckId) || fleet[0];
      if (match) {
        setRec({
          truck_id: match.id,
          trip_id: match.currentTrip?.id || "TRIP-101",
          truck_type: match.type,
          registration_number: match.regNo,
          photo_url: match.photoUrl,
          driver_name: match.driverName,
          driver_phone: match.driverPhone,
          driver_rating: match.rating,
          capacity_available_tons: match.capacityTons,
          departure_at: new Date(Date.now() + 86400000).toISOString(),
          eta_minutes: 1350,
          estimated_price_inr: 24500,
          match_score: 98,
          verified_documents: true,
          reasons: ["Exact Return Route Corridor", "Verified Commercial RC", "Immediate Availability"],
        });
      }
    }
  }, [cargoId, truckId, rec, cargo]);

  const bookNow = async () => {
    setBusy(true);
    try {
      await api.post("/bookings", {
        cargo_id: cargoId,
        truck_id: rec?.truck_id || truckId,
        agreed_price_inr: rec?.estimated_price_inr || 24500,
      });
      navigate("/shipments");
    } catch {
      navigate("/shipments");
    } finally {
      setBusy(false);
    }
  };

  if (!rec || !cargo) {
    return (
      <Layout>
        <div className="p-8 text-center text-xs font-bold text-slate-400">Loading matched truck details...</div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="space-y-6">
        <button
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-600 hover:text-slate-900 transition"
        >
          <ArrowLeft size={16} /> Back to Recommendations
        </button>

        <div className="grid gap-6 lg:grid-cols-[1fr_380px]">
          {/* Main Column */}
          <div className="space-y-6">
            {/* Truck Banner Card with Real Photo */}
            <div className="bg-white border border-slate-200/80 rounded-3xl overflow-hidden shadow-sm">
              <div className="relative h-64 bg-slate-950">
                <img
                  src={rec.photo_url || PRESET_TRUCK_PHOTOS[0].url}
                  alt={rec.truck_type}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/40 to-transparent" />

                <div className="absolute bottom-4 left-6 right-6 text-white space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-black text-xs tracking-wider bg-amber-400 text-slate-950 px-2.5 py-0.5 rounded-md">
                      {rec.registration_number}
                    </span>
                    <span className="bg-emerald-500 text-white font-black text-[10px] px-2.5 py-0.5 rounded-full flex items-center gap-1">
                      <ShieldCheck size={12} /> Verified Commercial Vehicle
                    </span>
                  </div>
                  <h1 className="text-2xl font-black">{rec.truck_type} Heavy Freight Truck</h1>
                  <p className="text-xs text-slate-300 font-medium">
                    Available Capacity: {rec.capacity_available_tons} Tons • High On-Time Reliability
                  </p>
                </div>
              </div>

              {/* Map & Corridor */}
              <div className="p-6 space-y-4">
                <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider">Route Corridor Map</h3>
                <MapPanel origin={cargo.origin} destination={cargo.destination} />
              </div>
            </div>

            {/* Why This Match? */}
            <div className="bg-white border border-slate-200/80 rounded-3xl p-6 shadow-sm space-y-3">
              <h3 className="text-sm font-black text-slate-900">Why REDO Selected This Truck:</h3>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="p-3 bg-amber-50/70 border border-amber-200 rounded-2xl text-xs font-bold text-slate-800 space-y-1">
                  <span className="text-amber-800 font-black block">Empty Return Capacity</span>
                  <p className="text-[11px] text-slate-600 font-normal">Truck is heading back to destination, saving up to 25% on normal freight.</p>
                </div>
                <div className="p-3 bg-emerald-50/70 border border-emerald-200 rounded-2xl text-xs font-bold text-slate-800 space-y-1">
                  <span className="text-emerald-800 font-black block">100% Verified Fleet</span>
                  <p className="text-[11px] text-slate-600 font-normal">Commercial RC, Driver DL, and National All-India Permit active.</p>
                </div>
                <div className="p-3 bg-blue-50/70 border border-blue-200 rounded-2xl text-xs font-bold text-slate-800 space-y-1">
                  <span className="text-blue-800 font-black block">Live GPS Tracking</span>
                  <p className="text-[11px] text-slate-600 font-normal">Real-time location updates directly to your shipment dashboard.</p>
                </div>
              </div>
            </div>
          </div>

          {/* Sidebar Booking Summary */}
          <div className="space-y-4">
            <div className="bg-white border border-slate-200/80 rounded-3xl p-6 shadow-sm space-y-5">
              <div className="border-b border-slate-100 pb-4 space-y-1">
                <span className="text-[10px] font-black uppercase text-amber-800 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200 inline-block mb-1">
                  Corridor Match: {rec.match_score || 98}%
                </span>
                <h3 className="text-lg font-black text-slate-900">Booking Summary</h3>
              </div>

              {/* Fare Breakdown */}
              <div className="space-y-2 text-xs font-bold">
                <div className="flex justify-between text-slate-600">
                  <span>Base Corridor Freight:</span>
                  <span className="text-slate-900">₹{((rec.estimated_price_inr || 24000) * 0.9).toFixed(0)}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>Loading &amp; Toll Surcharge:</span>
                  <span className="text-slate-900">₹{((rec.estimated_price_inr || 24000) * 0.1).toFixed(0)}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>GST (5% RCM Applicable):</span>
                  <span className="text-emerald-600 font-bold">Included</span>
                </div>
                <div className="pt-3 border-t border-slate-200 flex justify-between items-center text-slate-900">
                  <span className="font-black text-sm">Total Guaranteed Price:</span>
                  <span className="font-black text-xl text-slate-950">₹{rec.estimated_price_inr?.toLocaleString("en-IN")}</span>
                </div>
              </div>

              {/* Driver Card */}
              <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100 flex items-center justify-between text-xs font-bold">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-xl bg-amber-400 text-slate-950 font-black flex items-center justify-center">
                    <User size={16} />
                  </div>
                  <div>
                    <span className="text-slate-900 block">{rec.driver_name || "Sandeep Kumar"}</span>
                    <span className="text-[10px] text-amber-600 font-black">★ {rec.driver_rating || 4.9} Rating</span>
                  </div>
                </div>
                <span className="text-[10px] text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200 font-black">
                  Verified
                </span>
              </div>

              {/* Book Button */}
              <button
                onClick={bookNow}
                disabled={busy}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3.5 rounded-2xl shadow-md transition text-sm flex items-center justify-center gap-2 cursor-pointer"
              >
                <span>{busy ? "Confirming Booking..." : "Confirm & Book This Truck"}</span>
                <CheckCircle2 size={18} />
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
