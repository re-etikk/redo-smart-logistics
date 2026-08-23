import { useCallback, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import Layout from "../components/Layout";
import { api, ApiError } from "../lib/api";
import {
  Button, Card, CardSkeleton, EmptyState, ErrorState, MatchScore,
  Rating, ReasonChips, VerifiedBadge,
} from "../components/ui";
import type { Recommendation } from "../lib/types";

export default function Recommendations() {
  const { cargoId = "" } = useParams();
  const navigate = useNavigate();
  const [cargo, setCargo] = useState<any | null>(null);
  const [recs, setRecs] = useState<Recommendation[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null); setRecs(null);
    try {
      const [c, out] = await Promise.all([
        api.get<any>(`/cargo/${cargoId}`),
        api.get<{ recommendations: Recommendation[] }>(`/recommendations/trucks/${cargoId}`),
      ]);
      setCargo(c); setRecs(out.recommendations);
    } catch (e) {
      setError(e instanceof ApiError && e.code === "MATCHING_UNAVAILABLE"
        ? "Matching service is temporarily unavailable." : "We couldn't load your recommendations.");
    }
  }, [cargoId]);

  useEffect(() => { load(); }, [load]);

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Best matches for your shipment</h1>
      {cargo && <p className="text-sm text-ink-soft mt-1">{cargo.origin} → {cargo.destination} · {cargo.cargo_type} · {cargo.cargo_weight_tons} T</p>}
      <div className="mt-6 grid gap-4">
        {error && <ErrorState message={error} cta="Retry" onRetry={load} />}
        {!error && recs === null && (
          <>
            <p className="text-sm font-medium text-ink-faint animate-pulse">Finding suitable backhaul capacity…</p>
            <CardSkeleton /><CardSkeleton />
          </>
        )}
        {recs?.length === 0 && (
          <EmptyState title="No suitable backhaul capacity found." hint="Try widening your pickup window."
            action={<Button variant="secondary" onClick={() => navigate("/post-cargo")}>Adjust pickup window</Button>} />
        )}
        {recs?.map((r) => (
          <Card key={r.truck_id} hover className="p-5">
            <div className="flex items-start justify-between gap-4">
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <p className="font-bold text-ink">{r.truck_type} truck · {r.registration_number}</p>
                  {r.verified_documents && <VerifiedBadge />}
                </div>
                <p className="text-sm text-ink-soft mt-0.5">
                  Departs {new Date(r.departure_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })} ·{" "}
                  {r.capacity_available_tons} T free · <Rating value={r.driver_rating} />
                </p>
                <div className="mt-2"><ReasonChips reasons={r.reasons} /></div>
              </div>
              <MatchScore score={r.match_score} />
            </div>
            <div className="mt-4 flex items-center justify-between">
              <p className="text-sm"><span className="font-bold text-ink">₹{r.estimated_price_inr.toLocaleString("en-IN")}</span><span className="text-ink-faint"> estimated</span></p>
              <Button onClick={() => navigate(`/match/${cargoId}/${r.truck_id}`, { state: { rec: r, cargo } })}>View match</Button>
            </div>
          </Card>
        ))}
      </div>
    </Layout>
  );
}
