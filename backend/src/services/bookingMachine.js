// Booking state machine — single source of truth for transitions (spec §41–43).
// Pure module: no I/O, fully unit-testable.

export const STATUSES = [
  "pending", "accepted", "confirmed", "pickup_ready", "picked_up",
  "in_transit", "delivered", "completed", "cancelled", "disputed",
];

// status -> { nextStatus: role allowed to trigger it }
const TRANSITIONS = {
  pending:      { accepted: "truck_owner", cancelled: "any" },
  accepted:     { confirmed: "sme", cancelled: "any" },
  confirmed:    { pickup_ready: "truck_owner", cancelled: "any" },
  pickup_ready: { picked_up: "truck_owner", cancelled: "any" },
  picked_up:    { in_transit: "truck_owner" },
  in_transit:   { delivered: "truck_owner" },
  delivered:    { completed: "sme", disputed: "sme" },
  completed:    { disputed: "sme" },
  cancelled:    {},
  disputed:     {},
};

// Proof requirements gate certain transitions (spec §40–41).
const REQUIRED_PROOF = { picked_up: "pickup", delivered: "delivery" };

export function canTransition(from, to, role, { proofs = [] } = {}) {
  const allowed = TRANSITIONS[from];
  if (!allowed) return { ok: false, error: "UNKNOWN_STATUS" };
  const who = allowed[to];
  if (!who) return { ok: false, error: "INVALID_TRANSITION" };
  if (who !== "any" && who !== role) return { ok: false, error: "FORBIDDEN_ROLE" };
  const need = REQUIRED_PROOF[to];
  if (need && !proofs.includes(need)) return { ok: false, error: "PROOF_REQUIRED", proof: need };
  return { ok: true };
}

export const isTerminal = (s) => Object.keys(TRANSITIONS[s] || {}).length === 0;
