import { useState } from "react";
import {
  MapPin, Truck, CheckCircle2, Clock, XCircle, Navigation, ChevronRight, Filter
} from "lucide-react";
import OwnerLayout from "../../components/OwnerLayout";

export default function Trips() {
  const [activeTab, setActiveTab] = useState("all");

  const trips = [
    {
      id: "TRIP1",
      truck: "Eicher 17 Feet",
      regNo: "HR55 AB 1234",
      date: "20 May 2024, 10:00 AM",
      origin: "Delhi, Delhi",
      dest: "Mumbai, Maharashtra",
      distance: "1,450 km · 2 Days",
      driver: "Sandeep Kumar",
      status: "On the Way",
      statusTone: "bg-blue-100 text-blue-800",
      earningLabel: "Trip Earning",
      amount: "₹22,000",
      paymentStatus: "Paid",
      emoji: "🚛",
    },
    {
      id: "TRIP2",
      truck: "BharatBenz 19 Feet",
      regNo: "HR55 CD 5678",
      date: "19 May 2024, 09:30 AM",
      origin: "Delhi, Delhi",
      dest: "Mumbai, Maharashtra",
      distance: "1,450 km · 2 Days",
      driver: "Ramesh Yadav",
      status: "Completed",
      statusTone: "bg-emerald-100 text-emerald-800",
      earningLabel: "Trip Earning",
      amount: "₹26,500",
      paymentStatus: "Paid",
      emoji: "🚚",
    },
    {
      id: "TRIP3",
      truck: "Tata 14 Feet",
      regNo: "HR55 EF 9012",
      date: "18 May 2024, 02:00 PM",
      origin: "Delhi, Delhi",
      dest: "Indore, Madhya Pradesh",
      distance: "660 km · 1 Day",
      driver: "Not Assigned",
      status: "Upcoming",
      statusTone: "bg-amber-100 text-amber-800",
      earningLabel: "Expected Earning",
      amount: "₹16,200",
      paymentStatus: "Pending",
      emoji: "🚛",
    },
    {
      id: "TRIP4",
      truck: "Mahindra Pickup",
      regNo: "HR55 GH 3456",
      date: "17 May 2024, 11:00 AM",
      origin: "Delhi, Delhi",
      dest: "Lucknow, Uttar Pradesh",
      distance: "720 km · 1 Day",
      driver: "Amit Verma",
      status: "Completed",
      statusTone: "bg-emerald-100 text-emerald-800",
      earningLabel: "Trip Earning",
      amount: "₹12,500",
      paymentStatus: "Paid",
      emoji: "🛻",
    },
    {
      id: "TRIP5",
      truck: "BharatBenz 32 Feet",
      regNo: "HR55 IJ 7890",
      date: "16 May 2024, 08:00 AM",
      origin: "Bengaluru, Karnataka",
      dest: "Chennai, Tamil Nadu",
      distance: "350 km · 1 Day",
      driver: "Manoj Singh",
      status: "Cancelled",
      statusTone: "bg-rose-100 text-rose-800",
      earningLabel: "Trip Earning",
      amount: "₹28,800",
      paymentStatus: "Cancelled",
      emoji: "🚛",
    },
  ];

  const filteredTrips = trips.filter((t) => {
    if (activeTab === "ongoing") return t.status === "On the Way" || t.status === "Upcoming";
    if (activeTab === "completed") return t.status === "Completed";
    if (activeTab === "cancelled") return t.status === "Cancelled";
    return true;
  });

  return (
    <OwnerLayout activeTab="trips" promoCardType="truck">
      <div className="space-y-6">
        {/* Header Title matching Mockup 4 */}
        <div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">Trips</h1>
          <p className="text-xs text-slate-500 mt-0.5">Monitor and manage all your ongoing and completed trips.</p>
        </div>

        {/* 5 Stat Cards matching Mockup 4 */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <MapPin size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Trips</span>
            <span className="text-lg font-black text-slate-900 block">36</span>
            <span className="text-[10px] font-bold text-slate-500 block">All Time</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <Truck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Ongoing Trips</span>
            <span className="text-lg font-black text-slate-900 block">6</span>
            <span className="text-[10px] font-bold text-blue-600 block">On the Road</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <CheckCircle2 size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Completed Trips</span>
            <span className="text-lg font-black text-slate-900 block">28</span>
            <span className="text-[10px] font-bold text-emerald-600 block">All Completed</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <XCircle size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Cancelled Trips</span>
            <span className="text-lg font-black text-slate-900 block">2</span>
            <span className="text-[10px] font-bold text-rose-600 block">All Cancelled</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Navigation size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Distance</span>
            <span className="text-lg font-black text-slate-900 block">18,560 km</span>
            <span className="text-[10px] font-bold text-slate-500 block">All Time</span>
          </div>
        </div>

        {/* Tabs & Filter Bar matching Mockup 4 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-extrabold text-xs">
            <button
              onClick={() => setActiveTab("all")}
              className={`px-4 py-2 rounded-xl transition ${
                activeTab === "all" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              All Trips
            </button>
            <button
              onClick={() => setActiveTab("ongoing")}
              className={`px-4 py-2 rounded-xl transition ${
                activeTab === "ongoing" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              Ongoing
            </button>
            <button
              onClick={() => setActiveTab("completed")}
              className={`px-4 py-2 rounded-xl transition ${
                activeTab === "completed" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              Completed
            </button>
            <button
              onClick={() => setActiveTab("cancelled")}
              className={`px-4 py-2 rounded-xl transition ${
                activeTab === "cancelled" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              Cancelled
            </button>
          </div>

          <div className="flex items-center gap-2">
            <select className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-900 focus:outline-none">
              <option>All Trucks</option>
            </select>
            <select className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-900 focus:outline-none">
              <option>All Status</option>
            </select>
            <button className="p-2 border border-slate-200 rounded-xl hover:bg-slate-50 text-slate-600">
              <Filter size={14} />
            </button>
          </div>
        </div>

        {/* Trips Cards List matching Mockup 4 */}
        <div className="space-y-3">
          {filteredTrips.map((t) => (
            <div
              key={t.id}
              className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm hover:shadow-md transition flex flex-col lg:flex-row items-start lg:items-center justify-between gap-4"
            >
              {/* Left Truck Photo & Info */}
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-2xl bg-amber-50 border border-amber-200 flex items-center justify-center text-3xl shrink-0">
                  {t.emoji}
                </div>
                <div className="space-y-1">
                  <h3 className="font-black text-slate-900 text-sm">{t.truck}</h3>
                  <div className="text-xs font-bold text-slate-500">{t.regNo}</div>
                  <div className="text-[10px] text-slate-400 font-medium">{t.date}</div>
                </div>
              </div>

              {/* Middle Route & Distance */}
              <div className="space-y-1 text-xs border-t lg:border-t-0 lg:border-l border-slate-100 pt-3 lg:pt-0 lg:pl-6">
                <div className="flex items-center gap-2 font-black text-slate-900">
                  <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                  <span>{t.origin}</span>
                </div>
                <div className="flex items-center gap-2 font-black text-slate-900 pl-0.5">
                  <span className="w-2 h-2 rounded-full bg-amber-500"></span>
                  <span>{t.dest}</span>
                </div>
                <div className="text-[10px] text-slate-400 font-medium pt-0.5">
                  Distance: {t.distance}
                </div>
              </div>

              {/* Driver & Status */}
              <div className="text-xs space-y-1 border-t lg:border-t-0 lg:border-l border-slate-100 pt-3 lg:pt-0 lg:pl-6">
                <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold ${t.statusTone}`}>
                  {t.status}
                </span>
                <div className="text-[10px] text-slate-500 font-semibold pt-1">
                  Driver: <span className="font-black text-slate-900">{t.driver}</span>
                </div>
              </div>

              {/* Right Earning & Action */}
              <div className="flex items-center justify-between lg:justify-end gap-6 w-full lg:w-auto border-t lg:border-t-0 border-slate-100 pt-3 lg:pt-0">
                <div className="text-right">
                  <span className="text-[10px] font-bold text-slate-400 block uppercase">{t.earningLabel}</span>
                  <span className="text-sm font-black text-slate-900 block">{t.amount}</span>
                  <span className="text-[10px] text-emerald-600 font-bold block">{t.paymentStatus}</span>
                </div>

                <button className="bg-slate-50 hover:bg-slate-100 text-slate-900 font-bold text-xs px-4 py-2 rounded-xl border border-slate-200 shadow-sm transition flex items-center gap-1">
                  View Details <ChevronRight size={14} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </OwnerLayout>
  );
}
