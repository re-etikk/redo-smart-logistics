import { useState, useEffect } from "react";
import { 
  FileText, ShieldCheck, AlertTriangle, Clock, Search, RefreshCw, 
  Eye, Check, X, Filter, Calendar, ExternalLink
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface DocumentItem {
  id: string;
  category: "partner" | "vehicle" | "cargo";
  document_type: string;
  entity_id: string;
  entity_label: string;
  contact_phone?: string;
  reference_number: string;
  status: "verified" | "pending" | "under_review" | "rejected" | "expired";
  expiry_date: string | null;
  created_at: string;
}

export default function Documents() {
  const [docs, setDocs] = useState<DocumentItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterTab, setFilterTab] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedDoc, setSelectedDoc] = useState<DocumentItem | null>(null);
  const [reviewModal, setReviewModal] = useState<boolean>(false);
  const [decisionStatus, setDecisionStatus] = useState<"verified" | "rejected">("verified");
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const fetchDocs = async () => {
    setLoading(true);
    try {
      const data = await api.get<DocumentItem[]>(`/admin/verification/documents?filter=${filterTab}`);
      setDocs(data || []);
    } catch (err) {
      console.error("Error fetching documents:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDocs();
  }, [filterTab]);

  const handleReview = async () => {
    if (!selectedDoc) return;
    setSubmitting(true);
    try {
      await api.patch(`/admin/verification/documents/${selectedDoc.id}/review`, {
        category: selectedDoc.category,
        status: decisionStatus,
        reason: notes,
      });
      setReviewModal(false);
      setNotes("");
      await fetchDocs();
      setSelectedDoc(null);
    } catch (err) {
      console.error("Failed to review document:", err);
    } finally {
      setSubmitting(false);
    }
  };

  const filteredDocs = docs.filter((d) => {
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        d.entity_label.toLowerCase().includes(q) ||
        d.document_type.toLowerCase().includes(q) ||
        d.reference_number.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Universal Document Registry"
            sub="Central repository for commercial driving licenses, vehicle RC books, fitness certificates, permits, and E-Way bills."
          />
          <Button
            variant="secondary"
            onClick={fetchDocs}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Vault</span>
          </Button>
        </div>

        {/* Filter Tabs */}
        <div className="flex items-center gap-2 border-b border-slate-800 pb-2 text-xs">
          {[
            { id: "all", label: "All Documents" },
            { id: "pending", label: "Pending Review" },
            { id: "expired", label: "Expired & Expiring" },
            { id: "verified", label: "Verified Documents" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilterTab(tab.id)}
              className={`px-3 py-1.5 rounded-xl transition ${
                filterTab === tab.id
                  ? "bg-amber-400 text-slate-950 font-bold"
                  : "text-slate-400 hover:text-white hover:bg-slate-900"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by document type, vehicle number, or partner name..."
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        {/* Document Registry Table */}
        <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
          {loading ? (
            <div className="p-6"><CardSkeleton /></div>
          ) : filteredDocs.length === 0 ? (
            <div className="text-center py-12 text-slate-500 text-xs">
              No documents found matching the filter.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Document Type</th>
                    <th className="py-3 px-4">Category</th>
                    <th className="py-3 px-4">Associated Entity</th>
                    <th className="py-3 px-4">Reference / Serial</th>
                    <th className="py-3 px-4">Expiry Date</th>
                    <th className="py-3 px-4">Status</th>
                    <th className="py-3 px-4 text-right">Review</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {filteredDocs.map((doc) => (
                    <tr key={doc.id} className="hover:bg-slate-800/40 transition">
                      <td className="py-3 px-4">
                        <div className="font-bold text-white capitalize">{doc.document_type.replace("_", " ")}</div>
                        <div className="text-[10px] text-slate-500">ID: {doc.id.slice(-6)}</div>
                      </td>
                      <td className="py-3 px-4">
                        <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-slate-800 text-slate-300">
                          {doc.category}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <div className="text-slate-200 font-semibold">{doc.entity_label}</div>
                        {doc.contact_phone && (
                          <div className="text-[10px] text-slate-500 font-mono">
                            {doc.contact_phone.replace(/(\+91\d{2})\d{4}(\d{4})/, "$1••••$2")}
                          </div>
                        )}
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-300 text-[11px]">
                        {doc.reference_number}
                      </td>
                      <td className="py-3 px-4 text-slate-400">
                        {doc.expiry_date ? (
                          <span className={new Date(doc.expiry_date) < new Date() ? "text-rose-400 font-bold" : "text-slate-300"}>
                            {doc.expiry_date}
                          </span>
                        ) : (
                          "—"
                        )}
                      </td>
                      <td className="py-3 px-4">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                          doc.status === "verified"
                            ? "bg-emerald-500/15 text-emerald-400 border border-emerald-500/30"
                            : doc.status === "expired"
                            ? "bg-rose-500/15 text-rose-400 border border-rose-500/30"
                            : "bg-amber-500/15 text-amber-400 border border-amber-500/30"
                        }`}>
                          {doc.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-right">
                        <button
                          onClick={() => {
                            setSelectedDoc(doc);
                            setReviewModal(true);
                          }}
                          className="px-2.5 py-1 rounded-lg bg-amber-400 hover:bg-amber-500 text-slate-950 font-bold text-[11px] transition"
                        >
                          Review
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>

        {/* Review Modal */}
        {reviewModal && selectedDoc && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs">
            <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-2xl space-y-4">
              <h3 className="text-sm font-black text-white">
                Review {selectedDoc.document_type.replace("_", " ").toUpperCase()}
              </h3>
              <p className="text-xs text-slate-400">
                Entity: <span className="font-bold text-slate-200">{selectedDoc.entity_label}</span> • Ref: <span className="font-mono text-slate-300">{selectedDoc.reference_number}</span>
              </p>

              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setDecisionStatus("verified")}
                  className={`py-2 px-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5 ${
                    decisionStatus === "verified"
                      ? "bg-emerald-500 text-slate-950 font-black"
                      : "bg-slate-800 text-slate-400"
                  }`}
                >
                  <Check size={14} />
                  <span>Verify Document</span>
                </button>
                <button
                  type="button"
                  onClick={() => setDecisionStatus("rejected")}
                  className={`py-2 px-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5 ${
                    decisionStatus === "rejected"
                      ? "bg-rose-500 text-white font-black"
                      : "bg-slate-800 text-slate-400"
                  }`}
                >
                  <X size={14} />
                  <span>Reject</span>
                </button>
              </div>

              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Review notes or rejection reason..."
                rows={3}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
              />

              <div className="flex justify-end gap-2">
                <Button variant="secondary" onClick={() => setReviewModal(false)}>
                  Cancel
                </Button>
                <button
                  onClick={handleReview}
                  disabled={submitting}
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
