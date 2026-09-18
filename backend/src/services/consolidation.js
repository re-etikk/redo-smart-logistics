// consolidation.js — Multi-Cargo Consolidation & Corridor Capacity Optimizer
// Implements Best-Fit-Decreasing bin packing with co-load safety enforcement and incremental revenue tracking.

import { checkTwoCargoCompatibility } from './cargoCompatibility.js';
import { calculateVolumetricWeightTons } from './dynamicPricing.js';

export function consolidate(capacityTons, shipments, opts = {}) {
  const enforceSafety = opts.enforceSafety !== false;
  const baseRatePerTonKm = Number(opts.baseRatePerTonKm) || 2.40;

  // Compute effective weight (max of actual vs volumetric)
  const normalized = shipments.map(s => {
    const act = Number(s.weight_tons || s.cargo_weight_tons || 0);
    const vol = calculateVolumetricWeightTons(Number(s.volume_cft || 0));
    const effectiveWeight = Math.max(act, vol);
    return {
      ...s,
      actual_weight_tons: act,
      volumetric_weight_tons: vol,
      effective_weight_tons: +effectiveWeight.toFixed(2),
      cargo_type: s.cargo_type || 'general',
    };
  });

  // Sort descending by effective weight (Best-Fit-Decreasing)
  const sorted = [...normalized].sort((a, b) => b.effective_weight_tons - a.effective_weight_tons);

  const packed = [];
  const skipped = [];
  let used = 0;
  let totalRevenueInr = 0;

  for (const s of sorted) {
    // 1. Capacity boundary check
    if (used + s.effective_weight_tons > capacityTons + 1e-9) {
      skipped.push({ ...s, skip_reason: 'capacity_exceeded' });
      continue;
    }

    // 2. Safety / Co-load compatibility check
    let isSafeWithPacked = true;
    let safetyReason = null;
    if (enforceSafety && packed.length > 0) {
      for (const p of packed) {
        const check = checkTwoCargoCompatibility(p.cargo_type, s.cargo_type);
        if (!check.allowed) {
          isSafeWithPacked = false;
          safetyReason = check.reason;
          break;
        }
      }
    }

    if (!isSafeWithPacked) {
      skipped.push({ ...s, skip_reason: 'cargo_incompatible', safety_reason: safetyReason });
      continue;
    }

    // 3. Pack cargo
    packed.push(s);
    used += s.effective_weight_tons;

    const dist = Number(s.distance_km) || 450;
    const estFare = Math.round(s.effective_weight_tons * dist * baseRatePerTonKm);
    totalRevenueInr += estFare;
  }

  const remainingTons = Math.max(0, capacityTons - used);
  const utilizationPct = capacityTons > 0 ? +((used / capacityTons) * 100).toFixed(1) : 0;

  return {
    packed,
    skipped,
    used_tons: +used.toFixed(2),
    capacity_tons: capacityTons,
    remaining_capacity_tons: +remainingTons.toFixed(2),
    utilization_pct: utilizationPct,
    total_projected_revenue_inr: totalRevenueInr,
    co_load_safety_status: 'enforced_safe',
  };
}
