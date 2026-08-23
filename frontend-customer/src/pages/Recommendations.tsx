import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import Layout from "../components/Layout";
import {
  Truck, ShieldCheck, MapPin, ArrowRight, User, Star, Sparkles, Box, CheckCircle2,
  CalendarCheck, Scale, Phone, AlertCircle, Plus
} from "lucide-react";
import { getTrucks, type TruckItem } from "../lib/truckStore";
import { getSharedCargoList, type CargoItem } from "../lib/cargoStore";
import { computeMLMatches, type MLMatchResult } from "../lib/mlMatchEngine";

export default function Recommendations() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const cargoIdParam = searchParams.get("cargoId");

  const [cargo, setCargo] = useState<CargoItem | null>(null);
  const [matches, setMatches] = useState<MLMatchResult[]>([]);
  const [bookedSuccess, setBookedSuccess] = useState<string | null>(null);

  useEffect(() => {
    const allCargo = getSharedCargoList();
    let currentCargo: CargoItem | undefined;
    if (cargoIdParam) {
      currentCargo = allCargo.find(c => c.id === cargoIdParam);
    }
    if (!currentCargo && allCargo.length > 0) {
      currentCargo = allCargo[0];
    }
    setCargo(currentCargo || null);

    if (currentCargo) {
      const fleet = getTrucks();
      const computed = computeMLMatches(currentCargo, fleet);
      setMatches(computed);
    } else {
      setMatches([]);
    }
  }, [cargoIdParam]);

  const handleInstantBook = (match: MLMatchResult) => {
    setBookedSuccess(match.truck.modelName);
    setTimeout(() => {
      navigate("/shipments");
    }, 2000);
  };

  return (
    <Layout>
      <div className="max-w-5xl mx-auto space-y-6 py-4 text-slate-900 dark:text-white">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-700 text-xs font-black mb-2">
              <Sparkles size={14} className="text-emerald-600" />
              <span>Multi-Factor GBDT Backhaul AI Match</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              Matched Empty Return Trucks
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Ranked by route corridor alignment, available payload capacity, and verified driver score.
            </p>
          </div>

          <button
            onClick={() => navigate("/book")}
            className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-4 py-2 rounded-xl text-xs shadow-sm transition flex items-center gap-1.5 cursor-pointer"
          >
            <Plus size={14} /> Book New Shipment
          </button>
        </div>

        {/* Consignment Overview Banner */}
        {cargo && (
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
            <div className="flex items-center gap-3.5">
              {cargo.cargoPhotoUrl ? (
                <div className="w-16 h-16 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0">
                  <img src={cargo.cargoPhotoUrl} alt="Consignment" className="w-full h-full object-cover" />
                </div>
              ) : (
                <div className="w-12 h-12 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 flex items-center justify-center font-black">
                  <Box size={24} />
                </div>
              )}

              <div className="space-y-0.5">
                <span className="text-[10px] font-mono text-amber-500 font-black uppercase">Consignment: {cargo.id}</span>
                <h4 className="font-black text-sm text-slate-900 dark:text-white">
                  {cargo.origin} ➔ {cargo.destination}
                </h4>
                <div className="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400 font-bold">
                  <span>{cargo.cargoType}</span>
                  <span>•</span>
                  <span>{cargo.weightTons} Tons</span>
                  <span>•</span>
                  <span>{cargo.pickupDate}</span>
                </div>
              </div>
            </div>

            <div className="text-right">
              <span className="text-[10px] uppercase font-bold text-slate-400 block">Estimated Freight</span>
              <span className="text-xl font-black text-slate-900 dark:text-white">
                ₹{cargo.offeredPriceInr.toLocaleString("en-IN")}
              </span>
            </div>
          </div>
        )}

        {/* Booking Success Toast */}
        {bookedSuccess && (
          <div className="p-4 bg-emerald-500 text-white font-black text-xs rounded-2xl shadow-lg flex items-center justify-between animate-fadeIn">
            <div className="flex items-center gap-2">
              <CheckCircle2 size={20} />
              <span>Shipment Booked with {bookedSuccess}! Redirecting to My Shipments...</span>
            </div>
          </div>
        )}

        {/* AI Recommendations List or Empty State */}
        {matches.length > 0 ? (
          <div className="space-y-4">
            {matches.map((m, idx) => (
              <div
                key={m.truck.id}
                className={`bg-white dark:bg-slate-900 border rounded-3xl p-6 shadow-sm hover:shadow-md transition flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6 ${
                  idx === 0
                    ? "border-amber-400/80 ring-2 ring-amber-400/20"
                    : "border-slate-200/80 dark:border-slate-800"
                }`}
              >
                {/* Truck Photo & Info */}
                <div className="flex flex-col sm:flex-row items-start gap-4 flex-1">
                  <div className="relative w-28 h-28 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0 shadow-sm">
                    <img
                      src={m.truck.photoUrl}
                      alt={m.truck.modelName}
                      className="w-full h-full object-cover"
                    />
                    <span className="absolute top-2 left-2 bg-slate-950/80 text-amber-400 text-[9px] font-black px-2 py-0.5 rounded uppercase">
                      {m.truck.regNumber}
                    </span>
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <h3 className="font-black text-base text-slate-900 dark:text-white">
                        {m.truck.modelName}
                      </h3>
                      <span className="bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 text-[10px] font-black px-2.5 py-0.5 rounded-full border border-amber-300/40">
                        {m.matchScore}% ML Match
                      </span>
                      {idx === 0 && (
                        <span className="bg-emerald-500 text-white text-[9px] font-black px-2 py-0.5 rounded-md uppercase">
                          Best Recommended
                        </span>
                      )}
                    </div>

                    <div className="flex flex-wrap items-center gap-3 text-xs font-bold text-slate-600 dark:text-slate-300">
                      <span className="flex items-center gap-1">
                        <Truck size={14} className="text-amber-500" /> {m.truck.truckType} ({m.truck.bodyLengthFeet}ft)
                      </span>
                      <span className="flex items-center gap-1">
                        <Scale size={14} className="text-amber-500" /> {m.truck.capacityTons}T Max Capacity
                      </span>
                      <span className="flex items-center gap-1">
                        <Star size={14} className="text-amber-500 fill-amber-400" /> {m.truck.driverRating} ({m.truck.driverName})
                      </span>
                    </div>

                    {/* Explainable AI Chips */}
                    <div className="flex flex-wrap items-center gap-1.5 pt-1">
                      {m.explainableReasons.map((reason, rIdx) => (
                        <span
                          key={rIdx}
                          className="text-[10px] font-bold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 px-2.5 py-0.5 rounded-lg border border-slate-200/60 dark:border-slate-700"
                        >
                          ✓ {reason}
                        </span>
                      ))}
                      <span className="text-[10px] font-bold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-400 px-2 py-0.5 rounded-lg">
                        🌱 -{m.carbonReductionKg}kg CO₂ Saved
                      </span>
                    </div>
                  </div>
                </div>

                {/* Price & Instant Book Button */}
                <div className="flex items-center justify-between lg:flex-col lg:items-end gap-3 w-full lg:w-auto border-t lg:border-t-0 pt-4 lg:pt-0 border-slate-100 dark:border-slate-800">
                  <div className="lg:text-right">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                      Optimized Backhaul Rate
                    </span>
                    <span className="text-2xl font-black text-slate-900 dark:text-white">
                      ₹{m.recommendedPriceInr.toLocaleString("en-IN")}
                    </span>
                    <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold block">
                      Zero Return Empty Overhead
                    </span>
                  </div>

                  <button
                    onClick={() => handleInstantBook(m)}
                    className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-3 rounded-2xl shadow-md transition text-xs flex items-center gap-1.5 cursor-pointer whitespace-nowrap"
                  >
                    <span>Book This Truck Instantly</span>
                    <ArrowRight size={15} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-12 text-center space-y-4 shadow-sm">
            <div className="w-16 h-16 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 flex items-center justify-center mx-auto">
              <Truck size={28} />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-black text-slate-900 dark:text-white">
                {cargo ? "No Matching Trucks on this Corridor Yet" : "No Active Shipment Request"}
              </h3>
              <p className="text-xs text-slate-500 max-w-md mx-auto leading-relaxed">
                {cargo
                  ? `There are currently no registered trucks available for the ${cargo.origin} ➔ ${cargo.destination} corridor. As soon as a truck owner registers or posts on this route, it will automatically match here.`
                  : "Book a new commercial shipment to find verified returning trucks with zero deadhead miles."}
              </p>
            </div>
            <button
              onClick={() => navigate("/book")}
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl shadow-sm transition text-xs inline-flex items-center gap-1.5 cursor-pointer"
            >
              + Book New Shipment
            </button>
          </div>
        )}
      </div>
    </Layout>
  );
}
