// dynamicPricing.js — REDO Production Dynamic Pricing Engine
// Mathematically robust, explainable, and multi-factor pricing for partial-load moving capacity.

export const DEFAULT_CORRIDOR_RATES = {
  'delhi_patna': { base_rate: 2.40, min_fare: 1500, name: 'Delhi - Agra - Kanpur - Lucknow - Patna' },
  'delhi_mumbai': { base_rate: 2.20, min_fare: 1500, name: 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai' },
  'mumbai_bengaluru': { base_rate: 2.30, min_fare: 1500, name: 'Mumbai - Pune - Kolhapur - Bengaluru' },
  'default': { base_rate: 2.50, min_fare: 1200, name: 'All-India Standard Lane' },
};

export const CARGO_RISK_MULTIPLIERS = {
  'general': 1.00,
  'fmcg': 1.08,
  'packaged_food': 1.08,
  'food': 1.08,
  'fragile': 1.18,
  'perishable': 1.25,
  'high_value': 1.30,
  'machinery': 1.15,
  'heavy_machinery': 1.20,
  'chemicals': 1.35,
  'hazardous': 1.40,
};

/**
 * Calculates volumetric weight in metric tons from volume in cubic feet (CFT).
 * Logistics standard: 1 CFT ~ 8.33 kg => 120 CFT ~ 1 Ton.
 */
export function calculateVolumetricWeightTons(volumeCft) {
  if (!volumeCft || volumeCft <= 0) return 0;
  return +(volumeCft / 120).toFixed(2);
}

/**
 * Computes the billable weight in tons as max(actual, volumetric).
 */
export function getBillableWeightTons(actualWeightTons, volumeCft = 0) {
  const vol = calculateVolumetricWeightTons(volumeCft);
  return +Math.max(Number(actualWeightTons) || 0.1, vol).toFixed(2);
}

/**
 * Determines the occupancy discount factor ("Fill My Truck" curve).
 * High occupancy rewards the driver and provides a deep discount to the shipper to fill the last fraction.
 */
export function getOccupancyFactor(occupancyPct = 0) {
  const pct = Number(occupancyPct) > 1 ? occupancyPct / 100 : Number(occupancyPct);
  if (pct >= 0.75) return 0.88; // Deep fill discount (12% off base rate)
  if (pct >= 0.50) return 0.95; // Standard moving rate (5% off base rate)
  return 1.00; // Standard open rate
}

/**
 * Master Dynamic Pricing calculation.
 */
export function calculateDynamicPrice({
  weightTons,
  volumeCft = 0,
  distanceKm,
  corridorId = 'default',
  customBaseRate = null,
  cargoType = 'general',
  truckOccupancyPct = 0.60,
  detourKm = 0,
  urgency = 'standard', // 'standard' | 'express'
  commissionPct = 0.08,
}) {
  const normCargo = (cargoType || 'general').toLowerCase().trim().replace(/\s+/g, '_');
  const dist = Math.max(10, Number(distanceKm) || 100);
  const billableWeight = getBillableWeightTons(weightTons, volumeCft);

  // Corridor base rate
  const corridorConfig = DEFAULT_CORRIDOR_RATES[corridorId] || DEFAULT_CORRIDOR_RATES['default'];
  const baseRate = customBaseRate != null ? Number(customBaseRate) : corridorConfig.base_rate;
  const minFare = corridorConfig.min_fare;

  // 1. Base Freight = Billable Weight * Distance * Rate
  const rawBaseFreight = billableWeight * dist * baseRate;

  // 2. Multipliers
  const mCargo = CARGO_RISK_MULTIPLIERS[normCargo] || 1.00;
  const fOccupancy = getOccupancyFactor(truckOccupancyPct);
  const mUrgency = urgency === 'express' ? 1.15 : 1.00;

  // 3. Detour Compensation (100% passed to driver)
  const detourCost = Math.round((Number(detourKm) || 0) * 25); // ₹25/km

  // 4. Driver Net Freight
  const calculatedFreight = Math.round((rawBaseFreight * mCargo * fOccupancy * mUrgency) + detourCost);
  const driverFreight = Math.max(minFare, calculatedFreight);

  // 5. ReDo Platform Fee
  const redoFee = Math.round(driverFreight * (Number(commissionPct) || 0.08));

  // 6. Customer Final Total
  const customerPrice = driverFreight + redoFee;

  // 7. Dedicated Full Truck Comparison Benchmark (what a traditional transporter charges)
  // Standard mini-truck/Canter dedicated base is ~₹18/km + ₹1,500 base charge
  const estimatedDedicatedTruckPrice = Math.max(4500, Math.round(dist * 18 + 1500));
  const savingsAmount = Math.max(0, estimatedDedicatedTruckPrice - customerPrice);
  const savingsPct = Math.max(0, Math.min(85, Math.round((savingsAmount / estimatedDedicatedTruckPrice) * 100)));

  return {
    customerPrice,
    driverFreight,
    redoFee,
    savingsAmount,
    savingsPct,
    estimatedDedicatedTruckPrice,
    breakdown: {
      billableWeightTons: billableWeight,
      actualWeightTons: Number(weightTons),
      volumetricWeightTons: calculateVolumetricWeightTons(volumeCft),
      distanceKm: dist,
      corridorBaseRate: baseRate,
      rawBaseFreight: Math.round(rawBaseFreight),
      cargoMultiplier: mCargo,
      occupancyFactor: fOccupancy,
      urgencyMultiplier: mUrgency,
      detourCost,
      detourKm: Number(detourKm) || 0,
      commissionPct: Number(commissionPct) || 0.08,
    }
  };
}
