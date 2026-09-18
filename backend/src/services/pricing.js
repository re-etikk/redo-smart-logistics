// Live, corridor-aware, supply/demand-surging price quotes.
//
// Formula (mirrors the Uber-style structure the founder asked for):
//
//   price = max(
//     min_fare_inr,
//     distance_km * weight_tons * base_rate_per_ton_km
//       * cargo_type_multiplier * surge_multiplier
//   )

import { supabaseAdmin } from '../lib/supabase.js';
import { computeSurgeMultiplier, coordsForPlace } from './matching.js';

const CONFIG_CACHE_TTL_MS = 5 * 60 * 1000;
let _configCache = null;
let _configCacheAt = 0;
let _corridorCache = null;
let _corridorCacheAt = 0;

async function loadPricingConfigs() {
  const now = Date.now();
  if (_configCache && now - _configCacheAt < CONFIG_CACHE_TTL_MS) return _configCache;
  const { data } = await supabaseAdmin.from('pricing_configurations').select('*');
  _configCache = data && data.length ? data : [];
  _configCacheAt = now;
  return _configCache;
}

async function loadCorridorWaypoints() {
  const now = Date.now();
  if (_corridorCache && now - _corridorCacheAt < CONFIG_CACHE_TTL_MS) return _corridorCache;
  const { data } = await supabaseAdmin.from('corridor_waypoints').select('corridor_id, city');
  _corridorCache = data || [];
  _corridorCacheAt = now;
  return _corridorCache;
}

function cityMatches(placeName, city) {
  if (!placeName || !city) return false;
  return placeName.toLowerCase().includes(city.toLowerCase());
}

export async function findCorridorId(origin, destination) {
  const waypoints = await loadCorridorWaypoints();
  if (waypoints.length === 0) return 'default';

  const byCorridor = new Map();
  for (const w of waypoints) {
    if (!byCorridor.has(w.corridor_id)) byCorridor.set(w.corridor_id, []);
    byCorridor.get(w.corridor_id).push(w.city);
  }

  for (const [corridorId, cities] of byCorridor.entries()) {
    const hasOrigin = cities.some((c) => cityMatches(origin, c));
    const hasDest = cities.some((c) => cityMatches(destination, c));
    if (hasOrigin && hasDest) return corridorId;
  }
  return 'default';
}

async function getConfigForCorridor(corridorId) {
  const configs = await loadPricingConfigs();
  const match = configs.find((c) => c.corridor_id === corridorId);
  if (match) return match;
  const fallback = configs.find((c) => c.corridor_id === 'default');
  return fallback || {
    corridor_id: 'default', corridor_name: 'Standard All-India Freight Baseline',
    base_rate_per_ton_km: 2.5, min_fare_inr: 1200, detour_rate_per_km: 25,
    platform_commission_pct: 0.08, fragile_multiplier: 1.18, fmcg_multiplier: 1.08,
    perishable_multiplier: 1.25, high_value_multiplier: 1.3, hazardous_multiplier: 1.35,
  };
}

function cargoTypeMultiplier(config, cargoType) {
  const t = (cargoType || '').toLowerCase();
  if (t.includes('fragile')) return Number(config.fragile_multiplier) || 1;
  if (t.includes('fmcg')) return Number(config.fmcg_multiplier) || 1;
  if (t.includes('perishable') || t.includes('cold') || t.includes('reefer')) return Number(config.perishable_multiplier) || 1;
  if (t.includes('high_value') || t.includes('high value') || t.includes('electronics')) return Number(config.high_value_multiplier) || 1;
  if (t.includes('hazard') || t.includes('chemical')) return Number(config.hazardous_multiplier) || 1;
  return 1;
}

async function getSupplyDemandCounts(originCity) {
  const [{ data: cargos }, { data: trucks }, { data: trips }] = await Promise.all([
    supabaseAdmin.from('cargo_requests').select('origin').eq('status', 'open'),
    supabaseAdmin.from('trucks').select('truck_id, home_origin').eq('status', 'available'),
    supabaseAdmin.from('truck_trips').select('truck_id, origin').eq('open_for_matching', true),
  ]);

  const demand = (cargos || []).filter((c) => cityMatches(c.origin, originCity)).length;

  const truckIdsHere = new Set();
  for (const t of trucks || []) {
    if (cityMatches(t.home_origin, originCity)) truckIdsHere.add(t.truck_id);
  }
  for (const t of trips || []) {
    if (cityMatches(t.origin, originCity)) truckIdsHere.add(t.truck_id);
  }
  const supply = truckIdsHere.size;

  return { demand, supply };
}

export async function computePriceQuote({ origin, destination, distanceKm, weightTons, cargoType, volumeCft = 0 }) {
  const corridorId = await findCorridorId(origin, destination);
  const config = await getConfigForCorridor(corridorId);
  const { demand, supply } = await getSupplyDemandCounts(origin);
  const surgeMultiplier = computeSurgeMultiplier(demand, supply);
  const typeMultiplier = cargoTypeMultiplier(config, cargoType);

  const volTons = volumeCft > 0 ? +(volumeCft / 120).toFixed(2) : 0;
  const billableWeight = Math.max(Number(weightTons) || 0.1, volTons);

  const baseFare = distanceKm * billableWeight * Number(config.base_rate_per_ton_km);
  const beforeMinFare = Math.round(baseFare * typeMultiplier * surgeMultiplier);
  const priceInr = Math.max(Number(config.min_fare_inr), beforeMinFare);

  const estimatedDedicatedTruckPrice = Math.max(4500, Math.round(distanceKm * 18 + 1500));
  const savingsAmount = Math.max(0, estimatedDedicatedTruckPrice - priceInr);
  const savingsPct = Math.max(0, Math.min(85, Math.round((savingsAmount / estimatedDedicatedTruckPrice) * 100)));

  return {
    price_inr: priceInr,
    corridor_id: corridorId,
    corridor_name: config.corridor_name,
    base_rate_per_ton_km: Number(config.base_rate_per_ton_km),
    min_fare_inr: Number(config.min_fare_inr),
    cargo_type_multiplier: typeMultiplier,
    surge_multiplier: surgeMultiplier,
    demand_count: demand,
    supply_count: supply,
    is_surging: surgeMultiplier > 1,
    platform_commission_pct: Number(config.platform_commission_pct),
    billable_weight_tons: billableWeight,
    volumetric_weight_tons: volTons,
    estimated_dedicated_truck_price: estimatedDedicatedTruckPrice,
    savings_amount: savingsAmount,
    savings_pct: savingsPct,
  };
}
