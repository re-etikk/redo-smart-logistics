import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
  CalendarCheck, CheckCircle2, Clock, Download, Eye, Filter, IndianRupee,
  MapPin, Phone, Search, Truck, XCircle, ChevronRight, X, RotateCcw,
  SlidersHorizontal, Calendar, ArrowUpDown, ShieldCheck, Check
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getTrucks } from "../lib/truckStore";
import { getSharedCargoList } from "../lib/cargoStore";

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
  status: "In Progress" | "Upcoming" | "Completed" | "Cancelled";
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
}

const INITIAL_BOOKINGS: BookingItem[] = [
  {
    id: "B1",
    bookingId: "RD124578",
    truckName: "REDO Express Container (19 Feet)",
    specs: "19 Feet · 8.5 Ton · Enclosed Container",
    origin: "Delhi NCR (Okhla Industrial Area)",
    pickupAddress: "Plot 42, Sector 58, Okhla Phase 3 Industrial Area, Delhi - 110020",
    dest: "Mumbai (Bhiwandi Logistics Park)",
    deliveryAddress: "Gala No. 14, Indian Corporation Compound, Mankoli Naka, Bhiwandi, MH - 421302",
    date: "23 Aug 2026, 10:30 AM",
    timestamp: new Date("2026-08-23T10:30:00").getTime(),
    amount: 24500,
    paymentStatus: "Escrow Secured",
    paymentDate: "23 Aug 2026",
    status: "In Progress",
    statusDesc: "Live Highway Transit · Arriving in ~3 hrs 20 mins",
    statusTone: "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400",
    photoUrl: "/assets/redo_truck.jpg",
    driverName: "Mukesh Yadav",
    driverPhone: "+91 98112 34567",
    regNo: "REDO 2024",
    goodsType: "Automotive Components & Spare Parts",
    weightTons: 6.5,
    shipperName: "Hero Moto Logistics",
    shipperPhone: "+91 98765 43210",
  },
  {
    id: "B2",
    bookingId: "RD124567",
    truckName: "BharatBenz 1917R (19 Feet)",
    specs: "19 Feet · 10.5 Ton · Enclosed Container",
    origin: "Delhi (Kundli Industrial Area)",
    pickupAddress: "Shed 10, HSIIDC Industrial Complex, Kundli, Haryana - 131028",
    dest: "Indore (Pithampur Hub)",
    deliveryAddress: "Sector 3, Pithampur Industrial Estate, Dhar Road, MP - 454775",
    date: "22 Aug 2026, 04:00 PM",
    timestamp: new Date("2026-08-22T16:00:00").getTime(),
    amount: 16800,
    paymentStatus: "Paid",
    paymentDate: "22 Aug 2026",
    status: "Completed",
    statusDesc: "Delivered successfully · Signed e-POD Handover",
    statusTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
    driverName: "Mukesh Yadav",
    driverPhone: "+91 98112 34567",
    regNo: "REDO 2024",
    goodsType: "FMCG Packaged Food & Beverages",
    weightTons: 4.8,
    shipperName: "Dabur Distribution Pvt Ltd",
    shipperPhone: "+91 98112 55667",
  },
  {
    id: "B3",
    bookingId: "RD124556",
    truckName: "REDO Express Container (19 Feet)",
    specs: "19 Feet · 8.5 Ton · Enclosed Container",
    origin: "Bengaluru (Peenya Industrial Area)",
    pickupAddress: "Plot 18, 4th Phase, Peenya Industrial Area, Bengaluru - 560058",
    dest: "Chennai (Sriperumbudur Hub)",
    deliveryAddress: "SIPCOT Industrial Complex, Sriperumbudur, Tamil Nadu - 602105",
    date: "21 Aug 2026, 09:00 AM",
    timestamp: new Date("2026-08-21T09:00:00").getTime(),
    amount: 14500,
    paymentStatus: "Paid",
    paymentDate: "21 Aug 2026",
    status: "Completed",
    statusDesc: "Delivered · Payment Settled to Bank Account",
    statusTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
    driverName: "Mukesh Yadav",
    driverPhone: "+91 98112 34567",
    regNo: "REDO 2024",
    goodsType: "Industrial Machinery & Tooling",
    weightTons: 8.0,
    shipperName: "L&T Heavy Engineering",
    shipperPhone: "+91 98450 77889",
  },
  {
    id: "B4",
    bookingId: "RD124544",
    truckName: "REDO Express Container (19 Feet)",
    specs: "19 Feet · 8.5 Ton · Enclosed Container",
    origin: "Delhi (Mayapuri Transport Hub)",
    pickupAddress: "Phase 2, Mayapuri Industrial Area, New Delhi - 110064",
    dest: "Lucknow (Transport Nagar)",
    deliveryAddress: "Sector 18, Transport Nagar, Kanpur Road, Lucknow, UP - 226012",
    date: "19 Aug 2026, 11:00 AM",
    timestamp: new Date("2026-08-19T11:00:00").getTime(),
    amount: 18500,
    paymentStatus: "Paid",
    paymentDate: "19 Aug 2026",
    status: "Completed",
    statusDesc: "Trip Completed · e-POD Verified",
    statusTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
    driverName: "Mukesh Yadav",
    driverPhone: "+91 98112 34567",
    regNo: "REDO 2024",
    goodsType: "E-Commerce Packaged Parcels",
    weightTons: 5.2,
    shipperName: "Delhivery Surface Freight",
    shipperPhone: "+91 98445 67890",
  },
  {
    id: "B5",
    bookingId: "RD124533",
    truckName: "REDO Express Container (19 Feet)",
    specs: "19 Feet · 8.5 Ton · Enclosed Container",
    origin: "Jaipur (Sitapura Industrial Zone)",
    pickupAddress: "RIICO Industrial Area, Sitapura, Jaipur, Rajasthan - 302022",
    dest: "Ahmedabad (Sanand Auto Corridor)",
    deliveryAddress: "GIDC Industrial Estate, Sanand, Gujarat - 382110",
    date: "15 Aug 2026, 08:00 AM",
    timestamp: new Date("2026-08-15T08:00:00").getTime(),
    amount: 15200,
    paymentStatus: "Cancelled",
    paymentDate: "15 Aug 2026",
    status: "Cancelled",
    statusDesc: "Cancelled by shipper · Full cancellation compensation paid",
    statusTone: "bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-400",
    photoUrl: "/assets/redo_truck.jpg",
    driverName: "Mukesh Yadav",
    driverPhone: "+91 98112 34567",
    regNo: "REDO 2024",
    goodsType: "Textile Fabrics",
    weightTons: 4.0,
    shipperName: "Rajasthan Weaving Mills",
    shipperPhone: "+91 98556 78901",
  }
];

export default function Bookings() {
  const navigate = useNavigate();
  const { t } = useTranslation();

  // Filter States
  const [tab, setTab] = useState<"all" | "progress" | "upcoming" | "completed" | "cancelled">("all");
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

  // Synchronize newly accepted cargo
  const allBookings = useMemo(() => {
    const cargoList = getSharedCargoList();
    const assignedCargo = cargoList.filter(c => c.status === "Assigned");
    const merged = [...INITIAL_BOOKINGS];

    for (const c of assignedCargo) {
      if (!merged.some(b => b.bookingId === c.id)) {
        merged.unshift({
          id: `B-${c.id}`,
          bookingId: c.id,
          truckName: "REDO Express Container (19 Feet)",
          specs: "19 Feet · 8.5 Ton · Enclosed Container",
          origin: c.origin,
          pickupAddress: c.pickupAddress,
          dest: c.destination,
          deliveryAddress: c.deliveryAddress,
          date: c.pickupDate || "Today, Immediate",
          timestamp: Date.now(),
          amount: c.offeredPriceInr || 24500,
          paymentStatus: "Escrow Secured",
          paymentDate: "Today",
          status: "In Progress",
          statusDesc: "Active Highway Dispatch · Telemetry Connected",
          statusTone: "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400",
          photoUrl: "/assets/redo_truck.jpg",
          driverName: c.assignedDriverName || "Mukesh Yadav",
          driverPhone: c.assignedDriverPhone || "+91 98112 34567",
          regNo: c.assignedTruckReg || "REDO 2024",
          goodsType: c.cargoType,
          weightTons: c.weightTons,
          shipperName: c.shipperName,
          shipperPhone: c.shipperPhone,
        });
      }
    }
    return merged;
  }, []);

  // Filter Computation
  const filteredBookings = useMemo(() => {
    return allBookings.filter((b) => {
      // 1. Status Tab Filter
      if (tab === "progress" && b.status !== "In Progress") return false;
      if (tab === "upcoming" && b.status !== "Upcoming") return false;
      if (tab === "completed" && b.status !== "Completed") return false;
      if (tab === "cancelled" && b.status !== "Cancelled") return false;

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

      // 3. Date Range Filter
      if (dateRangePreset === "today") {
        const isToday = b.date.toLowerCase().includes("today") || b.date.includes("23 Aug 2026");
        if (!isToday) return false;
      } else if (dateRangePreset === "this_week") {
        const oneWeekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
        if (b.timestamp < oneWeekAgo) return false;
      } else if (dateRangePreset === "this_month") {
        const oneMonthAgo = Date.now() - 30 * 24 * 60 * 60 * 1000;
        if (b.timestamp < oneMonthAgo) return false;
      } else if (dateRangePreset === "custom" && customStartDate) {
        const start = new Date(customStartDate).getTime();
        const end = customEndDate ? new Date(customEndDate).getTime() + 86400000 : Infinity;
        if (b.timestamp < start || b.timestamp > end) return false;
      }

      // 4. Payment Filter
      if (filterPayment !== "all") {
        if (filterPayment === "Paid" && b.paymentStatus !== "Paid") return false;
        if (filterPayment === "Pending" && b.paymentStatus !== "Pending") return false;
        if (filterPayment === "Escrow" && b.paymentStatus !== "Escrow Secured") return false;
      }

      // 5. Goods Type Filter
      if (filterGoods !== "all" && !b.goodsType.toLowerCase().includes(filterGoods.toLowerCase())) {
        return false;
      }

      // 6. Price Range Filter
      if (minPrice && b.amount < parseFloat(minPrice)) return false;
      if (maxPrice && b.amount > parseFloat(maxPrice)) return false;

      return true;
    });
  }, [allBookings, tab, search, dateRangePreset, customStartDate, customEndDate, filterPayment, filterGoods, minPrice, maxPrice]);

  // Active Filters Count
  const activeFiltersCount = useMemo(() => {
    let count = 0;
    if (dateRangePreset !== "all") count++;
    if (filterPayment !== "all") count++;
    if (filterGoods !== "all") count++;
    if (minPrice || maxPrice) count++;
    return count;
  }, [dateRangePreset, filterPayment, filterGoods, minPrice, maxPrice]);

  const resetAllFilters = () => {
    setDateRangePreset("all");
    setCustomStartDate("");
    setCustomEndDate("");
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
              Filter by date range, payment status, commodity type, and download official CSV ledger statements.
            </p>
          </div>

          <button
            onClick={exportBookingsCSV}
            className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-900 dark:text-white font-bold px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm transition text-xs flex items-center gap-2 cursor-pointer"
          >
            <Download size={14} /> {t("exportReport")}
          </button>
        </div>

        {/* 5 Dynamic Stat Cards */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <CalendarCheck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("totalBookings")}</span>
            <span className="text-lg font-black block">{allBookings.length}</span>
            <span className="text-[10px] font-bold text-slate-500 block">All Time</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Truck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("inProgress")}</span>
            <span className="text-lg font-black text-blue-600 dark:text-blue-400 block">
              {allBookings.filter(b => b.status === "In Progress").length}
            </span>
            <span className="text-[10px] font-bold text-blue-600 block">Active On Highway</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Clock size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("upcoming")}</span>
            <span className="text-lg font-black text-amber-600 dark:text-amber-400 block">
              {allBookings.filter(b => b.status === "Upcoming").length}
            </span>
            <span className="text-[10px] font-bold text-amber-600 block">Scheduled Loading</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <CheckCircle2 size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("completed")}</span>
            <span className="text-lg font-black text-emerald-600 dark:text-emerald-400 block">
              {allBookings.filter(b => b.status === "Completed").length}
            </span>
            <span className="text-[10px] font-bold text-emerald-600 block">Signed e-POD</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center">
              <XCircle size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("cancelled")}</span>
            <span className="text-lg font-black text-rose-600 dark:text-rose-400 block">
              {allBookings.filter(b => b.status === "Cancelled").length}
            </span>
            <span className="text-[10px] font-bold text-rose-600 block">Cancelled Trips</span>
          </div>
        </div>

        {/* Filter & Date Range Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 shadow-sm flex flex-col lg:flex-row items-center justify-between gap-4">
          
          {/* Status Tabs */}
          <div className="flex items-center gap-1.5 font-bold text-xs overflow-x-auto w-full lg:w-auto">
            <button
              onClick={() => setTab("all")}
              className={`px-3.5 py-2 rounded-xl transition cursor-pointer ${tab === "all" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}
            >
              {t("all")} ({allBookings.length})
            </button>
            <button
              onClick={() => setTab("progress")}
              className={`px-3.5 py-2 rounded-xl transition cursor-pointer ${tab === "progress" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}
            >
              {t("inProgress")}
            </button>
            <button
              onClick={() => setTab("upcoming")}
              className={`px-3.5 py-2 rounded-xl transition cursor-pointer ${tab === "upcoming" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}
            >
              {t("upcoming")}
            </button>
            <button
              onClick={() => setTab("completed")}
              className={`px-3.5 py-2 rounded-xl transition cursor-pointer ${tab === "completed" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}
            >
              {t("completed")}
            </button>
            <button
              onClick={() => setTab("cancelled")}
              className={`px-3.5 py-2 rounded-xl transition cursor-pointer ${tab === "cancelled" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}
            >
              {t("cancelled")}
            </button>
          </div>

          {/* Right Controls: Search, Date Range, Advanced Filter */}
          <div className="flex flex-wrap items-center gap-2.5 w-full lg:w-auto justify-end">
            <div className="relative flex-1 sm:w-48">
              <Search size={14} className="text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search bookings..."
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl pl-8 pr-3 py-1.5 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>

            {/* Date Range Dropdown Trigger */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setShowDateDropdown(!showDateDropdown)}
                className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:border-amber-400 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2 transition cursor-pointer"
              >
                <CalendarCheck size={14} className="text-amber-500" />
                <span>
                  {dateRangePreset === "all" && "All Dates"}
                  {dateRangePreset === "today" && "Today"}
                  {dateRangePreset === "this_week" && "This Week"}
                  {dateRangePreset === "this_month" && "This Month"}
                  {dateRangePreset === "custom" && "Custom Range"}
                </span>
              </button>

              {/* Date Range Dropdown Menu */}
              {showDateDropdown && (
                <div className="absolute right-0 mt-2 w-56 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl z-30 p-2 space-y-1 text-xs font-bold">
                  {[
                    { id: "all", label: "All Time" },
                    { id: "today", label: "Today (23 Aug 2026)" },
                    { id: "this_week", label: "Last 7 Days" },
                    { id: "this_month", label: "This Month (Aug 2026)" },
                    { id: "custom", label: "Custom Date Range" },
                  ].map(opt => (
                    <button
                      key={opt.id}
                      type="button"
                      onClick={() => {
                        setDateRangePreset(opt.id);
                        if (opt.id !== "custom") setShowDateDropdown(false);
                      }}
                      className={`w-full text-left px-3 py-1.5 rounded-xl transition flex items-center justify-between ${
                        dateRangePreset === opt.id ? "bg-amber-100 dark:bg-slate-800 text-amber-900 dark:text-amber-400 font-black" : "hover:bg-slate-50 dark:hover:bg-slate-800"
                      }`}
                    >
                      <span>{opt.label}</span>
                      {dateRangePreset === opt.id && <Check size={13} />}
                    </button>
                  ))}

                  {dateRangePreset === "custom" && (
                    <div className="pt-2 border-t border-slate-100 dark:border-slate-800 space-y-2">
                      <div>
                        <span className="text-[10px] text-slate-400 block">From:</span>
                        <input
                          type="date"
                          value={customStartDate}
                          onChange={(e) => setCustomStartDate(e.target.value)}
                          className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg px-2 py-1 text-xs font-bold"
                        />
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-400 block">To:</span>
                        <input
                          type="date"
                          value={customEndDate}
                          onChange={(e) => setCustomEndDate(e.target.value)}
                          className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg px-2 py-1 text-xs font-bold"
                        />
                      </div>
                      <button
                        type="button"
                        onClick={() => setShowDateDropdown(false)}
                        className="w-full bg-amber-400 text-slate-950 font-black py-1.5 rounded-lg text-xs"
                      >
                        Apply Range
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Advanced Filters Button */}
            <button
              type="button"
              onClick={() => setShowFiltersModal(true)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 border transition cursor-pointer ${
                activeFiltersCount > 0
                  ? "bg-amber-400 text-slate-950 border-amber-400 font-black shadow-xs"
                  : "bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800"
              }`}
            >
              <Filter size={13} />
              <span>Filters {activeFiltersCount > 0 && `(${activeFiltersCount})`}</span>
            </button>

            {/* Reset Filters */}
            {activeFiltersCount > 0 && (
              <button
                type="button"
                onClick={resetAllFilters}
                title="Reset all filters"
                className="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg cursor-pointer"
              >
                <RotateCcw size={14} />
              </button>
            )}
          </div>
        </div>

        {/* Bookings Table List */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="hidden lg:grid grid-cols-12 text-[10px] font-black uppercase text-slate-400 pb-3 border-b border-slate-100 dark:border-slate-800 tracking-wider">
            <div className="col-span-4">Booking Details &amp; Vehicle</div>
            <div className="col-span-3">Route &amp; Warehouse Address</div>
            <div className="col-span-2">Freight &amp; Escrow</div>
            <div className="col-span-3 text-right">Trip Status &amp; Action</div>
          </div>

          {filteredBookings.length === 0 ? (
            <div className="py-12 text-center space-y-2">
              <p className="text-sm font-bold text-slate-500">No bookings match the selected filters or date range.</p>
              <button
                onClick={resetAllFilters}
                className="text-xs font-black text-amber-500 hover:underline"
              >
                Clear all filters
              </button>
            </div>
          ) : (
            <div className="divide-y divide-slate-100 dark:divide-slate-800">
              {filteredBookings.map((b) => (
                <div key={b.id} className="py-4 flex flex-col lg:grid lg:grid-cols-12 gap-4 items-start lg:items-center">
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

                    <div className="min-w-0">
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

                  {/* Trip Status & Modal Trigger */}
                  <div className="lg:col-span-3 flex items-center justify-between lg:justify-end gap-3 w-full">
                    <div className="lg:text-right">
                      <span className={`text-[10px] font-black px-2.5 py-0.5 rounded-full block w-fit lg:ml-auto ${b.statusTone}`}>
                        {b.status}
                      </span>
                      <span className="text-[10px] text-slate-400 font-medium block truncate max-w-xs">
                        {b.statusDesc}
                      </span>
                    </div>

                    <button
                      onClick={() => setSelectedBooking(b)}
                      className="bg-slate-100 dark:bg-slate-800 hover:bg-amber-400 hover:text-slate-950 text-slate-700 dark:text-slate-300 font-bold p-2.5 rounded-xl transition cursor-pointer shrink-0"
                      title="View Details"
                    >
                      <Eye size={16} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* ADVANCED FILTERS MODAL */}
      {/* ========================================================================= */}
      {showFiltersModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div className="flex items-center gap-2">
                <SlidersHorizontal size={16} className="text-amber-500" />
                <h3 className="text-base font-black">Filter Bookings</h3>
              </div>
              <button onClick={() => setShowFiltersModal(false)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            <div className="space-y-4">
              {/* Payment Filter */}
              <div>
                <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Payment Status</label>
                <div className="grid grid-cols-3 gap-2">
                  {["all", "Paid", "Escrow"].map((p) => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => setFilterPayment(p)}
                      className={`py-2 rounded-xl text-xs font-bold border transition ${
                        filterPayment === p
                          ? "bg-amber-400 text-slate-950 border-amber-400 font-black"
                          : "border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800"
                      }`}
                    >
                      {p === "all" ? "All Payments" : p}
                    </button>
                  ))}
                </div>
              </div>

              {/* Commodity Goods Type Filter */}
              <div>
                <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Cargo Commodity Type</label>
                <select
                  value={filterGoods}
                  onChange={(e) => setFilterGoods(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold"
                >
                  <option value="all">All Commodities</option>
                  <option value="Automotive">Automotive &amp; Spare Parts</option>
                  <option value="FMCG">FMCG &amp; Packaged Foods</option>
                  <option value="Machinery">Machinery &amp; Industrial</option>
                  <option value="Textile">Textiles &amp; Fabrics</option>
                  <option value="E-Commerce">E-Commerce Parcels</option>
                </select>
              </div>

              {/* Freight Price Range */}
              <div>
                <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Freight Rate Range (₹ INR)</label>
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="number"
                    value={minPrice}
                    onChange={(e) => setMinPrice(e.target.value)}
                    placeholder="Min Price (₹)"
                    className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold"
                  />
                  <input
                    type="number"
                    value={maxPrice}
                    onChange={(e) => setMaxPrice(e.target.value)}
                    placeholder="Max Price (₹)"
                    className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold"
                  />
                </div>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-slate-800">
              <button
                type="button"
                onClick={resetAllFilters}
                className="text-xs text-rose-500 hover:underline font-bold"
              >
                Reset Filters
              </button>
              <button
                type="button"
                onClick={() => setShowFiltersModal(false)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition"
              >
                Apply Filters ({filteredBookings.length} results)
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* BOOKING DETAILS MODAL */}
      {/* ========================================================================= */}
      {selectedBooking && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-lg w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <span className="text-[10px] font-mono text-amber-500 font-bold block">CONSIGNMENT LEDGER</span>
                <h3 className="text-base font-black">{selectedBooking.bookingId} • {selectedBooking.goodsType}</h3>
              </div>
              <button onClick={() => setSelectedBooking(null)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-2 bg-slate-50 dark:bg-slate-800 p-3 rounded-2xl border border-slate-200 dark:border-slate-700 text-[11px]">
                <div>
                  <span className="text-slate-400 block text-[10px]">VEHICLE</span>
                  <span className="font-black">{selectedBooking.truckName}</span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[10px]">REG NO</span>
                  <span className="font-mono text-amber-500 font-black">{selectedBooking.regNo}</span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[10px]">ASSIGNED DRIVER</span>
                  <span className="font-black">{selectedBooking.driverName}</span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[10px]">DRIVER CONTACT</span>
                  <a href={`tel:${selectedBooking.driverPhone}`} className="text-emerald-600 hover:underline font-mono">
                    {selectedBooking.driverPhone}
                  </a>
                </div>
              </div>

              {/* Exact Warehouse Addresses */}
              <div className="space-y-2 p-3 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700">
                <div>
                  <span className="text-[10px] text-emerald-600 font-black uppercase block">Pickup Warehouse Address:</span>
                  <p className="text-slate-800 dark:text-slate-200">{selectedBooking.pickupAddress || selectedBooking.origin}</p>
                </div>
                <div className="pt-1 border-t border-slate-200/60 dark:border-slate-700">
                  <span className="text-[10px] text-rose-600 font-black uppercase block">Delivery Destination Address:</span>
                  <p className="text-slate-800 dark:text-slate-200">{selectedBooking.deliveryAddress || selectedBooking.dest}</p>
                </div>
              </div>

              <div className="flex items-center justify-between p-3.5 bg-amber-50 dark:bg-slate-800 border border-amber-300 dark:border-slate-700 rounded-2xl">
                <div>
                  <span className="text-[10px] text-slate-400 block">SETTLED FREIGHT</span>
                  <span className="text-base font-black">₹{selectedBooking.amount.toLocaleString("en-IN")}</span>
                </div>
                <span className="px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-black">
                  {selectedBooking.paymentStatus}
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={() => setSelectedBooking(null)}
              className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-2.5 rounded-xl text-xs transition"
            >
              Close Details
            </button>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
