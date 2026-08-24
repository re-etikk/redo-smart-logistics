import { useState, useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
  MapPin, Weight, Search, Filter, ArrowRight, ArrowLeftRight, ShieldCheck, Zap,
  CheckCircle2, Clock, Truck, Box, Phone, X, Check, Camera, Building2, User,
  Sparkles, SlidersHorizontal, RotateCcw, IndianRupee, Navigation
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getTrucks, type TruckItem } from "../lib/truckStore";
import { getSharedCargoList, syncFromCloud, assignTruckToCargo, type CargoItem } from "../lib/cargoStore";
import { searchLocations, type LocationHub } from "../lib/locationService";

const POPULAR_HUBS = [
  "Delhi NCR",
  "Mumbai",
  "Ahmedabad",
  "Jaipur",
  "Pune",
  "Bengaluru",
  "Kolkata",
  "Hyderabad",
  "Surat",
  "Indore",
  "Chennai",
  "Kanpur",
];

const CARGO_CATEGORIES = [
  "All",
  "FMCG & Groceries",
  "Textiles & Garments",
  "Industrial Goods",
  "Electronics",
  "Auto Parts",
  "Agriculture & Produce",
  "Chemicals & Pharma",
];

const WEIGHT_RANGES = [
  { id: "all", label: "All Weights" },
  { id: "ltl", label: "Light (< 3T)", min: 0, max: 3 },
  { id: "medium", label: "Medium (3T – 7T)", min: 3, max: 7 },
  { id: "heavy", label: "Heavy (7T – 15T)", min: 7, max: 15 },
  { id: "ftl", label: "FTL (15T+)", min: 15, max: 100 },
];

export default function AvailableLoads() {
  const navigate = useNavigate();
  const { t } = useTranslation();

  // Search & Filter State
  const [originQuery, setOriginQuery] = useState("");
  const [destQuery, setDestQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [selectedWeightRange, setSelectedWeightRange] = useState("all");
  const [urgencyFilter, setUrgencyFilter] = useState("all");
  const [sortBy, setSortBy] = useState<"newest" | "highest_price" | "distance">("newest");
  const [selectedTruckIdForMatch, setSelectedTruckIdForMatch] = useState("all");

  // Accept Load Modal State
  const [selectedLoad, setSelectedLoad] = useState<CargoItem | null>(null);
  const [acceptedSuccess, setAcceptedSuccess] = useState(false);
  const [assigningTruckId, setAssigningTruckId] = useState("");

  const [trucks, setTrucks] = useState<TruckItem[]>([]);
  const [allLoads, setAllLoads] = useState<CargoItem[]>([]);

  const refreshData = () => {
    const loadedTrucks = getTrucks();
    setTrucks(loadedTrucks);
    if (loadedTrucks.length > 0 && !assigningTruckId) {
      setAssigningTruckId(loadedTrucks[0].id);
    }
    const customLoads = getSharedCargoList();
    setAllLoads(customLoads);
  };

  useEffect(() => {
    refreshData();
    syncFromCloud().then(updated => {
      if (updated && updated.length > 0) setAllLoads(updated);
    });

    const handleCargoUpdate = () => refreshData();
    const handleFleetUpdate = () => refreshData();
    window.addEventListener("redo_cargo_updated", handleCargoUpdate);
    window.addEventListener("redo_fleet_updated", handleFleetUpdate);

    const interval = setInterval(() => {
      syncFromCloud().then(updated => {
        if (updated && updated.length > 0) setAllLoads(updated);
      });
    }, 2500);

    return () => {
      window.removeEventListener("redo_cargo_updated", handleCargoUpdate);
      window.removeEventListener("redo_fleet_updated", handleFleetUpdate);
      clearInterval(interval);
    };
  }, []);

  // When a specific truck is selected for matching, auto-populate corridor
  const handleTruckSelectForMatch = (truckId: string) => {
    setSelectedTruckIdForMatch(truckId);
    if (truckId === "all") {
      setOriginQuery("");
      setDestQuery("");
      return;
    }
    const foundTruck = trucks.find(t => t.id === truckId);
    if (foundTruck && foundTruck.currentTrip) {
      setOriginQuery(foundTruck.currentTrip.origin || foundTruck.location || "");
      setDestQuery(foundTruck.currentTrip.dest || "");
    }
  };

  // Swap From & To cities
  const handleSwapCities = () => {
    const temp = originQuery;
    setOriginQuery(destQuery);
    setDestQuery(temp);
  };

  // Reset all filters
  const handleResetFilters = () => {
    setOriginQuery("");
    setDestQuery("");
    setSelectedCategory("All");
    setSelectedWeightRange("all");
    setUrgencyFilter("all");
    setSelectedTruckIdForMatch("all");
    setSortBy("newest");
  };

  // Active filter count
  const activeFiltersCount = useMemo(() => {
    let count = 0;
    if (originQuery.trim()) count++;
    if (destQuery.trim()) count++;
    if (selectedCategory !== "All") count++;
    if (selectedWeightRange !== "all") count++;
    if (urgencyFilter !== "all") count++;
    if (selectedTruckIdForMatch !== "all") count++;
    return count;
  }, [originQuery, destQuery, selectedCategory, selectedWeightRange, urgencyFilter, selectedTruckIdForMatch]);

  // Filtered & Sorted Loads
  const filteredLoads = useMemo(() => {
    const filtered = allLoads.filter((l) => {
      // 1. Origin Filter
      if (originQuery.trim()) {
        const oQuery = originQuery.toLowerCase().trim();
        const originMatch =
          l.origin.toLowerCase().includes(oQuery) ||
          (l.originHub && l.originHub.toLowerCase().includes(oQuery)) ||
          (l.pickupAddress && l.pickupAddress.toLowerCase().includes(oQuery));
        if (!originMatch) return false;
      }

      // 2. Destination Filter
      if (destQuery.trim()) {
        const dQuery = destQuery.toLowerCase().trim();
        const destMatch =
          l.destination.toLowerCase().includes(dQuery) ||
          (l.destHub && l.destHub.toLowerCase().includes(dQuery)) ||
          (l.deliveryAddress && l.deliveryAddress.toLowerCase().includes(dQuery));
        if (!destMatch) return false;
      }

      // 3. Category Filter
      if (selectedCategory !== "All") {
        if (!l.cargoType.toLowerCase().includes(selectedCategory.toLowerCase())) return false;
      }

      // 4. Weight Range Filter
      if (selectedWeightRange !== "all") {
        const range = WEIGHT_RANGES.find(r => r.id === selectedWeightRange);
        if (range && (range.min !== undefined && range.max !== undefined)) {
          if (l.weightTons < range.min || l.weightTons > range.max) return false;
        }
      }

      // 5. Urgency Filter
      if (urgencyFilter !== "all") {
        if (urgencyFilter === "immediate" && !l.urgency.includes("Immediate")) return false;
        if (urgencyFilter === "today" && !l.urgency.includes("Today")) return false;
      }

      return true;
    });

    // Sorting
    return filtered.sort((a, b) => {
      if (sortBy === "highest_price") {
        return (b.offeredPriceInr || 0) - (a.offeredPriceInr || 0);
      }
      if (sortBy === "distance") {
        return (a.distanceKm || 0) - (b.distanceKm || 0);
      }
      // default newest
      return new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime();
    });
  }, [allLoads, originQuery, destQuery, selectedCategory, selectedWeightRange, urgencyFilter, sortBy]);

  const handleOpenAcceptModal = (load: CargoItem) => {
    setSelectedLoad(load);
    setAcceptedSuccess(false);
    if (trucks.length > 0) {
      setAssigningTruckId(trucks[0].id);
    }
  };

  const confirmAcceptLoad = () => {
    if (selectedLoad) {
      const trk = trucks.find(t => t.id === assigningTruckId) || trucks[0] || {
        id: "TRK-AUTO",
        regNo: "HR 26 DQ 9871",
        driverName: "Self / Fleet Assigned",
        driverPhone: "+91 98112 34567",
      };

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
      }, 1300);
    }
  };

  return (
    <OwnerLayout>
      <div className="space-y-6 text-slate-900 dark:text-white py-2">
        
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 border border-amber-300 dark:border-amber-700 text-[11px] font-black uppercase tracking-wider mb-1">
              <Sparkles size={13} className="text-amber-500" />
              <span>Direct Freight Exchange</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              {t("findLoads")} (Live Customer Shipments)
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Find commercial loads matching your route corridors with exact warehouse pickup & delivery addresses.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 bg-emerald-50 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 px-3.5 py-1.5 rounded-2xl border border-emerald-200 dark:border-emerald-800 text-xs font-bold shadow-sm">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Live Network Sync</span>
            </div>
            {trucks.length > 0 && (
              <button
                onClick={() => navigate("/trucks")}
                className="text-xs font-black text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-950/40 border border-amber-300 dark:border-amber-700 px-3 py-1.5 rounded-xl hover:bg-amber-100 transition flex items-center gap-1 cursor-pointer"
              >
                <Truck size={14} />
                <span>{trucks.length} Fleet Trucks</span>
              </button>
            )}
          </div>
        </div>

        {/* 🌟 Corridor Route & City Search Engine */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 sm:p-6 shadow-sm space-y-5">
          
          <div className="flex items-center justify-between">
            <h2 className="text-xs font-black uppercase tracking-wider text-slate-500 dark:text-slate-400 flex items-center gap-2">
              <Navigation size={15} className="text-amber-500" />
              <span>Search Route Corridor &amp; Pickup / Drop Hubs</span>
            </h2>

            {/* Quick Match for Fleet Truck */}
            {trucks.length > 0 && (
              <div className="flex items-center gap-2">
                <span className="text-[11px] text-slate-500 hidden md:inline font-bold">Auto-Match Truck:</span>
                <select
                  value={selectedTruckIdForMatch}
                  onChange={(e) => handleTruckSelectForMatch(e.target.value)}
                  className="bg-amber-50 dark:bg-slate-800 border border-amber-300 dark:border-slate-700 rounded-xl px-2.5 py-1.5 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
                >
                  <option value="all">🔍 Search All Routes</option>
                  {trucks.map((trk) => (
                    <option key={trk.id} value={trk.id}>
                      🚚 {trk.regNo} ({trk.currentTrip?.origin || trk.location || "Delhi"} ➔ {trk.currentTrip?.dest || "Mumbai"})
                    </option>
                  ))}
                </select>
              </div>
            )}
          </div>

          {/* Main Origin & Destination Inputs Grid */}
          <div className="grid grid-cols-1 md:grid-cols-12 gap-3 items-center">
            
            {/* Origin (From City) */}
            <div className="md:col-span-5 relative">
              <label className="text-[10px] uppercase font-black tracking-wider text-emerald-600 dark:text-emerald-400 block mb-1.5 flex items-center gap-1">
                <MapPin size={12} />
                <span>Pickup Origin (From City / Hub)</span>
              </label>
              <div className="relative">
                <Search size={16} className="text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={originQuery}
                  onChange={(e) => setOriginQuery(e.target.value)}
                  placeholder="e.g. Delhi NCR, Mumbai, Ahmedabad..."
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl pl-10 pr-8 py-3 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400 text-slate-900 dark:text-white"
                />
                {originQuery && (
                  <button
                    onClick={() => setOriginQuery("")}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-slate-600 rounded-full"
                  >
                    <X size={14} />
                  </button>
                )}
              </div>
            </div>

            {/* Swap Button */}
            <div className="md:col-span-2 flex justify-center pt-3 md:pt-4">
              <button
                type="button"
                onClick={handleSwapCities}
                title="Swap From and To"
                className="w-10 h-10 rounded-2xl bg-[#FFC800] hover:bg-amber-400 text-slate-950 flex items-center justify-center shadow-sm hover:rotate-180 transition-transform duration-300 cursor-pointer"
              >
                <ArrowLeftRight size={16} />
              </button>
            </div>

            {/* Destination (To City) */}
            <div className="md:col-span-5 relative">
              <label className="text-[10px] uppercase font-black tracking-wider text-rose-600 dark:text-rose-400 block mb-1.5 flex items-center gap-1">
                <Building2 size={12} />
                <span>Drop Destination (To City / Hub)</span>
              </label>
              <div className="relative">
                <Search size={16} className="text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={destQuery}
                  onChange={(e) => setDestQuery(e.target.value)}
                  placeholder="e.g. Mumbai, Surat, Kolkata, Pune..."
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl pl-10 pr-8 py-3 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400 text-slate-900 dark:text-white"
                />
                {destQuery && (
                  <button
                    onClick={() => setDestQuery("")}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-slate-600 rounded-full"
                  >
                    <X size={14} />
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Quick Popular City Chips */}
          <div className="space-y-1.5 pt-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Quick Corridor Filter:
            </span>
            <div className="flex flex-wrap gap-1.5">
              {POPULAR_HUBS.map((hub) => {
                const isActive = originQuery === hub || destQuery === hub;
                return (
                  <button
                    key={hub}
                    onClick={() => {
                      if (!originQuery) setOriginQuery(hub);
                      else if (!destQuery && originQuery !== hub) setDestQuery(hub);
                      else setOriginQuery(hub);
                    }}
                    className={`px-3 py-1 rounded-xl text-[11px] font-bold transition cursor-pointer ${
                      isActive
                        ? "bg-[#FFC800] text-slate-950 font-black shadow-sm"
                        : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-amber-100 dark:hover:bg-amber-950/60"
                    }`}
                  >
                    {hub}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Secondary Filters Bar (Weight, Cargo Category, Urgency & Sorting) */}
          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
            
            {/* Weight Filter */}
            <div>
              <label className="text-[10px] uppercase font-black text-slate-400 block mb-1">Payload Weight</label>
              <select
                value={selectedWeightRange}
                onChange={(e) => setSelectedWeightRange(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                {WEIGHT_RANGES.map((r) => (
                  <option key={r.id} value={r.id}>{r.label}</option>
                ))}
              </select>
            </div>

            {/* Cargo Category */}
            <div>
              <label className="text-[10px] uppercase font-black text-slate-400 block mb-1">Cargo Type</label>
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                {CARGO_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>

            {/* Urgency */}
            <div>
              <label className="text-[10px] uppercase font-black text-slate-400 block mb-1">Pickup Urgency</label>
              <select
                value={urgencyFilter}
                onChange={(e) => setUrgencyFilter(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="all">All Pickup Slots</option>
                <option value="immediate">⚡ Immediate Dispatch (&lt; 2 hrs)</option>
                <option value="today">Today Evening</option>
              </select>
            </div>

            {/* Sort Order */}
            <div>
              <label className="text-[10px] uppercase font-black text-slate-400 block mb-1">Sort By</label>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as any)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="newest">Newest Consignments</option>
                <option value="highest_price">Highest Offered Rate (₹)</option>
                <option value="distance">Shortest Route (Km)</option>
              </select>
            </div>
          </div>

          {/* Active Filter Badges & Reset Button */}
          {activeFiltersCount > 0 && (
            <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-slate-100 dark:border-slate-800 text-xs font-bold">
              <div className="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                <span className="text-[11px] bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 px-2.5 py-0.5 rounded-full font-black">
                  {filteredLoads.length} Loads Matching {activeFiltersCount} Active Filters
                </span>
              </div>
              <button
                onClick={handleResetFilters}
                className="inline-flex items-center gap-1 text-rose-600 hover:text-rose-700 font-bold hover:underline cursor-pointer text-xs"
              >
                <RotateCcw size={13} />
                <span>Reset All Filters</span>
              </button>
            </div>
          )}
        </div>

        {/* 📦 Live Consignment Loads List */}
        {filteredLoads.length === 0 ? (
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-12 text-center space-y-4 shadow-sm">
            <div className="w-16 h-16 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 mx-auto flex items-center justify-center font-black">
              <Box size={30} />
            </div>
            <div className="space-y-1 max-w-md mx-auto">
              <h3 className="text-base font-black text-slate-900 dark:text-white">
                {activeFiltersCount > 0 ? "No Consignments Match Your Search" : "No Open Consignments Right Now"}
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {activeFiltersCount > 0
                  ? "Try clearing origin/destination city filters or broadening your payload weight range."
                  : "When shippers book shipments on the Customer Portal, they will appear live here in real-time."}
              </p>
            </div>
            {activeFiltersCount > 0 && (
              <button
                onClick={handleResetFilters}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-sm transition text-xs inline-flex items-center gap-1.5 cursor-pointer"
              >
                <RotateCcw size={14} />
                <span>Clear Filters &amp; View All Loads</span>
              </button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {filteredLoads.map((load) => {
              const isAssigned = load.status === "Assigned" || load.status === "In Transit";
              return (
                <div
                  key={load.id}
                  className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm hover:shadow-md transition flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6"
                >
                  {/* Left: Visual & Details */}
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

                    <div className="space-y-3 flex-1">
                      {/* Top Badges */}
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-[11px] font-mono text-amber-600 dark:text-amber-400 font-black">
                          {load.id}
                        </span>
                        <span className="text-[10px] font-black px-2.5 py-0.5 rounded-full bg-amber-100 text-amber-900 dark:bg-amber-950/60 dark:text-amber-300">
                          {load.urgency}
                        </span>
                        <span className="text-[10px] font-bold text-slate-400">
                          Shipper: <span className="text-slate-700 dark:text-slate-200 font-black">{load.shipperName}</span>
                        </span>
                        {isAssigned && (
                          <span className="text-[10px] font-black px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300">
                            ✓ Assigned ({load.assignedTruckReg})
                          </span>
                        )}
                      </div>

                      {/* Route Corridor & Addresses */}
                      <div className="grid md:grid-cols-2 gap-3 text-xs font-bold bg-slate-50 dark:bg-slate-800/60 p-3.5 rounded-2xl border border-slate-200/60 dark:border-slate-700/60">
                        {/* Pickup Origin */}
                        <div className="space-y-1">
                          <div className="flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400 font-black">
                            <MapPin size={14} />
                            <span>Pickup: {load.origin}</span>
                          </div>
                          {load.pickupAddress ? (
                            <p className="text-[11px] text-slate-600 dark:text-slate-300 font-medium pl-5 leading-relaxed">
                              {load.pickupAddress}
                            </p>
                          ) : (
                            <p className="text-[11px] text-slate-400 pl-5 font-normal">Warehouse Hub Station</p>
                          )}
                          {load.pickupContactPerson && (
                            <p className="text-[10px] text-slate-500 dark:text-slate-400 pl-5 font-normal flex items-center gap-1 pt-0.5">
                              <User size={11} className="text-slate-400" />
                              <span>Contact: {load.pickupContactPerson}</span>
                              <a href={`tel:${load.pickupContactPhone || load.shipperPhone}`} className="text-amber-600 dark:text-amber-400 font-bold hover:underline ml-1">
                                ({load.pickupContactPhone || load.shipperPhone})
                              </a>
                            </p>
                          )}
                        </div>

                        {/* Drop Destination */}
                        <div className="space-y-1">
                          <div className="flex items-center gap-1.5 text-rose-600 dark:text-rose-400 font-black">
                            <Building2 size={14} />
                            <span>Drop: {load.destination}</span>
                          </div>
                          {load.deliveryAddress ? (
                            <p className="text-[11px] text-slate-600 dark:text-slate-300 font-medium pl-5 leading-relaxed">
                              {load.deliveryAddress}
                            </p>
                          ) : (
                            <p className="text-[11px] text-slate-400 pl-5 font-normal">Delivery Hub Station</p>
                          )}
                          {load.deliveryContactPerson && (
                            <p className="text-[10px] text-slate-500 dark:text-slate-400 pl-5 font-normal flex items-center gap-1 pt-0.5">
                              <User size={11} className="text-slate-400" />
                              <span>Receiver: {load.deliveryContactPerson}</span>
                              <a href={`tel:${load.deliveryContactPhone}`} className="text-amber-600 dark:text-amber-400 font-bold hover:underline ml-1">
                                ({load.deliveryContactPhone})
                              </a>
                            </p>
                          )}
                        </div>
                      </div>

                      {/* Cargo Specs Badges */}
                      <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-500 dark:text-slate-400 pt-0.5">
                        <span className="flex items-center gap-1 font-bold text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 px-2.5 py-1 rounded-xl">
                          <Box size={13} className="text-amber-500" /> {load.cargoType}
                        </span>
                        <span className="flex items-center gap-1 font-bold text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 px-2.5 py-1 rounded-xl">
                          <Weight size={13} className="text-amber-500" /> {load.weightTons} Tons
                        </span>
                        <span className="flex items-center gap-1 font-bold text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 px-2.5 py-1 rounded-xl">
                          <Truck size={13} className="text-amber-500" /> {load.truckRequired}
                        </span>
                        <span className="flex items-center gap-1 font-bold text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 px-2.5 py-1 rounded-xl">
                          <Clock size={13} className="text-amber-500" /> Slot: {load.pickupDate}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Right: Price & Accept Action */}
                  <div className="w-full lg:w-56 flex flex-col items-end justify-between border-t lg:border-t-0 lg:border-l border-slate-100 dark:border-slate-800 pt-4 lg:pt-0 lg:pl-6 space-y-3">
                    <div className="text-right w-full">
                      <span className="text-[10px] uppercase font-bold text-slate-400 block">Offered Guaranteed Rate</span>
                      <div className="text-2xl font-black text-slate-900 dark:text-white flex items-center justify-end gap-0.5">
                        <span>₹{Number(load.offeredPriceInr || 24500).toLocaleString("en-IN")}</span>
                      </div>
                      <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold block">
                        ~{load.distanceKm || 1420} Km (Direct Highway)
                      </span>
                    </div>

                    {isAssigned ? (
                      <div className="w-full text-center py-2.5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-300 text-xs font-black border border-emerald-200 dark:border-emerald-800">
                        ✓ In Fleet Schedule
                      </div>
                    ) : (
                      <button
                        onClick={() => handleOpenAcceptModal(load)}
                        className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-2xl shadow-sm transition flex items-center justify-center gap-1.5 cursor-pointer text-xs"
                      >
                        <span>Accept &amp; Assign Truck</span>
                        <ArrowRight size={14} />
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* 🚛 Accept & Assign Truck Modal */}
        {selectedLoad && (
          <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
            <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl p-6 sm:p-8 max-w-lg w-full shadow-2xl space-y-5 animate-in fade-in zoom-in duration-200">
              
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                    <Truck size={18} />
                  </div>
                  <div>
                    <h3 className="text-base font-black text-slate-900 dark:text-white">
                      Assign Fleet Truck to Consignment
                    </h3>
                    <p className="text-[11px] text-slate-500 font-medium">Consignment #{selectedLoad.id}</p>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedLoad(null)}
                  className="p-1 text-slate-400 hover:text-slate-600 rounded-full"
                >
                  <X size={18} />
                </button>
              </div>

              {acceptedSuccess ? (
                <div className="p-6 text-center space-y-3 bg-emerald-50 dark:bg-emerald-950/60 rounded-2xl border border-emerald-200 dark:border-emerald-800">
                  <CheckCircle2 size={40} className="text-emerald-500 mx-auto" />
                  <h4 className="text-base font-black text-emerald-900 dark:text-emerald-200">
                    Consignment Confirmed &amp; Truck Assigned!
                  </h4>
                  <p className="text-xs text-emerald-700 dark:text-emerald-300">
                    Redirecting to active trips &amp; bookings...
                  </p>
                </div>
              ) : (
                <div className="space-y-4">
                  {/* Route & Shipper Summary */}
                  <div className="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200/60 dark:border-slate-700/60 space-y-2 text-xs">
                    <div className="flex justify-between font-bold">
                      <span className="text-slate-500">Route Corridor:</span>
                      <span className="text-slate-900 dark:text-white">{selectedLoad.origin} ➔ {selectedLoad.destination}</span>
                    </div>
                    <div className="flex justify-between font-bold">
                      <span className="text-slate-500">Cargo &amp; Weight:</span>
                      <span className="text-slate-900 dark:text-white">{selectedLoad.cargoType} ({selectedLoad.weightTons} T)</span>
                    </div>
                    <div className="flex justify-between font-bold">
                      <span className="text-slate-500">Guaranteed Earning:</span>
                      <span className="text-emerald-600 dark:text-emerald-400 font-black">
                        ₹{Number(selectedLoad.offeredPriceInr || 24500).toLocaleString("en-IN")}
                      </span>
                    </div>
                  </div>

                  {/* Vehicle Selection */}
                  <div className="space-y-1.5">
                    <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block">
                      Select Vehicle to Assign:
                    </label>
                    {trucks.length > 0 ? (
                      <select
                        value={assigningTruckId}
                        onChange={(e) => setAssigningTruckId(e.target.value)}
                        className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
                      >
                        {trucks.map((trk) => (
                          <option key={trk.id} value={trk.id}>
                            {trk.name} ({trk.regNo}) • Driver: {trk.driverName || "Mukesh Yadav"} • Cap: {trk.capacity}
                          </option>
                        ))}
                      </select>
                    ) : (
                      <div className="p-3 rounded-xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800 text-amber-900 dark:text-amber-300 text-xs font-medium">
                        No trucks registered yet. You can assign fleet driver &amp; truck will be linked automatically.
                      </div>
                    )}
                  </div>

                  <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                    <button
                      type="button"
                      onClick={() => setSelectedLoad(null)}
                      className="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-bold hover:bg-slate-50 dark:hover:bg-slate-800 text-xs"
                    >
                      Cancel
                    </button>
                    <button
                      type="button"
                      onClick={confirmAcceptLoad}
                      className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl shadow-md transition text-xs flex items-center gap-1.5 cursor-pointer"
                    >
                      <Check size={15} />
                      <span>Confirm &amp; Start Trip</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </OwnerLayout>
  );
}
