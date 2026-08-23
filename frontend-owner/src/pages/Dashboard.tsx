import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import {
  Truck, CalendarCheck, IndianRupee, Star, ChevronRight, TrendingUp, ShieldCheck, Tag, CreditCard, Headset
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";

export default function OwnerDashboard() {
  const navigate = useNavigate();

  const recentBookings = [
    { id: "B1", origin: "Delhi", originPin: "110025", dest: "Mumbai", destPin: "400001", date: "20 May, 2024", time: "10:00 AM", amount: "₹25,000", status: "Confirmed", tone: "bg-emerald-100 text-emerald-800" },
    { id: "B2", origin: "Bengaluru", originPin: "560001", dest: "Hyderabad", destPin: "500001", date: "18 May, 2024", time: "09:00 AM", amount: "₹18,500", status: "On the Way", tone: "bg-blue-100 text-blue-800" },
    { id: "B3", origin: "Ahmedabad", originPin: "380001", dest: "Indore", destPin: "452001", date: "16 May, 2024", time: "11:30 AM", amount: "₹16,000", status: "Completed", tone: "bg-emerald-100 text-emerald-800" },
    { id: "B4", origin: "Chennai", originPin: "600001", dest: "Coimbatore", destPin: "641001", date: "15 May, 2024", time: "02:00 PM", amount: "₹12,500", status: "Completed", tone: "bg-emerald-100 text-emerald-800" },
    { id: "B5", origin: "Pune", originPin: "411001", dest: "Nagpur", destPin: "440001", date: "14 May, 2024", time: "08:45 AM", amount: "₹15,750", status: "Cancelled", tone: "bg-rose-100 text-rose-800" },
  ];

  return (
    <OwnerLayout activeTab="dashboard" promoCardType="refer">
      <div className="space-y-6">
        {/* Main Hero Banner matching Mockup 1 */}
        <div className="relative bg-gradient-to-r from-amber-50/90 via-white to-amber-100/60 border border-amber-200/80 rounded-3xl p-8 shadow-sm overflow-hidden flex flex-col lg:flex-row items-center justify-between gap-6">
          <div className="space-y-3 max-w-md">
            <h1 className="text-3xl sm:text-4xl font-black text-slate-950 tracking-tight leading-tight">
              More Loads.<br />
              <span className="text-[#FFC800]">More Earnings.</span>
            </h1>
            <p className="text-xs text-slate-600 font-medium leading-relaxed">
              List your truck, get more bookings and grow your business with Redo.
            </p>

            <div className="pt-2 flex items-center gap-3">
              <button
                onClick={() => navigate("/trucks")}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-sm transition text-xs flex items-center gap-2"
              >
                + Add Truck
              </button>
              <button
                onClick={() => navigate("/bookings")}
                className="bg-white hover:bg-slate-50 text-slate-900 font-black px-5 py-2.5 rounded-xl border border-slate-200 shadow-sm transition text-xs cursor-pointer"
              >
                View Bookings
              </button>
            </div>
          </div>

          {/* SVG White Container Truck with Redo Branding */}
          <div className="w-full max-w-xs lg:max-w-md shrink-0">
            <svg viewBox="0 0 500 240" className="w-full h-auto drop-shadow-xl">
              <rect x="40" y="40" width="280" height="140" rx="6" fill="#FFFFFF" stroke="#CBD5E1" strokeWidth="2" />
              {[70, 110, 150, 190, 230, 270].map((x) => (
                <line key={x} x1={x} y1="42" x2={x} y2="178" stroke="#E2E8F0" strokeWidth="1.5" />
              ))}
              <rect x="40" y="165" width="280" height="15" fill="#FFC800" />
              
              <g transform="translate(80, 75)">
                <path d="M0 30 L12 3 H22 C28 3 32 7 30 13 C28 18 23 20 18 20 L25 30 H18 L13 20 H10 L6 30 H0 Z" fill="#0F172A" />
                <path d="M9 8 L13 0 H18 L14 8 H9 Z" fill="#FFC800" />
                <text x="36" y="24" fill="#0F172A" fontSize="28" fontFamily="sans-serif" fontWeight="900">redo</text>
                <text x="36" y="34" fill="#64748B" fontSize="8" fontFamily="sans-serif" fontWeight="800">TRANSPORT &amp; LOGISTICS</text>
              </g>

              <path d="M320 70 L370 70 Q395 70 405 105 L415 140 Q420 160 420 180 H320 V70 Z" fill="#F8FAFC" stroke="#94A3B8" strokeWidth="2" />
              <path d="M360 80 L390 80 Q402 80 410 105 H360 V80 Z" fill="#1E293B" />
              <circle cx="414" cy="145" r="5" fill="#FEF08A" stroke="#EAB308" strokeWidth="1.5" />

              <circle cx="100" cy="195" r="22" fill="#0F172A" stroke="#334155" strokeWidth="3" />
              <circle cx="100" cy="195" r="10" fill="#94A3B8" />

              <circle cx="150" cy="195" r="22" fill="#0F172A" stroke="#334155" strokeWidth="3" />
              <circle cx="150" cy="195" r="10" fill="#94A3B8" />

              <circle cx="260" cy="195" r="22" fill="#0F172A" stroke="#334155" strokeWidth="3" />
              <circle cx="260" cy="195" r="10" fill="#94A3B8" />

              <circle cx="360" cy="195" r="22" fill="#0F172A" stroke="#334155" strokeWidth="3" />
              <circle cx="360" cy="195" r="10" fill="#94A3B8" />
            </svg>
          </div>
        </div>

        {/* 4 Stat Cards matching Mockup 1 */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Trucks</span>
              <span className="text-xl font-black text-slate-900 block">5</span>
              <span className="text-[10px] font-bold text-emerald-600 block">Active</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Truck size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Bookings</span>
              <span className="text-xl font-black text-slate-900 block">28</span>
              <span className="text-[10px] font-bold text-blue-600 block">This Month</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <CalendarCheck size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Earnings</span>
              <span className="text-xl font-black text-slate-900 block">₹1,48,750</span>
              <span className="text-[10px] font-bold text-purple-600 block">This Month</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <IndianRupee size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Average Rating</span>
              <div className="flex items-center gap-1">
                <span className="text-xl font-black text-slate-900">4.8</span>
                <Star size={14} className="text-amber-500 fill-amber-400" />
              </div>
              <span className="text-[10px] font-bold text-slate-500 block">From 124 Reviews</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <Star size={20} />
            </div>
          </div>
        </div>

        {/* Middle Section: Recent Bookings Table + Earnings Graph + Priority Card */}
        <div className="grid gap-6 lg:grid-cols-[1fr_360px]">
          {/* Recent Bookings Card */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-black text-slate-900 text-sm">Recent Bookings</h3>
              <Link to="/shipments" className="text-xs font-bold text-amber-600 hover:underline flex items-center gap-1">
                View All <ChevronRight size={14} />
              </Link>
            </div>

            <div className="divide-y divide-slate-100">
              {recentBookings.map((b) => (
                <div key={b.id} className="py-3.5 flex items-center justify-between text-xs hover:bg-slate-50 px-2 -mx-2 rounded-xl transition">
                  <div className="flex items-center gap-3">
                    <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                    <div>
                      <div className="flex items-center gap-2 font-black text-slate-900">
                        <span>{b.origin}</span>
                        <span className="text-slate-400 font-normal text-[10px]">({b.originPin})</span>
                        <span className="text-slate-400 font-normal">→</span>
                        <span>{b.dest}</span>
                        <span className="text-slate-400 font-normal text-[10px]">({b.destPin})</span>
                      </div>
                      <div className="text-[10px] text-slate-400 font-medium">
                        {b.date} · {b.time}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <span className="font-black text-slate-900 text-xs">{b.amount}</span>
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${b.tone}`}>
                      {b.status}
                    </span>
                    <ChevronRight size={14} className="text-slate-400" />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right Column: Earnings Overview & Get Priority Bookings */}
          <div className="space-y-6">
            {/* Earnings Summary Card matching Mockup 1 */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
              <div className="flex items-center justify-between">
                <h4 className="font-black text-xs text-slate-900">Earnings Summary</h4>
                <Link to="/earnings" className="text-[11px] font-bold text-amber-600 hover:underline">View Details</Link>
              </div>

              <div>
                <span className="text-[10px] text-slate-400 font-bold block">This Month</span>
                <span className="text-2xl font-black text-slate-900 block">₹1,48,750</span>
                <span className="text-[10px] font-bold text-emerald-600 flex items-center gap-1 mt-0.5">
                  <TrendingUp size={12} /> +18.6% from last month
                </span>
              </div>

              {/* Yellow Smooth Line Graph SVG */}
              <div className="h-16 w-full pt-2">
                <svg viewBox="0 0 300 60" className="w-full h-full">
                  <defs>
                    <linearGradient id="yellowGraphGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#FFC800" stopOpacity="0.4" />
                      <stop offset="100%" stopColor="#FFC800" stopOpacity="0.0" />
                    </linearGradient>
                  </defs>
                  <path d="M0 45 Q 50 35, 100 40 T 200 20 T 300 10 L 300 60 L 0 60 Z" fill="url(#yellowGraphGrad)" />
                  <path d="M0 45 Q 50 35, 100 40 T 200 20 T 300 10" fill="none" stroke="#FFC800" strokeWidth="3" />
                </svg>
              </div>
            </div>

            {/* Priority Bookings Card matching Mockup 1 */}
            <div className="bg-amber-50/80 border border-amber-200 rounded-2xl p-5 shadow-sm space-y-3 relative overflow-hidden">
              <div className="space-y-1">
                <h4 className="font-black text-xs text-slate-900">Get Priority Bookings</h4>
                <p className="text-[10px] text-slate-600 font-medium leading-relaxed">
                  Verify your documents and get priority access to high value loads.
                </p>
              </div>

              <button
                onClick={() => navigate("/verification")}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-4 py-2 rounded-xl shadow-sm transition"
              >
                Verify Now
              </button>

              <div className="absolute right-2 bottom-2 w-16 h-16 opacity-80 pointer-events-none text-4xl">
                🛡️🚛
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Trust Banner matching Mockup 1 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm grid grid-cols-2 md:grid-cols-4 gap-4 text-center text-xs text-slate-600 font-medium">
          <div className="flex items-center justify-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center font-bold">
              <IndianRupee size={16} />
            </div>
            <div className="text-left">
              <span className="font-black text-slate-900 block">Zero Commission</span>
              <span className="text-[10px] text-slate-500">Keep 100% of your earnings</span>
            </div>
          </div>

          <div className="flex items-center justify-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center font-bold">
              <ShieldCheck size={16} />
            </div>
            <div className="text-left">
              <span className="font-black text-slate-900 block">Verified Shippers</span>
              <span className="text-[10px] text-slate-500">100% verified &amp; trusted</span>
            </div>
          </div>

          <div className="flex items-center justify-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center font-bold">
              <CreditCard size={16} />
            </div>
            <div className="text-left">
              <span className="font-black text-slate-900 block">Fast Payments</span>
              <span className="text-[10px] text-slate-500">Get paid directly in bank</span>
            </div>
          </div>

          <div className="flex items-center justify-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center font-bold">
              <Headset size={16} />
            </div>
            <div className="text-left">
              <span className="font-black text-slate-900 block">24/7 Support</span>
              <span className="text-[10px] text-slate-500">We're here to help anytime</span>
            </div>
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
