import { useState, useEffect } from "react";
import { 
  ShieldCheck, ShieldAlert, AlertCircle, CheckCircle2, XCircle, Clock, 
  FileText, Truck, Search, Filter, RefreshCw, Eye, ArrowRight, UserCheck, Phone, Building2
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface PartnerItem {
  id: string;
  name: string;
  company_name: string;
  phone: string;
  status: "pending" | "under_review" | "action_required" | "verified" | "rejected" | "suspended";
  account_status: string;
  risk_level: "low" | "medium" | "high";
  submitted_date: string;
  documents: {
    id: string;
    type: string;
    reference_masked: string;
    status: string;
    rejection_reason?: string;
  }[];
  registered_trucks_count: number;
  verified_trucks_count: number;
}

export default function PartnerVerification() {
  const [partners, setPartners] = useState<PartnerItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterTab, setFilterTab] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedPartner, setSelectedPartner] = useState<PartnerItem | null>(null);
  const [actionModal, setActionModal] = useState<"verify" | "action_required" | "reject" | "suspend" | null>(null);
  const [reasonInput, setReasonInput] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const fetchPartners = async () => {
    setLoading(true);
    try {
      const data = await api.get<PartnerItem[]>("/admin/verification/partners");
      setPartners(data || []);
    } catch (err) {
      console.error("Error fetching partners:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPartners();
  }, []);

  const handleDecision = async (status: string) => {
    if (!selectedPartner) return;
    setSubmitting(true);
    try {
      await api.patch(`/admin/verification/partners/${selectedPartner.id}/status`, {
        status,
        reason: reasonInput,
        notes: reasonInput,
      });
      setActionModal(null);
      setReasonInput("");
      await fetchPartners();
      // Update selected partner locally
      setSelectedPartner((prev) => prev ? { ...prev, status: status as any } : null);
    } catch (err) {
      console.error("Failed to update partner verification:", err);
    } finally {
      setSubmitting(false);
    }
  };

  const filteredPartners = partners.filter((p) => {
    if (filterTab !== "all" && p.status !== filterTab) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        p.name.toLowerCase().includes(q) ||
        p.company_name.toLowerCase().includes(q) ||
        p.phone?.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "verified":
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">VERIFIED</span>;
      case "under_review":
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-sky-500/15 text-sky-400 border border-sky-500/30">UNDER REVIEW</span>;
      case "action_required":
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/15 text-amber-400 border border-amber-500/30">ACTION REQUIRED</span>;
      case "rejected":
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-500/15 text-rose-400 border border-rose-500/30">REJECTED</span>;
      case "suspended":
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-purple-500/15 text-purple-400 border border-purple-500/30">SUSPENDED</span>;
      default:
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-500/15 text-slate-400 border border-slate-500/30">PENDING</span>;
    }
  };

  const getRiskBadge = (risk: string) => {
    switch (risk) {
      case "low":
        return <span className="text-[10px] font-bold text-emerald-400">LOW</span>;
      case "high":
        return <span className="text-[10px] font-bold text-rose-400">HIGH</span>;
      default:
        return <span className="text-[10px] font-bold text-amber-400">MEDIUM</span>;
    }
  };

  return (
    <Layout>
      <div className="space-y-5">
        {/* Page Head */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Partner Verification Center"
            sub="Comprehensive regulatory, KYC, and fleet credential verification for commercial truck operators."
          />
          <Button
            variant="secondary"
            onClick={fetchPartners}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Roster</span>
          </Button>
        </div>

        {/* Status Filter Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 no-scrollbar border-b border-slate-800 text-xs font-semibold">
          {[
            { id: "all", label: "All Partners", count: partners.length },
            { id: "pending", label: "Pending", count: partners.filter(p => p.status === "pending").length },
            { id: "under_review", label: "Under Review", count: partners.filter(p => p.status === "under_review").length },
            { id: "action_required", label: "Action Required", count: partners.filter(p => p.status === "action_required").length },
            { id: "verified", label: "Verified", count: partners.filter(p => p.status === "verified").length },
            { id: "rejected", label: "Rejected", count: partners.filter(p => p.status === "rejected").length },
            { id: "suspended", label: "Suspended", count: partners.filter(p => p.status === "suspended").length },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilterTab(tab.id)}
              className={`flex items-center gap-2 px-3 py-2 rounded-xl transition ${
                filterTab === tab.id
                  ? "bg-amber-400 text-slate-950 font-bold shadow-xs"
                  : "text-slate-400 hover:text-white hover:bg-slate-900"
              }`}
            >
              <span>{tab.label}</span>
              <span className={`px-1.5 py-0.2 rounded-full text-[10px] font-black ${
                filterTab === tab.id ? "bg-slate-950 text-amber-400" : "bg-slate-800 text-slate-400"
              }`}>
                {tab.count}
              </span>
            </button>
          ))}
        </div>

        {/* Search & Actions Bar */}
        <div className="flex items-center gap-3">
          <div className="flex-1 relative">
            <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search partner by name, fleet company, or phone..."
              className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
            />
          </div>
        </div>

        {/* Main Content: Table & Detail Drawer */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Partners Table */}
          <div className={selectedPartner ? "lg:col-span-7" : "lg:col-span-12"}>
            <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
              {loading ? (
                <div className="p-6"><CardSkeleton /></div>
              ) : filteredPartners.length === 0 ? (
                <div className="text-center py-12 text-slate-500 text-xs">
                  No partners found matching the selected filter.
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                      <tr>
                        <th className="py-3 px-4">Partner & Fleet</th>
                        <th className="py-3 px-4">Phone</th>
                        <th className="py-3 px-4">Status</th>
                        <th className="py-3 px-4">Risk</th>
                        <th className="py-3 px-4">Trucks</th>
                        <th className="py-3 px-4 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/60">
                      {filteredPartners.map((p) => {
                        const isSelected = selectedPartner?.id === p.id;
                        return (
                          <tr
                            key={p.id}
                            onClick={() => setSelectedPartner(p)}
                            className={`cursor-pointer transition ${
                              isSelected ? "bg-amber-500/10" : "hover:bg-slate-800/40"
                            }`}
                          >
                            <td className="py-3 px-4">
                              <div className="font-bold text-white">{p.name}</div>
                              <div className="text-[11px] text-slate-400">{p.company_name}</div>
                            </td>
                            <td className="py-3 px-4 text-slate-300 font-mono text-[11px]">
                              {p.phone ? p.phone.replace(/(\+91\d{2})\d{4}(\d{4})/, "$1••••$2") : "—"}
                            </td>
                            <td className="py-3 px-4">{getStatusBadge(p.status)}</td>
                            <td className="py-3 px-4">{getRiskBadge(p.risk_level)}</td>
                            <td className="py-3 px-4 text-slate-300">
                              <span className="font-bold text-amber-400">{p.verified_trucks_count}</span>
                              <span className="text-slate-500"> / {p.registered_trucks_count}</span>
                            </td>
                            <td className="py-3 px-4 text-right">
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setSelectedPartner(p);
                                }}
                                className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition"
                                title="Inspect Details"
                              >
                                <Eye size={14} />
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </Card>
          </div>

          {/* Partner Detail Drawer */}
          {selectedPartner && (
            <div className="lg:col-span-5">
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900 sticky top-20 shadow-2xl space-y-4">
                {/* Header */}
                <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Partner Dossier</span>
                    <h3 className="text-base font-black text-white">{selectedPartner.name}</h3>
                    <p className="text-xs text-slate-400">{selectedPartner.company_name}</p>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    {getStatusBadge(selectedPartner.status)}
                    <span className="text-[10px] text-slate-500">Risk: {selectedPartner.risk_level.toUpperCase()}</span>
                  </div>
                </div>

                {/* Contact & Registration Info */}
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Phone (Masked)</span>
                    <span className="font-mono text-slate-300">{selectedPartner.phone || "Not recorded"}</span>
                  </div>
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Fleet Capacity</span>
                    <span className="font-bold text-amber-400">{selectedPartner.registered_trucks_count} Commercial Trucks</span>
                  </div>
                </div>

                {/* Submitted Documents Checklist */}
                <div>
                  <h4 className="text-[11px] font-black uppercase text-slate-400 mb-2">
                    Submitted Regulatory Documents
                  </h4>
                  {selectedPartner.documents.length === 0 ? (
                    <div className="p-3 rounded-xl bg-slate-950/40 border border-slate-800 text-xs text-slate-500 text-center">
                      No KYC documents uploaded yet.
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {selectedPartner.documents.map((doc) => (
                        <div key={doc.id} className="p-2.5 rounded-xl bg-slate-950/70 border border-slate-800 flex items-center justify-between">
                          <div>
                            <div className="text-xs font-bold text-slate-200 capitalize">
                              {doc.type.replace("_", " ")}
                            </div>
                            <div className="text-[10px] text-slate-500 font-mono">
                              Ref: {doc.reference_masked}
                            </div>
                          </div>
                          <span className={`px-2 py-0.5 rounded text-[9px] font-bold uppercase ${
                            doc.status === "verified"
                              ? "bg-emerald-500/20 text-emerald-400"
                              : doc.status === "rejected"
                              ? "bg-rose-500/20 text-rose-400"
                              : "bg-amber-500/20 text-amber-400"
                          }`}>
                            {doc.status}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Operational Decision Buttons */}
                <div className="pt-2 border-t border-slate-800 space-y-2">
                  <div className="text-[10px] font-black uppercase text-slate-500">
                    Administrator Workflow Actions
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => handleDecision("verified")}
                      disabled={submitting || selectedPartner.status === "verified"}
                      className="py-2.5 px-3 rounded-xl bg-emerald-500 hover:bg-emerald-600 disabled:opacity-40 text-slate-950 font-black text-xs flex items-center justify-center gap-1.5 transition"
                    >
                      <UserCheck size={14} />
                      <span>Approve & Verify</span>
                    </button>
                    <button
                      onClick={() => setActionModal("action_required")}
                      disabled={submitting}
                      className="py-2.5 px-3 rounded-xl bg-amber-400 hover:bg-amber-500 disabled:opacity-40 text-slate-950 font-black text-xs flex items-center justify-center gap-1.5 transition"
                    >
                      <AlertCircle size={14} />
                      <span>Require Action</span>
                    </button>
                    <button
                      onClick={() => setActionModal("reject")}
                      disabled={submitting}
                      className="py-2 px-3 rounded-xl bg-slate-800 hover:bg-rose-500/20 hover:text-rose-400 text-slate-300 font-bold text-xs flex items-center justify-center gap-1.5 transition border border-slate-700"
                    >
                      <XCircle size={14} />
                      <span>Reject</span>
                    </button>
                    <button
                      onClick={() => setActionModal("suspend")}
                      disabled={submitting}
                      className="py-2 px-3 rounded-xl bg-slate-800 hover:bg-purple-500/20 hover:text-purple-400 text-slate-300 font-bold text-xs flex items-center justify-center gap-1.5 transition border border-slate-700"
                    >
                      <ShieldAlert size={14} />
                      <span>Suspend</span>
                    </button>
                  </div>
                </div>
              </Card>
            </div>
          )}
        </div>

        {/* Modal for Reject / Action Required / Suspend Reason */}
        {actionModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs">
            <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-2xl space-y-4">
              <h3 className="text-sm font-black text-white capitalize">
                {actionModal.replace("_", " ")} Partner
              </h3>
              <p className="text-xs text-slate-400">
                Please provide specific operational rationale. This will be recorded in the immutable audit log and transmitted to the partner.
              </p>
              <textarea
                value={reasonInput}
                onChange={(e) => setReasonInput(e.target.value)}
                placeholder="Reason or corrective instructions..."
                rows={3}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
              />
              <div className="flex justify-end gap-2">
                <Button variant="secondary" onClick={() => setActionModal(null)}>
                  Cancel
                </Button>
                <button
                  onClick={() => handleDecision(actionModal)}
                  disabled={submitting || !reasonInput.trim()}
                  className="px-4 py-2 rounded-xl bg-amber-400 hover:bg-amber-500 disabled:opacity-40 text-slate-950 font-black text-xs transition"
                >
                  Confirm Decision
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
}
