import { useState, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  CalendarCheck, CheckCircle2, Clock, Download, Eye, Filter, IndianRupee,
  MapPin, Phone, Search, Truck, XCircle, ChevronRight, X, RotateCcw,
  SlidersHorizontal, Calendar, ArrowUpDown, ShieldCheck, Check, Play, Navigation, Box
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getTrucks } from "../lib/truckStore";
import { getSharedCargoList, updateCargoStatus, syncFromCloud, type CargoItem } from "../lib/cargoStore";
import { depositTripEarning } from "../lib/walletStore";

interface BookingItem {
  id: string;
  bookingId: string;
  truckName: string;
  specs: string;
  origin: string;
  pickupAddress?: string;
  dest: string;
  deliveryAddress?: string;
  date: string;
  timestamp: number;
  amount: number;
  paymentStatus: "Paid" | "Pending" | "Cancelled" | "Escrow Secured";
  paymentDate: string;
  status: "Assigned" | "In Transit" | "Delivered" | "Cancelled";
  statusDesc: string;
  statusTone: string;
  photoUrl: string;
  driverName: string;
  driverPhone: string;
  regNo: string;
  goodsType: string;
  weightTons: number;
  shipperName: string;
  shipperPhone?: string;
  deliveryContactPerson?: string;
  deliveryContactPhone?: string;
  trackingProgress?: number;
  currentSpeed?: number;
  currentMilestone?: string;
}

export default function Bookings() {
  const navigate = useNavigate();
  const { t } = useTranslation();

  // Filter States
  const [tab, setTab] = useState<"all" | "assigned" | "transit" | "delivered">("all");
  const [search, setSearch] = useState("");
  
  // Date Range state
  const [dateRangePreset, setDateRangePreset] = useState("all");
  const [showDateDropdown, setShowDateDropdown] = useState(false);
  const [customStartDate, setCustomStartDate] = useState("");
  const [customEndDate, setCustomEndDate] = useState("");

  // Advanced Filters Modal State
  const [showFiltersModal, setShowFiltersModal] = useState(false);
  const [filterPayment, setFilterPayment] = useState<string>("all");
  const [filterGoods, setFilterGoods] = useState<string>("all");
  const [minPrice, setMinPrice] = useState<string>("");
  const [maxPrice, setMaxPrice] = useState<string>("");

  // Selected Booking for Detail Modal
  const [selectedBooking, setSelectedBooking] = useState<BookingItem | null>(null);
  const [cargoList, setCargoList] = useState<CargoItem[]>(() => getSharedCargoList());

  const refreshData = () => {
    setCargoList(getSharedCargoList());
  };

  useEffect(() => {
    refreshData();
    syncFromCloud().then(updated => {
      if (updated && updated.length > 0) setCargoList(updated);
    });

    const handleCargoUpdate = () => refreshData();
    window.addEventListener("redo_cargo_updated", handleCargoUpdate);

    const interval = setInterval(() => {
      syncFromCloud().then(updated => {
        if (updated && updated.length > 0) setCargoList(updated);
      });
    }, 2000);

    return () => {
      window.removeEventListener("redo_cargo_updated", handleCargoUpdate);
      clearInterval(interval);
    };
  }, []);

  // Map only assigned, in-transit, and delivered cargo
  const allBookings = useMemo<BookingItem[]>(() => {
    const relevant = cargoList.filter(c => c.status === "Assigned" || c.status === "In Transit" || c.status === "Delivered");

    return relevant.map(c => {
      let statusTone = "bg-amber-100 text-amber-900 dark:bg-amber-950/60 dark:text-amber-300";
      let statusDesc = "Driver Assigned • Heading to pickup warehouse";
      let paymentStatus: BookingItem["paymentStatus"] = "Escrow Secured";

      if (c.status === "In Transit") {
        statusTone = "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400";
        statusDesc = c.currentMilestone || "Live Highway Transit • Telemetry Connected";
      } else if (c.status === "Delivered") {
        statusTone = "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400";
        statusDesc = "Delivered successfully • Signed e-POD Handover";
        paymentStatus = "Paid";
      }

      return {
        id: `B-${c.id}`,
        bookingId: c.id,
        truckName: c.assignedTruckReg ? `Container Truck (${c.truckRequired || "19 Feet"})` : "Assigned Fleet Truck",
        specs: `${c.truckRequired || "19 Feet"} · ${c.weightTons} Ton · Enclosed Container`,
        origin: c.origin,
        pickupAddress: c.pickupAddress,
        dest: c.destination,
        deliveryAddress: c.deliveryAddress,
        date: c.pickupDate || "Today",
        timestamp: Date.now(),
        amount: c.offeredPriceInr || 23300,
        paymentStatus,
        paymentDate: c.pickupDate || "Today",
        status: c.status as BookingItem["status"],
        statusDesc,
        statusTone,
        photoUrl: "/assets/redo_truck.jpg",
        driverName: c.assignedDriverName || "Mukesh Yadav",
        driverPhone: c.assignedDriverPhone || "+91 98112 34567",
        regNo: c.assignedTruckReg || "MH 04 AB 1234",
        goodsType: c.cargoType,
        weightTons: c.weightTons,
        shipperName: c.shipperName,
        shipperPhone: c.pickupContactPhone || c.shipperPhone,
        deliveryContactPerson: c.deliveryContactPerson,
        deliveryContactPhone: c.deliveryContactPhone,
        trackingProgress: c.trackingProgress || (c.status === "In Transit" ? 60 : c.status === "Delivered" ? 100 : 25),
        currentSpeed: c.currentSpeed || (c.status === "In Transit" ? 48 : 0),
        currentMilestone: c.currentMilestone,
      };
    });
  }, [cargoList]);

  // Lifecycle actions
  const handleStartTransit = (bookingId: string) => {
    updateCargoStatus(bookingId, "In Transit", {
      trackingProgress: 55,
      currentSpeed: 48,
      currentMilestone: "Live Highway Transit • NH-48 Express Corridor",
    });
    refreshData();
    if (selectedBooking && selectedBooking.bookingId === bookingId) {
      setSelectedBooking(prev => prev ? { ...prev, status: "In Transit", statusDesc: "Live Highway Transit • NH-48 Express Corridor" } : null);
    }
  };

  const handleConfirmDelivery = (bookingId: string, amount: number, regNo: string) => {
    updateCargoStatus(bookingId, "Delivered", {
      trackingProgress: 100,
      currentSpeed: 0,
      currentMilestone: "Delivered & Signed e-POD Handover Complete",
    });
    depositTripEarning(amount, `Trip ${bookingId} Freight Settlement (Direct Delivery Handover)`, bookingId, regNo);
    refreshData();
    if (selectedBooking && selectedBooking.bookingId === bookingId) {
      setSelectedBooking(prev => prev ? { ...prev, status: "Delivered", statusDesc: "Delivered successfully • Signed e-POD Handover", paymentStatus: "Paid" } : null);
    }
  };

  // Filter Computation
  const filteredBookings = useMemo(() => {
    return allBookings.filter((b) => {
      // 1. Status Tab Filter
      if (tab === "assigned" && b.status !== "Assigned") return false;
      if (tab === "transit" && b.status !== "In Transit") return false;
      if (tab === "delivered" && b.status !== "Delivered") return false;

      // 2. Search Filter
      if (search.trim()) {
        const query = search.toLowerCase();
        const matches =
          b.bookingId.toLowerCase().includes(query) ||
          b.origin.toLowerCase().includes(query) ||
          b.dest.toLowerCase().includes(query) ||
          b.goodsType.toLowerCase().includes(query) ||
          b.driverName.toLowerCase().includes(query) ||
          b.shipperName.toLowerCase().includes(query);
        if (!matches) return false;
      }

      // 3. Payment Filter
      if (filterPayment !== "all") {
        if (filterPayment === "Paid" && b.paymentStatus !== "Paid") return false;
        if (filterPayment === "Escrow" && b.paymentStatus !== "Escrow Secured") return false;
      }

      // 4. Goods Type Filter
      if (filterGoods !== "all" && !b.goodsType.toLowerCase().includes(filterGoods.toLowerCase())) {
        return false;
      }

      // 5. Price Range Filter
      if (minPrice && b.amount < parseFloat(minPrice)) return false;
      if (maxPrice && b.amount > parseFloat(maxPrice)) return false;

      return true;
    });
  }, [allBookings, tab, search, filterPayment, filterGoods, minPrice, maxPrice]);

  // Active Filters Count
  const activeFiltersCount = useMemo(() => {
    let count = 0;
    if (filterPayment !== "all") count++;
    if (filterGoods !== "all") count++;
    if (minPrice || maxPrice) count++;
    return count;
  }, [filterPayment, filterGoods, minPrice, maxPrice]);

  const resetAllFilters = () => {
    setFilterPayment("all");
    setFilterGoods("all");
    setMinPrice("");
    setMaxPrice("");
    setSearch("");
    setTab("all");
  };

  // CSV Export Handler
  const exportBookingsCSV = () => {
    const headers = ["Booking ID,Vehicle,Route,Pickup Address,Delivery Address,Goods,Weight (Tons),Amount (INR),Payment Status,Trip Status,Date"];
    const rows = filteredBookings.map(b =>
      `"${b.bookingId}","${b.truckName}","${b.origin} -> ${b.dest}","${b.pickupAddress || ''}","${b.deliveryAddress || ''}","${b.goodsType}",${b.weightTons},${b.amount},"${b.paymentStatus}","${b.status}","${b.date}"`
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `REDO_Bookings_Statement_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <OwnerLayout activeTab="bookings" promoCardType="refer">
      <div className="space-y-6 text-slate-900 dark:text-white">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <span className="text-[10px] uppercase font-black tracking-wider text-amber-500 block">
              Fleet Trip Ledger &amp; Consignments
            </span>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">{t("myBookings")}</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Execute active trips, trigger live highway transit, confirm delivery receipts (e-POD), and manage settled earnings.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => navigate("/loads")}
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-4 py-2 rounded-xl shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <Search size={14} />
              <span>Find New Loads</span>
            </button>
            <button
              onClick={exportBookingsCSV}
              className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-900 dark:text-white font-bold px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <Download size={14} />
              <span>Export CSV</span>
            </button>
          </div>
        </div>

        {/* Filter Navigation Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 sm:p-5 shadow-sm space-y-4">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            {/* Status Tabs */}
            <div className="flex items-center gap-1 bg-slate-100 dark:bg-slate-800/80 p-1 rounded-2xl w-full sm:w-auto overflow-x-auto text-xs font-bold">
              {[
                { id: "all", label: "All Active", count: allBookings.length },
                { id: "assigned", label: "Assigned (At Warehouse)", count: allBookings.filter(b => b.status === "Assigned").length },
                { id: "transit", label: "In Transit (Live)", count: allBookings.filter(b => b.status === "In Transit").length },
                { id: "delivered", label: "Delivered (e-POD)", count: allBookings.filter(b => b.status === "Delivered").length },
              ].map((tabItem) => (
                <button
                  key={tabItem.id}
                  onClick={() => setTab(tabItem.id as any)}
                  className={`px-3.5 py-1.5 rounded-xl transition flex items-center gap-1.5 whitespace-nowrap cursor-pointer ${
                    tab === tabItem.id
                      ? "bg-white dark:bg-slate-900 text-slate-950 dark:text-white font-black shadow-xs"
                      : "text-slate-500 hover:text-slate-900 dark:hover:text-white"
                  }`}
                >
                  <span>{tabItem.label}</span>
                  <span className="text-[10px] opacity-70">({tabItem.count})</span>
                </button>
              ))}
            </div>

            {/* Search Input */}
            <div className="relative flex-1 sm:w-64 w-full">
              <Search size={14} className="text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search by city, ID or shipper..."
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl pl-8 pr-3 py-2 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400 text-slate-900 dark:text-white"
              />
            </div>
          </div>
        </div>

        {/* Bookings Table List */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="hidden lg:grid grid-cols-12 text-[10px] font-black uppercase text-slate-400 pb-3 border-b border-slate-100 dark:border-slate-800 tracking-wider">
            <div className="col-span-4">Booking Details &amp; Assigned Vehicle</div>
            <div className="col-span-3">Route &amp; Warehouse Address</div>
            <div className="col-span-2">Freight &amp; Escrow</div>
            <div className="col-span-3 text-right">Trip Lifecycle &amp; Actions</div>
          </div>

          {filteredBookings.length === 0 ? (
            <div className="py-16 text-center space-y-3">
              <div className="w-16 h-16 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 mx-auto flex items-center justify-center font-black">
                <Box size={28} />
              </div>
              <div className="space-y-1 max-w-sm mx-auto">
                <h3 className="text-base font-black text-slate-900 dark:text-white">No Trips in this View</h3>
                <p className="text-xs text-slate-500">
                  Search and accept commercial shipments from <strong>Find Loads</strong> to dispatch your fleet trucks.
                </p>
              </div>
              <button
                onClick={() => navigate("/loads")}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl shadow-sm text-xs cursor-pointer inline-flex items-center gap-1.5"
              >
                <Search size={14} />
                <span>Browse Available Loads</span>
              </button>
            </div>
          ) : (
            <div className="divide-y divide-slate-100 dark:divide-slate-800">
              {filteredBookings.map((b) => (
                <div key={b.id} className="py-5 flex flex-col lg:grid lg:grid-cols-12 gap-4 items-start lg:items-center">
                  {/* Vehicle Thumbnail & Info */}
                  <div className="lg:col-span-4 flex items-center gap-3 w-full">
                    <div className="relative w-16 h-16 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0 shadow-sm">
                      <img
                        src={b.photoUrl}
                        alt={b.truckName}
                        className="w-full h-full object-cover"
                      />
                      <span className="absolute bottom-0 inset-x-0 bg-slate-950/80 text-[8px] font-black text-amber-400 text-center py-0.5 uppercase tracking-wider">
                        {b.regNo}
                      </span>
                    </div>

                    <div className="min-w-0 flex-1">
                      <span className="text-[10px] font-mono text-amber-600 dark:text-amber-400 font-bold block">
                        ID: {b.bookingId}
                      </span>
                      <h4 className="font-black text-xs sm:text-sm truncate text-slate-900 dark:text-white">
                        {b.truckName}
                      </h4>
                      <p className="text-[11px] text-slate-500 font-medium truncate">
                        Driver: <strong>{b.driverName}</strong> ({b.driverPhone})
                      </p>
                      <span className="text-[10px] text-slate-400 font-bold block">
                        Shipper: {b.shipperName}
                      </span>
                    </div>
                  </div>

                  {/* Route Corridor & Address */}
                  <div className="lg:col-span-3 space-y-1 text-xs font-bold w-full">
                    <div className="flex items-center gap-1.5 text-slate-900 dark:text-white font-black">
                      <span>{b.origin.split(" ")[0]}</span>
                      <span className="text-amber-500">➔</span>
                      <span>{b.dest.split(" ")[0]}</span>
                    </div>
                    {b.pickupAddress && (
                      <p className="text-[10px] text-slate-500 font-medium truncate">
                        📍 Pickup: {b.pickupAddress}
                      </p>
                    )}
                    <span className="text-[10px] text-slate-400 font-bold block">
                      {b.goodsType} ({b.weightTons}T) • {b.date}
                    </span>
                  </div>

                  {/* Payment & Amount */}
                  <div className="lg:col-span-2 space-y-0.5">
                    <span className="text-sm font-black text-slate-900 dark:text-white block">
                      ₹{b.amount.toLocaleString("en-IN")}
                    </span>
                    <span className={`inline-block text-[9px] font-black px-2 py-0.5 rounded-full ${
                      b.paymentStatus === "Paid" || b.paymentStatus === "Escrow Secured"
                        ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400"
                        : "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400"
                    }`}>
                      {b.paymentStatus}
                    </span>
                  </div>

                  {/* Trip Status & Interactive Rapido/Flipkart Style Lifecycle Actions */}
                  <div className="lg:col-span-3 flex flex-col sm:flex-row lg:flex-col items-stretch lg:items-end justify-between gap-2.5 w-full">
                    <div className="lg:text-right">
                      <span className={`text-[10px] font-black px-2.5 py-0.5 rounded-full inline-block ${b.statusTone}`}>
                        {b.status === "Assigned" ? "Assigned (At Pickup)" : b.status === "In Transit" ? "Live Highway Transit" : "Delivered"}
                      </span>
                      <span className="text-[10px] text-slate-400 font-medium block truncate max-w-xs mt-0.5">
                        {b.statusDesc}
                      </span>
                    </div>

                    {/* Interactive Action Buttons */}
                    <div className="flex items-center gap-2">
                      {b.status === "Assigned" && (
                        <button
                          type="button"
                          onClick={() => handleStartTransit(b.bookingId)}
                          className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-3.5 py-1.5 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition cursor-pointer"
                        >
                          <Play size={13} />
                          <span>Goods Loaded / Start Transit</span>
                        </button>
                      )}

                      {b.status === "In Transit" && (
                        <button
                          type="button"
                          onClick={() => handleConfirmDelivery(b.bookingId, b.amount, b.regNo)}
                          className="bg-emerald-600 hover:bg-emerald-700 text-white font-black px-3.5 py-1.5 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition cursor-pointer"
                        >
                          <CheckCircle2 size={13} />
                          <span>Confirm Delivery (e-POD)</span>
                        </button>
                      )}

                      {b.status === "Delivered" && (
                        <span className="text-xs font-black text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 px-3 py-1.5 rounded-xl">
                          ✓ Settled to Wallet
                        </span>
                      )}

                      <button
                        onClick={() => setSelectedBooking(b)}
                        className="bg-slate-100 dark:bg-slate-800 hover:bg-amber-400 hover:text-slate-950 text-slate-700 dark:text-slate-300 font-bold p-2 rounded-xl transition cursor-pointer shrink-0"
                        title="View Full Trip Details"
                      >
                        <Eye size={15} />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* FULL TRIP DETAIL MODAL */}
      {/* ========================================================================= */}
      {selectedBooking && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-xl w-full shadow-2xl p-6 sm:p-8 space-y-6 text-xs text-slate-900 dark:text-white">
            
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-amber-100 dark:bg-amber-950 text-amber-900 dark:text-amber-300 flex items-center justify-center font-black">
                  <Truck size={20} />
                </div>
                <div>
                  <h3 className="text-base font-black">Trip Consignment Dossier</h3>
                  <p className="text-[11px] text-slate-500 font-mono">Consignment #{selectedBooking.bookingId}</p>
                </div>
              </div>
              <button onClick={() => setSelectedBooking(null)} className="p-1.5 text-slate-400 hover:text-slate-600 rounded-full cursor-pointer">
                <X size={18} />
              </button>
            </div>

            {/* Status Banner */}
            <div className={`p-4 rounded-2xl flex items-center justify-between font-bold ${selectedBooking.statusTone}`}>
              <div>
                <span className="text-[10px] uppercase tracking-wider block font-black">Current Trip Status</span>
                <span className="text-sm font-black">{selectedBooking.status}</span>
              </div>
              <span className="text-xs">{selectedBooking.statusDesc}</span>
            </div>

            {/* Warehouse Addresses */}
            <div className="grid sm:grid-cols-2 gap-4">
              <div className="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200/60 dark:border-slate-700/60 space-y-1">
                <span className="text-[10px] text-emerald-600 uppercase font-black block flex items-center gap-1">
                  <MapPin size={11} /> 1. Pickup Origin Warehouse
                </span>
                <p className="font-bold text-xs">{selectedBooking.origin}</p>
                <p className="text-[11px] text-slate-500">{selectedBooking.pickupAddress || "Standard Logistics Warehouse Station"}</p>
                <p className="text-[10px] text-slate-400 pt-1">Shipper Contact: {selectedBooking.shipperName} ({selectedBooking.shipperPhone})</p>
              </div>

              <div className="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200/60 dark:border-slate-700/60 space-y-1">
                <span className="text-[10px] text-rose-600 uppercase font-black block flex items-center gap-1">
                  <MapPin size={11} /> 2. Delivery Destination Warehouse
                </span>
                <p className="font-bold text-xs">{selectedBooking.dest}</p>
                <p className="text-[11px] text-slate-500">{selectedBooking.deliveryAddress || "Standard Unloading Bay Station"}</p>
                {selectedBooking.deliveryContactPerson && (
                  <p className="text-[10px] text-slate-400 pt-1">Receiver: {selectedBooking.deliveryContactPerson} ({selectedBooking.deliveryContactPhone})</p>
                )}
              </div>
            </div>

            {/* Specs & Freight Payment */}
            <div className="grid grid-cols-3 gap-3 bg-slate-50 dark:bg-slate-800/80 p-3.5 rounded-2xl border border-slate-200/60 dark:border-slate-700/60 font-bold text-xs">
              <div>
                <span className="text-[10px] text-slate-400 uppercase block">Vehicle Assigned</span>
                <span className="font-black">{selectedBooking.regNo}</span>
              </div>
              <div>
                <span className="text-[10px] text-slate-400 uppercase block">Cargo Weight</span>
                <span className="font-black">{selectedBooking.weightTons} Tons ({selectedBooking.goodsType})</span>
              </div>
              <div>
                <span className="text-[10px] text-slate-400 uppercase block">Total Freight Value</span>
                <span className="text-emerald-600 dark:text-emerald-400 font-black text-sm">₹{selectedBooking.amount.toLocaleString("en-IN")}</span>
              </div>
            </div>

            {/* Driver Contact */}
            <div className="flex items-center justify-between p-3.5 bg-amber-50 dark:bg-amber-950/40 rounded-2xl border border-amber-200 dark:border-amber-800">
              <div>
                <span className="text-[10px] text-amber-900 dark:text-amber-300 uppercase font-black block">Assigned Fleet Driver</span>
                <span className="text-xs font-black text-slate-900 dark:text-white">{selectedBooking.driverName}</span>
              </div>
              <a
                href={`tel:${selectedBooking.driverPhone}`}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-sm"
              >
                <Phone size={13} />
                <span>Call Driver ({selectedBooking.driverPhone})</span>
              </a>
            </div>

            {/* Actions in Modal */}
            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100 dark:border-slate-800">
              <button
                type="button"
                onClick={() => setSelectedBooking(null)}
                className="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-bold text-xs cursor-pointer"
              >
                Close
              </button>

              {selectedBooking.status === "Assigned" && (
                <button
                  type="button"
                  onClick={() => handleStartTransit(selectedBooking.bookingId)}
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs flex items-center gap-1.5 shadow-md cursor-pointer"
                >
                  <Play size={14} />
                  <span>Goods Loaded / Start Transit</span>
                </button>
              )}

              {selectedBooking.status === "In Transit" && (
                <button
                  type="button"
                  onClick={() => handleConfirmDelivery(selectedBooking.bookingId, selectedBooking.amount, selectedBooking.regNo)}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white font-black px-6 py-2.5 rounded-xl text-xs flex items-center gap-1.5 shadow-md cursor-pointer"
                >
                  <CheckCircle2 size={14} />
                  <span>Confirm Delivery &amp; Handover e-POD</span>
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
