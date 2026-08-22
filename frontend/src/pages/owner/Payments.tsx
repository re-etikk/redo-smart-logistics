import { useState } from "react";
import {
  CreditCard, IndianRupee, Wallet, CalendarCheck, Clock, Download, ArrowDownLeft, ArrowUpRight, Landmark, Settings, Filter
} from "lucide-react";
import OwnerLayout from "../../components/OwnerLayout";

export default function Payments() {
  const [activeTab, setActiveTab] = useState("all");
  const [showAddBankModal, setShowAddBankModal] = useState(false);

  const transactions = [
    { id: "P1", date: "19 Jun 2024, 09:30 AM", txId: "TXN1234567890", type: "Payout", icon: ArrowDownLeft, iconColor: "text-emerald-600 bg-emerald-100", trip: "TRIP124567", truck: "BharatBenz 19 Feet", amount: "₹26,500", status: "Paid", statusTone: "bg-emerald-100 text-emerald-800", datePaid: "19 Jun 2024", mode: "Bank Transfer" },
    { id: "P2", date: "18 Jun 2024, 02:00 PM", txId: "TXN1234567889", type: "Payout", icon: ArrowDownLeft, iconColor: "text-emerald-600 bg-emerald-100", trip: "TRIP124556", truck: "Tata 14 Feet", amount: "₹16,200", status: "Pending", statusTone: "bg-amber-100 text-amber-800", datePaid: "Expected on 20 Jun 2024", mode: "Bank Transfer" },
    { id: "P3", date: "17 Jun 2024, 11:00 AM", txId: "TXN1234567888", type: "Payout", icon: ArrowDownLeft, iconColor: "text-emerald-600 bg-emerald-100", trip: "TRIP124544", truck: "Mahindra Pickup", amount: "₹12,500", status: "Paid", statusTone: "bg-emerald-100 text-emerald-800", datePaid: "17 Jun 2024", mode: "UPI" },
    { id: "P4", date: "16 Jun 2024, 08:00 AM", txId: "TXN1234567887", type: "Payout", icon: ArrowDownLeft, iconColor: "text-emerald-600 bg-emerald-100", trip: "TRIP124533", truck: "BharatBenz 32 Feet", amount: "₹28,800", status: "Paid", statusTone: "bg-emerald-100 text-emerald-800", datePaid: "16 Jun 2024", mode: "Bank Transfer" },
    { id: "P5", date: "15 Jun 2024, 10:30 AM", txId: "TXN1234567886", type: "Deduction", icon: ArrowUpRight, iconColor: "text-rose-600 bg-rose-100", trip: "Platform Charges", truck: "TRIP124533", amount: "-₹2,880", status: "Paid", statusTone: "bg-emerald-100 text-emerald-800", datePaid: "15 Jun 2024", mode: "—" },
    { id: "P6", date: "14 Jun 2024, 01:15 PM", txId: "TXN1234567885", type: "Payout", icon: ArrowDownLeft, iconColor: "text-emerald-600 bg-emerald-100", trip: "TRIP124520", truck: "Eicher 17 Feet", amount: "₹22,000", status: "Paid", statusTone: "bg-emerald-100 text-emerald-800", datePaid: "14 Jun 2024", mode: "Bank Transfer" },
  ];

  return (
    <OwnerLayout activeTab="payments" promoCardType="bank" onAddBankClick={() => setShowAddBankModal(true)}>
      <div className="space-y-6">
        {/* Header Title & Payment Settings Button matching Mockup 5 */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">Payments</h1>
            <p className="text-xs text-slate-500 mt-0.5">Track all your payments, payouts and transaction history.</p>
          </div>

          <button
            onClick={() => setShowAddBankModal(true)}
            className="bg-white hover:bg-slate-50 text-slate-900 font-bold px-4 py-2 rounded-xl border border-slate-200 shadow-sm transition text-xs flex items-center gap-2"
          >
            <Settings size={14} /> Payment Settings
          </button>
        </div>

        {/* 5 Stat Cards matching Mockup 5 */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <IndianRupee size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Payouts</span>
            <span className="text-lg font-black text-slate-900 block">₹1,32,000</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 17.2% vs last month</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <Wallet size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Paid</span>
            <span className="text-lg font-black text-slate-900 block">₹1,15,250</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 16.8% vs last month</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <Clock size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Pending</span>
            <span className="text-lg font-black text-slate-900 block">₹16,750</span>
            <span className="text-[10px] font-bold text-amber-600 block">2 Trips</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <CreditCard size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Transactions</span>
            <span className="text-lg font-black text-slate-900 block">32</span>
            <span className="text-[10px] font-bold text-slate-500 block">This Month</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Clock size={16} />
            </div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Avg. Payout Time</span>
            <span className="text-lg font-black text-slate-900 block">2.3 Days</span>
            <span className="text-[10px] font-bold text-slate-500 block">This Month</span>
          </div>
        </div>

        {/* Filter Bar & Tabs matching Mockup 5 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-extrabold text-xs">
            <button
              onClick={() => setActiveTab("all")}
              className={`px-4 py-2 rounded-xl transition ${
                activeTab === "all" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              All Transactions
            </button>
            <button
              onClick={() => setActiveTab("payouts")}
              className={`px-4 py-2 rounded-xl transition ${
                activeTab === "payouts" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              Payouts
            </button>
            <button
              onClick={() => setActiveTab("settlements")}
              className={`px-4 py-2 rounded-xl transition ${
                activeTab === "settlements" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              Settlements
            </button>
          </div>

          <div className="flex items-center gap-2">
            <div className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 flex items-center gap-2">
              <CalendarCheck size={14} className="text-amber-500" />
              <span>20 May 2024 - 20 Jun 2024</span>
            </div>
            <button className="p-2 border border-slate-200 rounded-xl hover:bg-slate-50 text-slate-600">
              <Filter size={14} />
            </button>
          </div>
        </div>

        {/* Transactions Table matching Mockup 5 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
          <div className="divide-y divide-slate-100">
            <div className="grid grid-cols-6 gap-2 text-[10px] font-black uppercase text-slate-400 pb-2 px-2">
              <span>Date &amp; Time</span>
              <span>Transaction ID</span>
              <span>Type</span>
              <span>Related To</span>
              <span>Amount</span>
              <span>Status &amp; Mode</span>
            </div>

            {transactions.map((tx) => {
              const Icon = tx.icon;
              return (
                <div key={tx.id} className="py-3.5 grid grid-cols-6 gap-2 items-center text-xs hover:bg-slate-50 px-2 rounded-xl transition">
                  <div className="text-slate-900 font-bold">
                    {tx.date}
                  </div>

                  <div className="font-mono text-slate-500 text-[11px] font-semibold">
                    {tx.txId}
                  </div>

                  <div>
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-extrabold ${tx.iconColor}`}>
                      <Icon size={12} /> {tx.type}
                    </span>
                  </div>

                  <div>
                    <div className="font-black text-slate-900">{tx.trip}</div>
                    <div className="text-[10px] text-slate-400 font-medium">{tx.truck}</div>
                  </div>

                  <div className="font-black text-slate-900">
                    {tx.amount}
                  </div>

                  <div className="flex items-center justify-between">
                    <div>
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold block w-fit ${tx.statusTone}`}>
                        {tx.status}
                      </span>
                      <span className="text-[9px] text-slate-400 font-medium block pt-0.5">{tx.mode}</span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Add Bank Details Modal */}
      {showAddBankModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/40 backdrop-blur-sm">
          <div className="bg-white border border-slate-200 rounded-3xl p-6 w-full max-w-md shadow-2xl space-y-4 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2">
                <Landmark size={20} className="text-amber-500" />
                <h3 className="font-black text-slate-900 text-sm">Add Bank &amp; UPI Details</h3>
              </div>
              <button onClick={() => setShowAddBankModal(false)} className="text-slate-400 hover:text-slate-600 text-sm font-bold">✕</button>
            </div>

            <form onSubmit={(e) => { e.preventDefault(); setShowAddBankModal(false); }} className="space-y-3">
              <div>
                <label className="text-[11px] font-bold text-slate-700 block mb-1">Account Holder Name</label>
                <input required placeholder="Enter full name on bank account" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400" />
              </div>
              <div>
                <label className="text-[11px] font-bold text-slate-700 block mb-1">Bank Account Number</label>
                <input required placeholder="Enter account number" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400" />
              </div>
              <div>
                <label className="text-[11px] font-bold text-slate-700 block mb-1">IFSC Code</label>
                <input required placeholder="e.g. SBIN0001234" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400 uppercase" />
              </div>
              <div>
                <label className="text-[11px] font-bold text-slate-700 block mb-1">UPI ID (Optional)</label>
                <input placeholder="e.g. username@upi" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400" />
              </div>

              <button type="submit" className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md text-xs transition">
                Save &amp; Verify Bank Account
              </button>
            </form>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
