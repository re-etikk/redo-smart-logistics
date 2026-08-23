import { useState } from "react";
import {
  CalendarCheck, CheckCircle2, Truck, XCircle, Download, Filter, Eye,
  Phone, MapPin, ShieldCheck, X, FileText, ArrowRight
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getTrucks, type TruckItem } from "../lib/truckStore";

export default function OwnerBookings() {
  const { t } = useTranslation();
  const [tab, setTab] = useState<"all" | "upcoming" | "progress" | "completed" | "cancelled">("all");
  const [selectedBooking, setSelectedBooking] = useState<any | null>(null);

  const fleet = getTrucks();

  const ownerBookings = [
    {
      id: "B1",
      bookingId: "RD124578",
      truckName: "Eicher Pro 2059 (17 Feet)",
      specs: "17 Feet · 7 Ton · Container Enclosed",
      origin: "Delhi Hub (Okhla Phase 3)",
      dest: "Mumbai (Bhiwandi Logistics Park)",
      date: "20 May 2024, 10:00 AM",
      amount: 22000,
      paymentStatus: "Paid",
      paymentDate: "20 May 2024",
      status: "Completed",
      statusDesc: "Trip completed on 21 May 2024, 08:30 PM",
      statusTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80",
      driverName: "Mukesh Yadav",
      driverPhone: "+91 98112 34567",
      regNo: "HR55 AB 1234",
      goodsType: "Automobile Components & Spare Parts",
      weightTons: 6.2,
      shipperName: "Hero Moto Logistics",
    },
    {
      id: "B2",
      bookingId: "RD124567",
      truckName: "BharatBenz 1917R (19 Feet)",
      specs: "19 Feet · 10 Ton · Heavy Duty Enclosed",
      origin: "Delhi (Kundli Industrial Area)",
      dest: "Mumbai (JNPT Port Hub)",
      date: "21 May 2024, 09:00 AM",
      amount: 26500,
      paymentStatus: "Paid",
      paymentDate: "21 May 2024",
      status: "In Progress",
      statusDesc: "Driver on the way · Expected: 22 May, 06:00 AM",
      statusTone: "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400",
      photoUrl: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80",
      driverName: "Jaswinder Singh",
      driverPhone: "+91 98223 45678",
      regNo: "HR55 CD 5678",
      goodsType: "Electronics & White Goods",
      weightTons: 8.5,
      shipperName: "Samsung India Logistics",
    },
    {
      id: "B3",
      bookingId: "RD124556",
      truckName: "Tata 1412 LPT (14 Feet)",
      specs: "14 Feet · 5 Ton · Open Body",
      origin: "Delhi (Nangloi Transport Nagar)",
      dest: "Indore (Pithampur Industrial Hub)",
      date: "20 May 2024, 02:00 PM",
      amount: 16200,
      paymentStatus: "Pending",
      paymentDate: "Payment Pending",
      status: "Upcoming",
      statusDesc: "Starts on 20 May 2024, 02:00 PM",
      statusTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400",
      photoUrl: "https://images.unsplash.com/photo-1586191582150-a8d29837936a?auto=format&fit=crop&w=600&q=80",
      driverName: "Sanjay Verma",
      driverPhone: "+91 98334 56789",
      regNo: "HR55 EF 9012",
      goodsType: "FMCG Packaged Goods",
      weightTons: 4.8,
      shipperName: "Dabur Distribution",
    },
    {
      id: "B4",
      bookingId: "RD124544",
      truckName: "Mahindra Bolero Maxi Truck",
      specs: "Pickup · 1.5 Ton · High Payload",
      origin: "Delhi (Mayapuri)",
      dest: "Lucknow (Transport Nagar)",
      date: "22 May 2024, 11:00 AM",
      amount: 12500,
      paymentStatus: "Paid",
      paymentDate: "22 May 2024",
      status: "Completed",
      statusDesc: "Trip completed on 23 May 2024, 07:45 AM",
      statusTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1592838064575-70ed626d3a0e?auto=format&fit=crop&w=600&q=80",
      driverName: "Ramesh Chauhan",
      driverPhone: "+91 98445 67890",
      regNo: "HR55 GH 3456",
      goodsType: "E-Commerce Parcels",
      weightTons: 1.4,
      shipperName: "Delhivery Hub",
    },
    {
      id: "B5",
      bookingId: "RD124533",
      truckName: "BharatBenz 3528C (32 Feet Multi-Axle)",
      specs: "32 Feet · 25 Ton · Heavy Multi-Axle",
      origin: "Bengaluru (Peenya Industrial Area)",
      dest: "Chennai (Sriperumbudur Hub)",
      date: "18 May 2024, 08:00 AM",
      amount: 28800,
      paymentStatus: "Cancelled",
      paymentDate: "18 May 2024",
      status: "Cancelled",
      statusDesc: "Cancelled on 18 May 2024, 09:15 AM",
      statusTone: "bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-400",
      photoUrl: "https://images.unsplash.com/photo-1501700493788-fa1a4fc9fe62?auto=format&fit=crop&w=600&q=80",
      driverName: "Anand Pillai",
      driverPhone: "+91 98556 78901",
      regNo: "HR55 IJ 7890",
      goodsType: "Industrial Machinery",
      weightTons: 21.0,
      shipperName: "L&T Heavy Engineering",
    },
  ];

  const filteredBookings = ownerBookings.filter((b) => {
    if (tab === "all") return true;
    if (tab === "upcoming") return b.status === "Upcoming";
    if (tab === "progress") return b.status === "In Progress";
    if (tab === "completed") return b.status === "Completed";
    if (tab === "cancelled") return b.status === "Cancelled";
    return true;
  });

  return (
    <OwnerLayout activeTab="bookings" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight">{t("myBookings")}</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Track and manage all your truck bookings, cargo consignments and trip schedules.
            </p>
          </div>

          <button
            onClick={() => alert("Downloading Bookings CSV statement...")}
            className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-900 dark:text-white font-bold px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm transition text-xs flex items-center gap-2 cursor-pointer"
          >
            <Download size={14} /> {t("exportReport")}
          </button>
        </div>

        {/* 5 Stat Cards */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <CalendarCheck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("totalBookings")}</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">28</span>
            <span className="text-[10px] font-bold text-slate-500 block">All Time</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <CheckCircle2 size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("confirmed")}</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">14</span>
            <span className="text-[10px] font-bold text-emerald-600 block">Current &amp; Upcoming</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Truck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("inProgress")}</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">6</span>
            <span className="text-[10px] font-bold text-amber-600 block">Currently Running</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <CheckCircle2 size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("completed")}</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">22</span>
            <span className="text-[10px] font-bold text-slate-500 block">All Completed</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center">
              <XCircle size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("cancelled")}</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">3</span>
            <span className="text-[10px] font-bold text-rose-600 block">All Cancelled</span>
          </div>
        </div>

        {/* Filter Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-3 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-extrabold text-xs overflow-x-auto w-full sm:w-auto">
            <button onClick={() => setTab("all")} className={`px-4 py-2 rounded-xl transition cursor-pointer ${tab === "all" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}>{t("all")}</button>
            <button onClick={() => setTab("upcoming")} className={`px-4 py-2 rounded-xl transition cursor-pointer ${tab === "upcoming" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}>{t("upcoming")}</button>
            <button onClick={() => setTab("progress")} className={`px-4 py-2 rounded-xl transition cursor-pointer ${tab === "progress" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}>{t("inProgress")}</button>
            <button onClick={() => setTab("completed")} className={`px-4 py-2 rounded-xl transition cursor-pointer ${tab === "completed" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}>{t("completed")}</button>
            <button onClick={() => setTab("cancelled")} className={`px-4 py-2 rounded-xl transition cursor-pointer ${tab === "cancelled" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"}`}>{t("cancelled")}</button>
          </div>

          <div className="flex items-center gap-2">
            <div className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
              <CalendarCheck size={14} className="text-amber-500" />
              <span>Select Date Range</span>
            </div>
            <button className="p-2 border border-slate-200 dark:border-slate-700 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 flex items-center gap-1 text-xs font-bold">
              <Filter size={14} /> Filters
            </button>
          </div>
        </div>

        {/* Bookings List Card */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="hidden lg:grid grid-cols-12 text-[10px] font-black uppercase text-slate-400 pb-3 border-b border-slate-100 dark:border-slate-800 tracking-wider">
            <div className="col-span-4">Booking Details &amp; Vehicle</div>
            <div className="col-span-3">Route &amp; Date</div>
            <div className="col-span-2">Payment</div>
            <div className="col-span-3 text-right">Status &amp; Action</div>
          </div>

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
                      Booking ID: {b.bookingId}
                    </span>
                    <h4 className="font-black text-xs sm:text-sm truncate text-slate-900 dark:text-white">
                      {b.truckName}
                    </h4>
                    <p className="text-[11px] text-slate-500 font-medium truncate">
                      {b.specs}
                    </p>
                  </div>
                </div>

                {/* Route & Date */}
                <div className="lg:col-span-3 space-y-1 w-full text-xs font-bold">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" />
                    <span className="truncate text-slate-900 dark:text-slate-100">{b.origin}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-rose-500 shrink-0" />
                    <span className="truncate text-slate-900 dark:text-slate-100">{b.dest}</span>
                  </div>
                  <span className="text-[10px] text-slate-400 block pt-0.5">{b.date}</span>
                </div>

                {/* Payment */}
                <div className="lg:col-span-2 space-y-0.5 w-full">
                  <span className="text-sm font-black text-slate-900 dark:text-white block">
                    ₹{b.amount.toLocaleString("en-IN")}
                  </span>
                  <span className={`inline-block text-[9px] font-black px-2 py-0.5 rounded-full ${
                    b.paymentStatus === "Paid"
                      ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400"
                      : "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400"
                  }`}>
                    {b.paymentStatus}
                  </span>
                  <span className="text-[10px] text-slate-400 block">{b.paymentDate}</span>
                </div>

                {/* Status & View Details Action */}
                <div className="lg:col-span-3 flex items-center justify-between lg:justify-end gap-3 w-full">
                  <div className="lg:text-right">
                    <span className={`inline-block text-[10px] font-black px-2.5 py-0.5 rounded-full ${b.statusTone}`}>
                      {b.status}
                    </span>
                    <p className="text-[10px] text-slate-400 mt-0.5 max-w-[170px] truncate">
                      {b.statusDesc}
                    </p>
                  </div>

                  <button
                    onClick={() => setSelectedBooking(b)}
                    className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-3.5 py-1.5 rounded-xl shadow-xs transition whitespace-nowrap cursor-pointer"
                  >
                    {t("viewDetails")}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* VIEW BOOKING DETAILS MODAL */}
      {/* ========================================================================= */}
      {selectedBooking && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-lg w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <span className="text-[10px] font-mono text-amber-500 font-bold block">
                  BOOKING REFERENCE: {selectedBooking.bookingId}
                </span>
                <h3 className="text-base font-black">{selectedBooking.truckName}</h3>
              </div>
              <button onClick={() => setSelectedBooking(null)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            {/* Photo & Vehicle Header */}
            <div className="relative h-44 rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-700 shadow-md">
              <img
                src={selectedBooking.photoUrl}
                alt={selectedBooking.truckName}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-slate-950/90 via-slate-950/30 to-transparent flex flex-col justify-end p-4 text-white">
                <span className="text-xs font-black text-amber-400 uppercase">{selectedBooking.regNo}</span>
                <p className="text-xs font-bold">{selectedBooking.specs}</p>
              </div>
            </div>

            {/* Shipper & Consignment Details */}
            <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400">Shipper / Customer:</span>
                <span className="font-black">{selectedBooking.shipperName}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Goods Type:</span>
                <span>{selectedBooking.goodsType}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Weight Consignment:</span>
                <span>{selectedBooking.weightTons} Metric Tons</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Driver Assigned:</span>
                <span className="flex items-center gap-1.5 text-amber-600 dark:text-amber-400 font-black">
                  {selectedBooking.driverName} ({selectedBooking.driverPhone})
                </span>
              </div>
            </div>

            {/* Settlement Total */}
            <div className="flex items-center justify-between p-4 bg-amber-500/10 border border-amber-400/40 rounded-2xl">
              <div>
                <span className="text-[10px] uppercase font-bold text-amber-800 dark:text-amber-300 block">Total Freight Amount</span>
                <span className="text-xl font-black text-slate-900 dark:text-white">
                  ₹{selectedBooking.amount.toLocaleString("en-IN")}
                </span>
              </div>
              <span className="bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400 text-xs font-black px-3 py-1 rounded-full">
                ✓ {selectedBooking.paymentStatus}
              </span>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => setSelectedBooking(null)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm cursor-pointer"
              >
                Close Details
              </button>
            </div>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
