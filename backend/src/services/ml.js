import { apiError } from "../middleware/error.js";

const ML_URL = process.env.ML_SERVICE_URL || "http://localhost:8001";

// Stage-2 ranking. On ML failure we DO NOT invent scores (spec §30):
// the error propagates as MATCHING_UNAVAILABLE and the UI shows Retry.
export async function rankCandidates(candidates, topK = 5) {
  let res;
  try {
    res = await fetch(`${ML_URL}/rank-candidates`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ candidates, top_k: topK }),
      signal: AbortSignal.timeout(8000),
    });
  } catch {
    throw apiError(503, "MATCHING_UNAVAILABLE", "Matching service is temporarily unavailable.");
  }
  if (!res.ok) throw apiError(503, "MATCHING_UNAVAILABLE", "Matching service is temporarily unavailable.");
  return res.json();
}

export async function mlHealth() {
  try {
    const res = await fetch(`${ML_URL}/health`, { signal: AbortSignal.timeout(3000) });
    return res.ok ? await res.json() : { status: "down" };
  } catch { return { status: "down" }; }
}
