import { apiError } from "../middleware/error.js";

import { onlineModel } from "./onlineModel.js";

const ML_URL = process.env.ML_SERVICE_URL || "https://redo-ml.onrender.com";

// Primary Online Learning Ranking Engine (continually updates without batch retraining)
export async function rankCandidates(candidates, topK = 5) {
  // If remote microservice is explicitly configured and responds quickly, check it;
  // otherwise, default to the local Online Continual Learning engine that auto-updates in real time.
  try {
    if (process.env.USE_REMOTE_ML === "true") {
      const res = await fetch(`${ML_URL}/rank-candidates`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ candidates, top_k: topK }),
        signal: AbortSignal.timeout(3000),
      });
      if (res.ok) {
        return await res.json();
      }
    }
  } catch (_) {}

  // High-performance Online Learning model with live gradient updates
  return onlineModel.rankCandidates(candidates, topK);
}

export { onlineModel };

export async function mlHealth() {
  try {
    const res = await fetch(`${ML_URL}/health`, { signal: AbortSignal.timeout(5000) });
    return res.ok ? await res.json() : { status: "down" };
  } catch { return { status: "down" }; }
}
