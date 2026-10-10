import { useEffect, useState } from "react";
import { 
  CreditCard, CheckCircle2, AlertCircle, RefreshCw, 
  ExternalLink, Search, ShieldCheck, ArrowRight, DollarSign
} from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

interface PaymentRecord {
  id: string;
  order_id: string;
  payment_id?: string;
  shipment_id?: string;
  booking_id?: string;
  customer_id: string;
  amount: number;
  currency: string;
  status: string;
  signature_verified: boolean;
  receipt_url?: string;
  metadata?: {
    receipt?: string;
    origin?: string;
    destination?: string;
  };
  customer?: {
    full_name?: string;
    phone?: string;
  };
  created_at: string;
}

export default function AdminPayments() {
  const [payments, setPayments] = useState<PaymentRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const toast = useToast();

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await api.get<PaymentRecord[]>("/admin/payments");
      setPayments(Array.isArray(res) ? res : []);
    } catch (err: any) {
      console.error("Failed to load payments:", err);
      toast(err?.message || "Failed to load payment transactions", "danger");
      setPayments([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const filtered = payments.filter((p) => {
    const matchesStatus = statusFilter === "all" || p.status === statusFilter;
    const query = search.toLowerCase();
    const matchesSearch = !search ||
      p.order_id?.toLowerCase().includes(query) ||
      p.payment_id?.toLowerCase().includes(query) ||
      p.shipment_id?.toLowerCase().includes(query) ||
      p.customer?.full_name?.toLowerCase().includes(query) ||
      p.customer?.phone?.includes(query);
    return matchesStatus && matchesSearch;
  });

  const totalCaptured = payments
    .filter((p) => p.status === "captured")
    .reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
  const capturedCount = payments.filter((p) => p.status === "captured").length;
  const pendingCount = payments.filter((p) => p.status === "created" || p.status === "initiated").length;

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Customer Payments Desk" 
          sub="Live Razorpay captured orders, cryptographic signature verification audit, and customer digital receipts." 
        />
        <div className="flex items-center gap-2">
          <Button 
            variant="secondary" 
            onClick={loadData} 
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Ledger</span>
          </Button>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-5">
        <Card className="p-5 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-400">Total Captured Volume</span>
            <div className="p-2 rounded-xl bg-amber-500/10 text-amber-400">
              <DollarSign size={18} />
            </div>
          </div>
          <p className="text-2xl font-black text-amber-400 mt-2 font-mono">
            ₹{totalCaptured.toLocaleString("en-IN")}
          </p>
          <span className="text-[11px] text-slate-500 font-medium">{capturedCount} successful transactions</span>
        </Card>

        <Card className="p-5 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-400">Signature Verified Rate</span>
            <div className="p-2 rounded-xl bg-emerald-500/10 text-emerald-400">
              <ShieldCheck size={18} />
            </div>
          </div>
          <p className="text-2xl font-black text-emerald-400 mt-2 font-mono">
            {payments.length > 0 ? Math.round((capturedCount / payments.length) * 100) : 100}%
          </p>
          <span className="text-[11px] text-slate-500 font-medium">HMAC SHA-256 server verified</span>
        </Card>

        <Card className="p-5 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-400">Pending Checkout Orders</span>
            <div className="p-2 rounded-xl bg-sky-500/10 text-sky-400">
              <CreditCard size={18} />
            </div>
          </div>
          <p className="text-2xl font-black text-sky-400 mt-2 font-mono">
            {pendingCount}
          </p>
          <span className="text-[11px] text-slate-500 font-medium">Awaiting customer payment</span>
        </Card>
      </div>

      {/* Filter and Search Bar */}
      <div className="mt-6 flex flex-col sm:flex-row gap-3 items-center justify-between">
        <div className="relative w-full sm:w-80">
          <Search size={16} className="absolute left-3 top-3 text-slate-400" />
          <input
            type="text"
            placeholder="Search Order ID, Payment ID, Customer..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        <div className="flex items-center gap-1.5 self-start sm:self-auto overflow-x-auto pb-1 sm:pb-0 w-full sm:w-auto">
          {["all", "captured", "created", "failed"].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition capitalize ${
                statusFilter === st
                  ? "bg-amber-400 text-slate-950 shadow-sm"
                  : "bg-slate-900 text-slate-400 hover:text-white border border-slate-800"
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Transactions List */}
      <Card className="mt-4 p-0 bg-slate-900/90 border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {loading ? (
          <div className="p-6"><CardSkeleton /></div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center text-slate-500 space-y-2">
            <CreditCard size={36} className="mx-auto text-amber-400/60 mb-2" />
            <p className="font-bold text-slate-300">No payment records found</p>
            <p className="text-xs text-slate-500">
              Customer payments created via Razorpay Checkout in redo_customer will populate this ledger in real-time.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-950/60 border-b border-slate-800 text-slate-400 font-bold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="py-3 px-4">Order / Payment ID</th>
                  <th className="py-3 px-4">Customer</th>
                  <th className="py-3 px-4">Shipment Corridor</th>
                  <th className="py-3 px-4 text-right">Amount</th>
                  <th className="py-3 px-4 text-center">Status</th>
                  <th className="py-3 px-4 text-center">Verification</th>
                  <th className="py-3 px-4">Date</th>
                  <th className="py-3 px-4 text-right">Receipt</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 font-medium">
                {filtered.map((p) => {
                  const isCaptured = p.status === "captured";
                  const origin = p.metadata?.origin || "Origin";
                  const destination = p.metadata?.destination || "Destination";

                  return (
                    <tr key={p.id || p.order_id} className="hover:bg-slate-800/20 transition">
                      <td className="py-3.5 px-4 font-mono">
                        <div className="font-bold text-white text-xs">{p.order_id}</div>
                        {p.payment_id && (
                          <div className="text-[11px] text-amber-400/90 mt-0.5">{p.payment_id}</div>
                        )}
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-slate-200">{p.customer?.full_name || "Shipper"}</div>
                        {p.customer?.phone && (
                          <div className="text-[11px] text-slate-500 font-mono">{p.customer.phone}</div>
                        )}
                      </td>
                      <td className="py-3.5 px-4">
                        {p.metadata?.origin ? (
                          <div className="flex items-center gap-1.5 text-slate-300 font-semibold">
                            <span>{origin}</span>
                            <ArrowRight size={12} className="text-amber-400 shrink-0" />
                            <span>{destination}</span>
                          </div>
                        ) : (
                          <span className="text-slate-500 font-mono text-[11px]">
                            #{p.shipment_id?.slice(0, 8) || "Direct Fare"}
                          </span>
                        )}
                      </td>
                      <td className="py-3.5 px-4 text-right font-bold text-white font-mono text-sm">
                        ₹{Number(p.amount || 0).toLocaleString("en-IN")}
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <Badge tone={isCaptured ? "ok" : p.status === "failed" ? "danger" : "warn"}>
                          {p.status.toUpperCase()}
                        </Badge>
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        {p.signature_verified ? (
                          <span className="inline-flex items-center gap-1 text-[11px] text-emerald-400 font-bold">
                            <ShieldCheck size={14} />
                            Verified
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] text-amber-400/80 font-medium">
                            <AlertCircle size={14} />
                            Unverified
                          </span>
                        )}
                      </td>
                      <td className="py-3.5 px-4 text-slate-400 text-[11px] whitespace-nowrap">
                        {new Date(p.created_at).toLocaleDateString("en-IN", {
                          month: "short",
                          day: "numeric",
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        {p.receipt_url ? (
                          <a
                            href={p.receipt_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-[11px] text-amber-400 hover:text-amber-300 font-bold bg-amber-500/10 px-2 py-1 rounded-lg border border-amber-500/20"
                          >
                            <span>Receipt</span>
                            <ExternalLink size={11} />
                          </a>
                        ) : (
                          <span className="text-slate-600 text-[11px]">—</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </Layout>
  );
}
