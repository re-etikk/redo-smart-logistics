// Smart consolidation (spec §36): deterministic best-fit-decreasing bin packing.
// Explicitly NOT ML — do not label it as such in the UI.

export function consolidate(capacityTons, shipments) {
  const sorted = [...shipments].sort((a, b) => b.weight_tons - a.weight_tons);
  const packed = [], skipped = [];
  let used = 0;
  for (const s of sorted) {
    if (used + s.weight_tons <= capacityTons + 1e-9) { packed.push(s); used += s.weight_tons; }
    else skipped.push(s);
  }
  return {
    packed, skipped,
    used_tons: +used.toFixed(2),
    capacity_tons: capacityTons,
    utilization_pct: +((used / capacityTons) * 100).toFixed(2),
  };
}
