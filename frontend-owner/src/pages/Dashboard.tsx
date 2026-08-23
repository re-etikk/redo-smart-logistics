import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import {
  Truck, CalendarCheck, IndianRupee, Star, ChevronRight, TrendingUp, ShieldCheck, Tag, CreditCard, Headset,
  ArrowRight, CheckCircle2, AlertCircle
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getTrucks } from "../lib/truckStore";
import { getWallet } from "../lib/walletStore";

export default function OwnerDashboard() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const trucks = getTrucks();
  const wallet = getWallet();

  const recentBookings = [
    {
      id: "B1",
      origin: "Delhi",
      dest: "Mumbai",
      date: "20 May, 2024 • 10:00 AM",
      amount: "₹25,000",
      status: "Confirmed",
      tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80",
      truck: "Eicher 17 Feet",
    },
    {
      id: "B2",
      origin: "Bengaluru",
      dest: "Hyderabad",
      date: "18 May, 2024 • 09:00 AM",
      amount: "₹18,500",
      status: "On the Way",
      tone: "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400",
      photoUrl: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80",
      truck: "BharatBenz 19 Feet",
    },
    {
      id: "B3",
      origin: "Ahmedabad",
      dest: "Indore",
      date: "16 May, 2024 • 11:30 AM",
      amount: "₹16,000",
      status: "Completed",
      tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1586191582150-a8d29837936a?auto=format&fit=crop&w=600&q=80",
      truck: "Tata 14 Feet",
    },
    {
      id: "B4",
      origin: "Chennai",
      dest: "Coimbatore",
      date: "15 May, 2024 • 02:00 PM",
      amount: "₹12,500",
      status: "Completed",
      tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1592838064575-70ed626d3a0e?auto=format&fit=crop&w=600&q=80",
      truck: "Mahindra Bolero",
    },
    {
      id: "B5",
      origin: "Pune",
      dest: "Nagpur",
      date: "14 May, 2024 • 08:45 AM",
      amount: "₹15,750",
      status: "Cancelled",
      tone: "bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-400",
      photoUrl: "https://images.unsplash.com/photo-1501700493788-fa1a4fc9fe62?auto=format&fit=crop&w=600&q=80",
      truck: "BharatBenz 32 Feet",
    },
  ];

  return (
    <OwnerLayout activeTab="dashboard" promoCardType="refer">
      <div className="space-y-6 text-slate-900 dark:text-white">
        {/* Main Hero Banner */}
        <div className="relative bg-gradient-to-r from-amber-50/90 via-white to-amber-100/60 dark:from-slate-900 dark:via-slate-900 dark:to-amber-950/40 border border-amber-200/80 dark:border-slate-800 rounded-3xl p-8 shadow-sm overflow-hidden flex flex-col lg:flex-row items-center justify-between gap-6">
          <div className="space-y-3 max-w-md">
            <h1 className="text-3xl sm:text-4xl font-black tracking-tight leading-tight">
              More Loads.<br />
              <span className="text-[#FFC800]">More Earnings.</span>
            </h1>
            <p className="text-xs text-slate-600 dark:text-slate-300 font-medium leading-relaxed">
              List your commercial truck, get matched with returning freight consignments, and eliminate empty kilometers.
            </p>

            <div className="pt-2 flex items-center gap-3">
              <button
                onClick={() => navigate("/trucks")}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-sm transition text-xs flex items-center gap-2 cursor-pointer"
              >
                + Add Truck
              </button>
              <button
                onClick={() => navigate("/bookings")}
                className="bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-900 dark:text-white font-black px-5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 shadow-sm transition text-xs cursor-pointer"
              >
                View Bookings
              </button>
            </div>
          </div>

          {/* Official REDO Container Truck on Highway Visual matching Mockup */}
          <div className="w-full max-w-sm lg:max-w-lg shrink-0">
            <img
              src="/assets/redo_hero_truck.png"
              alt="REDO Container Truck on Highway"
              className="w-full h-auto max-h-64 object-contain drop-shadow-xl rounded-2xl"
            />
          </div>
        </div>

        {/* 4 Stat Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Trucks</span>
              <span className="text-2xl font-black text-slate-900 dark:text-white block">{trucks.length}</span>
              <span className="text-[10px] font-bold text-emerald-600 block">Active &amp; Ready</span>
            </div>
            <div className="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <Truck size={20} />
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Bookings</span>
              <span className="text-2xl font-black text-slate-900 dark:text-white block">28</span>
              <span className="text-[10px] font-bold text-slate-500 block">This Month</span>
            </div>
            <div className="w-10 h-10 rounded-2xl bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <CalendarCheck size={20} />
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Earnings</span>
              <span className="text-2xl font-black text-slate-900 dark:text-white block">₹1,48,750</span>
              <span className="text-[10px] font-bold text-emerald-600 block">↑ 18.6% Growth</span>
            </div>
            <div className="w-10 h-10 rounded-2xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <IndianRupee size={20} />
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Average Rating</span>
              <div className="flex items-center gap-1">
                <span className="text-2xl font-black text-slate-900 dark:text-white">4.8</span>
                <Star size={16} className="text-amber-500 fill-amber-400" />
              </div>
              <span className="text-[10px] font-bold text-slate-500 block">From 124 Reviews</span>
            </div>
            <div className="w-10 h-10 rounded-2xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <Star size={20} />
            </div>
          </div>
        </div>

        {/* Recent Bookings List Card */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
            <h3 className="font-black text-xs uppercase tracking-wider text-slate-900 dark:text-white">
              Recent Bookings &amp; Active Consignments
            </h3>
            <Link to="/bookings" className="text-xs font-bold text-amber-600 dark:text-amber-400 hover:underline flex items-center gap-1">
              View All <ChevronRight size={14} />
            </Link>
          </div>

          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {recentBookings.map((b) => (
              <div key={b.id} className="py-3.5 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0">
                    <img src={b.photoUrl} alt={b.truck} className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <h4 className="font-black text-xs sm:text-sm text-slate-900 dark:text-white">
                      {b.origin} ➔ {b.dest}
                    </h4>
                    <p className="text-[11px] text-slate-500 font-medium">{b.truck} • {b.date}</p>
                  </div>
                </div>

                <div className="text-right space-y-1">
                  <span className="text-sm font-black text-slate-900 dark:text-white block">{b.amount}</span>
                  <span className={`inline-block text-[9px] font-black px-2 py-0.5 rounded-full ${b.tone}`}>
                    {b.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Priority Verification Banner */}
        <div className="bg-amber-50/80 dark:bg-slate-900 border border-amber-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#FFC800] text-slate-950 flex items-center justify-center font-black text-xl shrink-0">
              <ShieldCheck size={26} />
            </div>
            <div>
              <h3 className="text-base font-black text-slate-900 dark:text-white">Get Priority Backhaul Bookings</h3>
              <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5">
                Verify your commercial vehicle RC, Insurance, and Driving License to unlock high-value enterprise loads.
              </p>
            </div>
          </div>

          <button
            onClick={() => navigate("/documents")}
            className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition whitespace-nowrap cursor-pointer"
          >
            Verify Now
          </button>
        </div>

        {/* Bottom Trust & Feature Highlights */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-xs font-black text-slate-900 dark:text-white block">Zero Commission</span>
            <p className="text-[10px] text-slate-500">Keep 100% of your agreed freight rate</p>
          </div>
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-xs font-black text-slate-900 dark:text-white block">Verified Shippers</span>
            <p className="text-[10px] text-slate-500">100% GST &amp; Aadhaar verified enterprises</p>
          </div>
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-xs font-black text-slate-900 dark:text-white block">Instant IMPS Payouts</span>
            <p className="text-[10px] text-slate-500">Direct wallet withdrawal in &lt; 2 mins</p>
          </div>
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-xs font-black text-slate-900 dark:text-white block">24/7 Dispatch Desk</span>
            <p className="text-[10px] text-slate-500">Always available for highway assistance</p>
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
