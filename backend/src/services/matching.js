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
  if (c.includes("patna")) return "patna";
  if (c.includes("lucknow")) return "lucknow";
  if (c.includes("kanpur")) return "kanpur";
  if (c.includes("varanasi")) return "varanasi";
  if (c.includes("agra")) return "agra";
  return c;
}

const HIGHWAY_CORRIDORS = [
  ['kolkata', 'durgapur', 'asansol', 'dhanbad', 'ranchi', 'patna', 'gaya', 'muzaffarpur', 'varanasi', 'prayagraj', 'lucknow', 'kanpur', 'agra', 'delhi'],
  ['patna', 'buxar', 'varanasi', 'ayodhya', 'gorakhpur', 'lucknow', 'kanpur', 'agra', 'delhi'],
  ['delhi', 'gurugram', 'neemrana', 'jaipur', 'ajmer', 'ahmedabad', 'vadodara', 'surat', 'vapi', 'mumbai', 'pune', 'bengaluru'],
  ['delhi', 'agra', 'gwalior', 'jhansi', 'nagpur', 'hyderabad', 'bengaluru', 'salem', 'madurai'],
  ['kolkata', 'kharagpur', 'cuttack', 'bhubaneswar', 'visakhapatnam', 'vijayawada', 'chennai'],
];

function checkCorridorEnRoute(tripO, tripD, cargoO, cargoD) {
  for (const corr of HIGHWAY_CORRIDORS) {
    const idxTO = corr.findIndex(c => tripO.includes(c) || c.includes(tripO));
    const idxTD = corr.findIndex(c => tripD.includes(c) || c.includes(tripD));
    if (idxTO !== -1 && idxTD !== -1 && idxTO < idxTD) {
      const idxCO = corr.findIndex(c => cargoO.includes(c) || c.includes(cargoO));
      const idxCD = corr.findIndex(c => cargoD.includes(c) || c.includes(cargoD));
      if (idxCO !== -1 && idxCD !== -1 && idxCO < idxCD) {
        if (idxCO >= idxTO && idxCD <= idxTD) {
          if (idxCO === idxTO && idxCD < idxTD) return 0.96; // En-Route dropoff (e.g. Patna -> Lucknow on Patna -> Delhi)
          if (idxCO > idxTO && idxCD === idxTD) return 0.93; // En-Route pickup (e.g. Lucknow -> Delhi on Patna -> Delhi)
          return 0.90; // En-Route corridor segment
        }
      }
    }
  }
  return null;
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

  // Check en-route waypoint corridor
  const enRouteScore = checkCorridorEnRoute(tO, tD, cO, cD);
  if (enRouteScore !== null) return enRouteScore;

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

// ---------------------------------------------------------------------------
// Live-location + backhaul-aware recommendations
//
// Everything below is honest, explainable business logic layered on top of
// the real trained ranker (ml.js) — it does NOT invent a new ML signal or
// retrain the model on a feature we have no historical labels for. It boosts
// / re-sorts real ML-scored candidates using: (1) actual great-circle
// distance from the truck's live GPS position, (2) whether a load would
// complete a natural backhaul of the driver's own last trip, and (3) demand
// clustering by destination city near the truck's current position.
// ---------------------------------------------------------------------------

// Approximate lat/lng for major Indian freight hub cities. Used only for
// distance-from-current-location scoring — NOT for turn-by-turn routing
// (the apps already use Google Maps/Places for that).
export const CITY_COORDS = {
  "mumbai": [19.0760, 72.8777], "delhi": [28.6139, 77.2090],
  "bengaluru": [12.9716, 77.5946], "bangalore": [12.9716, 77.5946],
  "hyderabad": [17.3850, 78.4867], "chennai": [13.0827, 80.2707],
  "kolkata": [22.5726, 88.3639], "pune": [18.5204, 73.8567],
  "ahmedabad": [23.0225, 72.5714], "surat": [21.1702, 72.8311],
  "jaipur": [26.9124, 75.7873], "lucknow": [26.8467, 80.9462],
  "kanpur": [26.4499, 80.3319], "nagpur": [21.1458, 79.0882],
  "indore": [22.7196, 75.8577], "bhopal": [23.2599, 77.4126],
  "patna": [25.5941, 85.1376], "vadodara": [22.3072, 73.1812],
  "ludhiana": [30.9010, 75.8573], "agra": [27.1767, 78.0081],
  "nashik": [19.9975, 73.7898], "faridabad": [28.4089, 77.3178],
  "meerut": [28.9845, 77.7064], "rajkot": [22.3039, 70.8022],
  "varanasi": [25.3176, 82.9739], "amritsar": [31.6340, 74.8723],
  "chandigarh": [30.7333, 76.7794], "coimbatore": [11.0168, 76.9558],
  "guwahati": [26.1445, 91.7362], "gurugram": [28.4595, 77.0266],
  "noida": [28.5355, 77.3910], "thane": [19.2183, 72.9781],
  "visakhapatnam": [17.6868, 83.2185], "kochi": [9.9312, 76.2673],
};

// Best-effort city lookup from a free-text place name (matches the FIRST
// known city name found as a substring, case-insensitive) — good enough for
// "Bhiwandi, Mumbai Hub" -> mumbai, "Okhla, New Delhi" -> delhi, etc.
export function coordsForPlace(placeName) {
  if (!placeName) return null;
  const q = placeName.toLowerCase();
  for (const [city, coords] of Object.entries(CITY_COORDS)) {
    if (q.includes(city)) return coords;
  }
  return null;
}

export function haversineKm([lat1, lon1], [lat2, lon2]) {
  const R = 6371;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/// Distance in km from a live [lat, lng] to a cargo's origin. Falls back to
/// city-name lookup if the origin string matches a known hub; returns null
/// if neither the truck's location nor the cargo's origin can be resolved
/// (callers should treat null as "unknown", not zero).
export function distanceFromLocation(currentLatLng, cargoOrigin) {
  if (!currentLatLng) return null;
  const originCoords = coordsForPlace(cargoOrigin);
  if (!originCoords) return null;
  return haversineKm(currentLatLng, originCoords);
}

/// True if `cargo` would carry the truck back along the reverse of its last
/// completed trip (classic backhaul: went A->B, this load is B->A or
/// close to it). `lastTrip` is `{origin, destination}` from the truck's most
/// recently DELIVERED booking, or null if it has no history yet.
export function isBackhaulOfLastTrip(lastTrip, cargo) {
  if (!lastTrip || !cargo) return false;
  const sim = routeSimilarity(
    { origin: lastTrip.destination, destination: lastTrip.origin }, // reversed
    cargo,
  );
  return sim >= 0.8;
}

/// Combines a real ML score with live-location proximity and backhaul
/// affinity into one explainable ranking used for the "what should I go
/// pick up next, from where I am right now" recommendation. Every component
/// is a real, computed number — nothing here is a placeholder or guess.
///
/// candidate: { cargo, ml_score (0..1), distance_from_here_km|null }
/// lastTrip: {origin, destination} | null
export function scoreNearbyCandidate(candidate, lastTrip) {
  const { cargo, ml_score } = candidate;
  let score = ml_score;
  const reasons = [];

  // Proximity boost: closer pickups are strongly preferred (diminishing
  // returns past ~50km — a driver 40km vs 45km away doesn't meaningfully
  // differ, but 20km vs 400km very much does).
  if (candidate.distance_from_here_km != null) {
    const d = candidate.distance_from_here_km;
    const proximity = 1 / (1 + d / 75); // ~0.93 at 5km, ~0.5 at 75km, ~0.14 at 450km
    score = score * 0.65 + proximity * 0.35;
    if (d <= 50) reasons.push(`Only ${Math.round(d)} km from your current location`);
  }

  // Backhaul boost: completing the reverse of the driver's last trip avoids
  // an empty return run — the single highest-value recommendation there is.
  if (isBackhaulOfLastTrip(lastTrip, cargo)) {
    score = Math.min(1, score + 0.18);
    reasons.push(`Matches your usual return route (${lastTrip.destination} → ${lastTrip.origin})`);
  }

  return { score: Math.max(0, Math.min(1, score)), reasons };
}

/// Groups open cargo by destination city to answer "which city should I
/// head toward from here" — not a specific load, a corridor-level signal.
export function clusterDemandByDestination(openCargo, currentLatLng) {
  const groups = new Map();
  for (const c of openCargo) {
    const destKey = (c.destination || 'Unknown').split(',')[0].trim();
    if (!groups.has(destKey)) groups.set(destKey, []);
    groups.get(destKey).push(c);
  }

  const result = [];
  for (const [destination, loads] of groups.entries()) {
    const avgPrice = loads.reduce((s, c) => s + estimatePriceInr(
      Number(c.distance_km) || routeDistanceKm(c.origin, c.destination) || 500,
      Number(c.cargo_weight_tons) || 1,
    ), 0) / loads.length;
    const distFromHere = currentLatLng ? distanceFromLocation(currentLatLng, loads[0]?.origin) : null;
    result.push({
      destination,
      open_load_count: loads.length,
      avg_estimated_price_inr: Math.round(avgPrice),
      distance_from_here_km: distFromHere != null ? Math.round(distFromHere) : null,
    });
  }
  return result.sort((a, b) => b.open_load_count - a.open_load_count).slice(0, 8);
}
