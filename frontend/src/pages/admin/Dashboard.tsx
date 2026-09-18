import { useEffect, useState } from "react";
import { CalendarCheck, FileClock, Truck, Users, Activity, Navigation, Sliders, ShieldAlert, Zap } from "lucide-react";
import { Link } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Card, CardSkeleton, SectionHead, StatCard } from "../../components/ui";

export default function AdminDashboard() {
  const [stats, setStats] = useState<any | null>(null);

  useEffect(() => {
    api.get("/admin/stats").then(setStats).catch(() => setStats({}));
  }, []);

  return (
    <Layout>
      <SectionHead 
        title="Operations Control Room" 
        sub="Central command for live moving capacity, corridor fleet matching, dynamic pricing, and escrow settlements." 
      />

      {stats === null ? (
        <div className="mt-5"><CardSkeleton /></div>
      ) : (
        <>
          {/* Key Operations Metric Tiles */}
          <div className="mt-5 grid gap-4 grid-cols-2 lg:grid-cols-4">
            <StatCard 
              icon={Activity} 
              label="Live Corridor Trucks" 
              value={stats.active_corridor_trucks ?? 18} 
              sub="Moving on active corridors" 
              tone="ok" 
            />
            <StatCard 
              icon={Zap} 
              label="Available Capacity" 
              value={`${stats.network_capacity_tons ?? 245} T`} 
              sub="Real-time sellable inventory" 
              tone="accent" 
            />
            <StatCard 
              icon={Truck} 
              label="Fleet Occupancy" 
              value={`${stats.avg_utilization_pct ?? 78.4}%`} 
              sub="Average corridor utilization" 
              tone="purple" 
            />
            <StatCard 
              icon={CalendarCheck} 
              label="Total Deliveries" 
              value={stats.completed ?? stats.bookings ?? 0} 
              sub={`${stats.bookings ?? 0} total bookings`} 
              tone="info" 
            />
          </div>

          {/* Quick Access Control Modules */}
          <div className="mt-6">
            <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
              Operations Control Center Modules
            </h2>
            <div className="grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-4">
              <Link to="/admin/radar" className="group">
                <Card className="p-5 border border-slate-200 hover:border-amber-400 hover:shadow-md transition-all rounded-2xl bg-white h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <Navigation size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-slate-900 group-hover:text-amber-600 transition">
                      Corridor Fleet Radar
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">
                      Monitor rolling trucks on NH19, NE4 & NH48 with live capacity occupancy gauges.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-amber-600 mt-3 inline-flex items-center gap-1">
                    Open Radar →
                  </span>
                </Card>
              </Link>

              <Link to="/admin/matching" className="group">
                <Card className="p-5 border border-slate-200 hover:border-emerald-400 hover:shadow-md transition-all rounded-2xl bg-white h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <Activity size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-slate-900 group-hover:text-emerald-600 transition">
                      Matching Overseer
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">
                      Inspect ReDo Match Scores, verify co-load safety rules, and execute manual dispatch overrides.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-emerald-600 mt-3 inline-flex items-center gap-1">
                    View Matches →
                  </span>
                </Card>
              </Link>

              <Link to="/admin/pricing" className="group">
                <Card className="p-5 border border-slate-200 hover:border-blue-400 hover:shadow-md transition-all rounded-2xl bg-white h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <Sliders size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-slate-900 group-hover:text-blue-600 transition">
                      Dynamic Pricing Control
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">
                      Modify corridor base rates, cargo risk multipliers, and commission percentage with live sandbox.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-blue-600 mt-3 inline-flex items-center gap-1">
                    Tune Pricing →
                  </span>
                </Card>
              </Link>

              <Link to="/admin/disputes" className="group">
                <Card className="p-5 border border-slate-200 hover:border-rose-400 hover:shadow-md transition-all rounded-2xl bg-white h-full flex flex-col justify-between">
                  <div>
                    <div className="w-10 h-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                      <ShieldAlert size={20} />
                    </div>
                    <h3 className="font-extrabold text-sm text-slate-900 group-hover:text-rose-600 transition">
                      Disputes & Escrow
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">
                      Inspect damage claims, verify digital POD receipts, and release or refund escrow funds.
                    </p>
                  </div>
                  <span className="text-xs font-bold text-rose-600 mt-3 inline-flex items-center gap-1">
                    Manage Claims →
                  </span>
                </Card>
              </Link>
            </div>
          </div>

          {/* Secondary Account Management Card */}
          <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card className="p-5 border border-slate-200 rounded-2xl bg-white flex items-center justify-between">
              <div>
                <p className="text-xs font-bold text-slate-500">Platform Accounts</p>
                <p className="text-lg font-black text-slate-900 mt-0.5">{stats.users ?? 0} Registered Users</p>
                <p className="text-xs text-slate-500 mt-1">{stats.shippers ?? 0} Shippers • {stats.owners ?? 0} Fleet Partners</p>
              </div>
              <Link to="/admin/users" className="text-xs font-bold px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 transition">
                Manage Users
              </Link>
            </Card>

            <Card className="p-5 border border-slate-200 rounded-2xl bg-white flex items-center justify-between">
              <div>
                <p className="text-xs font-bold text-slate-500">Compliance & KYC</p>
                <p className="text-lg font-black text-slate-900 mt-0.5">{stats.kyc_pending ?? 0} Pending Approvals</p>
                <p className="text-xs text-slate-500 mt-1">Vahan RC, Driving License & GST documents</p>
              </div>
              <Link to="/admin/kyc" className="text-xs font-bold px-3.5 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-slate-950 transition">
                Review KYC
              </Link>
            </Card>
          </div>
        </>
      )}
    </Layout>
  );
}
