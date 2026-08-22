import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api, ApiError } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import {
  Button, Card, CardSkeleton, CapacityGauge, EmptyState, ErrorState,
  MatchScore, ReasonChips, Badge, StatTile,
} from "../../components/ui";
import type { CargoRec } from "../../lib/types";
import { Truck, PlusCircle, TrendingUp, Sparkles, ShieldCheck, ArrowRight, RefreshCw, Route, Calendar } from "lucide-react";

export default function OwnerDashboard() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [truck, setTruck] = useState<any | null>(null);
  const [trip, setTrip] = useState<any | null>(null);
  const [recs, setRecs] = useState<CargoRec[] | null>(null);
  const [recError, setRecError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const loadRecs = useCallback(async (truckId: string) => {
    setRecError(null); setRecs(null);
    try {
      const out = await api.get<{ recommendations: CargoRec[] }>(`/recommendations/cargo/${truckId}`);
      setRecs(out.recommendations);
    } catch (e) {
      // Fallback demo recommendations if backend is offline
      setRecs([
        {
          cargo_id: "c-rec-1",
          trip_id: "trip-1",
          match_score: 0.94,
          origin: "Pune",
          destination: "Mumbai",
          cargo_type: "Industrial Fasteners",
          cargo_weight_tons: 2.2,
          pickup_at: new Date(Date.now() + 86400000).toISOString(),
          urgency: "urgent",
          estimated_price_inr: 9200,
          reasons: ["Exact Route Match", "High Reliability Owner", "Optimal Tonnage"],
        },
      ]);
    }
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const trucks = await api.get<any[]>("/trucks");
        const t = trucks[0] ?? null;
        setTruck(t);
        if (t) {
          const trips = await api.get<any[]>(`/trucks/${t.truck_id}/trips`);
          setTrip(trips.find((x) => x.open_for_matching) ?? trips[0] ?? null);
          await loadRecs(t.truck_id);
        } else {
          // Demo truck & trip fallback
          const demoTruck = { truck_id: "t-demo-1", truck_type: "20ft Container", registration_number: "MH-12-AB-4321", default_capacity_tons: 10 };
          const demoTrip = { trip_id: "tr-demo-1", origin: "Pune", destination: "Mumbai", departure_at: new Date(Date.now() + 86400000).toISOString(), available_capacity_tons: 4.5, open_for_matching: true };
          setTruck(demoTruck);
          setTrip(demoTrip);
          await loadRecs(demoTruck.truck_id);
        }
      } catch {
        const demoTruck = { truck_id: "t-demo-1", truck_type: "20ft Container", registration_number: "MH-12-AB-4321", default_capacity_tons: 10 };
        const demoTrip = { trip_id: "tr-demo-1", origin: "Pune", destination: "Mumbai", departure_at: new Date(Date.now() + 86400000).toISOString(), available_capacity_tons: 4.5, open_for_matching: true };
        setTruck(demoTruck);
        setTrip(demoTrip);
        await loadRecs(demoTruck.truck_id);
      } finally { setLoading(false); }
    })();
  }, [loadRecs]);

  return (
    <Layout>
      <div className="space-y-8">
        {/* Welcome Header */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 text-white flex flex-wrap items-center justify-between gap-6 shadow-xl relative overflow-hidden">
          <div className="relative z-10 space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold">
              <Truck className="w-3.5 h-3.5" />
              <span>Fleet Operations Backhaul Hub</span>
            </div>
            <h1 className="text-3xl font-black tracking-tight text-white">
              Welcome back, {profile?.full_name?.split(" ")[0]}!
            </h1>
            <p className="text-xs text-slate-400 max-w-lg">
              Monetize empty return trips, track spare capacity utilization, and review AI-ranked partial cargo matches.
            </p>
          </div>

          <Button
            onClick={() => navigate("/trips/new")}
            className="!bg-emerald-600 hover:!bg-emerald-500 !text-white !py-3 !px-5 !rounded-xl !font-bold shadow-lg shadow-emerald-600/25 flex items-center gap-2"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Post New Return Trip</span>
          </Button>
        </div>

        {/* Commercial Metric Tiles */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatTile
            title="Active Return Legs"
            value={trip ? "1 Open" : "0 Open"}
            subtext="Available for cargo pairing"
            icon={<Route className="w-5 h-5" />}
          />
          <StatTile
            title="Extra Return Revenue"
            value="₹42,800"
            trend="+24%"
            subtext="Earnings from backhauls"
            icon={<TrendingUp className="w-5 h-5" />}
          />
          <StatTile
            title="Capacity Utilization"
            value="78%"
            subtext="Avg payload per return"
            icon={<Sparkles className="w-5 h-5" />}
          />
          <StatTile
            title="Verification Status"
            value="Verified"
            subtext="KYC & Insurance active"
            icon={<ShieldCheck className="w-5 h-5" />}
          />
        </div>

        {loading ? <div className="grid gap-4 md:grid-cols-2"><CardSkeleton /><CardSkeleton /></div> : (
          <>
            {!trip ? (
              <EmptyState
                title="You haven't posted a return trip yet"
                hint="Post your next empty return leg to start receiving high-matching partial cargo requests."
                action={
                  <Button onClick={() => navigate("/trips/new")} className="!bg-emerald-600">
                    Add Return Trip Now
                  </Button>
                }
              />
            ) : (
              <Card className="p-6 space-y-6">
                <div className="flex flex-wrap items-start justify-between gap-4 border-b border-slate-100 pb-5">
                  <div className="space-y-1">
                    <span className="text-[11px] font-bold tracking-wider uppercase text-slate-400">Current Return Corridor</span>
                    <div className="text-xl font-black text-slate-900 flex items-center gap-2">
                      <span>{trip.origin}</span>
                      <ArrowRight className="w-5 h-5 text-emerald-600" />
                      <span>{trip.destination}</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs font-semibold text-slate-500">
                      <Calendar className="w-3.5 h-3.5" />
                      <span>Departure: {new Date(trip.departure_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })}</span>
                    </div>
                  </div>

                  <div className="text-right">
                    <span className="text-[11px] font-bold tracking-wider uppercase text-slate-400">Assigned Vehicle</span>
                    <div className="font-bold text-slate-900 text-sm mt-0.5">{truck?.truck_type}</div>
                    <Badge tone="ok" className="mt-1">{truck?.registration_number}</Badge>
                  </div>
                </div>

                <div className="max-w-md">
                  <CapacityGauge
                    total={Number(truck?.default_capacity_tons || 10)}
                    used={Number(truck?.default_capacity_tons || 10) - Number(trip.available_capacity_tons || 4.5)}
                    label={`Available Spare Capacity: ${trip.available_capacity_tons} Tonnes`}
                  />
                </div>
              </Card>
            )}

            {/* Recommended Cargo Section */}
            <div className="space-y-4 pt-2">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-extrabold text-slate-900 flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-blue-600" />
                  <span>AI-Ranked Compatible Cargo Consignments</span>
                </h2>
                {truck && (
                  <Button variant="ghost" onClick={() => loadRecs(truck.truck_id)} className="!text-xs">
                    <RefreshCw className="w-3.5 h-3.5" />
                    <span>Refresh Matches</span>
                  </Button>
                )}
              </div>

              <div className="grid gap-4">
                {recError && truck && <ErrorState message={recError} cta="Retry" onRetry={() => loadRecs(truck.truck_id)} />}
                {!recError && recs === null && truck && <><CardSkeleton /><CardSkeleton /></>}
                {recs && recs.length === 0 && (
                  <EmptyState title="No suitable cargo matches right now." hint="New SME requests on your corridor will appear here automatically." />
                )}
                {recs?.map((r) => (
                  <Card key={r.cargo_id} hover className="p-5">
                    <div className="flex flex-wrap items-start justify-between gap-4">
                      <div className="space-y-2">
                        <div className="flex items-center gap-2 text-base font-extrabold text-slate-900">
                          <span>{r.origin}</span>
                          <ArrowRight className="w-4 h-4 text-emerald-600" />
                          <span>{r.destination}</span>
                        </div>
                        <p className="text-xs font-semibold text-slate-500">
                          {r.cargo_type} • {r.cargo_weight_tons} Tonnes • Pickup {new Date(r.pickup_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })}
                        </p>
                        <ReasonChips reasons={r.reasons} />
                      </div>

                      <MatchScore score={r.match_score} />
                    </div>

                    <div className="mt-4 pt-4 border-t border-slate-100 flex items-center justify-between">
                      <div className="text-sm">
                        <span className="font-extrabold text-slate-900 text-base">₹{r.estimated_price_inr.toLocaleString("en-IN")}</span>
                        <span className="text-xs text-slate-500 font-medium"> Est. Freight Payout</span>
                        {r.urgency !== "normal" && <Badge tone="warn" className="ml-2">{r.urgency}</Badge>}
                      </div>
                      <Link to="/bookings" className="text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1">
                        <span>View Booking Status</span>
                        <ArrowRight className="w-3.5 h-3.5" />
                      </Link>
                    </div>
                  </Card>
                ))}
              </div>
            </div>
          </>
        )}
      </div>
    </Layout>
  );
}

