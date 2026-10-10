import { useEffect, useState } from "react";
import { 
  ArrowUpRight, CheckCircle2, Clock, RefreshCw, 
  Send, ShieldCheck, Check, Search, Truck, DollarSign
} from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

interface PayoutRecord {
  id: string;
  booking_id: string;
  partner_id: string;
  amount: number;
  currency: string;
  status: "earned" | "verified" | "payout_pending" | "paid" | "cancelled";
  payout_reference?: string;
  created_at: string;
  processed_at?: string;
  partner?: {
    full_name?: string;
    phone?: string;
  };
  booking?: {
    agreed_price_inr?: number;
    status?: string;
    cargo?: {
      origin?: string;
      destination?: string;
    };
  };
}

export default function AdminPayouts() {
  const [payouts, setPayouts] = useState<PayoutRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionBusyId, setActionBusyId] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState("all");
  const [search, setSearch] = useState("");
  const toast = useToast();

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await api.get<PayoutRecord[]>("/admin/payouts");
      setPayouts(Array.isArray(res) ? res : []);
    } catch (err: any) {
      console.error("Failed to load payouts:", err);
      toast(err?.message || "Failed to load driver payouts", "danger");
      setPayouts([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const updateStatus = async (record: PayoutRecord, newStatus: PayoutRecord["status"]) => {
    let ref = record.payout_reference;
    if (newStatus === "paid") {
      const promptRef = window.prompt("Enter Bank Transfer / IMPS / UPI Reference (UTR):", `UTR-${Date.now().toString().slice(-8)}`);
      if (!promptRef || !promptRef.trim()) return;
      ref = promptRef.trim();
    }

    setActionBusyId(record.id);
    try {
      await api.patch(`/admin/payouts/${record.id}`, {
        status: newStatus,
        transaction_reference: ref,
      });
      toast(`Payout status updated to ${newStatus.toUpperCase()}`, "ok");
      loadData();
    } catch (err: any) {
      toast(err?.message || "Failed to update payout status", "danger");
    } finally {
      setActionBusyId(null);
    }
  };

  const filtered = payouts.filter((p) => {
    const matchesStatus = statusFilter === "all" || p.status === statusFilter;
    const q = search.toLowerCase();
    const matchesSearch = !search ||
      p.id.toLowerCase().includes(q) ||
      p.booking_id.toLowerCase().includes(q) ||
      p.payout_reference?.toLowerCase().includes(q) ||
      p.partner?.full_name?.toLowerCase().includes(q) ||
      p.partner?.phone?.includes(q);
    return matchesStatus && matchesSearch;
  });

  const sumByStatus = (st: string) =>
    payouts.filter((p) => p.status === st).reduce((sum, p) => sum + (Number(p.amount) || 0), 0);

  const earnedTotal = sumByStatus("earned");
  const verifiedTotal = sumByStatus("verified");
  const pendingTotal = sumByStatus("payout_pending");
  const paidTotal = sumByStatus("paid");

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Partner Payouts & Settlement Desk" 
          sub="Manage the 4-stage partner payout lifecycle: EARNED → VERIFIED → PAYOUT PENDING → PAID with bank reference reconciliation." 
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

      {/* 4-Stage Lifecycle Metric Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 mt-5">
        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <span className="text-[11px] font-bold text-slate-400">1. Earned (Delivery Logged)</span>
          <p className="text-xl font-black text-amber-400 mt-1 font-mono">
            ₹{earnedTotal.toLocaleString("en-IN")}
          </p>
          <span className="text-[10px] text-slate-500 font-medium">Awaiting Ops audit</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <span className="text-[11px] font-bold text-slate-400">2. Verified (Audited)</span>
          <p className="text-xl font-black text-sky-400 mt-1 font-mono">
            ₹{verifiedTotal.toLocaleString("en-IN")}
          </p>
          <span className="text-[10px] text-slate-500 font-medium">Ready for disbursement</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <span className="text-[11px] font-bold text-slate-400">3. Payout Pending</span>
          <p className="text-xl font-black text-indigo-400 mt-1 font-mono">
            ₹{pendingTotal.toLocaleString("en-IN")}
          </p>
          <span className="text-[10px] text-slate-500 font-medium">Banking transfer queued</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <span className="text-[11px] font-bold text-slate-400">4. Paid & Settled</span>
          <p className="text-xl font-black text-emerald-400 mt-1 font-mono">
            ₹{paidTotal.toLocaleString("en-IN")}
          </p>
          <span className="text-[10px] text-slate-500 font-medium">Settled to bank accounts</span>
        </Card>
      </div>

      {/* Filter and Search Bar */}
      <div className="mt-6 flex flex-col sm:flex-row gap-3 items-center justify-between">
        <div className="relative w-full sm:w-80">
          <Search size={16} className="absolute left-3 top-3 text-slate-400" />
          <input
            type="text"
            placeholder="Search Driver, Phone, Payout Ref..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        <div className="flex items-center gap-1.5 self-start sm:self-auto overflow-x-auto pb-1 sm:pb-0 w-full sm:w-auto">
          {["all", "earned", "verified", "payout_pending", "paid"].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition capitalize ${
                statusFilter === st
                  ? "bg-amber-400 text-slate-950 shadow-sm"
                  : "bg-slate-900 text-slate-400 hover:text-white border border-slate-800"
              }`}
            >
              {st.replace("_", " ")}
            </button>
          ))}
        </div>
      </div>

      {/* Payouts Table */}
      <Card className="mt-4 p-0 bg-slate-900/90 border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {loading ? (
          <div className="p-6"><CardSkeleton /></div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center text-slate-500 space-y-2">
            <DollarSign size={36} className="mx-auto text-amber-400/60 mb-2" />
            <p className="font-bold text-slate-300">No driver payouts in this queue</p>
            <p className="text-xs text-slate-500">
              When drivers complete trip deliveries in redo_partner, earned payout records are recorded here automatically.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-950/60 border-b border-slate-800 text-slate-400 font-bold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="py-3 px-4">Payout Ref / ID</th>
                  <th className="py-3 px-4">Driver Partner</th>
                  <th className="py-3 px-4">Trip Lane</th>
                  <th className="py-3 px-4 text-right">Net Payout</th>
                  <th className="py-3 px-4 text-center">Lifecycle Status</th>
                  <th className="py-3 px-4">Date</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 font-medium">
                {filtered.map((p) => {
                  const isBusy = actionBusyId === p.id;
                  const origin = p.booking?.cargo?.origin || "Origin";
                  const destination = p.booking?.cargo?.destination || "Destination";

                  return (
                    <tr key={p.id} className="hover:bg-slate-800/20 transition">
                      <td className="py-3.5 px-4 font-mono">
                        <div className="font-bold text-white text-xs">{p.payout_reference || `PAY-${p.id.slice(0, 8)}`}</div>
                        <div className="text-[11px] text-slate-500 mt-0.5">Booking #{p.booking_id.slice(0, 8)}</div>
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-slate-200">{p.partner?.full_name || "Driver Partner"}</div>
                        {p.partner?.phone && (
                          <div className="text-[11px] text-slate-500 font-mono">{p.partner.phone}</div>
                        )}
                      </td>
                      <td className="py-3.5 px-4">
                        <span className="text-slate-300 font-semibold">{origin} → {destination}</span>
                      </td>
                      <td className="py-3.5 px-4 text-right font-bold text-amber-400 font-mono text-sm">
                        ₹{Number(p.amount || 0).toLocaleString("en-IN")}
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <Badge tone={p.status === "paid" ? "ok" : p.status === "payout_pending" ? "accent" : p.status === "verified" ? "accent" : "warn"}>
                          {p.status.toUpperCase().replace("_", " ")}
                        </Badge>
                      </td>
                      <td className="py-3.5 px-4 text-slate-400 text-[11px] whitespace-nowrap">
                        {new Date(p.created_at).toLocaleDateString("en-IN", {
                          month: "short",
                          day: "numeric",
                        })}
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        {p.status === "earned" && (
                          <button
                            onClick={() => updateStatus(p, "verified")}
                            disabled={isBusy}
                            className="px-2.5 py-1 rounded-lg bg-sky-500/20 border border-sky-500/30 text-sky-300 hover:bg-sky-500/30 text-xs font-bold transition flex items-center gap-1 ml-auto"
                          >
                            <ShieldCheck size={12} />
                            <span>Verify Payout</span>
                          </button>
                        )}
                        {p.status === "verified" && (
                          <button
                            onClick={() => updateStatus(p, "payout_pending")}
                            disabled={isBusy}
                            className="px-2.5 py-1 rounded-lg bg-indigo-500/20 border border-indigo-500/30 text-indigo-300 hover:bg-indigo-500/30 text-xs font-bold transition flex items-center gap-1 ml-auto"
                          >
                            <Clock size={12} />
                            <span>Queue for Bank</span>
                          </button>
                        )}
                        {p.status === "payout_pending" && (
                          <button
                            onClick={() => updateStatus(p, "paid")}
                            disabled={isBusy}
                            className="px-2.5 py-1 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-slate-950 text-xs font-black transition flex items-center gap-1 ml-auto shadow-sm"
                          >
                            <Check size={12} strokeWidth={3} />
                            <span>Mark Paid</span>
                          </button>
                        )}
                        {p.status === "paid" && (
                          <span className="inline-flex items-center gap-1 text-[11px] text-emerald-400 font-bold">
                            <CheckCircle2 size={13} />
                            Settled
                          </span>
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
