import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  MapPin, Weight, Search, Filter, ArrowRight, ShieldCheck, Zap,
  CheckCircle2, Clock, Truck, Box, Phone, X, Check, Camera, Building2, User
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
  const [selectedLoad, setSelectedLoad] = useState<CargoItem | null>(null);
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
      l.cargoType.toLowerCase().includes(search.toLowerCase()) ||
      (l.pickupAddress && l.pickupAddress.toLowerCase().includes(search.toLowerCase())) ||
      (l.deliveryAddress && l.deliveryAddress.toLowerCase().includes(search.toLowerCase()));

    const matchesFilter =
      filterType === "all" ||
      (filterType === "immediate" && l.urgency.includes("Immediate")) ||
      (filterType === "heavy" && l.weightTons > 6.0);

    return matchesSearch && matchesFilter;
  });

  const handleAcceptLoad = (load: CargoItem) => {
    setSelectedLoad(load);
    setAcceptedSuccess(false);
  };

  const confirmAcceptLoad = () => {
    if (selectedLoad && selectedTruckId) {
      const trk = trucks.find(t => t.id === selectedTruckId) || trucks[0];
      assignTruckToCargo(selectedLoad.id, {
        truckId: trk.id,
        regNo: trk.regNo,
        driverName: trk.driverName,
        driverPhone: trk.driverPhone,
      });

      setAcceptedSuccess(true);
      setTimeout(() => {
        setSelectedLoad(null);
        navigate("/bookings");
      }, 1400);
    }
  };

  return (
    <OwnerLayout>
      <div className="space-y-6 text-slate-900 dark:text-white py-2">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <span className="text-[10px] uppercase font-black tracking-wider text-amber-500 block">
              REDO Direct Freight Network
            </span>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              {t("findLoads")} (Live Customer Consignments)
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Verified commercial shippers with exact pickup warehouse addresses and guaranteed payments.
            </p>
          </div>

          <div className="flex items-center gap-2 bg-emerald-50 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 px-3.5 py-1.5 rounded-2xl border border-emerald-200 dark:border-emerald-800 text-xs font-bold">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>Active Fleet: {trucks.length} Registered Truck</span>
          </div>
        </div>

        {/* Filter Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex flex-wrap items-center gap-2 font-bold text-xs">
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
              <Zap size={14} className="text-amber-500" /> Immediate Dispatch
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
              placeholder="Search by city, cargo or address..."
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
                Customer consignments posted from the customer app will appear here live with exact warehouse addresses.
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
                {/* Origin / Dest & Addresses */}
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

                  <div className="space-y-2 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-mono text-amber-500 font-black">{load.id}</span>
                      <span className="text-[9px] font-black px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300">
                        {load.urgency}
                      </span>
                      <span className="text-[10px] font-bold text-slate-400">Shipper: {load.shipperName}</span>
                    </div>

                    <div className="grid md:grid-cols-2 gap-3 text-xs font-bold bg-slate-50 dark:bg-slate-800/60 p-3 rounded-2xl border border-slate-200/60 dark:border-slate-700/60">
                      <div className="space-y-1">
                        <div className="flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400 font-black">
                          <MapPin size={13} />
                          <span>Pickup: {load.origin}</span>
                        </div>
                        {load.pickupAddress && (
                          <p className="text-[11px] text-slate-600 dark:text-slate-300 font-medium pl-4">
                            {load.pickupAddress}
                          </p>
                        )}
                        {load.pickupContactPerson && (
                          <p className="text-[10px] text-slate-400 pl-4 font-normal">
                            Contact: {load.pickupContactPerson} ({load.pickupContactPhone || load.shipperPhone})
                          </p>
                        )}
                      </div>

                      <div className="space-y-1">
                        <div className="flex items-center gap-1.5 text-rose-600 dark:text-rose-400 font-black">
                          <Building2 size={13} />
                          <span>Drop: {load.destination}</span>
                        </div>
                        {load.deliveryAddress && (
                          <p className="text-[11px] text-slate-600 dark:text-slate-300 font-medium pl-4">
                            {load.deliveryAddress}
                          </p>
                        )}
                        {load.deliveryContactPerson && (
                          <p className="text-[10px] text-slate-400 pl-4 font-normal">
                            Receiver: {load.deliveryContactPerson} ({load.deliveryContactPhone})
                          </p>
                        )}
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
                        <Clock size={13} className="text-amber-500" /> Slot: {load.pickupDate}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Price & Action Button */}
                <div className="flex items-center justify-between lg:flex-col lg:items-end gap-3 w-full lg:w-auto border-t lg:border-t-0 pt-3 lg:pt-0 border-slate-100 dark:border-slate-800 shrink-0">
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

      {/* Accept Load Modal */}
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
              <div className="py-8 text-center space-y-3">
                <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 mx-auto flex items-center justify-center">
                  <Check size={24} />
                </div>
                <h4 className="text-base font-black">Consignment Accepted!</h4>
                <p className="text-xs text-slate-400">Assigned to your registered truck. Opening live trip...</p>
              </div>
            ) : (
              <div className="space-y-4">
                <div className="space-y-2 p-3.5 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 text-xs">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Shipper Name:</span>
                    <span className="font-black">{selectedLoad.shipperName}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Shipper Phone:</span>
                    <span className="font-mono text-amber-500">{selectedLoad.shipperPhone}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Agreed Freight:</span>
                    <span className="font-black text-sm">₹{selectedLoad.offeredPriceInr.toLocaleString("en-IN")}</span>
                  </div>
                  <div className="pt-1 border-t border-slate-200/60 dark:border-slate-700">
                    <span className="text-slate-400 block text-[10px] uppercase">Exact Loading Warehouse:</span>
                    <p className="font-bold text-slate-800 dark:text-slate-200 text-[11px]">{selectedLoad.pickupAddress || selectedLoad.origin}</p>
                  </div>
                </div>

                <div>
                  <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Select Vehicle from Fleet</label>
                  <select
                    value={selectedTruckId}
                    onChange={(e) => setSelectedTruckId(e.target.value)}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold"
                  >
                    {trucks.map(t => (
                      <option key={t.id} value={t.id}>
                        {t.name} ({t.regNo}) • Driver: {t.driverName}
                      </option>
                    ))}
                  </select>
                </div>

                <button
                  type="button"
                  onClick={confirmAcceptLoad}
                  className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-2xl shadow-md transition text-xs flex items-center justify-center gap-2 cursor-pointer"
                >
                  <CheckCircle2 size={16} /> Confirm Assignment &amp; Start Trip
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
