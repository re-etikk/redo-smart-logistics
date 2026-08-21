import test from "node:test";
import assert from "node:assert/strict";
import { canTransition, isTerminal, STATUSES } from "../src/services/bookingMachine.js";

test("happy path with role + proof gates", () => {
  assert.equal(canTransition("pending", "accepted", "truck_owner").ok, true);
  assert.equal(canTransition("pending", "accepted", "sme").ok, false);
  assert.equal(canTransition("accepted", "confirmed", "sme").ok, true);
  assert.equal(canTransition("confirmed", "pickup_ready", "truck_owner").ok, true);
  // picked_up requires pickup proof
  const noProof = canTransition("pickup_ready", "picked_up", "truck_owner", { proofs: [] });
  assert.deepEqual([noProof.ok, noProof.error], [false, "PROOF_REQUIRED"]);
  assert.equal(canTransition("pickup_ready", "picked_up", "truck_owner", { proofs: ["pickup"] }).ok, true);
  assert.equal(canTransition("picked_up", "in_transit", "truck_owner").ok, true);
  const noDel = canTransition("in_transit", "delivered", "truck_owner", { proofs: ["pickup"] });
  assert.equal(noDel.ok, false);
  assert.equal(canTransition("in_transit", "delivered", "truck_owner", { proofs: ["pickup","delivery"] }).ok, true);
  assert.equal(canTransition("delivered", "completed", "sme").ok, true);
});

test("invalid jumps and terminal states", () => {
  assert.equal(canTransition("pending", "in_transit", "truck_owner").ok, false);
  assert.equal(canTransition("completed", "in_transit", "sme").ok, false);
  assert.equal(isTerminal("cancelled"), true);
  assert.equal(isTerminal("disputed"), true);
  assert.equal(isTerminal("pending"), false);
  assert.equal(STATUSES.length, 10);
});

test("disputes allowed from delivered and completed by SME only", () => {
  assert.equal(canTransition("delivered", "disputed", "sme").ok, true);
  assert.equal(canTransition("completed", "disputed", "sme").ok, true);
  assert.equal(canTransition("completed", "disputed", "truck_owner").ok, false);
});
