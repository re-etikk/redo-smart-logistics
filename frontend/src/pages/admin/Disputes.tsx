import { useEffect, useState } from "react";
import { ShieldAlert, CheckCircle2, XCircle, FileText, RefreshCw, Scale } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

export default function Disputes() {
  const [loading, setLoading] = useState(true);
  const [disputes, setDisputes] = useState<any[]>([]);
  const [resolvingId, setResolvingId] = useState<string | null>(null);
  const toast = useToast();

  const loadData = () => {
    setLoading(true);
    api.get<any[]>("/admin/disputes")
      .then(res => setDisputes(res || []))
      .catch(() => setDisputes([]))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleResolve = async (id: string, resolutionStatus: string, notes: string) => {
    setResolvingId(id);
    try {
      await api.patch(`/admin/disputes/${id}/resolve`, {
        resolution_status: resolutionStatus,
        notes,
      });
      toast(`Claim ${id.slice(0, 8)} status set to ${resolutionStatus}. Escrow updated.`, "ok");
      loadData();
    } catch (e: any) {
      toast(e?.message || "Could not resolve dispute.", "danger");
    } finally {
      setResolvingId(null);
    }
  };

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Disputes & Escrow Settlement Desk" 
          sub="Review cargo damage claims, verify digital proof of delivery (POD), and authorize escrow releases or refunds." 
        />
        <Button variant="secondary" onClick={loadData} disabled={loading} className="gap-2 self-start md:self-auto">
          <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
          Refresh Claims
        </Button>
      </div>

      {loading ? (
        <div className="mt-6 space-y-4">
          <CardSkeleton /><CardSkeleton />
        </div>
      ) : disputes.length === 0 ? (
        <Card className="mt-6 p-10 text-center border-slate-200">
          <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto mb-3">
            <CheckCircle2 size={24} />
          </div>
          <p className="font-extrabold text-slate-800 text-base">Zero Active Disputes</p>
          <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto">
            All highway corridor deliveries have been verified with delivery OTP and clean Proof of Delivery.
          </p>
        </Card>
      ) : (
        <div className="mt-6 space-y-4">
          {disputes.map(d => {
            const isPending = d.status === 'open' || d.status === 'under_investigation';
            const isProcessing = resolvingId === d.id;

            return (
              <Card key={d.id} className="p-6 border border-slate-200 rounded-2xl bg-white shadow-sm">
                <div className="flex flex-col md:flex-row md:items-start justify-between gap-4 pb-4 border-b border-slate-100">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-xs font-mono bg-rose-50 text-rose-700 px-2.5 py-1 rounded-lg border border-rose-200">
                        Claim #{d.id.slice(0, 8)}
                      </span>
                      <Badge tone={isPending ? "danger" : "ok"}>
                        {d.status.replace('_', ' ').toUpperCase()}
                      </Badge>
                      <span className="text-xs font-bold text-slate-700">
                        Type: {d.claim_type.replace('_', ' ')}
                      </span>
                    </div>

                    <p className="text-sm font-semibold text-slate-900 mt-2">
                      {d.description}
                    </p>
                  </div>

                  <div className="text-right">
                    <p className="text-xs text-slate-500 font-medium">Claimed Amount</p>
                    <p className="text-lg font-black text-rose-600 font-mono">₹{Number(d.claim_amount_inr || 0).toLocaleString('en-IN')}</p>
                  </div>
                </div>

                <div className="mt-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div className="text-xs text-slate-500">
                    <span>Filed by: <strong>{d.filed_by_user?.full_name || 'Shipper'}</strong></span>
                    <span className="mx-2">•</span>
                    <span>Phone: <strong className="font-mono">{d.filed_by_user?.phone || 'N/A'}</strong></span>
                  </div>

                  {isPending && (
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleResolve(d.id, 'resolved_payout', 'POD verified, carrier exonerated')}
                        disabled={isProcessing}
                        className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition flex items-center gap-1.5 shadow-sm"
                      >
                        <CheckCircle2 size={13} />
                        Release to Driver
                      </button>
                      <button
                        onClick={() => handleResolve(d.id, 'resolved_refund', 'Damage confirmed on POD, full shipper refund')}
                        disabled={isProcessing}
                        className="px-3 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition flex items-center gap-1.5 shadow-sm"
                      >
                        <XCircle size={13} />
                        Refund Shipper
                      </button>
                      <button
                        onClick={() => handleResolve(d.id, 'resolved_payout', '50-50 split agreed')}
                        disabled={isProcessing}
                        className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-900 text-amber-400 text-xs font-bold transition flex items-center gap-1.5 shadow-sm"
                      >
                        <Scale size={13} />
                        Split Settle
                      </button>
                    </div>
                  )}

                  {!isPending && d.resolution_notes && (
                    <div className="text-xs text-slate-600 bg-slate-50 px-3 py-1.5 rounded-xl border border-slate-200">
                      <strong>Resolution:</strong> {d.resolution_notes}
                    </div>
                  )}
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </Layout>
  );
}
