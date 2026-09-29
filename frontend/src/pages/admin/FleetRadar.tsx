import { useEffect, useState } from "react";
import { Truck, MapPin, Navigation, ShieldCheck, Phone, RefreshCw, Layers } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead } from "../../components/ui";

export default function FleetRadar() {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<{ corridors: any[]; active_trucks: any[]; total_active_count: number } | null>(null);
  const [selectedCorridor, setSelectedCorridor] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");

  const loadData = () => {
    setLoading(true);
    api.get<any>("/admin/radar")
      .then(res => setData(res))
      .catch(() => setData({ corridors: [], active_trucks: [], total_active_count: 0 }))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  const trucks = (data?.active_trucks || []).filter(t => {
    const matchesCorridor = selectedCorridor === "all" || t.corridor_id === selectedCorridor;
    const matchesQuery = !searchQuery || 
      t.registration_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.owner_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.truck_type.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCorridor && matchesQuery;
  });

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Live Corridor Fleet Radar" 
          sub="Real-time moving capacity inventory and occupancy monitoring across key highway freight corridors." 
        />
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={loadData} disabled={loading} className="gap-2">
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            Refresh Radar
          </Button>
        </div>
      </div>

      {/* Corridor Filter Tabs */}
      <div className="mt-5 flex flex-wrap gap-2">
        <button
          onClick={() => setSelectedCorridor("all")}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            selectedCorridor === "all" 
              ? "bg-amber-400 text-slate-950 shadow-md" 
              : "bg-slate-900 text-slate-300 border border-slate-800 hover:bg-slate-800"
          }`}
        >
          <Layers size={14} />
          All Active Lanes ({data?.total_active_count ?? 0})
        </button>
        <button
          onClick={() => setSelectedCorridor("delhi_patna")}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            selectedCorridor === "delhi_patna" 
              ? "bg-amber-400 text-slate-950 shadow-md" 
              : "bg-slate-900 text-slate-300 border border-slate-800 hover:bg-slate-800"
          }`}
        >
          <Navigation size={14} />
          Delhi ➔ Agra ➔ Kanpur ➔ Lucknow ➔ Patna (NH19)
        </button>
        <button
          onClick={() => setSelectedCorridor("delhi_mumbai")}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            selectedCorridor === "delhi_mumbai" 
              ? "bg-amber-400 text-slate-950 shadow-md" 
              : "bg-slate-900 text-slate-300 border border-slate-800 hover:bg-slate-800"
          }`}
        >
          <Navigation size={14} />
          Delhi ➔ Jaipur ➔ Ahmedabad ➔ Mumbai (NE4)
        </button>
        <button
          onClick={() => setSelectedCorridor("mumbai_bengaluru")}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            selectedCorridor === "mumbai_bengaluru" 
              ? "bg-amber-400 text-slate-950 shadow-md" 
              : "bg-slate-900 text-slate-300 border border-slate-800 hover:bg-slate-800"
          }`}
        >
          <Navigation size={14} />
          Mumbai ➔ Pune ➔ Bengaluru (NH48)
        </button>
      </div>

      {/* Search Bar */}
      <div className="mt-4">
        <input
          type="text"
          placeholder="Filter by Truck Number (e.g. NL-01), Driver Name, or Body Type..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full md:w-96 px-4 py-2.5 rounded-xl border border-slate-800 bg-slate-900 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500"
        />
      </div>

      {/* Radar Cards Grid */}
      {loading ? (
        <div className="mt-6 grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
          <CardSkeleton /><CardSkeleton /><CardSkeleton />
        </div>
      ) : trucks.length === 0 ? (
        <Card className="mt-6 p-10 text-center bg-slate-900 border-slate-800">
          <Truck size={40} className="mx-auto text-slate-500 mb-2" />
          <p className="font-bold text-slate-200">No rolling trucks found on this filter.</p>
          <p className="text-xs text-slate-500 mt-1">Trucks will appear automatically when drivers set an active highway route.</p>
        </Card>
      ) : (
        <div className="mt-6 grid gap-4 grid-cols-1 md:grid-cols-2 xl:grid-cols-3">
          {trucks.map(truck => {
            return (
              <Card key={truck.truck_id} className="p-5 border border-slate-800 hover:border-amber-400/50 transition-all rounded-xl bg-slate-900 flex flex-col justify-between">
                <div>
                  {/* Top Header */}
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-extrabold text-base text-slate-900 tracking-wide font-mono bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                          {truck.registration_number}
                        </span>
                        <Badge tone={truck.verified_documents ? "ok" : "warn"}>
                          <ShieldCheck size={11} className="mr-0.5" />
                          {truck.verified_documents ? "Documents Verified" : "Verification Pending"}
                        </Badge>
                      </div>
                      <p className="text-xs text-slate-500 font-medium mt-1">
                        {truck.truck_type} · {truck.body_type || "Body type not set"}
                      </p>
                    </div>

                    <div className="text-right">
                      <span className="text-xs font-bold text-amber-300 bg-amber-500/10 px-2 py-1 rounded-lg border border-amber-500/20">
                        {truck.status.replaceAll("_", " ").toUpperCase()}
                      </span>
                    </div>
                  </div>

                  {/* Corridor Banner */}
                  <div className="mt-3.5 p-2.5 rounded-xl bg-slate-950 border border-slate-800">
                    <div className="flex items-center gap-1.5 text-xs font-bold text-slate-200">
                      <MapPin size={13} className="text-amber-500 shrink-0" />
                      <span className="truncate">{truck.corridor_name}</span>
                    </div>
                    <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1 font-medium">
                      <span>Home base: <strong className="text-slate-200">{truck.home_origin || "Not set"}</strong></span>
                      <span>{truck.current_lat != null && truck.current_lng != null
                        ? `${Number(truck.current_lat).toFixed(4)}, ${Number(truck.current_lng).toFixed(4)}`
                        : "GPS not reported"}</span>
                    </div>
                  </div>

                  <div className="mt-4 flex items-center justify-between text-xs">
                    <span className="text-slate-400">Registered capacity</span>
                    <span className="font-mono font-bold text-slate-100">{truck.total_capacity_tons} T</span>
                    <span className="text-slate-400">Rating</span>
                    <span className="font-mono font-bold text-amber-300">{truck.driver_rating ?? "—"}</span>
                  </div>
                </div>

                {/* Driver Contact Footer */}
                <div className="mt-5 pt-3 border-t border-slate-800 flex items-center justify-between">
                  <div className="text-xs">
                    <p className="font-bold text-slate-100">{truck.owner_name}</p>
                    <p className="text-slate-400 font-mono text-[11px]">{truck.driver_phone || "No phone on file"}</p>
                  </div>
                  {truck.driver_phone && <a
                    href={`tel:${truck.driver_phone}`}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 text-white text-xs font-bold hover:bg-slate-700 transition"
                  >
                    <Phone size={12} />
                    Call Driver
                  </a>}
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </Layout>
  );
}
