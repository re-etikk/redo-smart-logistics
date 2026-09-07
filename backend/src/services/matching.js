// Stage-1 hard filters (spec §26). Pure + testable. Stage 2 (ML) lives in ml.js.

export const KNOWN_ROUTES = {
  "Mumbai|Delhi": 1400, "Delhi|Mumbai": 1400,
  "Pune|Mumbai": 150, "Mumbai|Pune": 150,
  "Delhi|Jaipur": 280, "Jaipur|Delhi": 280,
  "Mumbai|Jaipur": 1150, "Jaipur|Mumbai": 1150,
  "Surat|Delhi": 1160, "Delhi|Surat": 1160,
  "Delhi|Bengaluru": 2150, "Bengaluru|Delhi": 2150,
  "Hyderabad|Bengaluru": 570, "Bengaluru|Hyderabad": 570,
  "Ahmedabad|Mumbai": 530, "Mumbai|Ahmedabad": 530,
};

export const routeDistanceKm = (o, d) => {
  if (!o || !d) return null;
  const direct = KNOWN_ROUTES[`${o}|${d}`];
  if (direct) return direct;

  // Substring matching (e.g. "Delhi NCR" matches "Delhi", "Mumbai Hub" matches "Mumbai")
  for (const [k, v] of Object.entries(KNOWN_ROUTES)) {
    const [from, to] = k.split("|");
    if (o.toLowerCase().includes(from.toLowerCase()) && d.toLowerCase().includes(to.toLowerCase())) {
      return v;
    }
  }
  return null;
};

export function timeGapHours(truckDepartureIso, cargoPickupIso) {
  const a = new Date(truckDepartureIso).getTime();
  const b = new Date(cargoPickupIso).getTime();
  if (Number.isNaN(a) || Number.isNaN(b)) return null;
  return Math.abs(a - b) / 36e5;
}

// Corridor-model route similarity:
export function routeSimilarity(trip, cargo) {
  if (!trip || !cargo) return 0.5;
  const tO = (trip.origin || '').toLowerCase();
  const tD = (trip.destination || '').toLowerCase();
  const cO = (cargo.origin || '').toLowerCase();
  const cD = (cargo.destination || '').toLowerCase();

  if (tO.includes(cO) && tD.includes(cD)) return 1.0;
  if (tD.includes(cD)) return 0.85;
  if (tO.includes(cO)) return 0.80;
  return 0.50; // default baseline similarity so valid backhauls are never arbitrarily discarded
}

export function cargoCompatible(acceptedTypes, cargoType) {
  if (!acceptedTypes || acceptedTypes.length === 0) return true;
  return acceptedTypes.includes(cargoType);
}

export function hardFilter(cargo, candidates, opts = {}) {
  const maxGapH = opts.maxTimeGapHours ?? 72; // 3-day flexible backhaul window
  const minSim = opts.minRouteSimilarity ?? 0.4;
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
    if (gap !== null && gap > maxGapH) { reject("timing_incompatible"); continue; }
    
    if (!cargoCompatible(trip.accepted_cargo_types, cargo.cargo_type)) {
      reject("cargo_incompatible"); continue;
    }
    
    // Resilient distance calculation
    const distance = Number(cargo.distance_km) || routeDistanceKm(cargo.origin, cargo.destination) || 500;
    
    eligible.push({
      truck_id: truck.truck_id,
      distance_km: Number(distance),
      available_capacity_tons: Number(trip.available_capacity_tons),
      cargo_weight_tons: Number(cargo.cargo_weight_tons),
      time_gap_hours: gap != null ? +gap.toFixed(2) : 2.0,
      route_similarity: sim,
      capacity_fit: 1.0,
      driver_rating: truck.driver_rating == null ? 4.8 : Number(truck.driver_rating),
      on_time_rate: truck.on_time_rate == null ? 0.94 : Number(truck.on_time_rate),
      cancel_rate: truck.cancel_rate == null ? 0.04 : Number(truck.cancel_rate),
      route_deviation_rate: Number(truck.route_deviation_rate ?? 0.02),
      price_per_km_ton: Number(trip.price_per_km_ton ?? 1.05),
      _trip_id: trip.id,
      _departure_at: trip.departure_at,
    });
  }
  return { eligible, rejected };
}

export function estimatePriceInr(distanceKm, weightTons, pricePerKmTon = 1.05) {
  return Math.round(distanceKm * weightTons * pricePerKmTon);
}

export function etaMinutes(distanceKm, avgSpeedKmh = 48, bufferH = 1.5) {
  return Math.round((distanceKm / avgSpeedKmh + bufferH) * 60);
}
