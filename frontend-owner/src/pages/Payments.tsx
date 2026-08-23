import { useState, useEffect } from "react";
import {
  CreditCard, IndianRupee, ArrowUpRight, ArrowDownLeft, Landmark, ShieldCheck,
  Plus, CheckCircle2, AlertCircle, Eye, Download, X, Check, RefreshCw, Send,
  FileText, ExternalLink, Printer, Building2
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import {
  getWallet, requestPayout, addMoneyToWallet, addBankAccount,
  type WalletState, type BankAccount, type WalletTransaction
} from "../lib/walletStore";
import { useTranslation } from "../lib/i18n";

export default function OwnerPayments() {
  const { t } = useTranslation();
  const [wallet, setWallet] = useState<WalletState>(getWallet());
  const [activeTxTab, setActiveTxTab] = useState<"all" | "payouts" | "earnings" | "fastag">("all");

  // Modals
  const [isWithdrawOpen, setIsWithdrawOpen] = useState(false);
  const [isAddBankOpen, setIsAddBankOpen] = useState(false);
  const [selectedReceipt, setSelectedReceipt] = useState<WalletTransaction | null>(null);

  // Withdraw Form State
  const [withdrawAmount, setWithdrawAmount] = useState<string>("10000");
  const [selectedBankId, setSelectedBankId] = useState<string>("");
  const [withdrawLoading, setWithdrawLoading] = useState(false);
  const [withdrawSuccess, setWithdrawSuccess] = useState<any | null>(null);
  const [withdrawError, setWithdrawError] = useState("");

  // Add Bank Form State
  const [bankForm, setBankForm] = useState({
    bankName: "HDFC Bank",
    accountNumber: "",
    confirmAccountNumber: "",
    ifsc: "",
    accountHolder: "Ritik Chaurasia",
    accountType: "Current" as const,
    upiId: "",
  });
  const [bankError, setBankError] = useState("");

  const refreshState = () => {
    const w = getWallet();
    setWallet(w);
    if (w.bankAccounts.length > 0 && !selectedBankId) {
      setSelectedBankId(w.bankAccounts[0].id);
    }
  };

  useEffect(() => {
    refreshState();
    const handleUpdate = () => refreshState();
    window.addEventListener("redo_wallet_updated", handleUpdate);
    return () => window.removeEventListener("redo_wallet_updated", handleUpdate);
  }, []);

  const handleWithdrawSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setWithdrawError("");
    const amt = parseFloat(withdrawAmount);
    if (isNaN(amt) || amt <= 0) {
      setWithdrawError("Please enter a valid amount.");
      return;
    }
    if (amt > wallet.balance) {
      setWithdrawError(`Amount exceeds available wallet balance of ₹${wallet.balance.toLocaleString("en-IN")}`);
      return;
    }
    if (!selectedBankId && wallet.bankAccounts.length === 0) {
      setWithdrawError("Please add and select a bank account first.");
      return;
    }

    setWithdrawLoading(true);
    setTimeout(() => {
      const res = requestPayout(amt, selectedBankId || wallet.bankAccounts[0]?.id);
      setWithdrawLoading(false);
      if (res.success) {
        setWithdrawSuccess(res.transaction);
        refreshState();
      } else {
        setWithdrawError(res.message);
      }
    }, 1200);
  };

  const handleAddBankSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setBankError("");
    if (!bankForm.accountNumber || bankForm.accountNumber !== bankForm.confirmAccountNumber) {
      setBankError("Account numbers do not match.");
      return;
    }
    if (!bankForm.ifsc || bankForm.ifsc.length < 6) {
      setBankError("Please enter a valid 11-digit IFSC code.");
      return;
    }

    const newAcc = addBankAccount({
      bankName: bankForm.bankName,
      accountNumber: bankForm.accountNumber,
      ifsc: bankForm.ifsc.toUpperCase(),
      accountHolder: bankForm.accountHolder,
      accountType: bankForm.accountType,
      upiId: bankForm.upiId || undefined,
    });

    setSelectedBankId(newAcc.id);
    setIsAddBankOpen(false);
    setBankForm({
      bankName: "HDFC Bank",
      accountNumber: "",
      confirmAccountNumber: "",
      ifsc: "",
      accountHolder: "Ritik Chaurasia",
      accountType: "Current",
      upiId: "",
    });
    refreshState();
  };

  const filteredTransactions = wallet.transactions.filter((tx) => {
    if (activeTxTab === "all") return true;
    if (activeTxTab === "payouts") return tx.type === "Payout";
    if (activeTxTab === "earnings") return tx.type === "Trip Earning";
    if (activeTxTab === "fastag") return tx.type === "FASTag Deduction";
    return true;
  });

  return (
    <OwnerLayout
      activeTab="payments"
      promoCardType="bank"
      onAddBankClick={() => setIsAddBankOpen(true)}
    >
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900 dark:text-white">
              {t("payments")} &amp; Wallet Ledger
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Instant freight settlements, bank payouts via IMPS &amp; FASTag ledger.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={() => setIsAddBankOpen(true)}
              className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-900 dark:text-white font-bold px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <Landmark size={14} className="text-amber-500" />
              <span>+ Add Bank / UPI</span>
            </button>

            <button
              onClick={() => {
                setWithdrawError("");
                setWithdrawSuccess(null);
                setIsWithdrawOpen(true);
              }}
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2 rounded-xl shadow-md transition text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <ArrowUpRight size={15} />
              <span>Request Instant Payout</span>
            </button>
          </div>
        </div>

        {/* 4 Stat Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {/* Wallet Balance Hero Card */}
          <div className="bg-gradient-to-br from-amber-400 via-amber-500 to-amber-600 rounded-3xl p-5 text-slate-950 shadow-md flex flex-col justify-between space-y-3 relative overflow-hidden">
            <div className="space-y-1">
              <span className="text-[10px] font-black uppercase tracking-wider text-slate-900/80">
                Available Wallet Balance
              </span>
              <h2 className="text-3xl font-black tracking-tight">
                ₹{wallet.balance.toLocaleString("en-IN")}
              </h2>
            </div>
            <div className="flex items-center justify-between text-[11px] font-bold border-t border-slate-950/10 pt-2">
              <span className="flex items-center gap-1">
                <ShieldCheck size={13} /> 100% Escrow Protected
              </span>
              <button
                onClick={() => {
                  setWithdrawError("");
                  setWithdrawSuccess(null);
                  setIsWithdrawOpen(true);
                }}
                className="underline font-black cursor-pointer hover:text-slate-900"
              >
                Withdraw ➔
              </button>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1 flex flex-col justify-between">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Total Withdrawn
            </span>
            <div>
              <span className="text-2xl font-black text-slate-900 dark:text-white block">
                ₹{wallet.totalWithdrawn.toLocaleString("en-IN")}
              </span>
              <span className="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 block pt-0.5">
                ✓ 100% Settled via IMPS
              </span>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1 flex flex-col justify-between">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Linked Accounts
            </span>
            <div>
              <span className="text-2xl font-black text-slate-900 dark:text-white block">
                {wallet.bankAccounts.length} Verified
              </span>
              <span className="text-[10px] font-bold text-slate-500 dark:text-slate-400 block pt-0.5">
                {wallet.bankAccounts.length > 0 ? "IMPS & UPI Enabled" : "No Bank Added Yet"}
              </span>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1 flex flex-col justify-between">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Avg Settlement Speed
            </span>
            <div>
              <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400 block">
                &lt; 2 Minutes
              </span>
              <span className="text-[10px] font-bold text-slate-500 dark:text-slate-400 block pt-0.5">
                Real-time NPCI IMPS
              </span>
            </div>
          </div>
        </div>

        {/* Linked Bank Accounts & UPI Card */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
            <div>
              <h3 className="font-black text-xs uppercase tracking-wider text-slate-900 dark:text-white flex items-center gap-2">
                <Landmark size={16} className="text-amber-500" /> Linked Bank Accounts &amp; UPI
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Bank accounts for receiving direct freight disbursements.
              </p>
            </div>

            <button
              onClick={() => setIsAddBankOpen(true)}
              className="text-xs font-bold text-amber-600 dark:text-amber-400 hover:underline flex items-center gap-1 cursor-pointer"
            >
              <Plus size={14} /> Add Another Account
            </button>
          </div>

          {wallet.bankAccounts.length === 0 ? (
            <div className="p-8 text-center border-2 border-dashed border-slate-200 dark:border-slate-800 rounded-3xl space-y-3 bg-slate-50 dark:bg-slate-800/40">
              <div className="w-12 h-12 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 mx-auto flex items-center justify-center">
                <Landmark size={22} />
              </div>
              <div className="space-y-1">
                <h4 className="font-black text-sm text-slate-900 dark:text-white">No Bank Account Linked Yet</h4>
                <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mx-auto">
                  Add your commercial bank account or UPI ID to receive instant freight disbursements directly.
                </p>
              </div>
              <button
                onClick={() => setIsAddBankOpen(true)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition inline-flex items-center gap-1.5 cursor-pointer"
              >
                <Plus size={15} /> Link Bank Account / UPI
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {wallet.bankAccounts.map((acc) => (
                <div
                  key={acc.id}
                  className={`p-4 rounded-2xl border transition relative ${
                    acc.isPrimary
                      ? "bg-amber-50/60 dark:bg-slate-800/80 border-amber-300 dark:border-amber-500/40 ring-1 ring-amber-400/40"
                      : "bg-slate-50 dark:bg-slate-800/40 border-slate-200 dark:border-slate-800"
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-slate-900 text-amber-400 flex items-center justify-center font-black">
                        <Landmark size={18} />
                      </div>
                      <div>
                        <h4 className="font-black text-xs sm:text-sm text-slate-900 dark:text-white">{acc.bankName}</h4>
                        <p className="text-[11px] font-mono text-slate-500 dark:text-slate-400">
                          A/C: •••• {acc.accountNumber.slice(-4)} ({acc.accountType})
                        </p>
                      </div>
                    </div>

                    {acc.isPrimary ? (
                      <span className="bg-[#FFC800] text-slate-950 text-[9px] font-black px-2 py-0.5 rounded-md uppercase tracking-wider">
                        Primary
                      </span>
                    ) : (
                      <span className="text-[9px] font-bold text-slate-400 uppercase">Secondary</span>
                    )}
                  </div>

                  <div className="mt-3 pt-3 border-t border-slate-200/60 dark:border-slate-700/60 flex items-center justify-between text-[11px]">
                    <span className="font-mono text-slate-600 dark:text-slate-400">IFSC: {acc.ifsc}</span>
                    {acc.upiId && (
                      <span className="font-mono text-slate-600 dark:text-slate-400">UPI: {acc.upiId}</span>
                    )}
                    <span className="text-emerald-600 dark:text-emerald-400 font-bold flex items-center gap-1">
                      <CheckCircle2 size={12} /> Verified
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Transaction History Ledger Card */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border-b border-slate-100 dark:border-slate-800 pb-3">
            <div>
              <h3 className="font-black text-xs uppercase tracking-wider text-slate-900 dark:text-white">
                Transaction History Ledger
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Live ledger of freight payouts, wallet withdrawals, and toll receipts.
              </p>
            </div>

            {/* Filter Tabs */}
            <div className="flex items-center gap-1.5 font-bold text-xs">
              <button
                onClick={() => setActiveTxTab("all")}
                className={`px-3 py-1.5 rounded-xl transition cursor-pointer ${
                  activeTxTab === "all"
                    ? "bg-[#FFC800] text-slate-950 font-black shadow-sm"
                    : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                }`}
              >
                All
              </button>
              <button
                onClick={() => setActiveTxTab("payouts")}
                className={`px-3 py-1.5 rounded-xl transition cursor-pointer ${
                  activeTxTab === "payouts"
                    ? "bg-[#FFC800] text-slate-950 font-black shadow-sm"
                    : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                }`}
              >
                Payouts
              </button>
              <button
                onClick={() => setActiveTxTab("earnings")}
                className={`px-3 py-1.5 rounded-xl transition cursor-pointer ${
                  activeTxTab === "earnings"
                    ? "bg-[#FFC800] text-slate-950 font-black shadow-sm"
                    : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                }`}
              >
                Earnings
              </button>
              <button
                onClick={() => setActiveTxTab("fastag")}
                className={`px-3 py-1.5 rounded-xl transition cursor-pointer ${
                  activeTxTab === "fastag"
                    ? "bg-[#FFC800] text-slate-950 font-black shadow-sm"
                    : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                }`}
              >
                FASTag/Tolls
              </button>
            </div>
          </div>

          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {filteredTransactions.map((tx) => (
              <div key={tx.id} className="py-4 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3.5">
                  <div
                    className={`w-10 h-10 rounded-2xl flex items-center justify-center font-black ${
                      tx.direction === "credit"
                        ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400"
                        : "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400"
                    }`}
                  >
                    {tx.direction === "credit" ? <ArrowDownLeft size={20} /> : <ArrowUpRight size={20} />}
                  </div>

                  <div className="space-y-0.5">
                    <h4 className="font-black text-xs sm:text-sm text-slate-900 dark:text-white">{tx.description}</h4>
                    <div className="flex flex-wrap items-center gap-2 text-[11px] text-slate-500 dark:text-slate-400 font-medium">
                      <span>{tx.date}</span>
                      <span>•</span>
                      <span>{tx.mode}</span>
                      <span>•</span>
                      <span className="font-mono text-slate-400">UTR: {tx.utrNumber}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <div className="text-right">
                    <span
                      className={`text-sm sm:text-base font-black block ${
                        tx.direction === "credit"
                          ? "text-emerald-600 dark:text-emerald-400"
                          : "text-slate-900 dark:text-white"
                      }`}
                    >
                      {tx.direction === "credit" ? "+" : "-"}₹{tx.amount.toLocaleString("en-IN")}
                    </span>
                    <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold block">
                      ✓ {tx.status}
                    </span>
                  </div>

                  <button
                    onClick={() => setSelectedReceipt(tx)}
                    className="p-2 text-slate-400 hover:text-amber-500 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
                    title="View &amp; Print Official Tax Receipt"
                  >
                    <FileText size={18} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* WITHDRAW PAYOUT MODAL */}
      {/* ========================================================================= */}
      {isWithdrawOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <h3 className="text-base font-black">Request Instant Bank Withdrawal</h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">Direct NPCI IMPS transfer to your verified account</p>
              </div>
              <button
                onClick={() => setIsWithdrawOpen(false)}
                className="p-1.5 text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            {withdrawSuccess ? (
              <div className="p-6 text-center space-y-3 bg-emerald-50 dark:bg-emerald-950/40 rounded-2xl border border-emerald-300 dark:border-emerald-800">
                <div className="w-14 h-14 rounded-full bg-emerald-500 text-white mx-auto flex items-center justify-center">
                  <Check size={28} />
                </div>
                <h4 className="text-base font-black text-emerald-950 dark:text-emerald-300">
                  Withdrawal Initiated Successfully!
                </h4>
                <p className="text-xs text-slate-600 dark:text-slate-300">
                  ₹{withdrawSuccess.amount.toLocaleString("en-IN")} has been dispatched to your bank.
                </p>
                <div className="text-[11px] font-mono bg-white dark:bg-slate-900 p-2.5 rounded-xl border border-slate-200 dark:border-slate-800">
                  UTR: {withdrawSuccess.utrNumber}
                </div>
                <button
                  onClick={() => setIsWithdrawOpen(false)}
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2 rounded-xl text-xs shadow-sm mt-2"
                >
                  Done
                </button>
              </div>
            ) : (
              <form onSubmit={handleWithdrawSubmit} className="space-y-4">
                <div>
                  <label className="text-slate-400 uppercase text-[10px] block mb-1">
                    Withdrawal Amount (₹)
                  </label>
                  <input
                    type="number"
                    min="500"
                    max={wallet.balance}
                    required
                    value={withdrawAmount}
                    onChange={(e) => setWithdrawAmount(e.target.value)}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-base font-black focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                  <span className="text-[10px] text-slate-400 block mt-1">
                    Available Balance: ₹{wallet.balance.toLocaleString("en-IN")}
                  </span>
                </div>

                {/* Quick Chips */}
                <div className="flex gap-2">
                  {[5000, 10000, 20000, wallet.balance].map((amt, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => setWithdrawAmount(amt.toString())}
                      className="flex-1 py-1.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-amber-100 dark:hover:bg-slate-700 text-[11px] font-bold transition"
                    >
                      {amt === wallet.balance ? "Full" : `₹${amt / 1000}k`}
                    </button>
                  ))}
                </div>

                {wallet.bankAccounts.length === 0 ? (
                  <div className="p-3 bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 rounded-xl text-rose-700 dark:text-rose-300 text-xs">
                    No bank account linked. Please link a bank account first!
                  </div>
                ) : (
                  <div>
                    <label className="text-slate-400 uppercase text-[10px] block mb-1">
                      Select Destination Bank Account
                    </label>
                    <select
                      value={selectedBankId}
                      onChange={(e) => setSelectedBankId(e.target.value)}
                      className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                    >
                      {wallet.bankAccounts.map((acc) => (
                        <option key={acc.id} value={acc.id}>
                          {acc.bankName} (•••• {acc.accountNumber.slice(-4)}) — {acc.accountHolder}
                        </option>
                      ))}
                    </select>
                  </div>
                )}

                {withdrawError && (
                  <p className="text-xs font-bold text-rose-600">{withdrawError}</p>
                )}

                <button
                  type="submit"
                  disabled={withdrawLoading || wallet.bankAccounts.length === 0}
                  className="w-full bg-[#FFC800] hover:bg-amber-400 disabled:opacity-50 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2 cursor-pointer"
                >
                  {withdrawLoading ? (
                    <>
                      <RefreshCw size={15} className="animate-spin" />
                      <span>Processing IMPS Dispatch...</span>
                    </>
                  ) : (
                    <>
                      <ArrowUpRight size={16} />
                      <span>Confirm &amp; Transfer to Bank</span>
                    </>
                  )}
                </button>
              </form>
            )}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* ADD BANK ACCOUNT MODAL */}
      {/* ========================================================================= */}
      {isAddBankOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <h3 className="text-base font-black">Link Commercial Bank Account</h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">Add your bank details for direct payout settlements</p>
              </div>
              <button
                onClick={() => setIsAddBankOpen(false)}
                className="p-1.5 text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleAddBankSubmit} className="space-y-4">
              <div>
                <label className="text-slate-400 uppercase text-[10px] block mb-1">Bank Name *</label>
                <input
                  required
                  value={bankForm.bankName}
                  onChange={(e) => setBankForm({ ...bankForm, bankName: e.target.value })}
                  placeholder="e.g. HDFC Bank, ICICI Bank, SBI"
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                />
              </div>

              <div>
                <label className="text-slate-400 uppercase text-[10px] block mb-1">Account Holder Name *</label>
                <input
                  required
                  value={bankForm.accountHolder}
                  onChange={(e) => setBankForm({ ...bankForm, accountHolder: e.target.value })}
                  placeholder="Name as on Bank Passbook"
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-400 uppercase text-[10px] block mb-1">Account Number *</label>
                  <input
                    required
                    type="password"
                    value={bankForm.accountNumber}
                    onChange={(e) => setBankForm({ ...bankForm, accountNumber: e.target.value })}
                    placeholder="Enter Account Number"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-mono"
                  />
                </div>
                <div>
                  <label className="text-slate-400 uppercase text-[10px] block mb-1">Confirm Number *</label>
                  <input
                    required
                    value={bankForm.confirmAccountNumber}
                    onChange={(e) => setBankForm({ ...bankForm, confirmAccountNumber: e.target.value })}
                    placeholder="Re-enter Number"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-400 uppercase text-[10px] block mb-1">IFSC Code *</label>
                  <input
                    required
                    value={bankForm.ifsc}
                    onChange={(e) => setBankForm({ ...bankForm, ifsc: e.target.value.toUpperCase() })}
                    placeholder="HDFC0000128"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-mono uppercase"
                  />
                </div>
                <div>
                  <label className="text-slate-400 uppercase text-[10px] block mb-1">UPI ID (Optional)</label>
                  <input
                    value={bankForm.upiId}
                    onChange={(e) => setBankForm({ ...bankForm, upiId: e.target.value })}
                    placeholder="mobile@upi"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-mono"
                  />
                </div>
              </div>

              {bankError && (
                <p className="text-xs font-bold text-rose-600">{bankError}</p>
              )}

              <button
                type="submit"
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2 cursor-pointer mt-2"
              >
                <Check size={16} /> Link &amp; Verify Account Instantly
              </button>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* OFFICIAL GST FREIGHT SETTLEMENT RECEIPT MODAL */}
      {/* ========================================================================= */}
      {selectedReceipt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-lg w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div className="flex items-center gap-2">
                <FileText size={18} className="text-amber-500" />
                <h3 className="text-base font-black">Official Freight Settlement Receipt</h3>
              </div>
              <button
                onClick={() => setSelectedReceipt(null)}
                className="p-1.5 text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400">Transaction ID:</span>
                <span className="font-mono">{selectedReceipt.txId}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Bank UTR Reference:</span>
                <span className="font-mono text-amber-600 dark:text-amber-400">{selectedReceipt.utrNumber}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Transaction Type:</span>
                <span>{selectedReceipt.type} ({selectedReceipt.mode})</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Settlement Date:</span>
                <span>{selectedReceipt.date}</span>
              </div>
            </div>

            <div className="flex items-center justify-between p-4 bg-amber-500/10 border border-amber-400/40 rounded-2xl">
              <div>
                <span className="text-[10px] uppercase font-bold text-amber-800 dark:text-amber-300 block">
                  Amount Disbursed
                </span>
                <span className="text-xl font-black text-slate-900 dark:text-white">
                  ₹{selectedReceipt.amount.toLocaleString("en-IN")}
                </span>
              </div>
              <span className="bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400 text-xs font-black px-3 py-1 rounded-full">
                ✓ {selectedReceipt.status}
              </span>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => window.print()}
                className="bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-900 dark:text-white font-black px-4 py-2.5 rounded-xl text-xs flex items-center gap-1.5 cursor-pointer"
              >
                <Printer size={14} /> Print Receipt
              </button>
              <button
                onClick={() => setSelectedReceipt(null)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm cursor-pointer"
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
