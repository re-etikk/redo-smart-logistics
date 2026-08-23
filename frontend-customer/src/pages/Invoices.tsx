import { useEffect, useState } from "react";
import {
  Download, FileText, IndianRupee, ShieldCheck, CheckCircle2,
  Clock, AlertCircle, Eye, Printer, X, Check, ArrowUpRight, Landmark, CreditCard
} from "lucide-react";
import Layout from "../components/Layout";
import { useTranslation } from "../lib/i18n";
import { getSharedCargoList } from "../lib/cargoStore";

interface InvoiceItem {
  id: string;
  invoiceNo: string;
  consignmentId: string;
  route: string;
  date: string;
  baseFreightInr: number;
  gstInr: number; // 5% GTA GST
  totalInr: number;
  status: "Paid" | "Pending Clearance";
  truckAssigned: string;
  driverName: string;
  goodsType: string;
}

export default function Invoices() {
  const { t } = useTranslation();
  const [selectedInvoice, setSelectedInvoice] = useState<InvoiceItem | null>(null);
  const [paySuccess, setPaySuccess] = useState<string | null>(null);

  const [invoices, setInvoices] = useState<InvoiceItem[]>([
    {
      id: "INV-001",
      invoiceNo: "REDO/2026/08/042",
      consignmentId: "CARGO-101",
      route: "Delhi NCR (Okhla) ➔ Mumbai (Bhiwandi)",
      date: "20 Aug 2026",
      baseFreightInr: 22000,
      gstInr: 1100,
      totalInr: 23100,
      status: "Paid",
      truckAssigned: "Eicher Pro 17 Feet (HR55 AB 1234)",
      driverName: "Mukesh Yadav",
      goodsType: "Automotive Parts",
    },
    {
      id: "INV-002",
      invoiceNo: "REDO/2026/08/043",
      consignmentId: "CARGO-102",
      route: "Delhi (Kundli) ➔ Indore (Pithampur)",
      date: "21 Aug 2026",
      baseFreightInr: 16000,
      gstInr: 800,
      totalInr: 16800,
      status: "Paid",
      truckAssigned: "BharatBenz 19 Feet (HR55 CD 5678)",
      driverName: "Jaswinder Singh",
      goodsType: "FMCG Packaged Goods",
    },
    {
      id: "INV-003",
      invoiceNo: "REDO/2026/08/044",
      consignmentId: "CARGO-103",
      route: "Bengaluru (Peenya) ➔ Chennai (Sriperumbudur)",
      date: "22 Aug 2026",
      baseFreightInr: 12500,
      gstInr: 625,
      totalInr: 13125,
      status: "Pending Clearance",
      truckAssigned: "Tata 14 Feet (HR55 EF 9012)",
      driverName: "Sanjay Verma",
      goodsType: "Textile Bales",
    },
  ]);

  const totalBilled = invoices.reduce((acc, i) => acc + i.totalInr, 0);
  const totalPaid = invoices.filter(i => i.status === "Paid").reduce((acc, i) => acc + i.totalInr, 0);
  const pendingAmount = invoices.filter(i => i.status === "Pending Clearance").reduce((acc, i) => acc + i.totalInr, 0);

  const handlePayNow = (inv: InvoiceItem) => {
    setPaySuccess(inv.invoiceNo);
    setTimeout(() => {
      setInvoices(prev => prev.map(item => item.id === inv.id ? { ...item, status: "Paid" } : item));
      setPaySuccess(null);
    }, 1500);
  };

  return (
    <Layout>
      <div className="max-w-5xl mx-auto space-y-6 py-4 text-slate-900 dark:text-white">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              {t("invoices")} &amp; GST Invoicing
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Official GST freight tax invoices, automated input tax credit (ITC) bills, and escrow settlements.
            </p>
          </div>

          <button
            onClick={() => window.print()}
            className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-900 dark:text-white font-bold px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
          >
            <Printer size={14} /> Print Statement
          </button>
        </div>

        {/* 3 Stat Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Freight Invoices</span>
            <span className="text-2xl font-black text-slate-900 dark:text-white block">
              ₹{totalBilled.toLocaleString("en-IN")}
            </span>
            <span className="text-[10px] font-bold text-slate-500 block">3 GST Invoices</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Paid Invoices</span>
            <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400 block">
              ₹{totalPaid.toLocaleString("en-IN")}
            </span>
            <span className="text-[10px] font-bold text-emerald-600 block">✓ 100% Tax Compliant</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Pending Escrow Clearance</span>
            <span className="text-2xl font-black text-amber-600 dark:text-amber-400 block">
              ₹{pendingAmount.toLocaleString("en-IN")}
            </span>
            <span className="text-[10px] font-bold text-amber-600 block">1 Consignment Pending</span>
          </div>
        </div>

        {/* Invoices List Card */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
            <h3 className="font-black text-xs uppercase tracking-wider">
              Official Tax Invoices (GST Form GTA)
            </h3>
            <span className="text-[10px] text-slate-400 font-bold">5% GST with ITC Input Tax Credit</span>
          </div>

          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {invoices.map((inv) => (
              <div key={inv.id} className="py-4 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
                <div className="flex items-center gap-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 flex items-center justify-center font-black">
                    <FileText size={18} />
                  </div>
                  <div className="space-y-0.5">
                    <span className="font-mono text-xs font-black text-amber-600 dark:text-amber-400">{inv.invoiceNo}</span>
                    <h4 className="font-black text-xs sm:text-sm text-slate-900 dark:text-white">{inv.route}</h4>
                    <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">
                      {inv.truckAssigned} • {inv.date}
                    </p>
                  </div>
                </div>

                <div className="flex items-center justify-between md:justify-end gap-4 w-full md:w-auto">
                  <div className="text-right">
                    <span className="text-sm sm:text-base font-black text-slate-900 dark:text-white block">
                      ₹{inv.totalInr.toLocaleString("en-IN")}
                    </span>
                    <span className={`inline-block text-[9px] font-black px-2 py-0.5 rounded-full ${
                      inv.status === "Paid"
                        ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400"
                        : "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400"
                    }`}>
                      {inv.status}
                    </span>
                  </div>

                  <div className="flex items-center gap-2">
                    {inv.status === "Pending Clearance" && (
                      <button
                        onClick={() => handlePayNow(inv)}
                        className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-3.5 py-1.5 rounded-xl text-xs shadow-xs cursor-pointer"
                      >
                        Pay Escrow
                      </button>
                    )}
                    <button
                      onClick={() => setSelectedInvoice(inv)}
                      className="p-2 bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-xl transition cursor-pointer"
                      title="View Official Invoice PDF"
                    >
                      <Eye size={16} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* VIEW INVOICE MODAL */}
      {/* ========================================================================= */}
      {selectedInvoice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-lg w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <span className="text-[10px] font-mono text-amber-500 font-bold block">TAX INVOICE</span>
                <h3 className="text-base font-black">{selectedInvoice.invoiceNo}</h3>
              </div>
              <button onClick={() => setSelectedInvoice(null)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400">Route:</span>
                <span>{selectedInvoice.route}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Truck Assigned:</span>
                <span>{selectedInvoice.truckAssigned}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Driver:</span>
                <span>{selectedInvoice.driverName}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Base Freight:</span>
                <span>₹{selectedInvoice.baseFreightInr.toLocaleString("en-IN")}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">GST (5% GTA):</span>
                <span>₹{selectedInvoice.gstInr.toLocaleString("en-IN")}</span>
              </div>
            </div>

            <div className="flex items-center justify-between p-4 bg-amber-500/10 border border-amber-400/40 rounded-2xl">
              <div>
                <span className="text-[10px] uppercase font-bold text-amber-800 dark:text-amber-300 block">Total Freight Amount</span>
                <span className="text-xl font-black text-slate-900 dark:text-white">
                  ₹{selectedInvoice.totalInr.toLocaleString("en-IN")}
                </span>
              </div>
              <span className="bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400 text-xs font-black px-3 py-1 rounded-full">
                ✓ {selectedInvoice.status}
              </span>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => window.print()}
                className="bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-900 dark:text-white font-black px-4 py-2.5 rounded-xl text-xs flex items-center gap-1.5 cursor-pointer"
              >
                <Printer size={14} /> Print PDF
              </button>
              <button
                onClick={() => setSelectedInvoice(null)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm cursor-pointer"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}
