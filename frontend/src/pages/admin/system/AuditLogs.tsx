import { useState, useEffect } from "react";
import { 
  ShieldAlert, ShieldCheck, Search, RefreshCw, Clock, 
  FileText, ArrowRight, UserCheck, Filter
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface AuditLogItem {
  id: string;
  admin_id?: string;
  action: string;
  entity: string;
  entity_id: string;
  old_value?: any;
  new_value?: any;
  reason?: string;
  ip_address?: string;
  created_at: string;
  admin?: {
    full_name: string;
    role: string;
  };
}

export default function AuditLogs() {
  const [logs, setLogs] = useState<AuditLogItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [entityFilter, setEntityFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const url = entityFilter === "all" ? "/admin/system/audit-logs" : `/admin/system/audit-logs?entity=${entityFilter}`;
      const data = await api.get<AuditLogItem[]>(url);
      setLogs(data || []);
    } catch (err) {
      console.error("Error fetching audit logs:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [entityFilter]);

  const filteredLogs = logs.filter((l) => {
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        l.action.toLowerCase().includes(q) ||
        l.entity.toLowerCase().includes(q) ||
        l.entity_id.toLowerCase().includes(q) ||
        (l.reason && l.reason.toLowerCase().includes(q))
      );
    }
    return true;
  });

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Immutable Operational Audit Trail"
            sub="Tamper-evident record of all administrator actions, pricing revisions, KYC approvals, and escrow disbursements."
          />
          <Button
            variant="secondary"
            onClick={fetchLogs}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Trail</span>
          </Button>
        </div>

        {/* Entity Filter Tabs */}
        <div className="flex items-center gap-2 border-b border-slate-800 pb-2 text-xs">
          {[
            { id: "all", label: "All Operational Events" },
            { id: "partner", label: "Partner KYC" },
            { id: "vehicle", label: "Vehicle Compliance" },
            { id: "cargo", label: "Cargo Verification" },
            { id: "support_ticket", label: "Support Tickets" },
            { id: "pricing", label: "Dynamic Pricing" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setEntityFilter(tab.id)}
              className={`px-3 py-1.5 rounded-xl transition ${
                entityFilter === tab.id
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
            placeholder="Search audit trail by action, entity ID, or rationale..."
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        {/* Audit Log Table */}
        <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
          {loading ? (
            <div className="p-6"><CardSkeleton /></div>
          ) : filteredLogs.length === 0 ? (
            <div className="text-center py-12 text-slate-500 text-xs">
              No audit logs recorded for the selected criteria.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Action</th>
                    <th className="py-3 px-4">Entity</th>
                    <th className="py-3 px-4">Target ID</th>
                    <th className="py-3 px-4">Operational Rationale</th>
                    <th className="py-3 px-4">IP Address</th>
                    <th className="py-3 px-4 text-right">Timestamp</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60 font-mono text-[11px]">
                  {filteredLogs.map((log) => (
                    <tr key={log.id} className="hover:bg-slate-800/40 transition">
                      <td className="py-3 px-4 font-bold text-amber-400">
                        {log.action}
                      </td>
                      <td className="py-3 px-4 text-slate-300 uppercase">
                        {log.entity}
                      </td>
                      <td className="py-3 px-4 text-slate-400">
                        {log.entity_id}
                      </td>
                      <td className="py-3 px-4 font-sans text-xs text-slate-300 max-w-xs truncate">
                        {log.reason || "Standard operations execution"}
                      </td>
                      <td className="py-3 px-4 text-slate-500">
                        {log.ip_address || "127.0.0.1"}
                      </td>
                      <td className="py-3 px-4 text-right text-slate-400">
                        {new Date(log.created_at).toLocaleString([], { dateStyle: "short", timeStyle: "medium" })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>
    </Layout>
  );
}
