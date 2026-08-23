// Stage-1 hard filters (spec §26). Pure + testable. Stage 2 (ML) lives in ml.js.

export const KNOWN_ROUTES = {
  "Mumbai|Delhi": 1400, "Delhi|Mumbai": 1400,
  "Pune|Mumbai": 150, "Mumbai|Pune": 150,
  "Delhi|Jaipur": 280, "Jaipur|Delhi": 280,
  "Mumbai|Jaipur": 1150, "Jaipur|Mumbai": 1150,
  "Surat|Delhi": 1160, "Delhi|Surat": 1160,
  "Delhi|Bengaluru": 2150, "Hyderabad|Bengaluru": 570,
};

export const routeDistanceKm = (o, d) => KNOWN_ROUTES[`${o}|${d}`] ?? null;

export function timeGapHours(truckDepartureIso, cargoPickupIso) {
  const a = new Date(truckDepartureIso).getTime();
  const b = new Date(cargoPickupIso).getTime();
  if (Number.isNaN(a) || Number.isNaN(b)) return null;
  return Math.abs(a - b) / 36e5;
}

// Simple corridor-model route similarity:
// same O+D = 1.0; same destination = 0.75; same origin = 0.7; else 0.
export function routeSimilarity(trip, cargo) {
  if (trip.origin === cargo.origin && trip.destination === cargo.destination) return 1.0;
  if (trip.destination === cargo.destination) return 0.75;
  if (trip.origin === cargo.origin) return 0.7;
  return 0;
}

export function cargoCompatible(acceptedTypes, cargoType) {
  if (!acceptedTypes || acceptedTypes.length === 0) return true;
  return acceptedTypes.includes(cargoType);
}

export function hardFilter(cargo, candidates, opts = {}) {
  const maxGapH = opts.maxTimeGapHours ?? 12;
  const minSim = opts.minRouteSimilarity ?? 0.5;
  const eligible = [], rejected = [];
  for (const { truck, trip } of candidates) {
    const reject = (reason) => rejected.push({ truck_id: truck.truck_id, reason });
    if (truck.status !== "available") { reject("truck_unavailable"); continue; }
    const sim = routeSimilarity(trip, cargo);
    if (sim < minSim) { reject("route_mismatch"); continue; }
    if (Number(trip.available_capacity_tons) < Number(cargo.cargo_weight_tons)) {
      reject("insufficient_capacity"); continue;
    }
    const gap = timeGapHours(trip.departure_at, cargo.pickup_at);
    if (gap === null || gap > maxGapH) { reject("timing_incompatible"); continue; }
    if (!cargoCompatible(trip.accepted_cargo_types, cargo.cargo_type)) {
      reject("cargo_incompatible"); continue;
    }
    const distance = cargo.distance_km ?? routeDistanceKm(cargo.origin, cargo.destination);
    if (!distance) { reject("unknown_route"); continue; }
    eligible.push({
      truck_id: truck.truck_id,
      distance_km: Number(distance),
      available_capacity_tons: Number(trip.available_capacity_tons),
      cargo_weight_tons: Number(cargo.cargo_weight_tons),
      time_gap_hours: +gap.toFixed(2),
      route_similarity: sim,
      capacity_fit: 1.0,
      // Neutral priors for brand-new (unrated) trucks — used ONLY for scoring.
      // The API/UI still expose null so nobody ever sees a fabricated rating.
      driver_rating: truck.driver_rating == null ? 4.0 : Number(truck.driver_rating),
      on_time_rate: truck.on_time_rate == null ? 0.85 : Number(truck.on_time_rate),
      cancel_rate: truck.cancel_rate == null ? 0.05 : Number(truck.cancel_rate),
      route_deviation_rate: Number(truck.route_deviation_rate ?? 0.03),
      price_per_km_ton: Number(trip.price_per_km_ton ?? 1.0),
      // context passthrough for pricing/UI
      _trip_id: trip.id, _departure_at: trip.departure_at,
    });
  }
  return { eligible, rejected };
}

export function estimatePriceInr(distanceKm, weightTons, pricePerKmTon = 1.0) {
  return Math.round(distanceKm * weightTons * pricePerKmTon);
}

export function etaMinutes(distanceKm, avgSpeedKmh = 42, bufferH = 2) {
  return Math.round((distanceKm / avgSpeedKmh + bufferH) * 60);
}
