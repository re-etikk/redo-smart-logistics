import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api, ApiError } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import {
  Button, Card, CardSkeleton, CapacityGauge, EmptyState, ErrorState,
  MatchScore, ReasonChips, Badge,
} from "../../components/ui";
import type { CargoRec } from "../../lib/types";

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
      setRecError(e instanceof ApiError && e.code === "MATCHING_UNAVAILABLE"
        ? "Smart matching is temporarily unavailable." : "We couldn't load your recommendations.");
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
        }
      } finally { setLoading(false); }
    })();
  }, [loadRecs]);

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Hello, {profile?.full_name?.split(" ")[0]}</h1>
      {loading ? <div className="mt-6 grid gap-4 md:grid-cols-2"><CardSkeleton /><CardSkeleton /></div> : (
        <>
          {!trip ? (
            <div className="mt-6">
              <EmptyState title="You haven't posted a trip yet." hint="Post your next return leg to start receiving cargo matches."
                action={<Button onClick={() => navigate("/trips/new")}>Add return trip</Button>} />
            </div>
          ) : (
            <Card className="mt-6 p-6">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wide text-ink-faint">Next return</p>
                  <p className="mt-1 text-xl font-bold text-ink">{trip.origin} → {trip.destination}</p>
                  <p className="text-sm text-ink-soft">{new Date(trip.departure_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs font-semibold uppercase tracking-wide text-ink-faint">Truck</p>
                  <p className="mt-1 font-semibold text-ink">{truck.truck_type} · {truck.registration_number}</p>
                </div>
              </div>
              <div className="mt-5 max-w-md">
                <CapacityGauge total={Number(truck.default_capacity_tons)}
                  used={Number(truck.default_capacity_tons) - Number(trip.available_capacity_tons)}
                  label={`Available on this return: ${trip.available_capacity_tons} T`} />
              </div>
            </Card>
          )}

          <div className="mt-8 flex items-center justify-between">
            <h2 className="text-lg font-bold text-ink">Recommended cargo</h2>
            {truck && <Button variant="ghost" onClick={() => loadRecs(truck.truck_id)}>Refresh</Button>}
          </div>
          <div className="mt-3 grid gap-4">
            {recError && truck && <ErrorState message={recError} cta="Retry" onRetry={() => loadRecs(truck.truck_id)} />}
            {!recError && recs === null && truck && <><CardSkeleton /><CardSkeleton /></>}
            {recs && recs.length === 0 && (
              <EmptyState title="No suitable cargo right now." hint="New SME requests on your corridor will appear here." />
            )}
            {recs?.map((r) => (
              <Card key={r.cargo_id} hover className="p-5">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="font-bold text-ink">{r.origin} → {r.destination}</p>
                    <p className="text-sm text-ink-soft mt-0.5">{r.cargo_type} · {r.cargo_weight_tons} T · pickup {new Date(r.pickup_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })}</p>
                    <div className="mt-2"><ReasonChips reasons={r.reasons} /></div>
                  </div>
                  <MatchScore score={r.match_score} />
                </div>
                <div className="mt-4 flex items-center justify-between">
                  <p className="text-sm"><span className="font-bold text-ink">₹{r.estimated_price_inr.toLocaleString("en-IN")}</span>
                    <span className="text-ink-faint"> estimated</span> {r.urgency !== "normal" && <Badge tone="warn">{r.urgency}</Badge>}</p>
                  <Link to="/bookings" className="text-sm font-semibold text-accent">Requests appear in Bookings →</Link>
                </div>
              </Card>
            ))}
          </div>
        </>
      )}
    </Layout>
  );
}
