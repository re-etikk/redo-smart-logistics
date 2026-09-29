import { useEffect, useState } from "react";
import { 
  CalendarCheck, FileClock, Truck, Users, Activity, Navigation,
  Sliders, ShieldAlert, Zap, Package, RefreshCw, ArrowRight, ShieldCheck, CheckCircle2, IndianRupee
} from "lucide-react";
import { Link } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Card, CardSkeleton, SectionHead, StatCard, Button } from "../../components/ui";

export default function AdminDashboard() {
  const [stats, setStats] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);

  const loadStats = async () => {
    setLoading(true);
    try {
      const res = await api.get("/admin/stats");
      setStats(res);
    } catch (err) {
      console.error('Error loading admin stats:', err);
      setStats(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadStats();
  }, []);

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Operations Control Room" 
          sub="Central real-time command for live moving capacity, corridor fleet matching, dynamic pricing, and escrow settlements." 
        />
        <div className="flex items-center gap-2">
          <Button 
            variant="secondary" 
            onClick={loadStats} 
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Stats</span>
          </Button>
        </div>
      </div>

      {loading && stats === null ? (
        <div className="mt-5"><CardSkeleton /></div>
      ) : (
        <>
          {/* Key Operations Metric Tiles */}
          <div className="mt-5 grid gap-4 grid-cols-2 md:grid-cols-3 xl:grid-cols-6">
            <StatCard 
              icon={Activity} 
              label="Live Corridor Trucks" 
              value={stats?.active_corridor_trucks ?? 0} 
              sub="Moving on active corridors" 
              tone="ok" 
            />
            <StatCard 
              icon={Zap} 
              label="Available Capacity" 
              value={`${stats?.network_capacity_tons ?? 0} T`} 
              sub="Real-time sellable inventory" 
              tone="accent" 
            />
            <StatCard 
              icon={Package} 
              label="Live Shipments" 
              value={stats?.bookings ?? 0} 
              sub={`${stats?.completed ?? 0} successfully delivered`} 
              tone="info" 
            />
            <StatCard 
              icon={ShieldCheck} 
              label="Pending KYC" 
              value={stats?.kyc_pending ?? 0} 
              sub="Awaiting admin approval" 
              tone={stats?.kyc_pending > 0 ? "warn" : "ok"} 
            />
            <StatCard
              icon={Users}
              label="Verified Trucks"
              value={stats?.verified_drivers ?? "—"}
              sub="Documents approved"
              tone="ok"
            />
            <StatCard
              icon={IndianRupee}
              label="Platform GMV"
              value={stats ? `₹${Number(stats.platform_gmv_inr || 0).toLocaleString("en-IN")}` : "—"}
              sub="Delivered shipments"
              tone="accent"
            />
          </div>

          {/* Featured Live Bookings Banner */}
          <div className="mt-6">
            <div className="p-5 rounded-2xl bg-gradient-to-r from-amber-500/20 via-slate-900 to-slate-900 border border-amber-500/30 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-xl">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-amber-400 text-slate-950 flex items-center justify-center shrink-0 shadow-lg shadow-amber-400/20">
                  <Package size={24} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="text-base font-black text-white">Live Shipments & Customer Bookings</h3>
                    <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 text-[10px] font-bold">
                      Realtime Active
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 mt-1">
                    Manage loads booked by customers from redo_customer, track driver pickups, verify OTP handovers, and resolve disputes.
                  </p>
                </div>
              </div>
              <Link 
                to="/admin/bookings" 
                className="px-4 py-2.5 rounded-xl bg-amber-400 hover:bg-amber-500 text-slate-950 font-bold text-xs flex items-center justify-center gap-2 shadow-md shadow-amber-400/20 shrink-0 transition"
              >
                <span>Open Shipments Desk</span>
                <ArrowRight size={14} />
              </Link>
            </div>
          </div>

          {/* Quick Access Control Modules */}
          <div className="mt-6">
            <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
              Operations Control Center Modules
            </h2>
            <div className="grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-4">
              <Link to="/admin/radar" className="group">
                <Card className="p-5 border border-slate-800 hover:border-amber-400 hover:shadow-lg hover:shadow-amber-500/5 transition-all rounded-2xl bg-slate-900/90 h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-amber-500/15 border border-amber-500/30 text-amber-400 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <Navigation size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-white group-hover:text-amber-400 transition">
                      Corridor Fleet Radar
                    </h3>
                    <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                      Monitor rolling trucks on NH19, NE4 & NH48 with live capacity occupancy gauges.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-amber-400 mt-4 inline-flex items-center gap-1 group-hover:translate-x-0.5 transition">
                    Open Radar →
                  </span>
                </Card>
              </Link>

              <Link to="/admin/matching" className="group">
                <Card className="p-5 border border-slate-800 hover:border-emerald-400 hover:shadow-lg hover:shadow-emerald-500/5 transition-all rounded-2xl bg-slate-900/90 h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <Activity size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-white group-hover:text-emerald-400 transition">
                      Matching Overseer
                    </h3>
                    <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                      Inspect ReDo Match Scores, verify co-load safety rules, and execute manual dispatch overrides.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-emerald-400 mt-4 inline-flex items-center gap-1 group-hover:translate-x-0.5 transition">
                    View Matches →
                  </span>
                </Card>
              </Link>

              <Link to="/admin/pricing" className="group">
                <Card className="p-5 border border-slate-800 hover:border-sky-400 hover:shadow-lg hover:shadow-sky-500/5 transition-all rounded-2xl bg-slate-900/90 h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-sky-500/15 border border-sky-500/30 text-sky-400 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <Sliders size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-white group-hover:text-sky-400 transition">
                      Dynamic Pricing Control
                    </h3>
                    <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                      Modify corridor base rates, cargo risk multipliers, and commission percentage with live sandbox.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-sky-400 mt-4 inline-flex items-center gap-1 group-hover:translate-x-0.5 transition">
                    Tune Pricing →
                  </span>
                </Card>
              </Link>

              <Link to="/admin/disputes" className="group">
                <Card className="p-5 border border-slate-800 hover:border-rose-400 hover:shadow-lg hover:shadow-rose-500/5 transition-all rounded-2xl bg-slate-900/90 h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-rose-500/15 border border-rose-500/30 text-rose-400 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <ShieldAlert size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-white group-hover:text-rose-400 transition">
                      Disputes & Escrow
                    </h3>
                    <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                      Inspect damage claims, verify digital POD receipts, and release or refund escrow funds.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-rose-400 mt-4 inline-flex items-center gap-1 group-hover:translate-x-0.5 transition">
                    Manage Claims →
                  </span>
                </Card>
              </Link>
            </div>
          </div>

          {/* Secondary Account & Compliance Row */}
          <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 flex items-center justify-between">
              <div>
                <p className="text-xs font-bold text-slate-400">Platform Accounts & Directory</p>
                <p className="text-lg font-black text-white mt-0.5">{stats?.users ?? 0} Registered Users</p>
                <p className="text-xs text-slate-400 mt-1">{stats?.shippers ?? 0} Shippers • {stats?.owners ?? 0} Fleet Partners</p>
              </div>
              <Link to="/admin/users" className="text-xs font-bold px-3.5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white transition border border-slate-700">
                Manage Users
              </Link>
            </Card>

            <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900/90 flex items-center justify-between">
              <div>
                <p className="text-xs font-bold text-slate-400">Compliance & KYC Desk</p>
                <p className="text-lg font-black text-white mt-0.5">{stats?.kyc_pending ?? 0} Pending Document Approvals</p>
                <p className="text-xs text-slate-400 mt-1">Driving License, RC Books & GSTIN verifications</p>
              </div>
              <Link to="/admin/kyc" className="text-xs font-bold px-3.5 py-2 rounded-xl bg-amber-400 hover:bg-amber-500 text-slate-950 transition font-black">
                Review KYC
              </Link>
            </Card>
          </div>
        </>
      )}
    </Layout>
  );
}
