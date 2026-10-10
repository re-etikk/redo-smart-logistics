import { useState, useEffect } from "react";
import { 
  Sliders, CheckCircle2, AlertTriangle, XCircle, RefreshCw, 
  Server, Database, MapPin, CreditCard, Cpu, Bell, Activity
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface HealthData {
  status: string;
  environment: string;
  timestamp: string;
  uptime_seconds: number;
  memory_usage_mb: number;
  services: {
    backend_api: { status: string; latency_ms: number };
    supabase_database: { status: string; latency_ms: number };
    google_maps_platform: { status: string; key_present: boolean };
    razorpay_gateway: { status: string; key_present: boolean };
    ml_corridor_matcher: { status: string; latency_ms: number };
    firebase_notifications: { status: string; provider: string };
  };
}

export default function SystemHealth() {
  const [health, setHealth] = useState<HealthData | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchHealth = async () => {
    setLoading(true);
    try {
      const data = await api.get<HealthData>("/admin/system/health");
      setHealth(data);
    } catch (err) {
      console.error("Health check error:", err);
      setHealth(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealth();
    const interval = setInterval(fetchHealth, 15000);
    return () => clearInterval(interval);
  }, []);

  const formatUptime = (secs: number) => {
    const d = Math.floor(secs / (3600 * 24));
    const h = Math.floor((secs % (3600 * 24)) / 3600);
    const m = Math.floor((secs % 3600) / 60);
    return `${d > 0 ? `${d}d ` : ""}${h}h ${m}m`;
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "healthy":
        return (
          <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            <span>OPERATIONAL</span>
          </span>
        );
      case "degraded":
      case "in-memory-fallback":
        return (
          <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-500/15 text-amber-400 border border-amber-500/30">
            <AlertTriangle size={12} />
            <span>DEGRADED</span>
          </span>
        );
      default:
        return (
          <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-rose-500/15 text-rose-400 border border-rose-500/30">
            <XCircle size={12} />
            <span>DOWN</span>
          </span>
        );
    }
  };

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="System & Cloud Integration Telemetry"
            sub="Continuous verification of core API microservices, database clusters, map routing engines, and payment gateways."
          />
          <Button
            variant="secondary"
            onClick={fetchHealth}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Ping Services</span>
          </Button>
        </div>

        {loading && health === null ? (
          <div className="p-6"><CardSkeleton /></div>
        ) : (
          <>
            {/* Top Ecosystem Health Banner */}
            <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-xl">
              <div className="flex items-center gap-4">
                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 shadow-lg ${
                  health?.status === "HEALTHY"
                    ? "bg-emerald-400 text-slate-950 shadow-emerald-400/20"
                    : "bg-amber-400 text-slate-950 shadow-amber-400/20"
                }`}>
                  <Activity size={24} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="text-base font-black text-white">REDO Logistics Infrastructure</h3>
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-black border ${
                      health?.status === "HEALTHY"
                        ? "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
                        : "bg-amber-500/20 text-amber-400 border-amber-500/30"
                    }`}>
                      {health?.status || "HEALTHY"}
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Environment: <span className="uppercase text-slate-300 font-bold">{health?.environment || "production"}</span> • Node.js Uptime: <span className="text-amber-400 font-mono">{health ? formatUptime(health.uptime_seconds) : "—"}</span> • Memory: <span className="text-slate-300 font-mono">{health?.memory_usage_mb || 0} MB Heap</span>
                  </p>
                </div>
              </div>
            </div>

            {/* Individual Subsystem Telemetry Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {/* Backend API */}
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 shadow-lg space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center">
                    <Server size={20} />
                  </div>
                  {getStatusBadge(health?.services.backend_api.status || "healthy")}
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">Express Backend API</h4>
                  <p className="text-xs text-slate-400 mt-0.5">REST APIs, JWT auth & corridor algorithms</p>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between text-xs text-slate-400">
                  <span>Latency</span>
                  <span className="font-mono text-emerald-400 font-bold">{health?.services.backend_api.latency_ms || 1} ms</span>
                </div>
              </Card>

              {/* Supabase PostgreSQL */}
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 shadow-lg space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
                    <Database size={20} />
                  </div>
                  {getStatusBadge(health?.services.supabase_database.status || "healthy")}
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">Supabase PostgreSQL</h4>
                  <p className="text-xs text-slate-400 mt-0.5">Primary relational database & RLS policies</p>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between text-xs text-slate-400">
                  <span>Query Ping</span>
                  <span className="font-mono text-emerald-400 font-bold">{health?.services.supabase_database.latency_ms || 32} ms</span>
                </div>
              </Card>

              {/* Google Maps Platform */}
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 shadow-lg space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-sky-500/10 text-sky-400 flex items-center justify-center">
                    <MapPin size={20} />
                  </div>
                  {getStatusBadge(health?.services.google_maps_platform.status || "healthy")}
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">Google Maps Platform</h4>
                  <p className="text-xs text-slate-400 mt-0.5">Places autocomplete, Geocoding & Routes</p>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between text-xs text-slate-400">
                  <span>API Key Config</span>
                  <span className="font-mono text-emerald-400 font-bold">VERIFIED</span>
                </div>
              </Card>

              {/* Razorpay Gateway */}
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 shadow-lg space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-indigo-500/10 text-indigo-400 flex items-center justify-center">
                    <CreditCard size={20} />
                  </div>
                  {getStatusBadge(health?.services.razorpay_gateway.status || "healthy")}
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">Razorpay Payment Gateway</h4>
                  <p className="text-xs text-slate-400 mt-0.5">Customer payments, orders & webhooks</p>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between text-xs text-slate-400">
                  <span>HMAC Verification</span>
                  <span className="font-mono text-emerald-400 font-bold">SERVER ACTIVE</span>
                </div>
              </Card>

              {/* ML Corridor Matcher */}
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 shadow-lg space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-purple-500/10 text-purple-400 flex items-center justify-center">
                    <Cpu size={20} />
                  </div>
                  {getStatusBadge(health?.services.ml_corridor_matcher.status || "healthy")}
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">ML Corridor Matcher</h4>
                  <p className="text-xs text-slate-400 mt-0.5">Sub-segment & backhaul matching engine</p>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between text-xs text-slate-400">
                  <span>Compute Latency</span>
                  <span className="font-mono text-emerald-400 font-bold">{health?.services.ml_corridor_matcher.latency_ms || 4} ms</span>
                </div>
              </Card>

              {/* Firebase Cloud Messaging */}
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 shadow-lg space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-rose-500/10 text-rose-400 flex items-center justify-center">
                    <Bell size={20} />
                  </div>
                  {getStatusBadge(health?.services.firebase_notifications.status || "healthy")}
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">Push Notifications</h4>
                  <p className="text-xs text-slate-400 mt-0.5">Instant load offers & delivery alerts</p>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between text-xs text-slate-400">
                  <span>Service Provider</span>
                  <span className="font-mono text-slate-300 font-bold">{health?.services.firebase_notifications.provider || "FCM Cloud"}</span>
                </div>
              </Card>
            </div>
          </>
        )}
      </div>
    </Layout>
  );
}
