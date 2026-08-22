import { useEffect, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import Layout from "../components/Layout";
import MapPanel from "../components/MapPanel";
import { api, ApiError } from "../services/api";
import { Button, Card, ErrorState, MatchScore, Rating, ReasonChips, VerifiedBadge, useToast } from "../components/ui";
import type { Recommendation } from "../lib/types";

export default function MatchDetail() {
  const { cargoId = "", truckId = "" } = useParams();
  const state = (useLocation().state ?? {}) as { rec?: Recommendation; cargo?: any };
  const [rec, setRec] = useState<Recommendation | null>(state.rec ?? null);
  const [cargo, setCargo] = useState<any | null>(state.cargo ?? null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const toast = useToast();

  useEffect(() => {
    if (rec && cargo) return;
    (async () => {
      try {
        const c = await api.get<any>(`/cargo/${cargoId}`);
        setCargo(c);
        const out = await api.get<{ recommendations: Recommendation[] }>(`/recommendations/trucks/${cargoId}`);
        const found = out.recommendations.find((r) => r.truck_id === truckId);
        if (!found) setError("This match is no longer available."); else setRec(found);
      } catch (e) {
        setError(e instanceof ApiError && e.code === "MATCHING_UNAVAILABLE"
          ? "Matching service is temporarily unavailable." : "Couldn't load this match.");
      }
    })();
  }, [cargoId, truckId, rec, cargo]);

  const book = async () => {
    if (!rec) return;
    setBusy(true);
    try {
      const b = await api.post<{ id: string }>("/bookings", {
        cargo_id: cargoId, truck_id: rec.truck_id, trip_id: rec.trip_id,
        match_score: rec.match_score, agreed_price_inr: rec.estimated_price_inr,
      });
      toast("Booking requested — the owner has been notified");
      navigate(`/bookings/${b.id}`);
    } catch (e: any) { toast(e.message, "danger"); setBusy(false); }
  };

  if (error) return <Layout><ErrorState message={error} onRetry={() => window.location.reload()} /></Layout>;
  if (!rec || !cargo) return <Layout><p className="text-sm text-ink-faint animate-pulse">Loading match…</p></Layout>;

  const etaAt = new Date(new Date(rec.departure_at).getTime() + rec.eta_minutes * 60000);
  return (
    <Layout>
      <div className="grid gap-6 lg:grid-cols-[1fr_380px]">
        <div>
          <div className="flex items-start justify-between">
            <div>
              <h1 className="text-2xl font-extrabold text-ink">{cargo.origin} → {cargo.destination}</h1>
              <p className="text-sm text-ink-soft mt-1">{cargo.cargo_type} · {cargo.cargo_weight_tons} T</p>
            </div>
            <MatchScore score={rec.match_score} />
          </div>
          <div className="mt-4"><MapPanel origin={cargo.origin} destination={cargo.destination} /></div>
          <Card className="mt-4 p-5">
            <h2 className="font-bold text-ink">Why this match?</h2>
            <div className="mt-2"><ReasonChips reasons={rec.reasons} /></div>
            <p className="mt-3 text-xs text-ink-faint">Score produced by the Redo match model from live route, timing, capacity and reliability features.</p>
          </Card>
        </div>
        <div className="space-y-4">
          <Card className="p-5">
            <div className="flex items-center justify-between">
              <p className="font-bold text-ink">{rec.truck_type} · {rec.registration_number}</p>
              {rec.verified_documents && <VerifiedBadge />}
            </div>
            <dl className="mt-4 grid grid-cols-2 gap-3 text-sm">
              <div><dt className="text-ink-faint">Price</dt><dd className="font-bold text-ink">₹{rec.estimated_price_inr.toLocaleString("en-IN")}</dd></div>
              <div><dt className="text-ink-faint">Free capacity</dt><dd className="font-bold text-ink">{rec.capacity_available_tons} T</dd></div>
              <div><dt className="text-ink-faint">Departure</dt><dd className="font-semibold text-ink">{new Date(rec.departure_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })}</dd></div>
              <div><dt className="text-ink-faint">Estimated ETA</dt><dd className="font-semibold text-ink">{etaAt.toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })}</dd></div>
              <div><dt className="text-ink-faint">Reliability</dt><dd className="font-semibold text-ink">{Math.round(rec.reliability_score * 100)}/100</dd></div>
              <div><dt className="text-ink-faint">On-time rate</dt><dd className="font-semibold text-ink">{Math.round(rec.on_time_rate * 100)}%</dd></div>
              <div><dt className="text-ink-faint">Driver rating</dt><dd><Rating value={rec.driver_rating} /></dd></div>
            </dl>
            <Button className="w-full mt-5" onClick={book} disabled={busy}>{busy ? "Requesting…" : "Request booking"}</Button>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
