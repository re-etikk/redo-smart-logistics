import type { TruckItem } from "./truckStore";
import type { CargoItem } from "./cargoStore";
import { estimateFairPrice } from "./locationService";

export interface MLMatchResult {
  truck: TruckItem;
  cargo: CargoItem;
  matchScore: number; // 0 - 100
  matchGrade: "A+ (Optimal Backhaul)" | "A (Strong Match)" | "B (Compatible)";
  routeSimilarity: number;
  capacityFitPercent: number;
  explainableReasons: string[];
  recommendedPriceInr: number;
  carbonReductionKg: number;
}

export function computeMLMatches(cargo: CargoItem, fleet: TruckItem[]): MLMatchResult[] {
  if (!fleet || fleet.length === 0) return [];

  const results: MLMatchResult[] = fleet.map((truck) => {
    // 1. Route similarity
    const originMatch = truck.operatingRoutes.some(r =>
      r.toLowerCase().includes(cargo.origin.toLowerCase().split(" ")[0]) ||
      cargo.origin.toLowerCase().includes(r.toLowerCase().split(" ")[0])
    );
    const destMatch = truck.operatingRoutes.some(r =>
      r.toLowerCase().includes(cargo.destination.toLowerCase().split(" ")[0]) ||
      cargo.destination.toLowerCase().includes(r.toLowerCase().split(" ")[0])
    );

    let routeScore = 0.5;
    if (originMatch && destMatch) routeScore = 1.0;
    else if (originMatch || destMatch) routeScore = 0.8;

    // 2. Capacity Fit
    const capRatio = cargo.weightTons / truck.capacityTons;
    let capScore = 0.4;
    let capFitPct = Math.round(capRatio * 100);

    if (capRatio > 0.6 && capRatio <= 1.0) {
      capScore = 1.0; // Perfect full utilization
    } else if (capRatio <= 0.6) {
      capScore = 0.75; // Partial load
    } else {
      capScore = 0.2; // Overweight
    }

    // 3. Driver & Fleet Reliability
    const driverScore = (truck.driverRating || 4.5) / 5.0;

    // 4. KYC & Verification Boost
    const kycBoost = truck.status === "Available" ? 1.0 : 0.7;

    // Multivariate Logistic Formula
    const rawScore =
      0.35 * routeScore +
      0.25 * capScore +
      0.20 * driverScore +
      0.20 * kycBoost;

    const matchScore = Math.min(99.5, Math.round((rawScore * 100) * 10) / 10);

    const reasons: string[] = [];
    if (routeScore >= 0.8) reasons.push("Direct Return Route Corridor");
    if (capScore >= 0.8) reasons.push(`Optimal ${truck.capacityTons}T Payload Fit`);
    if (truck.driverRating >= 4.8) reasons.push("Top Rated Verified Driver");
    if (truck.status === "Available") reasons.push("Ready for Immediate Dispatch");
    if (reasons.length === 0) reasons.push("Standard Compatible Backhaul");

    const matchGrade =
      matchScore >= 90 ? "A+ (Optimal Backhaul)" : matchScore >= 75 ? "A (Strong Match)" : "B (Compatible)";

    const fairPrice = estimateFairPrice(cargo.distanceKm || 650, cargo.weightTons);
    const co2Saved = Math.round((cargo.distanceKm || 650) * 0.85);

    return {
      truck,
      cargo,
      matchScore,
      matchGrade,
      routeSimilarity: Math.round(routeScore * 100),
      capacityFitPercent: Math.min(100, capFitPct),
      explainableReasons: reasons,
      recommendedPriceInr: fairPrice,
      carbonReductionKg: co2Saved,
    };
  });

  // Sort descending by highest ML match score
  return results.sort((a, b) => b.matchScore - a.matchScore);
}
