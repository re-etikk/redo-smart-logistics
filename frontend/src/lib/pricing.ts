// Shared indicative pricing helper (frontend display only — backend authoritative).
export const estimateFromDistance = (distanceKm?: number | null, weightTons?: number | null, rate = 1.05) =>
  Math.round(Number(distanceKm || 0) * Number(weightTons || 0) * rate) || 0;
