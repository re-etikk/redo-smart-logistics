import { useState } from "react";
import {
  IndianRupee, CalendarCheck, TrendingUp, Download, ChevronRight, Wallet, CheckCircle, Clock
} from "lucide-react";
import OwnerLayout from "../../components/OwnerLayout";

export default function Earnings() {
  const [dateRange, setDateRange] = useState("20 May 2024 - 20 Jun 2024");

  const transactions = [
    { id: "T1", date: "20 Jun 2024, 10:00 AM", bookingId: "RD124578", route: "Delhi → Mumbai", truck: "Eicher 17 Feet", regNo: "HR55 AB 1234", amount: "₹22,000", status: "Paid", tone: "bg-emerald-100 text-emerald-800" },
    { id: "T2", date: "19 Jun 2024, 09:30 AM", bookingId: "RD124567", route: "Delhi → Mumbai", truck: "BharatBenz 19 Feet", regNo: "HR55 CD 5678", amount: "₹26,500", status: "Paid", tone: "bg-emerald-100 text-emerald-800" },
    { id: "T3", date: "18 Jun 2024, 02:00 PM", bookingId: "RD124556", route: "Delhi → Indore", truck: "Tata 14 Feet", regNo: "HR55 EF 9012", amount: "₹16,200", status: "Pending", tone: "bg-amber-100 text-amber-800" },
    { id: "T4", date: "17 Jun 2024, 11:00 AM", bookingId: "RD124544", route: "Delhi → Lucknow", truck: "Mahindra Pickup", regNo: "HR55 GH 3456", amount: "₹12,500", status: "Paid", tone: "bg-emerald-100 text-emerald-800" },
    { id: "T5", date: "16 Jun 2024, 08:00 AM", bookingId: "RD124533", route: "Bengaluru → Chennai", truck: "BharatBenz 32 Feet", regNo: "HR55 IJ 7890", amount: "₹28,800", status: "Paid", tone: "bg-emerald-100 text-emerald-800" },
  ];

  return (
    <OwnerLayout activeTab="earnings" promoCardType="truck">
      <div className="space-y-6">
        {/* Header Title matching Mockup 3 */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">Earnings</h1>
            <p className="text-xs text-slate-500 mt-0.5">Track your earnings, payouts and performance.</p>
          </div>

          <div className="bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-700 flex items-center gap-2 shadow-sm">
            <CalendarCheck size={14} className="text-amber-500" />
            <span>{dateRange}</span>
          </div>
        </div>

        {/* 5 Stat Cards matching Mockup 3 */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <IndianRupee size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Earnings</span>
            <span className="text-lg font-black text-slate-900 block">₹1,48,750</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 18.6% vs last month</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <CalendarCheck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Completed Trips</span>
            <span className="text-lg font-black text-slate-900 block">28</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 12.5% vs last month</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <TrendingUp size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Average Per Trip</span>
            <span className="text-lg font-black text-slate-900 block">₹5,312</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 8.3% vs last month</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <Wallet size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Payouts</span>
            <span className="text-lg font-black text-slate-900 block">₹1,32,000</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 17.2% vs last month</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <Clock size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Pending Amount</span>
            <span className="text-lg font-black text-slate-900 block">₹16,750</span>
            <span className="text-[10px] font-bold text-amber-600 block">2 Trips</span>
          </div>
        </div>

        {/* Charts & Payout Summary Grid matching Mockup 3 */}
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Earnings Overview Line Chart */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-4 lg:col-span-1">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-xs text-slate-900">Earnings Overview</h3>
              <span className="text-[10px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded">This Month</span>
            </div>

            <div>
              <span className="text-2xl font-black text-slate-900">₹1,48,750</span>
              <span className="text-[10px] font-bold text-emerald-600 ml-2">↑ 18.6% vs last month</span>
            </div>

            {/* Line Chart SVG */}
            <div className="h-32 w-full pt-2">
              <svg viewBox="0 0 400 120" className="w-full h-full">
                <defs>
                  <linearGradient id="earningsGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#FFC800" stopOpacity="0.4" />
                    <stop offset="100%" stopColor="#FFC800" stopOpacity="0.0" />
                  </linearGradient>
                </defs>
                <path d="M0 90 Q 60 70, 120 75 T 240 50 T 400 20 L 400 120 L 0 120 Z" fill="url(#earningsGrad)" />
                <path d="M0 90 Q 60 70, 120 75 T 240 50 T 400 20" fill="none" stroke="#FFC800" strokeWidth="3" />
              </svg>
            </div>
          </div>

          {/* Earnings Breakdown Pie Donut Chart */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-4 lg:col-span-1">
            <h3 className="font-black text-xs text-slate-900">Earnings Breakdown</h3>

            <div className="flex items-center justify-between gap-4">
              {/* Donut Chart SVG */}
              <div className="relative w-28 h-28 shrink-0">
                <svg viewBox="0 0 100 100" className="w-full h-full">
                  <circle cx="50" cy="50" r="38" fill="none" stroke="#FFC800" strokeWidth="16" strokeDasharray="70 100" />
                  <circle cx="50" cy="50" r="38" fill="none" stroke="#8B5CF6" strokeWidth="16" strokeDasharray="50 100" strokeDashoffset="-70" />
                  <circle cx="50" cy="50" r="38" fill="none" stroke="#3B82F6" strokeWidth="16" strokeDasharray="30 100" strokeDashoffset="-120" />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                  <span className="text-[9px] font-bold text-slate-400 uppercase">Total</span>
                  <span className="text-xs font-black text-slate-900">₹1.48L</span>
                </div>
              </div>

              {/* Legends */}
              <div className="space-y-2 text-xs font-bold flex-1">
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-slate-700">
                    <span className="w-2.5 h-2.5 rounded-full bg-amber-400"></span> Delhi
                  </span>
                  <span>₹45,600 <span className="text-slate-400 text-[10px]">30.7%</span></span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-slate-700">
                    <span className="w-2.5 h-2.5 rounded-full bg-purple-500"></span> Mumbai
                  </span>
                  <span>₹52,300 <span className="text-slate-400 text-[10px]">35.2%</span></span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-slate-700">
                    <span className="w-2.5 h-2.5 rounded-full bg-blue-500"></span> Bengaluru
                  </span>
                  <span>₹28,450 <span className="text-slate-400 text-[10px]">19.1%</span></span>
                </div>
              </div>
            </div>
          </div>

          {/* Payout Summary Box matching Mockup 3 */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-4 lg:col-span-1 flex flex-col justify-between">
            <h3 className="font-black text-xs text-slate-900">Payout Summary</h3>

            <div className="space-y-3 text-xs">
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <div>
                  <span className="text-slate-400 text-[10px] font-bold block">Total Payouts</span>
                  <span className="text-lg font-black text-slate-900">₹1,32,000</span>
                </div>
                <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-100 text-emerald-800">Paid</span>
              </div>

              <div className="flex items-center justify-between pt-1">
                <div>
                  <span className="text-slate-400 text-[10px] font-bold block">Next Payout</span>
                  <span className="text-base font-black text-slate-900">₹16,750</span>
                  <span className="text-[10px] text-slate-400 block font-medium">Expected on 25 Jun 2024</span>
                </div>
                <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-100 text-amber-800">Pending</span>
              </div>
            </div>

            <button className="w-full bg-amber-50 hover:bg-amber-100 text-amber-900 font-extrabold text-xs py-2.5 rounded-xl border border-amber-200 transition">
              View Payout History
            </button>
          </div>
        </div>

        {/* Transactions Table matching Mockup 3 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <h3 className="font-black text-slate-900 text-sm">Earnings Transactions</h3>
            <button className="text-xs font-bold text-slate-700 bg-slate-50 border border-slate-200 px-3 py-1.5 rounded-xl hover:bg-slate-100 flex items-center gap-1.5">
              <Download size={14} /> Download Statement
            </button>
          </div>

          <div className="divide-y divide-slate-100">
            {transactions.map((tx) => (
              <div key={tx.id} className="py-3.5 flex items-center justify-between text-xs hover:bg-slate-50 px-2 -mx-2 rounded-xl transition">
                <div className="flex items-center gap-4">
                  <div className="w-8 h-8 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center font-bold">
                    🚚
                  </div>
                  <div>
                    <div className="font-black text-slate-900">{tx.route}</div>
                    <div className="text-[10px] text-slate-500 font-medium">
                      {tx.truck} ({tx.regNo}) · {tx.date}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-6">
                  <div className="text-right">
                    <span className="font-black text-slate-900 text-xs block">{tx.amount}</span>
                    <span className="text-[10px] text-slate-400 font-bold">{tx.bookingId}</span>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${tx.tone}`}>
                    {tx.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
