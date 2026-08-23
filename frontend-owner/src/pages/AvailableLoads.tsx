import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  MapPin, Weight, Search, Filter, ArrowRight, ShieldCheck, Zap,
  CheckCircle2, Clock, Truck, Box, Phone, X, Check, Camera
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getTrucks } from "../lib/truckStore";
import { getSharedCargoList, syncFromCloud, assignTruckToCargo, type CargoItem } from "../lib/cargoStore";

export default function AvailableLoads() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [search, setSearch] = useState("");
  const [filterType, setFilterType] = useState("all");
  const [selectedLoad, setSelectedLoad] = useState<any | null>(null);
  const [acceptedSuccess, setAcceptedSuccess] = useState(false);
  const [selectedTruckId, setSelectedTruckId] = useState("");

  const trucks = getTrucks();
  const [allLoads, setAllLoads] = useState<CargoItem[]>([]);

  const refreshLoads = () => {
    const customLoads = getSharedCargoList();
    setAllLoads(customLoads);
  };

  useEffect(() => {
    refreshLoads();
    syncFromCloud().then(updated => {
      if (updated && updated.length > 0) setAllLoads(updated);
    });

    if (trucks.length > 0) {
      setSelectedTruckId(trucks[0].id);
    }
    const handleUpdate = () => refreshLoads();
    window.addEventListener("redo_cargo_updated", handleUpdate);

    const interval = setInterval(() => {
      syncFromCloud().then(updated => {
        if (updated && updated.length > 0) setAllLoads(updated);
      });
    }, 3000);

    return () => {
      window.removeEventListener("redo_cargo_updated", handleUpdate);
      clearInterval(interval);
    };
  }, []);

  const filteredLoads = allLoads.filter((l) => {
    const matchesSearch =
      l.origin.toLowerCase().includes(search.toLowerCase()) ||
      l.destination.toLowerCase().includes(search.toLowerCase()) ||
      l.cargoType.toLowerCase().includes(search.toLowerCase());

    const matchesFilter =
      filterType === "all" ||
      (filterType === "immediate" && l.urgency.includes("Immediate")) ||
      (filterType === "heavy" && l.weightTons > 6.0);

    return matchesSearch && matchesFilter;
  });

  const handleAcceptLoad = (load: any) => {
    setSelectedLoad(load);
    setAcceptedSuccess(false);
  };

  const confirmAcceptLoad = () => {
    if (selectedLoad && selectedTruckId) {
      const trk = trucks.find(t => t.id === selectedTruckId) || trucks[0];
      assignTruckToCargo(selectedLoad.id, {
        truckId: trk.id,
        regNo: trk.regNumber,
        driverName: trk.driverName,
      });
    }

    setAcceptedSuccess(true);
    setTimeout(() => {
      setSelectedLoad(null);
      setAcceptedSuccess(false);
      navigate("/bookings");
    }, 1500);
  };

  return (
    <OwnerLayout activeTab="loads" promoCardType="truck">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900 dark:text-white">
              {t("findLoads")} (Live Consignments)
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Instant cargo matching for your return trips. Accept customer freight consignments directly.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400">
              Active Fleet: <strong className="text-amber-500">{trucks.length} Trucks Registered</strong>
            </span>
          </div>
        </div>

        {/* Filter and Search Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-bold text-xs overflow-x-auto w-full md:w-auto">
            <button
              onClick={() => setFilterType("all")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                filterType === "all" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              }`}
            >
              All Open Consignments ({allLoads.length})
            </button>
            <button
              onClick={() => setFilterType("immediate")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                filterType === "immediate" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              }`}
            >
              <Zap size={14} className="text-rose-500" /> Immediate Dispatch
            </button>
            <button
              onClick={() => setFilterType("heavy")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                filterType === "heavy" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              }`}
            >
              Heavy Tonnage (&gt;6T)
            </button>
          </div>

          <div className="relative w-full md:w-72">
            <Search size={15} className="text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by city, cargo or type..."
              className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl pl-9 pr-3.5 py-2 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>
        </div>

        {/* Loads Grid */}
        {filteredLoads.length === 0 ? (
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-12 text-center space-y-3">
            <div className="w-14 h-14 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 mx-auto flex items-center justify-center">
              <Box size={28} />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-black text-slate-900 dark:text-white">No Open Consignments</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mx-auto">
                Customer consignments posted from the customer app will appear here live.
              </p>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {filteredLoads.map((load) => (
              <div
                key={load.id}
                className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm hover:shadow-md transition flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6"
              >
                {/* Origin / Dest & Cargo */}
                <div className="flex flex-col sm:flex-row items-start gap-4 flex-1">
                  {load.cargoPhotoUrl ? (
                    <div className="w-20 h-20 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0 shadow-sm">
                      <img src={load.cargoPhotoUrl} alt={load.cargoType} className="w-full h-full object-cover" />
                    </div>
                  ) : (
                    <div className="w-16 h-16 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 flex items-center justify-center font-black shrink-0 shadow-sm">
                      <Box size={26} />
                    </div>
                  )}

                  <div className="space-y-1.5">
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-mono text-amber-500 font-black">{load.id}</span>
                      <span className="text-[9px] font-black px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300">
                        {load.urgency}
                      </span>
                      <span className="text-[10px] font-bold text-slate-400">By {load.shipperName}</span>
                    </div>

                    <div className="space-y-1 text-xs font-bold">
                      <div className="flex items-center gap-2">
                        <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0" />
                        <span className="text-slate-900 dark:text-white font-black">{load.origin}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="w-2.5 h-2.5 rounded-full bg-rose-500 shrink-0" />
                        <span className="text-slate-900 dark:text-white font-black">{load.destination}</span>
                      </div>
                    </div>

                    <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-500 dark:text-slate-400 pt-1">
                      <span className="flex items-center gap-1">
                        <Box size={13} className="text-amber-500" /> {load.cargoType}
                      </span>
                      <span className="flex items-center gap-1">
                        <Weight size={13} className="text-amber-500" /> {load.weightTons} Tons
                      </span>
                      <span className="flex items-center gap-1">
                        <Truck size={13} className="text-amber-500" /> {load.truckRequired}
                      </span>
                      <span className="flex items-center gap-1">
                        <Clock size={13} className="text-amber-500" /> Pickup: {load.pickupDate}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Price & Action Button */}
                <div className="flex items-center justify-between lg:flex-col lg:items-end gap-3 w-full lg:w-auto border-t lg:border-t-0 pt-3 lg:pt-0 border-slate-100 dark:border-slate-800">
                  <div className="lg:text-right">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Offered Rate</span>
                    <span className="text-2xl font-black text-slate-900 dark:text-white">
                      ₹{load.offeredPriceInr.toLocaleString("en-IN")}
                    </span>
                    <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold block">
                      100% Escrow Guaranteed
                    </span>
                  </div>

                  <button
                    onClick={() => handleAcceptLoad(load)}
                    className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer whitespace-nowrap"
                  >
                    <span>Accept Consignment</span>
                    <ArrowRight size={14} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ========================================================================= */}
      {/* ACCEPT LOAD ASSIGNMENT MODAL */}
      {/* ========================================================================= */}
      {selectedLoad && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <span className="text-[10px] font-mono text-amber-500 font-black block">CONFIRM FREIGHT ASSIGNMENT</span>
                <h3 className="text-base font-black">{selectedLoad.id} • {selectedLoad.cargoType}</h3>
              </div>
              <button onClick={() => setSelectedLoad(null)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            {acceptedSuccess ? (
              <div className="p-6 text-center space-y-3">
                <div className="w-14 h-14 rounded-full bg-emerald-100 dark:bg-emerald-950 text-emerald-600 mx-auto flex items-center justify-center font-black">
                  <Check size={28} />
                </div>
                <h4 className="text-lg font-black">Consignment Accepted!</h4>
                <p className="text-xs text-slate-400">Driver notified with pickup PIN. Redirecting to My Bookings...</p>
              </div>
            ) : (
              <>
                <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-2">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Route Corridor:</span>
                    <span>{selectedLoad.origin} ➔ {selectedLoad.destination}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Distance:</span>
                    <span>{selectedLoad.distanceKm} Kilometers</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Shipper Enterprise:</span>
                    <span className="font-black text-amber-600 dark:text-amber-400">{selectedLoad.shipperName}</span>
                  </div>
                </div>

                <div>
                  <label className="block mb-1.5">Select Truck from Your Registered Fleet *</label>
                  <select
                    value={selectedTruckId}
                    onChange={(e) => setSelectedTruckId(e.target.value)}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold"
                  >
                    {trucks.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.modelName} ({t.regNumber}) — {t.capacityTons}T Available
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex items-center justify-between p-3.5 bg-amber-500/10 border border-amber-400/40 rounded-2xl">
                  <span className="text-slate-400">Freight Payout:</span>
                  <span className="text-lg font-black text-slate-900 dark:text-white">
                    ₹{selectedLoad.offeredPriceInr.toLocaleString("en-IN")}
                  </span>
                </div>

                <button
                  onClick={confirmAcceptLoad}
                  className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2 cursor-pointer"
                >
                  <Check size={16} /> Confirm &amp; Accept Freight Load
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
