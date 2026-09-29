import { useEffect, useState } from "react";
import { 
  FileCheck, ShieldCheck, AlertCircle, RefreshCw, FileText, 
  Truck, User, Calendar, ExternalLink, Check, X
} from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

interface KycRecord {
  id: string;
  user_id: string;
  document_type: string;
  document_reference_masked?: string;
  verification_status: string;
  created_at: string;
  owner_name?: string;
  company_name?: string;
  phone?: string;
}

export default function AdminKyc() {
  const [rows, setRows] = useState<KycRecord[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionBusyId, setActionBusyId] = useState<string | null>(null);
  const toast = useToast();

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await api.get<KycRecord[]>("/admin/kyc");
      setRows(Array.isArray(res) ? res : []);
    } catch (err) {
      console.error('Error fetching KYC documents:', err);
      setRows([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const decide = async (record: KycRecord, status: "verified" | "rejected") => {
    const rejectionReason = status === "rejected"
      ? window.prompt("Reason for rejection")?.trim()
      : undefined;
    if (status === "rejected" && !rejectionReason) return;

    setActionBusyId(record.id);
    try {
      await api.patch(`/admin/kyc/${record.id}/verify`, { status, rejection_reason: rejectionReason });
      toast(`Document ${status === 'verified' ? 'Approved & Truck Verified' : 'Rejected'}`, status === 'verified' ? "ok" : "warn");
      loadData();
    } catch (err: any) {
      toast(err?.message || "Failed to update KYC status", "danger");
    } finally {
      setActionBusyId(null);
    }
  };

  const list = rows ?? [];

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="KYC & Legal Document Verification" 
          sub="Review and approve Commercial Driver Licenses, RC Books, and Carrier Legal Certifications. Approving grants Verified status." 
        />
        <div className="flex items-center gap-2">
          <Button 
            variant="secondary" 
            onClick={loadData} 
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Queue</span>
          </Button>
        </div>
      </div>

      <Card className="mt-5 p-0 bg-slate-900/90 border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {loading ? (
          <div className="p-6"><CardSkeleton /></div>
        ) : list.length === 0 ? (
          <div className="p-12 text-center text-slate-500 space-y-2">
            <ShieldCheck size={36} className="mx-auto text-emerald-500 mb-2" />
            <p className="font-bold text-slate-300">All driver verifications are up to date!</p>
            <p className="text-xs text-slate-500">
              When a new driver completes the onboarding stepper in redo_partner, their documents will appear here for 1-click verification.
            </p>
          </div>
        ) : (
          <div className="divide-y divide-slate-800/60">
            {list.map((r) => {
              const isBusy = actionBusyId === r.id;
              const docTitle = r.document_type.replaceAll("_", " ").toUpperCase();

              return (
                <div key={r.id} className="p-4 sm:p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-slate-800/20 transition">
                  <div className="flex items-start gap-3.5">
                    <div className="w-10 h-10 rounded-xl bg-amber-500/15 border border-amber-500/30 text-amber-400 flex items-center justify-center shrink-0 mt-0.5">
                      <FileText size={20} />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-black text-white text-sm tracking-wide">
                          {docTitle}
                        </span>
                        <Badge tone="warn">Pending Verification</Badge>
                      </div>

                      <p className="text-xs text-slate-300 mt-1 flex items-center gap-2 flex-wrap">
                        <span className="font-bold text-amber-300">{r.owner_name}</span>
                        {r.phone && <span>· <span className="font-mono text-slate-400">{r.phone}</span></span>}
                        <span>· Reference: <span className="font-mono text-white bg-slate-800 px-1.5 py-0.5 rounded">{r.document_reference_masked || 'DOC-PENDING'}</span></span>
                      </p>

                      <p className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
                        <Calendar size={12} />
                        <span>Submitted on {new Date(r.created_at).toLocaleDateString("en-IN", { month: "short", day: "numeric", year: "numeric", hour: "2-digit", minute: "2-digit" })}</span>
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2.5 self-end md:self-auto">
                    <Button
                      onClick={() => decide(r, "verified")}
                      disabled={isBusy}
                      className="bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold py-2 px-3 rounded-xl text-xs flex items-center gap-1.5 shadow-sm shadow-emerald-500/20"
                    >
                      <Check size={14} strokeWidth={3} />
                      <span>{isBusy ? "Approving…" : "Verify & Approve Truck"}</span>
                    </Button>
                    <Button
                      variant="danger"
                      onClick={() => decide(r, "rejected")}
                      disabled={isBusy}
                      className="py-2 px-3 rounded-xl text-xs flex items-center gap-1.5"
                    >
                      <X size={14} />
                      <span>Reject</span>
                    </Button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </Layout>
  );
}
