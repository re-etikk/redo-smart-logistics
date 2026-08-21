// Impact engine (spec §46). All outputs are estimates; labeled in UI/docs.

const FUEL_L_PER_KM_FULL = 0.28;        // typical MCV/HCV consumption band
const CO2_KG_PER_L_DIESEL = 2.68;       // standard diesel emission factor
const DEDICATED_PARTIAL_PREMIUM = 0.35; // SME saving vs dedicated partial truck

export function computeImpact({ distance_km, cargo_weight_tons, truck_capacity_tons, agreed_price_inr }) {
  const utilShare = Math.min(1, cargo_weight_tons / truck_capacity_tons);
  const fuel = +(distance_km * FUEL_L_PER_KM_FULL * utilShare).toFixed(1);
  return {
    empty_km_avoided: Math.round(distance_km),
    utilization_gain_pct: +(utilShare * 100).toFixed(1),
    truck_owner_income_inr: Math.round(agreed_price_inr),
    sme_saving_inr: Math.round(agreed_price_inr * DEDICATED_PARTIAL_PREMIUM),
    fuel_avoided_liters: fuel,
    co2_avoided_kg: +(fuel * CO2_KG_PER_L_DIESEL).toFixed(1),
  };
}
