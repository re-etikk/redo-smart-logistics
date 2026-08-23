import { useState, useEffect } from "react";
import {
  CreditCard, IndianRupee, Wallet, CalendarCheck, Clock, Download, ArrowDownLeft,
  ArrowUpRight, Landmark, Settings, Filter, Plus, CheckCircle2, ShieldCheck, X,
  Building2, ArrowRight, FileText, Printer, Check
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import {
  getWallet, requestPayout, addMoneyToWallet, addBankAccount,
  type WalletState, type WalletTransaction, type BankAccount
} from "../lib/walletStore";

export default function Payments() {
  const [wallet, setWallet] = useState<WalletState>(getWallet());
  const [activeTab, setActiveTab] = useState("all");

  // Modals
  const [showWithdrawModal, setShowWithdrawModal] = useState(false);
  const [showAddBankModal, setShowAddBankModal] = useState(false);
  const [showAddMoneyModal, setShowAddMoneyModal] = useState(false);
  const [selectedReceipt, setSelectedReceipt] = useState<WalletTransaction | null>(null);

  // Form states
  const [withdrawAmount, setWithdrawAmount] = useState("10000");
  const [selectedBankId, setSelectedBankId] = useState<string>("");
  const [payoutStatusMessage, setPayoutStatusMessage] = useState<{ text: string; type: "success" | "error" } | null>(null);

  const [newBank, setNewBank] = useState({
    bankName: "ICICI Bank Ltd",
    accountNumber: "",
    ifsc: "",
    accountHolder: "Ritik Chaurasia",
    accountType: "Current" as const,
    upiId: "",
    isPrimary: false,
  });

  const [topUpAmount, setTopUpAmount] = useState("5000");

  const refresh = () => {
    const w = getWallet();
    setWallet(w);
    if (w.bankAccounts.length > 0 && !selectedBankId) {
      setSelectedBankId(w.bankAccounts[0].id);
    }
  };

  useEffect(() => {
    refresh();
    window.addEventListener("redo_wallet_updated", refresh);
    return () => window.removeEventListener("redo_wallet_updated", refresh);
  }, []);

  const handleWithdrawSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const amt = parseFloat(withdrawAmount);
    if (isNaN(amt) || amt <= 0) {
      setPayoutStatusMessage({ text: "Please enter a valid amount", type: "error" });
      return;
    }

    const res = requestPayout(amt, selectedBankId || wallet.bankAccounts[0]?.id);
    if (res.success) {
      setPayoutStatusMessage({ text: res.message, type: "success" });
      setTimeout(() => {
        setShowWithdrawModal(false);
        setPayoutStatusMessage(null);
      }, 2000);
    } else {
      setPayoutStatusMessage({ text: res.message, type: "error" });
    }
  };

  const handleAddBankSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBank.accountNumber || !newBank.ifsc) return;

    addBankAccount(newBank);
    setShowAddBankModal(false);
    setNewBank({
      bankName: "ICICI Bank Ltd",
      accountNumber: "",
      ifsc: "",
      accountHolder: "Ritik Chaurasia",
      accountType: "Current",
      upiId: "",
      isPrimary: false,
    });
  };

  const handleTopUpSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const amt = parseFloat(topUpAmount);
    if (isNaN(amt) || amt <= 0) return;

    addMoneyToWallet(amt);
    setShowAddMoneyModal(false);
  };

  const filteredTransactions = wallet.transactions.filter((tx) => {
    if (activeTab === "payouts") return tx.type === "Payout";
    if (activeTab === "earnings") return tx.type === "Trip Earning";
    if (activeTab === "deductions") return tx.type === "FASTag Deduction" || tx.direction === "debit";
    return true;
  });

  const totalEarnings = wallet.transactions
    .filter(t => t.direction === "credit")
    .reduce((acc, curr) => acc + curr.amount, 0);

  return (
    <OwnerLayout activeTab="payments" promoCardType="bank" onAddBankClick={() => setShowAddBankModal(true)}>
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">Payments &amp; Wallet</h1>
            <p className="text-xs text-slate-500 mt-0.5">Manage your commercial freight earnings, bank payouts, and GST receipts.</p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowAddBankModal(true)}
              className="bg-white hover:bg-slate-50 text-slate-900 font-bold px-4 py-2.5 rounded-xl border border-slate-200 shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <Landmark size={15} className="text-amber-500" />
              <span>+ Add Bank / UPI</span>
            </button>
            <button
              onClick={() => setShowWithdrawModal(true)}
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-md transition text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <ArrowDownLeft size={16} />
              <span>Withdraw Money</span>
            </button>
          </div>
        </div>

        {/* Wallet Overview Hero Card */}
        <div className="bg-slate-900 text-white rounded-3xl p-6 sm:p-8 shadow-xl relative overflow-hidden flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-2 relative z-10">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
              <span className="text-xs uppercase tracking-wider text-slate-400 font-bold">REDO Verified Wallet Balance</span>
            </div>
            <div className="flex items-baseline gap-2">
              <h2 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
                ₹{wallet.balance.toLocaleString("en-IN")}
              </h2>
              <span className="text-xs text-emerald-400 font-bold bg-emerald-950/60 px-2 py-0.5 rounded border border-emerald-500/30">
                Instant Payout Ready
              </span>
            </div>
            <p className="text-xs text-slate-400 max-w-md">
              Earnings from completed trips are credited automatically to this wallet and can be withdrawn 24/7 via IMPS/UPI.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3 relative z-10">
            <button
              onClick={() => setShowWithdrawModal(true)}
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-3.5 rounded-2xl shadow-lg transition text-xs flex items-center gap-2 cursor-pointer"
            >
              <ArrowDownLeft size={16} /> Request Instant Payout
            </button>
            <button
              onClick={() => setShowAddMoneyModal(true)}
              className="bg-white/10 hover:bg-white/20 text-white font-bold px-4 py-3.5 rounded-2xl backdrop-blur-md transition text-xs flex items-center gap-2 cursor-pointer"
            >
              <Plus size={16} /> Top-up Wallet
            </button>
          </div>

          {/* Subtle Background Pattern */}
          <div className="absolute right-0 top-0 bottom-0 w-80 bg-gradient-to-l from-amber-500/10 to-transparent pointer-events-none" />
        </div>

        {/* 4 Metrics Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Freight Earned</span>
            <span className="text-xl font-black text-slate-900 block">₹{totalEarnings.toLocaleString("en-IN")}</span>
            <span className="text-[10px] font-bold text-emerald-600 block">↑ 18.5% Growth</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Withdrawn</span>
            <span className="text-xl font-black text-slate-900 block">₹{wallet.totalWithdrawn.toLocaleString("en-IN")}</span>
            <span className="text-[10px] font-bold text-slate-500 block">100% Settled</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Linked Accounts</span>
            <span className="text-xl font-black text-slate-900 block">{wallet.bankAccounts.length} Verified</span>
            <span className="text-[10px] font-bold text-purple-600 block">IMPS / UPI Enabled</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Avg Settlement Speed</span>
            <span className="text-xl font-black text-emerald-600 block">&lt; 2 Minutes</span>
            <span className="text-[10px] font-bold text-emerald-700 block">Real-time NPCI IMPS</span>
          </div>
        </div>

        {/* Linked Bank Accounts Section */}
        <div className="bg-white border border-slate-200/80 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-black text-slate-900">Linked Bank Accounts &amp; UPI</h3>
              <p className="text-xs text-slate-500">Bank accounts for receiving direct freight disbursements.</p>
            </div>
            <button
              onClick={() => setShowAddBankModal(true)}
              className="text-xs font-bold text-amber-600 hover:text-amber-700 flex items-center gap-1"
            >
              <Plus size={14} /> Add Another Account
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {wallet.bankAccounts.map((b) => (
              <div
                key={b.id}
                className={`p-5 rounded-2xl border transition flex flex-col justify-between space-y-3 ${
                  b.isPrimary
                    ? "bg-amber-50/50 border-amber-300 ring-1 ring-amber-400/40"
                    : "bg-slate-50 border-slate-200"
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-slate-900 text-amber-400 flex items-center justify-center font-black">
                      <Building2 size={18} />
                    </div>
                    <div>
                      <h4 className="font-black text-slate-900 text-sm">{b.bankName}</h4>
                      <p className="text-xs text-slate-500 font-mono">A/C: {b.accountNumber}</p>
                    </div>
                  </div>
                  {b.isPrimary ? (
                    <span className="bg-amber-400 text-slate-950 text-[10px] font-black px-2.5 py-0.5 rounded-full">
                      Primary
                    </span>
                  ) : (
                    <span className="text-[10px] text-slate-400 font-bold">Secondary</span>
                  )}
                </div>

                <div className="flex items-center justify-between text-xs font-bold text-slate-600 pt-2 border-t border-slate-200/60">
                  <span>IFSC: <strong className="text-slate-900 font-mono">{b.ifsc}</strong></span>
                  <span>UPI: <strong className="text-slate-900 font-mono">{b.upiId || "—"}</strong></span>
                  <span className="text-emerald-700 flex items-center gap-1">
                    <ShieldCheck size={13} /> Verified
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Transaction History Section */}
        <div className="bg-white border border-slate-200/80 rounded-3xl p-6 shadow-sm space-y-5">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-black text-slate-900">Transaction History</h3>
              <p className="text-xs text-slate-500">Live ledger of freight payouts, wallet withdrawals, and toll receipts.</p>
            </div>

            {/* Tabs */}
            <div className="flex items-center gap-1.5 bg-slate-100 p-1 rounded-xl text-xs font-bold">
              <button
                onClick={() => setActiveTab("all")}
                className={`px-3 py-1.5 rounded-lg transition ${activeTab === "all" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"}`}
              >
                All
              </button>
              <button
                onClick={() => setActiveTab("payouts")}
                className={`px-3 py-1.5 rounded-lg transition ${activeTab === "payouts" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"}`}
              >
                Payouts
              </button>
              <button
                onClick={() => setActiveTab("earnings")}
                className={`px-3 py-1.5 rounded-lg transition ${activeTab === "earnings" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"}`}
              >
                Earnings
              </button>
              <button
                onClick={() => setActiveTab("deductions")}
                className={`px-3 py-1.5 rounded-lg transition ${activeTab === "deductions" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"}`}
              >
                FASTag/Tolls
              </button>
            </div>
          </div>

          <div className="space-y-3">
            {filteredTransactions.map((tx) => (
              <div
                key={tx.id}
                className="p-4 rounded-2xl bg-slate-50 border border-slate-200/80 hover:bg-white hover:border-slate-300 transition flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4"
              >
                <div className="flex items-center gap-3.5">
                  <div className={`w-11 h-11 rounded-2xl flex items-center justify-center font-black ${
                    tx.direction === "credit" ? "bg-emerald-100 text-emerald-800" : "bg-amber-100 text-amber-900"
                  }`}>
                    {tx.direction === "credit" ? <ArrowDownLeft size={20} /> : <ArrowUpRight size={20} />}
                  </div>

                  <div>
                    <h4 className="font-black text-slate-900 text-xs sm:text-sm">{tx.description}</h4>
                    <div className="flex items-center gap-2 text-[11px] text-slate-500 font-medium">
                      <span>{tx.date}</span>
                      <span>•</span>
                      <span className="font-mono">{tx.mode}</span>
                      <span>•</span>
                      <span className="font-mono font-bold text-slate-700">{tx.utrNumber}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between sm:justify-end gap-4 w-full sm:w-auto border-t sm:border-t-0 pt-2 sm:pt-0 border-slate-200/60">
                  <div className="text-left sm:text-right">
                    <span className={`text-sm sm:text-base font-black ${
                      tx.direction === "credit" ? "text-emerald-700" : "text-slate-900"
                    }`}>
                      {tx.direction === "credit" ? "+" : "-"}₹{tx.amount.toLocaleString("en-IN")}
                    </span>
                    <span className="text-[10px] text-emerald-700 font-extrabold block">
                      ✓ {tx.status}
                    </span>
                  </div>

                  <button
                    onClick={() => setSelectedReceipt(tx)}
                    className="p-2 text-slate-500 hover:text-slate-900 bg-white border border-slate-200 rounded-xl shadow-xs hover:bg-slate-100 transition cursor-pointer"
                    title="View Tax Invoice & Receipt"
                  >
                    <FileText size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* MODAL 1: WITHDRAW MONEY */}
      {/* ========================================================================= */}
      {showWithdrawModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-lg font-black text-slate-900">Request Payout</h3>
                <p className="text-xs text-slate-500">Available: ₹{wallet.balance.toLocaleString("en-IN")}</p>
              </div>
              <button onClick={() => setShowWithdrawModal(false)} className="p-1.5 text-slate-400 hover:text-slate-700">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleWithdrawSubmit} className="space-y-4 text-xs font-bold">
              <div>
                <label className="text-slate-700 block mb-1">Withdrawal Amount (₹)</label>
                <input
                  type="number"
                  required
                  max={wallet.balance}
                  value={withdrawAmount}
                  onChange={(e) => setWithdrawAmount(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-lg font-black text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                />
              </div>

              {/* Quick Amount Chips */}
              <div className="grid grid-cols-4 gap-2">
                {[5000, 10000, 20000, wallet.balance].map((amt, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => setWithdrawAmount(amt.toString())}
                    className="p-2 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-xl text-[11px] font-bold text-slate-800 text-center transition"
                  >
                    ₹{amt.toLocaleString("en-IN")}
                  </button>
                ))}
              </div>

              {/* Destination Bank Account */}
              <div>
                <label className="text-slate-700 block mb-1">Destination Bank Account</label>
                <select
                  value={selectedBankId}
                  onChange={(e) => setSelectedBankId(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                >
                  {wallet.bankAccounts.map((b) => (
                    <option key={b.id} value={b.id}>
                      {b.bankName} (A/C ••{b.accountNumber.slice(-4)}) — {b.ifsc}
                    </option>
                  ))}
                </select>
              </div>

              {payoutStatusMessage && (
                <div className={`p-3 rounded-xl text-xs font-bold border ${
                  payoutStatusMessage.type === "success"
                    ? "bg-emerald-50 text-emerald-800 border-emerald-200"
                    : "bg-rose-50 text-rose-800 border-rose-200"
                }`}>
                  {payoutStatusMessage.text}
                </div>
              )}

              <button
                type="submit"
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs cursor-pointer flex items-center justify-center gap-2"
              >
                <span>Confirm &amp; Transfer to Bank</span>
                <ArrowRight size={16} />
              </button>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 2: ADD BANK ACCOUNT */}
      {/* ========================================================================= */}
      {showAddBankModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-lg font-black text-slate-900">Add Commercial Bank Account</h3>
                <p className="text-xs text-slate-500">Direct NEFT/IMPS payout setup</p>
              </div>
              <button onClick={() => setShowAddBankModal(false)} className="p-1.5 text-slate-400 hover:text-slate-700">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleAddBankSubmit} className="space-y-3.5 text-xs font-bold">
              <div>
                <label className="text-slate-700 block mb-1">Bank Name *</label>
                <input
                  required
                  value={newBank.bankName}
                  onChange={(e) => setNewBank({ ...newBank, bankName: e.target.value })}
                  placeholder="e.g. HDFC Bank, ICICI Bank, SBI"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 text-slate-900"
                />
              </div>

              <div>
                <label className="text-slate-700 block mb-1">Account Holder Name *</label>
                <input
                  required
                  value={newBank.accountHolder}
                  onChange={(e) => setNewBank({ ...newBank, accountHolder: e.target.value })}
                  placeholder="Name as on Bank Passbook / Cheque"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 text-slate-900"
                />
              </div>

              <div>
                <label className="text-slate-700 block mb-1">Account Number *</label>
                <input
                  required
                  value={newBank.accountNumber}
                  onChange={(e) => setNewBank({ ...newBank, accountNumber: e.target.value })}
                  placeholder="e.g. 50200084920192"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 font-mono text-slate-900"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-700 block mb-1">IFSC Code *</label>
                  <input
                    required
                    value={newBank.ifsc}
                    onChange={(e) => setNewBank({ ...newBank, ifsc: e.target.value.toUpperCase() })}
                    placeholder="HDFC0000128"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 font-mono uppercase text-slate-900"
                  />
                </div>
                <div>
                  <label className="text-slate-700 block mb-1">Account Type</label>
                  <select
                    value={newBank.accountType}
                    onChange={(e) => setNewBank({ ...newBank, accountType: e.target.value as any })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  >
                    <option value="Current">Current</option>
                    <option value="Savings">Savings</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-slate-700 block mb-1">UPI ID (Optional for Instant Payouts)</label>
                <input
                  value={newBank.upiId}
                  onChange={(e) => setNewBank({ ...newBank, upiId: e.target.value })}
                  placeholder="e.g. mobile@upi"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 font-mono text-slate-900"
                />
              </div>

              <button
                type="submit"
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs cursor-pointer mt-2"
              >
                Verify &amp; Save Bank Account
              </button>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 3: INVOICE / RECEIPT VIEWER */}
      {/* ========================================================================= */}
      {selectedReceipt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-lg w-full shadow-2xl p-6 space-y-5">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <span className="text-[10px] font-mono font-bold bg-amber-100 text-amber-900 px-2 py-0.5 rounded">
                  {selectedReceipt.txId}
                </span>
                <h3 className="text-lg font-black text-slate-900 mt-1">Official Freight Settlement Receipt</h3>
              </div>
              <button onClick={() => setSelectedReceipt(null)} className="p-1.5 text-slate-400 hover:text-slate-700">
                <X size={18} />
              </button>
            </div>

            <div className="space-y-4 text-xs font-bold bg-slate-50 p-4 rounded-2xl border border-slate-200">
              <div className="flex justify-between">
                <span className="text-slate-500">Transaction Date:</span>
                <span className="text-slate-900">{selectedReceipt.date}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Bank UTR / Ref Number:</span>
                <span className="text-slate-900 font-mono">{selectedReceipt.utrNumber}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Payment Mode:</span>
                <span className="text-slate-900">{selectedReceipt.mode}</span>
              </div>
              {selectedReceipt.regNo && (
                <div className="flex justify-between">
                  <span className="text-slate-500">Commercial Vehicle:</span>
                  <span className="text-slate-900">{selectedReceipt.truckName} ({selectedReceipt.regNo})</span>
                </div>
              )}
              <div className="pt-2 border-t border-slate-200 flex justify-between items-center text-slate-900">
                <span className="font-black text-sm">Settled Amount:</span>
                <span className="text-xl font-black text-emerald-700">
                  ₹{selectedReceipt.amount.toLocaleString("en-IN")}
                </span>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => window.print()}
                className="px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold rounded-xl text-xs flex items-center gap-1.5 transition"
              >
                <Printer size={15} /> Print Receipt
              </button>
              <button
                onClick={() => setSelectedReceipt(null)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
