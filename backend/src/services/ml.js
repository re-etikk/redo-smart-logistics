import { apiError } from "../middleware/error.js";

const ML_URL = process.env.ML_SERVICE_URL || "https://redo-ml.onrender.com";

// Heuristic fallback for cold starts / temporary Render sleeping states
function heuristicRanking(candidates, topK = 5) {
  const scored = candidates.map((c) => {
    const sim = Number(c.route_similarity ?? 0.8);
    const cap = Number(c.capacity_fit ?? 1.0);
    const rating = (Number(c.driver_rating ?? 4.5)) / 5.0;
    const ontime = Number(c.on_time_rate ?? 0.9);
    const gap = Number(c.time_gap_hours ?? 2.0);
    const gapBonus = Math.max(0, 1.0 - (gap / 12.0)) * 0.05;
    const score = +(Math.min(0.98, Math.max(0.40, 0.40 * sim + 0.20 * cap + 0.20 * rating + 0.15 * ontime + gapBonus))).toFixed(4);

    const reasons = [];
    if (sim >= 0.85) reasons.push("Route aligned");
    if (gap <= 2) reasons.push("Timing aligned");
    if (rating >= 0.85) reasons.push("Reliable driver");
    if (reasons.length === 0) reasons.push("Meets basic requirements");

    return {
      truck_id: c.truck_id,
      cargo_id: c.cargo_id,
      match_score: score,
      reasons,
    };
  });

  scored.sort((a, b) => b.match_score - a.match_score);
  return {
    model_backend: "heuristic-fallback",
    recommendations: scored.slice(0, topK),
    eligible_count: candidates.length,
    rejected_count: 0,
  };
}

// Stage-2 ranking: Primary ML call with automatic heuristic fallback if ML service is sleeping/down
export async function rankCandidates(candidates, topK = 5) {
  try {
    const res = await fetch(`${ML_URL}/rank-candidates`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ candidates, top_k: topK }),
      signal: AbortSignal.timeout(10000),
    });
    if (res.ok) {
      return await res.json();
    }
  } catch (err) {
    console.warn(`[ML Service] Warning: ${ML_URL} unreachable (${err.message}). Using heuristic ranking fallback.`);
  }

  // Graceful fallback — keeps the marketplace fully functional even during cold starts
  return heuristicRanking(candidates, topK);
}

export async function mlHealth() {
  try {
    const res = await fetch(`${ML_URL}/health`, { signal: AbortSignal.timeout(5000) });
    return res.ok ? await res.json() : { status: "down" };
  } catch { return { status: "down" }; }
}
