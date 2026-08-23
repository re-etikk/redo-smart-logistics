import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
  CalendarCheck, IndianRupee, TrendingUp, Wallet, ArrowUpRight,
  Download, Clock, CheckCircle2, ChevronRight, Check, X, Filter
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getWallet } from "../lib/walletStore";

interface TransactionItem {
  id: string;
  date: string;
  timestamp: number;
  bookingId: string;
  route: string;
  truck: string;
  regNo: string;
  amountNum: number;
  amount: string;
  status: string;
  tone: string;
  photoUrl: string;
}

const ALL_TRANSACTIONS: TransactionItem[] = [
  {
    id: "T1",
    date: "23 Aug 2026, 04:30 PM",
    timestamp: new Date("2026-08-23T16:30:00").getTime(),
    bookingId: "RD124578",
    route: "Delhi → Mumbai",
    truck: "REDO Express Container (19 Feet)",
    regNo: "REDO 2024",
    amountNum: 24500,
    amount: "₹24,500",
    status: "Escrow Secured",
    tone: "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400",
    photoUrl: "/assets/redo_truck.jpg",
  },
  {
    id: "T2",
    date: "22 Aug 2026, 08:30 PM",
    timestamp: new Date("2026-08-22T20:30:00").getTime(),
    bookingId: "RD124567",
    route: "Delhi → Indore",
    truck: "REDO Express Container (19 Feet)",
    regNo: "REDO 2024",
    amountNum: 16800,
    amount: "₹16,800",
    status: "Paid",
    tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
  },
  {
    id: "T3",
    date: "20 Aug 2026, 02:00 PM",
    timestamp: new Date("2026-08-20T14:00:00").getTime(),
    bookingId: "RD124556",
    route: "Bengaluru → Chennai",
    truck: "Tata 1412 LPT",
    regNo: "KA01 EF 9012",
    amountNum: 14500,
    amount: "₹14,500",
    status: "Paid",
    tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
  },
  {
    id: "T4",
    date: "17 Aug 2026, 11:00 AM",
    timestamp: new Date("2026-08-17T11:00:00").getTime(),
    bookingId: "RD124544",
    route: "Delhi → Lucknow",
    truck: "Mahindra Pickup",
    regNo: "HR55 GH 3456",
    amountNum: 12500,
    amount: "₹12,500",
    status: "Paid",
    tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
  },
  {
    id: "T5",
    date: "15 Aug 2026, 08:00 AM",
    timestamp: new Date("2026-08-15T08:00:00").getTime(),
    bookingId: "RD124533",
    route: "Jaipur → Ahmedabad",
    truck: "REDO Express Container",
    regNo: "REDO 2024",
    amountNum: 15200,
    amount: "₹15,200",
    status: "Paid",
    tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
  },
  {
    id: "T6",
    date: "28 Jul 2026, 03:00 PM",
    timestamp: new Date("2026-07-28T15:00:00").getTime(),
    bookingId: "RD124490",
    route: "Mumbai → Pune",
    truck: "REDO Express Container",
    regNo: "REDO 2024",
    amountNum: 9500,
    amount: "₹9,500",
    status: "Paid",
    tone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
    photoUrl: "/assets/redo_truck.jpg",
  },
];

export default function Earnings() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const wallet = getWallet();

  const [dateRangePreset, setDateRangePreset] = useState("this_month");
  const [showDateDropdown, setShowDateDropdown] = useState(false);
  const [customStartDate, setCustomStartDate] = useState("");
  const [customEndDate, setCustomEndDate] = useState("");

  const filteredTransactions = useMemo(() => {
    return ALL_TRANSACTIONS.filter((t) => {
      if (dateRangePreset === "today") {
        return t.date.includes("23 Aug 2026");
      }
      if (dateRangePreset === "this_week") {
        const oneWeekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
        return t.timestamp >= oneWeekAgo;
      }
      if (dateRangePreset === "this_month") {
        return t.date.includes("Aug 2026");
      }
      if (dateRangePreset === "last_month") {
        return t.date.includes("Jul 2026");
      }
      if (dateRangePreset === "custom" && customStartDate) {
        const start = new Date(customStartDate).getTime();
        const end = customEndDate ? new Date(customEndDate).getTime() + 86400000 : Infinity;
        return t.timestamp >= start && t.timestamp <= end;
      }
      return true;
    });
  }, [dateRangePreset, customStartDate, customEndDate]);

  const totalEarningsNum = useMemo(() => {
    return filteredTransactions.reduce((acc, curr) => acc + curr.amountNum, 0);
  }, [filteredTransactions]);

  const exportEarningsCSV = () => {
    const headers = ["Transaction ID,Date,Booking ID,Route,Vehicle,Reg No,Amount (INR),Status"];
    const rows = filteredTransactions.map(t =>
      `"${t.id}","${t.date}","${t.bookingId}","${t.route}","${t.truck}","${t.regNo}",${t.amountNum},"${t.status}"`
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `REDO_Earnings_Statement_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <OwnerLayout activeTab="earnings" promoCardType="truck">
      <div className="space-y-6 text-slate-900 dark:text-white">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight">{t("earnings")} &amp; Revenue</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Track your trip freight settlements, wallet payouts and gross income.</p>
          </div>

          <div className="flex items-center gap-3">
            {/* Interactive Date Range Dropdown */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setShowDateDropdown(!showDateDropdown)}
                className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2 shadow-sm hover:border-amber-400 transition cursor-pointer"
              >
                <CalendarCheck size={14} className="text-amber-500" />
                <span>
                  {dateRangePreset === "today" && "Today (23 Aug 2026)"}
                  {dateRangePreset === "this_week" && "Last 7 Days"}
                  {dateRangePreset === "this_month" && "This Month (Aug 2026)"}
                  {dateRangePreset === "last_month" && "Last Month (Jul 2026)"}
                  {dateRangePreset === "all" && "All Time"}
                  {dateRangePreset === "custom" && "Custom Range"}
                </span>
              </button>

              {showDateDropdown && (
                <div className="absolute right-0 mt-2 w-56 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl z-30 p-2 space-y-1 text-xs font-bold">
                  {[
                    { id: "this_month", label: "This Month (Aug 2026)" },
                    { id: "today", label: "Today (23 Aug 2026)" },
                    { id: "this_week", label: "Last 7 Days" },
                    { id: "last_month", label: "Last Month (Jul 2026)" },
                    { id: "all", label: "All Time" },
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

            <button
              onClick={exportEarningsCSV}
              className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-900 dark:text-white font-bold px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <Download size={14} /> Export CSV
            </button>
          </div>
        </div>

        {/* 5 Stat Cards */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <IndianRupee size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">{t("totalEarnings")}</span>
            <span className="text-lg font-black block">₹{totalEarningsNum.toLocaleString("en-IN")}</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 18.6% vs previous</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <CalendarCheck size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Settled Trips</span>
            <span className="text-lg font-black block">{filteredTransactions.length}</span>
            <span className="text-[10px] font-bold text-emerald-600 block">100% Guaranteed</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <TrendingUp size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Average Per Trip</span>
            <span className="text-lg font-black block">
              ₹{filteredTransactions.length > 0 ? Math.round(totalEarningsNum / filteredTransactions.length).toLocaleString("en-IN") : "0"}
            </span>
            <span className="text-[10px] font-bold text-emerald-600 block">Optimal Backhaul Rate</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Wallet size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Payouts</span>
            <span className="text-lg font-black block">₹{totalEarningsNum.toLocaleString("en-IN")}</span>
            <span className="text-[10px] font-bold text-emerald-600 block">Bank Transferred</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Clock size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Wallet Available</span>
            <span className="text-lg font-black block">₹{wallet.balance.toLocaleString("en-IN")}</span>
            <span className="text-[10px] font-bold text-amber-600 block">Ready to Withdraw</span>
          </div>
        </div>

        {/* Transactions Table */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-black text-sm text-slate-900 dark:text-white">Settlement Transactions ({filteredTransactions.length})</h3>
            <span className="text-xs text-slate-400 font-bold">Auto Bank Transfer every 24h</span>
          </div>

          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {filteredTransactions.map((tx) => (
              <div key={tx.id} className="py-3.5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0">
                    <img src={tx.photoUrl} alt={tx.truck} className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-black text-xs text-slate-900 dark:text-white">{tx.route}</span>
                      <span className="text-[10px] font-mono text-amber-500 font-bold">({tx.bookingId})</span>
                    </div>
                    <p className="text-[11px] text-slate-400 font-medium">
                      {tx.truck} • <strong className="text-slate-600 dark:text-slate-300">{tx.regNo}</strong> • {tx.date}
                    </p>
                  </div>
                </div>

                <div className="flex items-center justify-between sm:justify-end gap-3 w-full sm:w-auto">
                  <span className="font-black text-sm text-slate-900 dark:text-white">{tx.amount}</span>
                  <span className={`text-[10px] font-black px-2.5 py-0.5 rounded-full ${tx.tone}`}>
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
