import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  IndianRupee, CalendarCheck, TrendingUp, Download, ChevronRight, Wallet, CheckCircle, Clock, ArrowUpRight
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getWallet } from "../lib/walletStore";

export default function Earnings() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [dateRange, setDateRange] = useState("20 May 2024 - 20 Jun 2024");
  const wallet = getWallet();

  const transactions = [
    {
      id: "T1",
      date: "20 Jun 2024, 10:00 AM",
      bookingId: "RD124578",
      route: "Delhi → Mumbai",
      truck: "Eicher 17 Feet",
      regNo: "HR55 AB 1234",
      amount: "₹22,000",
      status: "Paid",
      tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "T2",
      date: "19 Jun 2024, 09:30 AM",
      bookingId: "RD124567",
      route: "Delhi → Mumbai",
      truck: "BharatBenz 19 Feet",
      regNo: "HR55 CD 5678",
      amount: "₹26,500",
      status: "Paid",
      tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "T3",
      date: "18 Jun 2024, 02:00 PM",
      bookingId: "RD124556",
      route: "Delhi → Indore",
      truck: "Tata 14 Feet",
      regNo: "HR55 EF 9012",
      amount: "₹16,200",
      status: "Pending",
      tone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400",
      photoUrl: "https://images.unsplash.com/photo-1586191582150-a8d29837936a?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "T4",
      date: "17 Jun 2024, 11:00 AM",
      bookingId: "RD124544",
      route: "Delhi → Lucknow",
      truck: "Mahindra Pickup",
      regNo: "HR55 GH 3456",
      amount: "₹12,500",
      status: "Paid",
      tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1592838064575-70ed626d3a0e?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "T5",
      date: "16 Jun 2024, 08:00 AM",
      bookingId: "RD124533",
      route: "Bengaluru → Chennai",
      truck: "BharatBenz 32 Feet",
      regNo: "HR55 IJ 7890",
      amount: "₹28,800",
      status: "Paid",
      tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      photoUrl: "https://images.unsplash.com/photo-1501700493788-fa1a4fc9fe62?auto=format&fit=crop&w=600&q=80",
    },
  ];

  return (
    <OwnerLayout activeTab="earnings" promoCardType="truck">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight">{t("earnings")} &amp; Revenue</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Track your trip freight settlements, wallet payouts and gross income.</p>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2 shadow-sm">
            <CalendarCheck size={14} className="text-amber-500" />
            <span>{dateRange}</span>
          </div>
        </div>

        {/* 5 Stat Cards */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <IndianRupee size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("totalEarnings")}</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">₹1,48,750</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 18.6% vs last month</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <CalendarCheck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Completed Trips</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">28</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 12.5% vs last month</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <TrendingUp size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Average Per Trip</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">₹5,312</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 8.3% vs last month</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Wallet size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Payouts</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">₹1,32,000</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 17.2% vs last month</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Clock size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Wallet Available</span>
            <span className="text-lg font-black text-slate-900 dark:text-white block">₹{wallet.balance.toLocaleString("en-IN")}</span>
            <span className="text-[10px] font-bold text-amber-600 block">Ready to Withdraw</span>
          </div>
        </div>

        {/* Charts & Payout Summary Grid */}
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Earnings Overview Line Chart */}
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4 lg:col-span-1">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-xs text-slate-900 dark:text-white">Earnings Overview</h3>
              <span className="text-[10px] font-bold text-slate-400 bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded">This Month</span>
            </div>

            <div>
              <span className="text-2xl font-black text-slate-900 dark:text-white">₹1,48,750</span>
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
                <path d="M 0 100 Q 80 80 160 85 T 320 40 T 400 30 L 400 120 L 0 120 Z" fill="url(#earningsGrad)" />
                <path d="M 0 100 Q 80 80 160 85 T 320 40 T 400 30" fill="none" stroke="#FFC800" strokeWidth="3" />
              </svg>
            </div>
          </div>

          {/* Earnings Breakdown Donut Chart */}
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4 lg:col-span-1">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-xs text-slate-900 dark:text-white">Earnings Breakdown</h3>
              <span className="text-[10px] font-bold text-slate-400">By Corridor</span>
            </div>

            <div className="flex items-center justify-center gap-6 pt-2">
              <div className="relative w-28 h-28 flex items-center justify-center">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="14" fill="none" stroke="#CBD5E1" strokeWidth="4" className="dark:stroke-slate-800" />
                  <circle cx="18" cy="18" r="14" fill="none" stroke="#FFC800" strokeWidth="4" strokeDasharray="35 100" strokeDashoffset="0" />
                  <circle cx="18" cy="18" r="14" fill="none" stroke="#6366F1" strokeWidth="4" strokeDasharray="30 100" strokeDashoffset="-35" />
                  <circle cx="18" cy="18" r="14" fill="none" stroke="#3B82F6" strokeWidth="4" strokeDasharray="25 100" strokeDashoffset="-65" />
                </svg>
                <div className="absolute text-center">
                  <span className="text-[8px] font-bold text-slate-400 block uppercase">Total</span>
                  <span className="text-xs font-black text-slate-900 dark:text-white">₹1.48L</span>
                </div>
              </div>

              <div className="space-y-2 text-[11px] font-bold">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-amber-400" />
                  <span className="text-slate-600 dark:text-slate-300">Delhi Corridor</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-indigo-500" />
                  <span className="text-slate-600 dark:text-slate-300">Mumbai Corridor</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-blue-500" />
                  <span className="text-slate-600 dark:text-slate-300">Bengaluru Hub</span>
                </div>
              </div>
            </div>
          </div>

          {/* Payout Summary */}
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4 lg:col-span-1 flex flex-col justify-between">
            <div className="space-y-4">
              <h3 className="font-black text-xs text-slate-900 dark:text-white">Payout Summary</h3>

              <div className="space-y-3">
                <div className="flex items-center justify-between pb-2 border-b border-slate-100 dark:border-slate-800">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 block">Total Payouts</span>
                    <span className="text-base font-black text-slate-900 dark:text-white">₹1,32,000</span>
                  </div>
                  <span className="text-[10px] font-black text-emerald-800 bg-emerald-100 dark:bg-emerald-950/60 dark:text-emerald-400 px-2 py-0.5 rounded-full">
                    Paid
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 block">Available in Wallet</span>
                    <span className="text-base font-black text-slate-900 dark:text-white">₹{wallet.balance.toLocaleString("en-IN")}</span>
                  </div>
                  <span className="text-[10px] font-black text-amber-800 bg-amber-100 dark:bg-amber-950/60 dark:text-amber-400 px-2 py-0.5 rounded-full">
                    Available
                  </span>
                </div>
              </div>
            </div>

            <button
              onClick={() => navigate("/payments")}
              className="w-full bg-amber-50 dark:bg-slate-800 hover:bg-amber-100 dark:hover:bg-slate-700 text-amber-900 dark:text-amber-300 font-black py-2.5 rounded-xl text-xs transition flex items-center justify-center gap-1.5 cursor-pointer mt-2"
            >
              <span>{t("withdrawMoney")}</span>
              <ArrowUpRight size={14} />
            </button>
          </div>
        </div>

        {/* Earnings Transactions Table */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-black text-xs text-slate-900 dark:text-white uppercase tracking-wider">
              Freight Settlement Ledger
            </h3>
            <button
              onClick={() => alert("Downloading statements...")}
              className="text-xs font-bold text-slate-600 dark:text-slate-300 hover:text-amber-600 flex items-center gap-1 cursor-pointer"
            >
              <Download size={14} /> Download Statement
            </button>
          </div>

          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {transactions.map((tx) => (
              <div key={tx.id} className="py-4 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-14 h-14 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0 shadow-sm">
                    <img src={tx.photoUrl} alt={tx.truck} className="w-full h-full object-cover" />
                  </div>

                  <div className="space-y-0.5">
                    <h4 className="font-black text-xs sm:text-sm text-slate-900 dark:text-white">{tx.route}</h4>
                    <p className="text-[11px] text-slate-500 font-medium">
                      {tx.truck} ({tx.regNo}) • {tx.date}
                    </p>
                  </div>
                </div>

                <div className="text-right space-y-1">
                  <span className="text-sm font-black text-slate-900 dark:text-white block">{tx.amount}</span>
                  <span className={`inline-block text-[9px] font-black px-2 py-0.5 rounded-full ${tx.tone}`}>
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
