import { useState, useEffect } from "react";
import { 
  AlertTriangle, ShieldAlert, CheckCircle2, Clock, Search, RefreshCw, 
  Eye, Check, Radio, Bell
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface AlertItem {
  id: string;
  severity: "low" | "medium" | "high" | "critical";
  type: string;
  title: string;
  message: string;
  entity_type: string;
  entity_id: string;
  created_at: string;
  status: string;
}

export default function Alerts() {
  const [alerts, setAlerts] = useState<AlertItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [resolvingId, setResolvingId] = useState<string | null>(null);

  const fetchAlerts = async () => {
    setLoading(true);
    try {
      const data = await api.get<AlertItem[]>("/admin/alerts");
      setAlerts(data || []);
    } catch (err) {
      console.error("Error fetching alerts:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
    const interval = setInterval(fetchAlerts, 15000);
    return () => clearInterval(interval);
  }, []);

  const handleResolve = async (alertId: string) => {
    setResolvingId(alertId);
    try {
      await api.patch(`/admin/alerts/${alertId}/resolve`, {});
      setAlerts(prev => prev.filter(a => a.id !== alertId));
    } catch (err) {
      console.error("Failed to resolve alert:", err);
    } finally {
      setResolvingId(null);
    }
  };

  const getSeverityBadge = (s: string) => {
    switch (s) {
      case "critical":
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-rose-500/20 text-rose-400 border border-rose-500/30">CRITICAL</span>;
      case "high":
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-amber-500/20 text-amber-400 border border-amber-500/30">HIGH</span>;
      case "medium":
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-sky-500/20 text-sky-400 border border-sky-500/30">MEDIUM</span>;
      default:
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-slate-500/20 text-slate-400 border border-slate-500/30">INFO</span>;
    }
  };

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Operations Exceptions & Signals"
            sub="Proactive monitoring for stale telematics GPS signals, verification backlog delays, and dispatch bottlenecks."
          />
          <Button
            variant="secondary"
            onClick={fetchAlerts}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Poll Live Alerts</span>
          </Button>
        </div>

        {/* Live Metrics Header */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div className="p-4 rounded-2xl bg-slate-900/90 border border-slate-800 flex items-center justify-between">
            <div>
              <span className="text-[10px] text-slate-400 font-bold uppercase">Active Anomaly Flags</span>
              <div className="text-2xl font-black text-amber-400 mt-0.5">{alerts.length} Active</div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center">
              <AlertTriangle size={20} />
            </div>
          </div>

          <div className="p-4 rounded-2xl bg-slate-900/90 border border-slate-800 flex items-center justify-between">
            <div>
              <span className="text-[10px] text-slate-400 font-bold uppercase">Critical Escalations</span>
              <div className="text-2xl font-black text-rose-400 mt-0.5">
                {alerts.filter(a => a.severity === "critical" || a.severity === "high").length}
              </div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-rose-500/10 text-rose-400 flex items-center justify-center">
              <ShieldAlert size={20} />
            </div>
          </div>

          <div className="p-4 rounded-2xl bg-slate-900/90 border border-slate-800 flex items-center justify-between">
            <div>
              <span className="text-[10px] text-slate-400 font-bold uppercase">Corridor Telematics</span>
              <div className="text-2xl font-black text-emerald-400 mt-0.5">
                {alerts.filter(a => a.type === "STALE_GPS_SIGNAL").length === 0 ? "Normal" : "GPS Drops"}
              </div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <Radio size={20} />
            </div>
          </div>
        </div>

        {/* Alerts List */}
        <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
          {loading && alerts.length === 0 ? (
            <div className="p-6"><CardSkeleton /></div>
          ) : alerts.length === 0 ? (
            <div className="text-center py-16 space-y-2">
              <CheckCircle2 size={32} className="mx-auto text-emerald-400" />
              <h3 className="text-sm font-black text-white">All Operational Pipelines Normal</h3>
              <p className="text-xs text-slate-400">Zero active exceptions, stale GPS signals, or SLA breaches detected.</p>
            </div>
          ) : (
            <div className="divide-y divide-slate-800/60">
              {alerts.map((alert) => (
                <div key={alert.id} className="p-4 hover:bg-slate-800/30 transition flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      {getSeverityBadge(alert.severity)}
                      <span className="text-xs font-mono font-bold text-amber-400">
                        {alert.type}
                      </span>
                      <span className="text-[10px] text-slate-500 font-mono">
                        {new Date(alert.created_at).toLocaleTimeString()}
                      </span>
                    </div>
                    <h4 className="text-sm font-bold text-white">{alert.title}</h4>
                    <p className="text-xs text-slate-400">{alert.message}</p>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => handleResolve(alert.id)}
                      disabled={resolvingId === alert.id}
                      className="px-3 py-1.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 disabled:opacity-40 text-slate-950 font-bold text-xs flex items-center gap-1.5 transition"
                    >
                      <Check size={14} />
                      <span>Acknowledge & Resolve</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </Layout>
  );
}
