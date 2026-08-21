import test from "node:test";
import assert from "node:assert/strict";
import { computeImpact } from "../src/services/impact.js";
import { consolidate } from "../src/services/consolidation.js";

test("impact math", () => {
  const im = computeImpact({ distance_km: 1400, cargo_weight_tons: 1.5, truck_capacity_tons: 9, agreed_price_inr: 2205 });
  assert.equal(im.empty_km_avoided, 1400);
  assert.equal(im.utilization_gain_pct, +( (1.5/9)*100 ).toFixed(1));
  assert.equal(im.truck_owner_income_inr, 2205);
  assert.equal(im.sme_saving_inr, Math.round(2205 * 0.35));
  assert.ok(im.fuel_avoided_liters > 0);
  assert.equal(im.co2_avoided_kg, +(im.fuel_avoided_liters * 2.68).toFixed(1));
});

test("consolidation is deterministic best-fit-decreasing", () => {
  const r = consolidate(8, [
    { id: "A", weight_tons: 2 }, { id: "B", weight_tons: 1.5 },
    { id: "C", weight_tons: 2 }, { id: "D", weight_tons: 5 },
  ]);
  assert.equal(r.used_tons, 7);
  assert.equal(r.utilization_pct, 87.5);
  assert.equal(r.skipped.length, 2);
});
