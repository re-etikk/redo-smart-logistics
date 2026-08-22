import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { CalendarCheck, IndianRupee, Star, Truck } from "lucide-react";
import Layout from "../../components/Layout";
import { api, ApiError } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import {
  Badge, Button, Card, CardSkeleton, EmptyState, ErrorState, MatchScore,
  ReasonChips, StatCard, statusLabel, statusTone,
} from "../../components/ui";
import type { Booking, CargoRec } from "../../lib/types";

export default function OwnerDashboard() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [trucks, setTrucks] = useState<any[] | null>(null);
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const [earnings, setEarnings] = useState<any | null>(null);
  const [recs, setRecs] = useState<CargoRec[] | null>(null);
  const [recError, setRecError] = useState<string | null>(null);

  const loadRecs = useCallback(async (truckId: string) => {
    setRecError(null); setRecs(null);
    try {
      const out = await api.get<{ recommendations: CargoRec[] }>(`/recommendations/cargo/${truckId}`);
      setRecs(out.recommendations);
    } catch (e) {
      setRecError(e instanceof ApiError && e.code === "MATCHING_UNAVAILABLE"
        ? "Smart matching is temporarily unavailable." : "Could not load recommendations.");
    }
  }, []);

  useEffect(() => {
    api.get<any[]>("/trucks").then((t) => { setTrucks(t); if (t[0]) loadRecs(t[0].truck_id); }).catch(() => setTrucks([]));
    api.get<Booking[]>("/bookings").then(setBookings).catch(() => setBookings([]));
    api.get<any>("/earnings").then(setEarnings).catch(() => {});
  }, [loadRecs]);

  const b = bookings ?? [];
  const avgRating = trucks?.length ? (trucks.reduce((a, t) => a + Number(t.driver_rating || 0), 0) / trucks.length).toFixed(1) : "—";

  return (
    <Layout>
      {/* Hero banner */}
      <Card className="p-6 md:p-8 bg-gradient-to-r from-brand-soft to-white border-brand/30 overflow-hidden relative">
        <div className="max-w-md">
          <h1 className="text-3xl font-extrabold text-ink leading-tight">More Loads.<br /><span className="text-brand-dark">More Earnings.</span></h1>
          <p className="mt-2 text-sm text-ink-soft">List your truck, get more bookings and grow your business with Redo.</p>
          <div className="mt-4 flex gap-3">
            <Button onClick={() => navigate("/trucks")}>+ Add Truck</Button>
            <Button variant="secondary" onClick={() => navigate("/shipments")}>View Bookings</Button>
          </div>
        </div>
        <Truck size={140} className="hidden md:block absolute right-6 top-1/2 -translate-y-1/2 text-brand/25" aria-hidden="true" />
      </Card>

      <div className="mt-5 grid gap-4 grid-cols-2 xl:grid-cols-4">
        <StatCard icon={Truck} label="Total Trucks" value={trucks?.length ?? "—"} sub="Active" tone="ok" />
        <StatCard icon={CalendarCheck} label="Total Bookings" value={b.length} sub="All time" tone="info" />
        <StatCard icon={IndianRupee} label="Total Earnings" value={`₹${Number(earnings?.totals?.completed_inr ?? 0).toLocaleString("en-IN")}`} sub="Completed trips" tone="purple" />
        <StatCard icon={Star} label="Average Rating" value={avgRating} sub={trucks?.length ? `Across ${trucks.length} trucks` : ""} tone="warn" />
      </div>

      <div className="mt-6 grid gap-5 xl:grid-cols-[1fr_340px]">
        <Card className="p-5">
          <div className="flex items-center justify-between">
            <h2 className="font-bold text-ink">Recent Bookings</h2>
            <Link to="/shipments" className="text-sm font-semibold text-info">View All →</Link>
          </div>
          {bookings === null ? <div className="mt-4"><CardSkeleton /></div> : b.length === 0 ? (
            <div className="mt-4"><EmptyState title="No bookings yet." hint="Accept a load to start earning on returns."
              action={<Button onClick={() => navigate("/loads")}>Browse Available Loads</Button>} /></div>
          ) : (
            <div className="mt-2 divide-y divide-line">
              {b.slice(0, 5).map((x) => (
                <button key={x.id} onClick={() => navigate(`/bookings/${x.id}`)}
                  className="w-full py-3.5 flex items-center gap-4 text-left hover:bg-canvas/60 rounded-lg px-2 -mx-2">
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-ink text-sm">{x.cargo.origin} → {x.cargo.destination}</p>
                    <p className="text-xs text-ink-faint">{new Date(x.created_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })} · {x.cargo.cargo_weight_tons} T</p>
                  </div>
                  <span className="font-bold text-sm tabular-nums">₹{Number(x.agreed_price_inr || 0).toLocaleString("en-IN")}</span>
                  <Badge tone={statusTone(x.status)}>{statusLabel(x.status)}</Badge>
                </button>
              ))}
            </div>
          )}
        </Card>

        <div className="space-y-4">
          <Card className="p-5">
            <div className="flex items-center justify-between">
              <h2 className="font-bold text-ink">Recommended Loads</h2>
              {trucks?.[0] && <button className="text-xs font-semibold text-info" onClick={() => loadRecs(trucks[0].truck_id)}>Refresh</button>}
            </div>
            <div className="mt-3 space-y-3">
              {recError && trucks?.[0] && <ErrorState message={recError} cta="Retry" onRetry={() => loadRecs(trucks[0].truck_id)} />}
              {!recError && recs === null && trucks !== null && trucks.length > 0 && <CardSkeleton />}
              {trucks !== null && trucks.length === 0 && (
                <p className="text-sm text-ink-faint">Add a truck and post a return trip to see ML-matched loads.</p>
              )}
              {recs?.length === 0 && <p className="text-sm text-ink-faint">No matching loads on your corridor right now.</p>}
              {recs?.slice(0, 3).map((r) => (
                <div key={r.cargo_id} className="rounded-xl border border-line p-3">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-bold text-ink text-sm">{r.origin} → {r.destination}</p>
                      <p className="text-xs text-ink-soft">{r.cargo_type} · {r.cargo_weight_tons} T</p>
                    </div>
                    <MatchScore score={r.match_score} />
                  </div>
                  <div className="mt-2"><ReasonChips reasons={r.reasons.slice(0, 2)} /></div>
                  <p className="mt-2 text-sm font-bold">₹{r.estimated_price_inr.toLocaleString("en-IN")} <span className="font-medium text-ink-faint text-xs">estimated</span></p>
                </div>
              ))}
              <Link to="/loads" className="block text-center text-sm font-semibold text-info">See all available loads →</Link>
            </div>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
