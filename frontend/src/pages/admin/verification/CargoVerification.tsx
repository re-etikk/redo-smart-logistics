import { useState, useEffect } from "react";
import { 
  FileCheck, ShieldAlert, CheckCircle2, XCircle, AlertTriangle, 
  Search, RefreshCw, Eye, Package, ArrowRight, ShieldCheck, AlertCircle
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface CargoVerificationItem {
  cargo_id: string;
  origin: string;
  destination: string;
  distance_km: number;
  cargo_type: string;
  cargo_weight_tons: number;
  pickup_date: string;
  urgency: string;
  gstin: string | null;
  declared_value_inr: number;
  verification_status: "verified" | "under_review" | "action_required" | "rejected";
  validation_flags: string[];
  documents: any[];
  shipper: {
    id: string;
    name: string;
    company_name: string;
    phone: string;
  };
  created_at: string;
}

export default function CargoVerification() {
  const [cargoList, setCargoList] = useState<CargoVerificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterTab, setFilterTab] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCargo, setSelectedCargo] = useState<CargoVerificationItem | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const fetchCargo = async () => {
    setLoading(true);
    try {
      const data = await api.get<CargoVerificationItem[]>("/admin/verification/cargo");
      setCargoList(data || []);
    } catch (err) {
      console.error("Error fetching cargo verification:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCargo();
  }, []);

  const handleDecision = async (status: string, reason?: string) => {
    if (!selectedCargo) return;
    setSubmitting(true);
    try {
      await api.patch(`/admin/verification/cargo/${selectedCargo.cargo_id}/status`, {
        status,
        reason: reason || `Cargo verification marked as ${status} by Operations`,
      });
      await fetchCargo();
      setSelectedCargo((prev) => prev ? { ...prev, verification_status: status as any } : null);
    } catch (err) {
      console.error("Failed to update cargo status:", err);
    } finally {
      setSubmitting(false);
    }
  };

  const filteredCargo = cargoList.filter((c) => {
    if (filterTab !== "all" && c.verification_status !== filterTab) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        c.cargo_id.toLowerCase().includes(q) ||
        c.origin.toLowerCase().includes(q) ||
        c.destination.toLowerCase().includes(q) ||
        c.shipper?.company_name?.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Cargo & Regulatory Compliance"
            sub="Verify GSTIN credentials, high-value E-Way bill declarations, and hazmat compliance prior to dispatch."
          />
          <Button
            variant="secondary"
            onClick={fetchCargo}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Cargo</span>
          </Button>
        </div>

        {/* Status Filter Tabs */}
        <div className="flex items-center gap-2 border-b border-slate-800 pb-2 text-xs">
          {[
            { id: "all", label: "All Cargo Requests", count: cargoList.length },
            { id: "action_required", label: "Flagged / Action Required", count: cargoList.filter(c => c.verification_status === "action_required").length },
            { id: "under_review", label: "Under Review", count: cargoList.filter(c => c.verification_status === "under_review").length },
            { id: "verified", label: "Verified & Cleared", count: cargoList.filter(c => c.verification_status === "verified").length },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilterTab(tab.id)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl transition ${
                filterTab === tab.id
                  ? "bg-amber-400 text-slate-950 font-bold"
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

        {/* Search Bar */}
        <div className="relative">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search cargo by Cargo ID, corridor, or shipper company..."
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <div className={selectedCargo ? "lg:col-span-7" : "lg:col-span-12"}>
            <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
              {loading ? (
                <div className="p-6"><CardSkeleton /></div>
              ) : filteredCargo.length === 0 ? (
                <div className="text-center py-12 text-slate-500 text-xs">
                  No cargo requests found matching criteria.
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                      <tr>
                        <th className="py-3 px-4">Cargo & Route</th>
                        <th className="py-3 px-4">Shipper</th>
                        <th className="py-3 px-4">Weight / Value</th>
                        <th className="py-3 px-4">Compliance Flags</th>
                        <th className="py-3 px-4">Status</th>
                        <th className="py-3 px-4 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/60">
                      {filteredCargo.map((c) => {
                        const isSelected = selectedCargo?.cargo_id === c.cargo_id;
                        return (
                          <tr
                            key={c.cargo_id}
                            onClick={() => setSelectedCargo(c)}
                            className={`cursor-pointer transition ${
                              isSelected ? "bg-amber-500/10" : "hover:bg-slate-800/40"
                            }`}
                          >
                            <td className="py-3 px-4">
                              <div className="font-bold text-white">#{c.cargo_id.slice(-8)}</div>
                              <div className="text-[11px] text-slate-400">{c.origin} → {c.destination}</div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="text-slate-200 font-semibold">{c.shipper?.company_name || c.shipper?.name}</div>
                              <div className="text-[10px] text-slate-500 font-mono">
                                GSTIN: {c.gstin || "NOT REPORTED"}
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="text-amber-400 font-bold">{c.cargo_weight_tons} Tons</div>
                              <div className="text-[10px] text-slate-400">
                                Declared: ₹{Number(c.declared_value_inr || 0).toLocaleString("en-IN")}
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              {c.validation_flags.length === 0 ? (
                                <span className="text-[10px] text-emerald-400 font-bold flex items-center gap-1">
                                  <CheckCircle2 size={12} />
                                  <span>Clear</span>
                                </span>
                              ) : (
                                <div className="flex flex-wrap gap-1">
                                  {c.validation_flags.map((f, idx) => (
                                    <span key={idx} className="px-1.5 py-0.5 rounded text-[8px] font-black bg-rose-500/20 text-rose-400 border border-rose-500/30">
                                      {f.replace("_", " ")}
                                    </span>
                                  ))}
                                </div>
                              )}
                            </td>
                            <td className="py-3 px-4">
                              <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                                c.verification_status === "verified"
                                  ? "bg-emerald-500/15 text-emerald-400 border border-emerald-500/30"
                                  : c.verification_status === "action_required"
                                  ? "bg-rose-500/15 text-rose-400 border border-rose-500/30"
                                  : "bg-amber-500/15 text-amber-400 border border-amber-500/30"
                              }`}>
                                {c.verification_status.replace("_", " ")}
                              </span>
                            </td>
                            <td className="py-3 px-4 text-right">
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setSelectedCargo(c);
                                }}
                                className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition"
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

          {/* Cargo Detail Drawer */}
          {selectedCargo && (
            <div className="lg:col-span-5">
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900 sticky top-20 shadow-2xl space-y-4">
                <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Commercial Review Dossier</span>
                    <h3 className="text-base font-black text-white font-mono">Cargo #{selectedCargo.cargo_id.slice(-8)}</h3>
                    <p className="text-xs text-slate-400">{selectedCargo.origin} → {selectedCargo.destination}</p>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase ${
                    selectedCargo.verification_status === "verified"
                      ? "bg-emerald-500/20 text-emerald-400 border border-emerald-500/30"
                      : "bg-amber-500/20 text-amber-400 border border-amber-500/30"
                  }`}>
                    {selectedCargo.verification_status.replace("_", " ")}
                  </span>
                </div>

                {/* Shipper & GSTIN Details */}
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Shipper Enterprise</span>
                    <span className="font-bold text-slate-200">{selectedCargo.shipper?.company_name || selectedCargo.shipper?.name}</span>
                  </div>
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Declared Goods Value</span>
                    <span className="font-bold text-amber-400">₹{Number(selectedCargo.declared_value_inr || 0).toLocaleString("en-IN")}</span>
                  </div>
                </div>

                {/* Validation Flag Checklist */}
                <div>
                  <h4 className="text-[11px] font-black uppercase text-slate-400 mb-2">
                    Commercial Regulatory Rules
                  </h4>
                  <div className="space-y-2">
                    <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800 flex items-center justify-between text-xs">
                      <div>
                        <div className="text-slate-300 font-semibold">GSTIN Registration</div>
                        <div className="text-[10px] text-slate-500 font-mono">{selectedCargo.gstin || "Missing GSTIN"}</div>
                      </div>
                      {selectedCargo.gstin ? (
                        <span className="text-emerald-400 text-[10px] font-bold">Valid Format</span>
                      ) : (
                        <span className="text-rose-400 text-[10px] font-bold">Missing</span>
                      )}
                    </div>

                    <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800 flex items-center justify-between text-xs">
                      <div>
                        <div className="text-slate-300 font-semibold">E-Way Bill Mandatory Threshold</div>
                        <div className="text-[10px] text-slate-500">Required if value &gt; ₹50,000</div>
                      </div>
                      {selectedCargo.declared_value_inr > 50000 ? (
                        <span className="text-amber-400 text-[10px] font-bold">E-Way Bill Required</span>
                      ) : (
                        <span className="text-emerald-400 text-[10px] font-bold">Below Threshold</span>
                      )}
                    </div>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="pt-2 border-t border-slate-800 flex items-center gap-2">
                  <button
                    onClick={() => handleDecision("verified")}
                    disabled={submitting || selectedCargo.verification_status === "verified"}
                    className="flex-1 py-2.5 px-3 rounded-xl bg-emerald-500 hover:bg-emerald-600 disabled:opacity-40 text-slate-950 font-black text-xs flex items-center justify-center gap-1.5 transition"
                  >
                    <CheckCircle2 size={14} />
                    <span>Approve for Dispatch</span>
                  </button>
                  <button
                    onClick={() => handleDecision("action_required", "Commercial tax invoice / E-Way bill required")}
                    disabled={submitting}
                    className="py-2.5 px-3 rounded-xl bg-amber-400 hover:bg-amber-500 disabled:opacity-40 text-slate-950 font-black text-xs flex items-center justify-center gap-1.5 transition"
                  >
                    <AlertCircle size={14} />
                    <span>Flag Issue</span>
                  </button>
                </div>
              </Card>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}
