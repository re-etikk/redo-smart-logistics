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
  "Delhi|Hyderabad": 1530, "Hyderabad|Delhi": 1530,
  "Delhi|Kolkata": 1500, "Kolkata|Delhi": 1500,
  "Delhi|Chennai": 2200, "Chennai|Delhi": 2200,
  "Mumbai|Hyderabad": 710, "Hyderabad|Mumbai": 710,
  "Mumbai|Bengaluru": 980, "Bengaluru|Mumbai": 980,
  "Mumbai|Kolkata": 1960, "Kolkata|Mumbai": 1960,
  "Mumbai|Chennai": 1340, "Chennai|Mumbai": 1340,
  "Chennai|Bengaluru": 350, "Bengaluru|Chennai": 350,
  "Chennai|Hyderabad": 630, "Hyderabad|Chennai": 630,
  "Kolkata|Hyderabad": 1490, "Hyderabad|Kolkata": 1490,
  "Delhi|Pune": 1450, "Pune|Delhi": 1450,
  "Delhi|Ahmedabad": 930, "Ahmedabad|Delhi": 930,
  "Delhi|Lucknow": 550, "Lucknow|Delhi": 550,
  "Delhi|Kanpur": 490, "Kanpur|Delhi": 490,
  "Delhi|Nagpur": 1080, "Nagpur|Delhi": 1080,
  "Delhi|Indore": 810, "Indore|Delhi": 810,
  "Ahmedabad|Surat": 260, "Surat|Ahmedabad": 260,
};

export const routeDistanceKm = (o, d) => {
  if (!o || !d) return null;
  const direct = KNOWN_ROUTES[`${o}|${d}`];
  if (direct) return direct;

  const nO = normCity(o);
  const nD = normCity(d);
  for (const [k, v] of Object.entries(KNOWN_ROUTES)) {
    const [from, to] = k.split("|");
    const nf = normCity(from);
    const nt = normCity(to);
    if ((nO.includes(nf) || nf.includes(nO)) && (nD.includes(nt) || nt.includes(nD))) {
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

export function normCity(s) {
  if (!s) return "";
  let c = s.toLowerCase().split(",")[0].trim()
    .replace(/\b(hub|junction|station|terminal|city|ncr|depot|wharf|port|area|district|industrial)\b/gi, " ")
    .replace(/[^\w\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (c.includes("delhi") || c.includes("gurugram") || c.includes("noida")) return "delhi";
  if (c.includes("mumbai") || c.includes("navi mumbai") || c.includes("thane")) return "mumbai";
  if (c.includes("hyderabad") || c.includes("secunderabad")) return "hyderabad";
  if (c.includes("bengaluru") || c.includes("bangalore")) return "bengaluru";
  if (c.includes("kolkata") || c.includes("calcutta")) return "kolkata";
  if (c.includes("chennai") || c.includes("madras")) return "chennai";
  return c;
}

// Corridor-model route similarity:
export function routeSimilarity(trip, cargo) {
  if (!trip || !cargo) return 0.5;
  const tO = normCity(trip.origin);
  const tD = normCity(trip.destination);
  const cO = normCity(cargo.origin);
  const cD = normCity(cargo.destination);

  const oMatch = tO && cO && (tO.includes(cO) || cO.includes(tO));
  const dMatch = tD && cD && (tD.includes(cD) || cD.includes(tD));
  const revMatch = tO && cD && (tO.includes(cD) || cD.includes(tO)) && tD && cO && (tD.includes(cO) || cO.includes(tD));

  if (oMatch && dMatch) return 1.0;
  if (revMatch) return 0.95; // perfect return corridor / backhaul load
  if (dMatch) return 0.85;
  if (oMatch) return 0.80;
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
