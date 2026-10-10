import { useEffect, useState } from "react";
import { 
  CalendarCheck, FileClock, Truck, Users, Activity, Navigation,
  Sliders, ShieldAlert, Zap, Package, RefreshCw, ArrowRight, ShieldCheck, 
  CheckCircle2, IndianRupee, MapPin, Gauge, AlertTriangle, LifeBuoy, 
  MessageSquare, CreditCard, ChevronRight, X
} from "lucide-react";
import { Link } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Card, CardSkeleton, SectionHead, StatCard, Button } from "../../components/ui";

interface ActiveTruckRadar {
  truck_id: string;
  registration_number: string;
  truck_type: string;
  body_type: string;
  owner_name: string;
  driver_phone?: string;
  driver_rating: number;
  status: string;
  home_origin: string;
  current_lat: number;
  current_lng: number;
  corridor_name: string;
  total_capacity_tons: number;
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<any | null>(null);
  const [trips, setTrips] = useState<any[]>([]);
  const [radarTrucks, setRadarTrucks] = useState<ActiveTruckRadar[]>([]);
  const [alerts, setAlerts] = useState<any[]>([]);
  const [tickets, setTickets] = useState<any[]>([]);
  const [selectedTruck, setSelectedTruck] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const [statsRes, tripsRes, radarRes, alertsRes, ticketsRes] = await Promise.all([
        api.get<any>("/admin/stats").catch(() => null),
        api.get<any[]>("/admin/trips").catch(() => []),
        api.get<any>("/admin/radar").catch(() => ({ active_trucks: [] })),
        api.get<any[]>("/admin/alerts").catch(() => []),
        api.get<any[]>("/admin/tickets").catch(() => []),
      ]);

      setStats(statsRes);
      setTrips(tripsRes || []);
      setRadarTrucks(radarRes?.active_trucks || []);
      setAlerts(alertsRes || []);
      setTickets(ticketsRes || []);
    } catch (err) {
      console.error("Error loading admin control room data:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 20000); // 20s auto sync
    return () => clearInterval(interval);
  }, []);

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead 
            title="Operations Control Room" 
            sub="Real-time operational command for backhaul freight corridors, moving truck capacity, KYC verification, and escrow settlement." 
          />
          <div className="flex items-center gap-2">
            <Button 
              variant="secondary" 
              onClick={loadData} 
              disabled={loading}
              className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
            >
              <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
              <span>Refresh Control Room</span>
            </Button>
          </div>
        </div>

        {/* 8 Primary Operations KPI Cards */}
        <div className="grid gap-3 grid-cols-2 md:grid-cols-4 xl:grid-cols-8">
          <StatCard 
            icon={Package} 
            label="Active Shipments" 
            value={stats?.bookings ?? 0} 
            sub="Live cargo loads" 
            tone="info" 
          />
          <StatCard 
            icon={Activity} 
            label="Active Trips" 
            value={trips.length} 
            sub="Trucks in transit" 
            tone="accent" 
          />
          <StatCard 
            icon={Truck} 
            label="Online Partners" 
            value={stats?.active_corridor_trucks ?? radarTrucks.length} 
            sub="Connected drivers" 
            tone="ok" 
          />
          <StatCard 
            icon={ShieldCheck} 
            label="Pending KYC" 
            value={stats?.kyc_pending ?? 0} 
            sub="Partner verification" 
            tone={(stats?.kyc_pending ?? 0) > 0 ? "warn" : "ok"} 
          />
          <StatCard 
            icon={FileClock} 
            label="Cargo Reviews" 
            value={alerts.filter(a => a.type?.includes("KYC") || a.type?.includes("CARGO")).length} 
            sub="E-Way bill & GSTIN" 
            tone="info" 
          />
          <StatCard 
            icon={CreditCard} 
            label="Pending Payments" 
            value={stats ? `₹${Math.round((stats.platform_gmv_inr || 0) * 0.15).toLocaleString("en-IN")}` : "₹0"} 
            sub="Escrow vault" 
            tone="ok" 
          />
          <StatCard 
            icon={LifeBuoy} 
            label="Open Tickets" 
            value={tickets.filter(t => !["resolved", "closed"].includes(t.status)).length} 
            sub="Support queue" 
            tone={tickets.filter(t => t.priority === "high" || t.priority === "critical").length > 0 ? "danger" : "ok"} 
          />
          <StatCard 
            icon={IndianRupee} 
            label="Platform GMV" 
            value={stats ? `₹${Number(stats.platform_gmv_inr || 0).toLocaleString("en-IN")}` : "—"} 
            sub="Delivered orders" 
            tone="accent" 
          />
        </div>

        {/* Live Operations Map & Telematics Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Map & Corridor Overview */}
          <div className={selectedTruck ? "lg:col-span-8" : "lg:col-span-12"}>
            <Card className="border border-slate-800 rounded-2xl bg-slate-900 overflow-hidden shadow-2xl flex flex-col">
              {/* Map Header Bar */}
              <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/70">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-bold">
                    <Navigation size={16} />
                  </div>
                  <div>
                    <h3 className="text-xs font-black uppercase tracking-wider text-white flex items-center gap-2">
                      Live Freight Telematics Radar
                      <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 text-[9px] font-black border border-emerald-500/30">
                        GPS LIVE
                      </span>
                    </h3>
                    <p className="text-[11px] text-slate-400">
                      Tracking commercial trucks along NH48 (Delhi-Mumbai) and NH19 (Delhi-Kolkata)
                    </p>
                  </div>
                </div>
                <Link
                  to="/admin/radar"
                  className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold transition flex items-center gap-1.5 border border-slate-700"
                >
                  <span>Full Radar</span>
                  <ChevronRight size={14} />
                </Link>
              </div>

              {/* Interactive Radar Visual Canvas */}
              <div className="relative bg-slate-950 p-6 min-h-[340px] flex flex-col justify-between overflow-hidden">
                {/* Background Grid Pattern */}
                <div className="absolute inset-0 bg-[linear-gradient(to_right,#1e293b_1px,transparent_1px),linear-gradient(to_bottom,#1e293b_1px,transparent_1px)] bg-[size:40px_40px] opacity-25" />

                {/* Corridor Highway Lines */}
                <div className="relative z-10 space-y-6">
                  {/* NH48 Corridor */}
                  <div className="p-4 rounded-xl bg-slate-900/80 border border-slate-800 space-y-3">
                    <div className="flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse" />
                        <span className="font-black text-amber-400">NH48 Western Corridor</span>
                        <span className="text-slate-500">• Delhi - Jaipur - Ahmedabad - Surat - Mumbai</span>
                      </div>
                      <span className="text-[10px] font-mono text-slate-400">1,410 KM</span>
                    </div>

                    {/* Corridor Highway Progress Bar with Moving Truck Markers */}
                    <div className="relative h-10 bg-slate-950 rounded-xl border border-slate-800 flex items-center px-4">
                      {/* Polyline line */}
                      <div className="absolute left-4 right-4 h-1.5 bg-slate-800 rounded-full overflow-hidden">
                        <div className="h-full bg-gradient-to-r from-amber-400 via-amber-300 to-emerald-400 w-full opacity-60" />
                      </div>

                      {/* City Nodes */}
                      <div className="relative w-full flex justify-between items-center z-10 text-[10px] font-bold text-slate-400">
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Delhi</span>
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Jaipur</span>
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Ahmedabad</span>
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Mumbai</span>
                      </div>
                    </div>
                  </div>

                  {/* NH19 Corridor */}
                  <div className="p-4 rounded-xl bg-slate-900/80 border border-slate-800 space-y-3">
                    <div className="flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
                        <span className="font-black text-emerald-400">NH19 Eastern Corridor</span>
                        <span className="text-slate-500">• Delhi - Agra - Kanpur - Lucknow - Varanasi - Kolkata</span>
                      </div>
                      <span className="text-[10px] font-mono text-slate-400">1,450 KM</span>
                    </div>

                    <div className="relative h-10 bg-slate-950 rounded-xl border border-slate-800 flex items-center px-4">
                      <div className="absolute left-4 right-4 h-1.5 bg-slate-800 rounded-full overflow-hidden">
                        <div className="h-full bg-gradient-to-r from-emerald-400 via-emerald-300 to-sky-400 w-full opacity-60" />
                      </div>

                      <div className="relative w-full flex justify-between items-center z-10 text-[10px] font-bold text-slate-400">
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Delhi</span>
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Agra</span>
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Kanpur</span>
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Patna</span>
                        <span className="bg-slate-900 px-1.5 py-0.5 rounded border border-slate-800">Kolkata</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Moving Commercial Trucks Row */}
                <div className="relative z-10 pt-4 border-t border-slate-800/80">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[10px] font-black uppercase text-slate-400">
                      Active Commercial Trucks On Corridors (Click to inspect telemetry)
                    </span>
                    <span className="text-[10px] text-amber-400 font-bold">{radarTrucks.length} Units Reporting</span>
                  </div>

                  <div className="flex items-center gap-2 overflow-x-auto pb-2 no-scrollbar">
                    {radarTrucks.map((truck) => (
                      <button
                        key={truck.truck_id}
                        onClick={() => setSelectedTruck(truck)}
                        className={`p-2.5 rounded-xl border transition flex items-center gap-2.5 shrink-0 text-left ${
                          selectedTruck?.truck_id === truck.truck_id
                            ? "bg-amber-500/20 border-amber-400 shadow-md shadow-amber-400/10"
                            : "bg-slate-900 border-slate-800 hover:border-slate-700"
                        }`}
                      >
                        <div className="w-8 h-8 rounded-lg bg-amber-400/10 text-amber-400 flex items-center justify-center font-bold">
                          <Truck size={16} />
                        </div>
                        <div>
                          <div className="font-mono font-bold text-xs text-white">
                            {truck.registration_number || truck.truck_id}
                          </div>
                          <div className="text-[10px] text-slate-400">
                            {truck.owner_name} • {truck.home_origin || "En-Route"}
                          </div>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </Card>
          </div>

          {/* Selected Truck Telemetry Inspector Drawer */}
          {selectedTruck && (
            <div className="lg:col-span-4">
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900 sticky top-20 shadow-2xl space-y-4">
                <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Telematics Inspector</span>
                    <h3 className="text-base font-black text-white font-mono">{selectedTruck.registration_number}</h3>
                    <p className="text-xs text-slate-400">{selectedTruck.truck_type} • {selectedTruck.body_type}</p>
                  </div>
                  <button 
                    onClick={() => setSelectedTruck(null)}
                    className="p-1 rounded-lg text-slate-400 hover:text-white"
                  >
                    <X size={16} />
                  </button>
                </div>

                {/* Telemetry Numbers */}
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Fleet Partner</span>
                    <span className="font-bold text-slate-200">{selectedTruck.owner_name}</span>
                    <span className="text-[10px] text-slate-400 block font-mono">
                      {selectedTruck.driver_phone ? selectedTruck.driver_phone.replace(/(\+91\d{2})\d{4}(\d{4})/, "$1••••$2") : "Verified Partner"}
                    </span>
                  </div>
                  <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800">
                    <span className="text-[10px] text-slate-500 block">Payload Capacity</span>
                    <span className="font-bold text-amber-400">{selectedTruck.total_capacity_tons} Tons</span>
                    <span className="text-[10px] text-emerald-400 block">★ {selectedTruck.driver_rating} Rating</span>
                  </div>
                </div>

                {/* Live GPS Coordinates */}
                <div className="p-3 rounded-xl bg-slate-950/70 border border-slate-800 space-y-2 text-xs">
                  <div className="flex justify-between items-center">
                    <span className="text-slate-400 flex items-center gap-1">
                      <MapPin size={13} className="text-amber-400" />
                      <span>Reported Coordinates</span>
                    </span>
                    <span className="font-mono text-slate-200">
                      {selectedTruck.current_lat || 28.7041}, {selectedTruck.current_lng || 77.1025}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-slate-400">Assigned Lane</span>
                    <span className="font-bold text-slate-300">{selectedTruck.corridor_name}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-slate-400">Operational State</span>
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-emerald-500/15 text-emerald-400">
                      {selectedTruck.status}
                    </span>
                  </div>
                </div>

                {/* Action Links */}
                <div className="pt-2 border-t border-slate-800 flex items-center gap-2">
                  <Link
                    to={`/admin/radar?truck=${selectedTruck.truck_id}`}
                    className="flex-1 py-2 px-3 rounded-xl bg-amber-400 hover:bg-amber-500 text-slate-950 font-black text-xs text-center transition"
                  >
                    Track on Radar
                  </Link>
                  <Link
                    to="/admin/matching"
                    className="py-2 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold text-xs transition border border-slate-700"
                  >
                    Assign Load
                  </Link>
                </div>
              </Card>
            </div>
          )}
        </div>

        {/* Featured Live Bookings Banner */}
        <div className="p-5 rounded-2xl bg-gradient-to-r from-amber-500/20 via-slate-900 to-slate-900 border border-amber-500/30 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-xl">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-amber-400 text-slate-950 flex items-center justify-center shrink-0 shadow-lg shadow-amber-400/20">
              <Package size={24} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-black text-white">Live Shipments & Customer Bookings</h3>
                <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 text-[10px] font-bold">
                  {trips.length} EN-ROUTE
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-1">
                Oversee shipments booked through REDO mobile apps, monitor OTP pickups and POD deliveries, and execute dispatch overrides.
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

        {/* Operational Modules Quick Links Grid */}
        <div>
          <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
            Operations Control Center Desks
          </h2>
          <div className="grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-4">
            <Link to="/admin/verification/partners" className="group">
              <Card className="p-5 border border-slate-800 hover:border-amber-400 hover:shadow-lg hover:shadow-amber-500/5 transition-all rounded-2xl bg-slate-900/90 h-full flex flex-col justify-between">
                <div>
                  <div className="w-10 h-10 rounded-xl bg-amber-500/15 border border-amber-500/30 text-amber-400 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                    <ShieldCheck size={20} />
                  </div>
                  <h3 className="font-extrabold text-sm text-white group-hover:text-amber-400 transition">
                    Partner & Fleet Verification
                  </h3>
                  <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                    Verify driver licenses, Aadhaar, PAN, and commercial RC books for commercial onboarding.
                  </p>
                </div>
                <span className="text-xs font-bold text-amber-400 mt-4 inline-flex items-center gap-1 group-hover:translate-x-0.5 transition">
                  Review KYC ({stats?.kyc_pending ?? 0}) →
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
                    Dynamic Pricing Engine
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

            <Link to="/admin/communication/tickets" className="group">
              <Card className="p-5 border border-slate-800 hover:border-rose-400 hover:shadow-lg hover:shadow-rose-500/5 transition-all rounded-2xl bg-slate-900/90 h-full flex flex-col justify-between">
                <div>
                  <div className="w-10 h-10 rounded-xl bg-rose-500/15 border border-rose-500/30 text-rose-400 flex items-center justify-center mb-3 group-hover:scale-105 transition">
                    <LifeBuoy size={20} />
                  </div>
                  <h3 className="font-extrabold text-sm text-white group-hover:text-rose-400 transition">
                    Support & Escalations
                  </h3>
                  <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                    Resolve shipper disputes, investigate telematics signal drops, and manage settlements.
                  </p>
                </div>
                <span className="text-xs font-bold text-rose-400 mt-4 inline-flex items-center gap-1 group-hover:translate-x-0.5 transition">
                  Support Queue ({tickets.filter(t => !["resolved", "closed"].includes(t.status)).length}) →
                </span>
              </Card>
            </Link>
          </div>
        </div>
      </div>
    </Layout>
  );
}
