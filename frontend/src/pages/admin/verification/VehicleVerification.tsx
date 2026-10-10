import { useState, useEffect } from "react";
import { 
  Truck, ShieldCheck, ShieldAlert, CheckCircle2, XCircle, AlertTriangle, 
  FileText, Search, RefreshCw, Eye, Check, ExternalLink, Calendar
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface VehicleItem {
  truck_id: string;
  registration_number: string;
  truck_type: string;
  body_type: string;
  default_capacity_tons: number;
  driver_rating: number;
  operational_status: string;
  verification_status: "verified" | "pending" | "action_required" | "rejected" | "expired";
  verified_documents: boolean;
  owner: {
    id: string;
    name: string;
    company_name: string;
    phone: string;
  };
  checklist: {
    rc_book: boolean;
    insurance: boolean;
    fitness: boolean;
    permit: boolean;
    puc: boolean;
  };
  documents: any[];
  created_at: string;
}

export default function VehicleVerification() {
  const [vehicles, setVehicles] = useState<VehicleItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterTab, setFilterTab] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleItem | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const fetchVehicles = async () => {
    setLoading(true);
    try {
      const data = await api.get<VehicleItem[]>("/admin/verification/vehicles");
      setVehicles(data || []);
    } catch (err) {
      console.error("Error fetching vehicles:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVehicles();
  }, []);

  const handleVerifyToggle = async (truckId: string, verify: boolean) => {
    setSubmitting(true);
    try {
      await api.patch(`/admin/verification/vehicles/${truckId}/status`, {
        status: verify ? "verified" : "rejected",
        verified_documents: verify,
        notes: verify ? "All vehicle documents verified by Operations" : "Vehicle documents flagged for correction",
      });
      await fetchVehicles();
      if (selectedVehicle?.truck_id === truckId) {
        setSelectedVehicle((prev) => prev ? {
          ...prev,
          verified_documents: verify,
          verification_status: verify ? "verified" : "rejected"
        } : null);
      }
    } catch (err) {
      console.error("Failed to update vehicle status:", err);
    } finally {
      setSubmitting(false);
    }
  };

  const filteredVehicles = vehicles.filter((v) => {
    if (filterTab === "verified" && !v.verified_documents) return false;
    if (filterTab === "pending" && v.verified_documents) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        v.registration_number.toLowerCase().includes(q) ||
        v.owner?.name?.toLowerCase().includes(q) ||
        v.truck_type?.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Vehicle Commercial Compliance"
            sub="Inspect RC, commercial fitness, national permits, and commercial insurance for roadworthiness."
          />
          <Button
            variant="secondary"
            onClick={fetchVehicles}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Fleet</span>
          </Button>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-2 border-b border-slate-800 pb-2 text-xs">
          {[
            { id: "all", label: "All Vehicles", count: vehicles.length },
            { id: "pending", label: "Pending Verification", count: vehicles.filter(v => !v.verified_documents).length },
            { id: "verified", label: "Certified Roadworthy", count: vehicles.filter(v => v.verified_documents).length },
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
            placeholder="Search vehicle by registration number, model, or partner name..."
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        {/* Grid / Table Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <div className={selectedVehicle ? "lg:col-span-7" : "lg:col-span-12"}>
            <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
              {loading ? (
                <div className="p-6"><CardSkeleton /></div>
              ) : filteredVehicles.length === 0 ? (
                <div className="text-center py-12 text-slate-500 text-xs">
                  No vehicles found.
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                      <tr>
                        <th className="py-3 px-4">Registration</th>
                        <th className="py-3 px-4">Specifications</th>
                        <th className="py-3 px-4">Operator</th>
                        <th className="py-3 px-4">Document Check</th>
                        <th className="py-3 px-4">Status</th>
                        <th className="py-3 px-4 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/60">
                      {filteredVehicles.map((v) => {
                        const isSelected = selectedVehicle?.truck_id === v.truck_id;
                        return (
                          <tr
                            key={v.truck_id}
                            onClick={() => setSelectedVehicle(v)}
                            className={`cursor-pointer transition ${
                              isSelected ? "bg-amber-500/10" : "hover:bg-slate-800/40"
                            }`}
                          >
                            <td className="py-3 px-4 font-mono font-bold text-white">
                              {v.registration_number}
                            </td>
                            <td className="py-3 px-4">
                              <div className="text-slate-200 font-semibold">{v.truck_type}</div>
                              <div className="text-[11px] text-slate-400">{v.default_capacity_tons} Tons • {v.body_type}</div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="text-slate-300 font-medium">{v.owner?.name}</div>
                              <div className="text-[10px] text-slate-500">{v.owner?.company_name}</div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="flex items-center gap-1">
                                {["RC", "INS", "FIT", "PMT"].map((docName, idx) => {
                                  const isChecked = v.verified_documents;
                                  return (
                                    <span
                                      key={idx}
                                      className={`px-1.5 py-0.5 rounded text-[9px] font-black ${
                                        isChecked
                                          ? "bg-emerald-500/20 text-emerald-400 border border-emerald-500/30"
                                          : "bg-slate-800 text-slate-500 border border-slate-700"
                                      }`}
                                    >
                                      {docName}
                                    </span>
                                  );
                                })}
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              {v.verified_documents ? (
                                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
                                  CERTIFIED
                                </span>
                              ) : (
                                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/15 text-amber-400 border border-amber-500/30">
                                  PENDING
                                </span>
                              )}
                            </td>
                            <td className="py-3 px-4 text-right">
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setSelectedVehicle(v);
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

          {/* Vehicle Detail Drawer */}
          {selectedVehicle && (
            <div className="lg:col-span-5">
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900 sticky top-20 shadow-2xl space-y-4">
                <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Vehicle Technical Card</span>
                    <h3 className="text-base font-black text-white font-mono">{selectedVehicle.registration_number}</h3>
                    <p className="text-xs text-slate-400">{selectedVehicle.truck_type} • {selectedVehicle.body_type}</p>
                  </div>
                  {selectedVehicle.verified_documents ? (
                    <span className="px-2.5 py-1 rounded-full text-[10px] font-black bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                      CERTIFIED
                    </span>
                  ) : (
                    <span className="px-2.5 py-1 rounded-full text-[10px] font-black bg-amber-500/20 text-amber-400 border border-amber-500/30">
                      ACTION REQUIRED
                    </span>
                  )}
                </div>

                {/* Specs */}
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Payload Capacity</span>
                    <span className="font-bold text-amber-400">{selectedVehicle.default_capacity_tons} Metric Tons</span>
                  </div>
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Registered Partner</span>
                    <span className="font-semibold text-slate-200">{selectedVehicle.owner?.name}</span>
                  </div>
                </div>

                {/* Document Verification Checklist */}
                <div>
                  <h4 className="text-[11px] font-black uppercase text-slate-400 mb-2">
                    Commercial Compliance Checklist
                  </h4>
                  <div className="space-y-2">
                    {[
                      { name: "RC Book (Registration Certificate)", valid: selectedVehicle.verified_documents },
                      { name: "Commercial Vehicle Insurance", valid: selectedVehicle.verified_documents },
                      { name: "Fitness Certificate (Form 38)", valid: selectedVehicle.verified_documents },
                      { name: "All India Commercial Goods Permit", valid: selectedVehicle.verified_documents },
                      { name: "Pollution Under Control (PUC)", valid: selectedVehicle.verified_documents },
                    ].map((item, idx) => (
                      <div key={idx} className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800 flex items-center justify-between text-xs">
                        <span className="text-slate-300">{item.name}</span>
                        {item.valid ? (
                          <span className="flex items-center gap-1 text-[11px] font-bold text-emerald-400">
                            <CheckCircle2 size={14} />
                            <span>Verified</span>
                          </span>
                        ) : (
                          <span className="flex items-center gap-1 text-[11px] font-bold text-amber-400">
                            <AlertTriangle size={14} />
                            <span>Pending Review</span>
                          </span>
                        )}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Verification Actions */}
                <div className="pt-2 border-t border-slate-800 flex items-center gap-2">
                  <button
                    onClick={() => handleVerifyToggle(selectedVehicle.truck_id, true)}
                    disabled={submitting || selectedVehicle.verified_documents}
                    className="flex-1 py-2.5 px-3 rounded-xl bg-emerald-500 hover:bg-emerald-600 disabled:opacity-40 text-slate-950 font-black text-xs flex items-center justify-center gap-1.5 transition"
                  >
                    <Check size={14} />
                    <span>Approve Commercial Clearance</span>
                  </button>
                  <button
                    onClick={() => handleVerifyToggle(selectedVehicle.truck_id, false)}
                    disabled={submitting || !selectedVehicle.verified_documents}
                    className="py-2.5 px-3 rounded-xl bg-slate-800 hover:bg-rose-500/20 hover:text-rose-400 disabled:opacity-40 text-slate-300 font-bold text-xs flex items-center justify-center gap-1.5 transition border border-slate-700"
                  >
                    <XCircle size={14} />
                    <span>Revoke Clearance</span>
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
