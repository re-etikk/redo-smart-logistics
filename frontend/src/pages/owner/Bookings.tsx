import { useState } from "react";
import {
  CalendarCheck, CheckCircle2, Truck, XCircle, Download, Filter, MoreVertical
} from "lucide-react";
import OwnerLayout from "../../components/OwnerLayout";

export default function OwnerBookings() {
  const [tab, setTab] = useState("all");

  const mockOwnerBookings = [
    { id: "B1", bookingId: "RD124578", truck: "Eicher 17 Feet", specs: "17 Feet · 7 Ton · Enclosed", origin: "Delhi, Delhi", dest: "Mumbai, Maharashtra", date: "20 May 2024, 10:00 AM", amount: "₹22,000", paymentStatus: "Paid", paymentDate: "20 May 2024", status: "Completed", statusDesc: "Trip completed on 21 May 2024, 08:30 PM", statusTone: "bg-emerald-100 text-emerald-800", emoji: "🚛" },
    { id: "B2", bookingId: "RD124567", truck: "BharatBenz 19 Feet", specs: "19 Feet · 10 Ton · Enclosed", origin: "Delhi, Delhi", dest: "Mumbai, Maharashtra", date: "21 May 2024, 09:00 AM", amount: "₹26,500", paymentStatus: "Paid", paymentDate: "21 May 2024", status: "In Progress", statusDesc: "Driver on the way · Expected: 22 May, 06:00 AM", statusTone: "bg-blue-100 text-blue-800", emoji: "🚚" },
    { id: "B3", bookingId: "RD124556", truck: "Tata 14 Feet", specs: "14 Feet · 5 Ton · Open Body", origin: "Delhi, Delhi", dest: "Indore, Madhya Pradesh", date: "20 May 2024, 02:00 PM", amount: "₹16,200", paymentStatus: "Pending", paymentDate: "Payment Pending", status: "Upcoming", statusDesc: "Starts on 20 May 2024, 02:00 PM", statusTone: "bg-amber-100 text-amber-800", emoji: "🚛" },
    { id: "B4", bookingId: "RD124544", truck: "Mahindra Pickup", specs: "Pickup · 1.5 Ton · Open Body", origin: "Delhi, Delhi", dest: "Lucknow, Uttar Pradesh", date: "22 May 2024, 11:00 AM", amount: "₹12,500", paymentStatus: "Paid", paymentDate: "22 May 2024", status: "Completed", statusDesc: "Trip completed on 23 May 2024, 07:45 AM", statusTone: "bg-emerald-100 text-emerald-800", emoji: "🛻" },
    { id: "B5", bookingId: "RD124533", truck: "BharatBenz 32 Feet", specs: "32 Feet · 16 Ton · Tipper", origin: "Bengaluru, Karnataka", dest: "Chennai, Tamil Nadu", date: "18 May 2024, 08:00 AM", amount: "₹28,800", paymentStatus: "Cancelled", paymentDate: "18 May 2024", status: "Cancelled", statusDesc: "Cancelled on 18 May 2024, 09:15 AM", statusTone: "bg-rose-100 text-rose-800", emoji: "🚛" },
  ];

  return (
    <OwnerLayout activeTab="bookings" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title matching Mockup 6 */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">My Bookings</h1>
            <p className="text-xs text-slate-500 mt-0.5">Track and manage all your truck bookings in one place.</p>
          </div>

          <button className="bg-white hover:bg-slate-50 text-slate-900 font-bold px-4 py-2 rounded-xl border border-slate-200 shadow-sm transition text-xs flex items-center gap-2">
            <Download size={14} /> Export Report
          </button>
        </div>

        {/* 5 Stat Cards matching Mockup 6 */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <CalendarCheck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Bookings</span>
            <span className="text-lg font-black text-slate-900 block">28</span>
            <span className="text-[10px] font-bold text-slate-500 block">All Time</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <CheckCircle2 size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Confirmed</span>
            <span className="text-lg font-black text-slate-900 block">14</span>
            <span className="text-[10px] font-bold text-emerald-600 block">Current &amp; Upcoming</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <Truck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">In Progress</span>
            <span className="text-lg font-black text-slate-900 block">6</span>
            <span className="text-[10px] font-bold text-amber-600 block">Currently Running</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <CheckCircle2 size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Completed</span>
            <span className="text-lg font-black text-slate-900 block">22</span>
            <span className="text-[10px] font-bold text-slate-500 block">All Completed</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center">
              <XCircle size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Cancelled</span>
            <span className="text-lg font-black text-slate-900 block">3</span>
            <span className="text-[10px] font-bold text-rose-600 block">All Cancelled</span>
          </div>
        </div>

        {/* Filter Bar matching Mockup 6 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-extrabold text-xs">
            <button onClick={() => setTab("all")} className={`px-4 py-2 rounded-xl transition ${tab === "all" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>All</button>
            <button onClick={() => setTab("upcoming")} className={`px-4 py-2 rounded-xl transition ${tab === "upcoming" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Upcoming</button>
            <button onClick={() => setTab("progress")} className={`px-4 py-2 rounded-xl transition ${tab === "progress" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>In Progress</button>
            <button onClick={() => setTab("completed")} className={`px-4 py-2 rounded-xl transition ${tab === "completed" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Completed</button>
            <button onClick={() => setTab("cancelled")} className={`px-4 py-2 rounded-xl transition ${tab === "cancelled" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Cancelled</button>
          </div>

          <div className="flex items-center gap-2">
            <div className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 flex items-center gap-2">
              <CalendarCheck size={14} className="text-amber-500" />
              <span>Select Date Range</span>
            </div>
            <button className="p-2 border border-slate-200 rounded-xl hover:bg-slate-50 text-slate-600 flex items-center gap-1 text-xs font-bold">
              <Filter size={14} /> Filters
            </button>
          </div>
        </div>

        {/* Bookings Table matching Mockup 6 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
          <div className="divide-y divide-slate-100">
            <div className="grid grid-cols-4 gap-4 text-[10px] font-black uppercase text-slate-400 pb-3 px-2">
              <span>Booking Details</span>
              <span>Route &amp; Date</span>
              <span>Payment</span>
              <span>Status &amp; Action</span>
            </div>

            {mockOwnerBookings.map((b) => (
              <div key={b.id} className="py-4 grid grid-cols-4 gap-4 items-center text-xs hover:bg-slate-50 px-2 rounded-xl transition">
                {/* Booking Details */}
                <div className="flex items-center gap-3">
                  <div className="w-14 h-14 rounded-2xl bg-amber-50 border border-amber-200 flex items-center justify-center text-2xl shrink-0">
                    {b.emoji}
                  </div>
                  <div>
                    <span className="text-[10px] font-black text-slate-400 block">Booking ID: {b.bookingId}</span>
                    <h4 className="font-black text-slate-900 text-xs">{b.truck}</h4>
                    <span className="text-[10px] text-slate-500 font-medium">{b.specs}</span>
                  </div>
                </div>

                {/* Route & Date */}
                <div className="space-y-1">
                  <div className="flex items-center gap-1.5 font-black text-slate-900 text-xs">
                    <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                    <span>{b.origin}</span>
                  </div>
                  <div className="flex items-center gap-1.5 font-black text-slate-900 text-xs">
                    <span className="w-2 h-2 rounded-full bg-rose-500"></span>
                    <span>{b.dest}</span>
                  </div>
                  <span className="text-[10px] text-slate-400 font-medium block pt-0.5">{b.date}</span>
                </div>

                {/* Payment */}
                <div>
                  <span className="font-black text-slate-900 text-sm block">{b.amount}</span>
                  <span className={`px-2 py-0.5 rounded text-[9px] font-extrabold inline-block mt-0.5 ${
                    b.paymentStatus === "Paid" ? "bg-emerald-100 text-emerald-800" : b.paymentStatus === "Pending" ? "bg-amber-100 text-amber-800" : "bg-rose-100 text-rose-800"
                  }`}>
                    {b.paymentStatus}
                  </span>
                  <span className="text-[9px] text-slate-400 font-medium block pt-0.5">{b.paymentDate}</span>
                </div>

                {/* Status & Action */}
                <div className="flex items-center justify-between gap-2">
                  <div>
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-extrabold inline-block ${b.statusTone}`}>
                      {b.status}
                    </span>
                    <span className="text-[10px] text-slate-500 font-medium block pt-1">{b.statusDesc}</span>
                  </div>

                  <div className="flex items-center gap-1">
                    <button className="bg-slate-50 hover:bg-slate-100 text-slate-900 font-bold text-xs px-3 py-1.5 rounded-xl border border-slate-200 transition whitespace-nowrap">
                      View Details
                    </button>
                    <button className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg">
                      <MoreVertical size={16} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
