import test from "node:test";
import assert from "node:assert/strict";
import { hardFilter, routeSimilarity, estimatePriceInr, etaMinutes } from "../src/services/matching.js";

const cargo = {
  origin: "Mumbai", destination: "Delhi", cargo_type: "Textiles",
  cargo_weight_tons: 1.5, pickup_at: "2026-08-21T07:00:00Z", distance_km: 1400,
};
const mk = (id, over = {}, tripOver = {}) => ({
  truck: { truck_id: id, status: "available", driver_rating: 4.7, on_time_rate: 0.94, cancel_rate: 0.03, ...over },
  trip: { id: "trip-" + id, origin: "Mumbai", destination: "Delhi",
    departure_at: "2026-08-21T06:00:00Z", available_capacity_tons: 4.2,
    price_per_km_ton: 1.05, accepted_cargo_types: null, ...tripOver },
});

test("filters each rejection reason correctly", () => {
  const { eligible, rejected } = hardFilter(cargo, [
    mk("OK"),
    mk("BUSY", { status: "in_transit" }),
    mk("SMALL", {}, { available_capacity_tons: 1.0 }),
    mk("LATE", {}, { departure_at: "2026-08-22T06:00:00Z" }),
    mk("WRONG", {}, { origin: "Pune", destination: "Jaipur" }),
    mk("PICKY", {}, { accepted_cargo_types: ["Electronics"] }),
  ]);
  assert.equal(eligible.length, 1);
  assert.equal(eligible[0].truck_id, "OK");
  assert.equal(eligible[0].time_gap_hours, 1);
  const reasons = Object.fromEntries(rejected.map((r) => [r.truck_id, r.reason]));
  assert.deepEqual(reasons, {
    BUSY: "truck_unavailable", SMALL: "insufficient_capacity",
    LATE: "timing_incompatible", WRONG: "route_mismatch", PICKY: "cargo_incompatible",
  });
});

test("route similarity corridor model", () => {
  assert.equal(routeSimilarity({ origin: "Mumbai", destination: "Delhi" }, cargo), 1.0);
  assert.equal(routeSimilarity({ origin: "Pune", destination: "Delhi" }, cargo), 0.75);
  assert.equal(routeSimilarity({ origin: "Mumbai", destination: "Jaipur" }, cargo), 0.7);
});

test("price and ETA estimates", () => {
  assert.equal(estimatePriceInr(1400, 1.5, 1.05), 2205);
  assert.equal(etaMinutes(1400), Math.round((1400 / 42 + 2) * 60));
});
