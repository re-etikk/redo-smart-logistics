import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';
import {
  estimatePriceInr, etaMinutes, hardFilter,
  distanceFromLocation, scoreNearbyCandidate, clusterDemandByDestination,
} from '../services/matching.js';
import { rankCandidates, onlineModel } from '../services/ml.js';
import { getCargoById, getActiveOpenCargos } from './cargo.js';
import { getActiveTrips, getActiveTrucks, getTruckById, activeTripPool } from './trucks.js';

const r = Router();
r.use(requireAuth);

async function loadOpenTripCandidates() {
  const candidateMap = new Map();

  // 1. Fetch real trips from database and active pool
  try {
    const trips = await getActiveTrips();
    for (const t of trips) {
      if (t && t.truck) {
        candidateMap.set(t.id || t.truck_id, { trip: t, truck: t.truck });
      }
    }
  } catch (_) {}

  // 2. Fetch real registered trucks without explicit trips and allow corridor matching
  try {
    const trucks = await getActiveTrucks();
    for (const trk of trucks) {
      if (trk && trk.status === 'available') {
        const key = 'trk-' + trk.truck_id;
        if (!candidateMap.has(key)) {
          candidateMap.set(key, {
            truck: trk,
            trip: {
              id: 'trip-' + trk.truck_id,
              truck_id: trk.truck_id,
              origin: trk.home_origin || 'Delhi',
              destination: 'Anywhere',
              available_capacity_tons: trk.default_capacity_tons || 16.0,
              departure_at: new Date().toISOString(),
              open_for_matching: true,
              price_per_km_ton: 1.05,
            },
          });
        }
      }
    }
  } catch (_) {}

  return Array.from(candidateMap.values());
}

function enrich(rec, eligibleById, truckById) {
  const c = eligibleById[rec.truck_id];
  const truck = truckById[rec.truck_id] || {};
  return {
    truck_id: rec.truck_id,
    match_score: rec.match_score,
    reasons: rec.reasons,
    estimated_price_inr: estimatePriceInr(c.distance_km, c.cargo_weight_tons, c.price_per_km_ton),
    eta_minutes: etaMinutes(c.distance_km),
    capacity_available_tons: c.available_capacity_tons,
    reliability_score: c.on_time_rate == null ? null
      : +((c.on_time_rate) * (1 - (c.cancel_rate ?? 0))).toFixed(2),
    is_new: c.driver_rating == null,
    driver_rating: c.driver_rating,
    on_time_rate: c.on_time_rate,
    departure_at: c._departure_at,
    trip_id: c._trip_id,
    truck_type: truck.truck_type,
    registration_number: truck.registration_number,
    verified_documents: truck.verified_documents,
    owner_id: truck.owner_id,
  };
}

// GET /recommendations/trucks/:cargo_id — ranked trucks for an SME cargo request
r.get('/trucks/:cargo_id', async (req, res, next) => {
  try {
    let cargo = getCargoById(req.params.cargo_id);
    if (!cargo) {
      try {
        const { data } = await supabaseAdmin
          .from('cargo_requests').select('*').eq('cargo_id', req.params.cargo_id).single();
        cargo = data;
      } catch (_) {}
    }
    if (!cargo) throw apiError(404, 'CARGO_NOT_FOUND', 'Cargo request not found.');

    const candidates = await loadOpenTripCandidates();
    const { eligible, rejected } = hardFilter(cargo, candidates);
    if (eligible.length === 0) {
      return res.json({ request_id: cargo.cargo_id, recommendations: [], rejected_count: rejected.length });
    }
    const ml = await rankCandidates(eligible, 5);
    const eligibleById = Object.fromEntries(eligible.map((e) => [e.truck_id, e]));
    const truckById = Object.fromEntries(candidates.map((c) => [c.truck.truck_id, c.truck]));
    res.json({
      request_id: cargo.cargo_id,
      model_backend: ml.model_backend,
      recommendations: ml.recommendations.map((x) => enrich(x, eligibleById, truckById)),
      rejected_count: rejected.length,
    });
  } catch (e) { next(e); }
});

// GET /recommendations/cargo/:truck_id — ranked cargo for an owner's open trip
r.get('/cargo/:truck_id', async (req, res, next) => {
  try {
    let truck = getTruckById(req.params.truck_id);
    if (!truck) {
      try {
        const { data } = await supabaseAdmin
          .from('trucks').select('*').eq('truck_id', req.params.truck_id).single();
        truck = data;
      } catch (_) {}
    }
    if (!truck) throw apiError(404, 'TRUCK_NOT_FOUND', 'Truck not found.');

    let trip = null;
    for (const t of activeTripPool.values()) {
      if (t.truck_id === truck.truck_id && t.open_for_matching) {
        trip = t;
        break;
      }
    }
    if (!trip) {
      try {
        const { data } = await supabaseAdmin
          .from('truck_trips').select('*').eq('truck_id', truck.truck_id)
          .eq('open_for_matching', true).order('departure_at').limit(1).single();
        trip = data;
      } catch (_) {}
    }
    if (!trip) {
      trip = {
        id: 'trip-' + truck.truck_id,
        truck_id: truck.truck_id,
        origin: truck.home_origin || 'Delhi',
        destination: 'Anywhere',
        available_capacity_tons: truck.default_capacity_tons || 16.0,
        departure_at: new Date().toISOString(),
        open_for_matching: true,
        price_per_km_ton: 1.05,
      };
    }

    const cargos = await getActiveOpenCargos();

    // Score each real cargo against this truck/trip using the real ML pipeline
    const out = [];
    const pairs = [];
    for (const cargo of cargos || []) {
      const { eligible } = hardFilter(cargo, [{ trip, truck }]);
      if (eligible.length) pairs.push({ cargo, feat: { ...eligible[0], cargo_id: cargo.cargo_id } });
    }
    if (pairs.length === 0) return res.json({ recommendations: [] });

    const ml = await rankCandidates(pairs.map((p) => p.feat), 5);
    const byCargo = Object.fromEntries(pairs.map((p) => [p.feat.cargo_id, p]));
    for (const rec of ml.recommendations) {
      const { cargo, feat } = byCargo[rec.cargo_id];
      if (cargo && feat) {
        out.push({
          cargo_id: cargo.cargo_id,
          match_score: rec.match_score,
          reasons: rec.reasons,
          origin: cargo.origin,
          destination: cargo.destination,
          cargo_type: cargo.cargo_type,
          cargo_weight_tons: cargo.cargo_weight_tons,
          pickup_at: cargo.pickup_at,
          urgency: cargo.urgency,
          estimated_price_inr: estimatePriceInr(feat.distance_km, feat.cargo_weight_tons, feat.price_per_km_ton),
          trip_id: trip.id,
        });
      }
    }
    res.json({ model_backend: ml.model_backend, recommendations: out });
  } catch (e) { next(e); }
});

// GET /recommendations/nearby/:truck_id — live-location + backhaul-aware
// recommendations. Works even if the driver hasn't declared a trip yet:
// uses the truck's live GPS (trucks.current_lat/current_lng, kept fresh by
// PATCH /trucks/:id/location) or falls back to home_origin, plus the
// driver's own most recently delivered booking to detect a natural
// backhaul. Returns both specific top-matched loads AND a corridor-level
// "which city should I head toward" summary.
r.get('/nearby/:truck_id', async (req, res, next) => {
  try {
    let truck = getTruckById(req.params.truck_id);
    if (!truck) {
      try {
        const { data } = await supabaseAdmin
          .from('trucks').select('*').eq('truck_id', req.params.truck_id).single();
        truck = data;
      } catch (_) {}
    }
    if (!truck) throw apiError(404, 'TRUCK_NOT_FOUND', 'Truck not found.');

    // Live location: query params (freshest, sent by the app each call) win
    // over the last value persisted on the truck row, which itself beats
    // guessing from home_origin text.
    const qLat = req.query.lat != null ? Number(req.query.lat) : null;
    const qLng = req.query.lng != null ? Number(req.query.lng) : null;
    const currentLatLng =
      (qLat != null && qLng != null && !Number.isNaN(qLat) && !Number.isNaN(qLng))
        ? [qLat, qLng]
        : (truck.current_lat != null && truck.current_lng != null)
          ? [Number(truck.current_lat), Number(truck.current_lng)]
          : null;

    // The driver's own last completed run — the single strongest signal for
    // "where do they probably need to go next" (classic empty-return / backhaul).
    let lastTrip = null;
    try {
      const { data: lastBooking } = await supabaseAdmin
        .from('bookings')
        .select('*, cargo:cargo_requests(origin, destination)')
        .eq('truck_id', truck.truck_id)
        .in('status', ['delivered', 'completed'])
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
      lastTrip = lastBooking?.cargo
        ? { origin: lastBooking.cargo.origin, destination: lastBooking.cargo.destination }
        : null;
    } catch (_) {}

    // Find any declared open trip for this truck; if none, synthesize a
    // virtual trip anchored at the truck's current location (or home) so
    // that drivers who haven't declared a trip yet still get useful recommendations.
    let openTrip = null;
    for (const t of activeTripPool.values()) {
      if (t.truck_id === truck.truck_id && t.open_for_matching) {
        openTrip = t;
        break;
      }
    }
    if (!openTrip) {
      try {
        const { data } = await supabaseAdmin
          .from('truck_trips').select('*').eq('truck_id', truck.truck_id)
          .eq('open_for_matching', true).order('departure_at').limit(1).maybeSingle();
        openTrip = data;
      } catch (_) {}
    }

    const virtualTrip = openTrip || {
      id: null,
      truck_id: truck.truck_id,
      origin: truck.home_origin || '',
      destination: '',
      available_capacity_tons: truck.default_capacity_tons || 16.0,
      departure_at: new Date(Date.now() + 48 * 36e5).toISOString(),
      accepted_cargo_types: null,
      price_per_km_ton: 1.05,
    };

    const openCargo = await getActiveOpenCargos();

    const pairs = [];
    for (const cargo of openCargo || []) {
      const { eligible } = hardFilter(cargo, [{ trip: virtualTrip, truck }], { maxTimeGapHours: openTrip ? 72 : 24 * 14 });
      if (eligible.length) {
        pairs.push({
          cargo,
          feat: { ...eligible[0], cargo_id: cargo.cargo_id },
          distance_from_here_km: currentLatLng ? distanceFromLocation(currentLatLng, cargo.origin) : null,
        });
      }
    }

    let topLoads = [];
    if (pairs.length > 0) {
      const ml = await rankCandidates(pairs.map((p) => p.feat), 10);
      const byCargo = Object.fromEntries(pairs.map((p) => [p.feat.cargo_id, p]));
      const boosted = ml.recommendations.map((rec) => {
        const { cargo, feat, distance_from_here_km } = byCargo[rec.cargo_id];
        const { score, reasons: extraReasons } = scoreNearbyCandidate(
          { cargo, ml_score: rec.match_score, distance_from_here_km },
          lastTrip,
        );
        return {
          cargo_id: cargo.cargo_id,
          match_score: score,
          reasons: [...rec.reasons, ...extraReasons],
          origin: cargo.origin,
          destination: cargo.destination,
          cargo_type: cargo.cargo_type,
          cargo_weight_tons: cargo.cargo_weight_tons,
          pickup_at: cargo.pickup_at,
          urgency: cargo.urgency,
          distance_from_here_km: distance_from_here_km != null ? Math.round(distance_from_here_km) : null,
          estimated_price_inr: estimatePriceInr(feat.distance_km, feat.cargo_weight_tons, feat.price_per_km_ton),
          trip_id: openTrip?.id ?? null,
        };
      });
      topLoads = boosted.sort((a, b) => b.match_score - a.match_score).slice(0, 8);
    }

    res.json({
      current_location: currentLatLng,
      last_trip: lastTrip,
      top_loads: topLoads,
      recommended_corridors: clusterDemandByDestination(openCargo || [], currentLatLng),
      model_meta: onlineModel.getModelStatus(),
    });
  } catch (e) { next(e); }
});

// POST /recommendations/feedback — Online continual learning feedback endpoint
r.post('/feedback', (req, res) => {
  const { cargo_id, truck_id, action, features, corridor_key } = req.body || {};
  const result = onlineModel.recordFeedback({
    cargo_id,
    truck_id,
    action: action || 'view_route',
    features,
    corridor_key,
  });
  res.json(result);
});

// GET /recommendations/model-status — Returns online model weights & continual learning status
r.get('/model-status', (req, res) => {
  res.json(onlineModel.getModelStatus());
});

export default r;
