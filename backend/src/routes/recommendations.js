import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';
import { estimatePriceInr, etaMinutes, hardFilter } from '../services/matching.js';
import { rankCandidates } from '../services/ml.js';

const r = Router();
r.use(requireAuth);

async function loadOpenTripCandidates() {
  const { data: trips, error } = await supabaseAdmin
    .from('truck_trips')
    .select('*, truck:trucks(*)')
    .eq('open_for_matching', true)
    .gte('departure_at', new Date(Date.now() - 6 * 36e5).toISOString());
  if (error) throw apiError(500, 'DB_ERROR', "We couldn't load available trucks.");
  return (trips || []).map((t) => ({ trip: t, truck: t.truck }));
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
    const { data: cargo } = await supabaseAdmin
      .from('cargo_requests').select('*').eq('cargo_id', req.params.cargo_id).single();
    if (!cargo) throw apiError(404, 'CARGO_NOT_FOUND', 'Cargo request not found.');
    if (cargo.sme_id !== req.profile.id && req.profile.role !== 'truck_owner') {
      throw apiError(403, 'FORBIDDEN', 'Not your cargo request.');
    }
    const candidates = await loadOpenTripCandidates();
    const { eligible, rejected } = hardFilter(cargo, candidates);
    if (eligible.length === 0) {
      return res.json({ request_id: cargo.cargo_id, recommendations: [], rejected_count: rejected.length });
    }
    const ml = await rankCandidates(eligible, 5); // throws MATCHING_UNAVAILABLE on failure — no fake scores
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
    const { data: truck } = await supabaseAdmin
      .from('trucks').select('*').eq('truck_id', req.params.truck_id).single();
    if (!truck) throw apiError(404, 'TRUCK_NOT_FOUND', 'Truck not found.');
    if (truck.owner_id !== req.profile.id) throw apiError(403, 'FORBIDDEN', 'Not your truck.');

    const { data: trip } = await supabaseAdmin
      .from('truck_trips').select('*').eq('truck_id', truck.truck_id)
      .eq('open_for_matching', true).order('departure_at').limit(1).single();
    if (!trip) return res.json({ recommendations: [], note: 'NO_OPEN_TRIP' });

    const { data: cargos } = await supabaseAdmin
      .from('cargo_requests').select('*').eq('status', 'open');

    // Reuse the same pipeline: each cargo scored against this one trip.
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
      out.push({
        cargo_id: cargo.cargo_id, match_score: rec.match_score, reasons: rec.reasons,
        origin: cargo.origin, destination: cargo.destination,
        cargo_type: cargo.cargo_type, cargo_weight_tons: cargo.cargo_weight_tons,
        pickup_at: cargo.pickup_at, urgency: cargo.urgency,
        estimated_price_inr: estimatePriceInr(feat.distance_km, feat.cargo_weight_tons, feat.price_per_km_ton),
        trip_id: trip.id,
      });
    }
    res.json({ model_backend: ml.model_backend, recommendations: out });
  } catch (e) { next(e); }
});

export default r;
