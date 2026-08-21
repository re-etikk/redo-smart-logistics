import { Router } from "express";
import { supabaseAdmin } from "../lib/supabase.js";
import { requireAuth } from "../middleware/auth.js";
import { apiError } from "../middleware/error.js";
import { canTransition } from "../services/bookingMachine.js";
import { computeImpact } from "../services/impact.js";
import { notify } from "../services/notifications.js";
import { routeDistanceKm } from "../services/matching.js";

const r = Router();
r.use(requireAuth);

async function loadBookingForUser(id, profile) {
  const { data: b } = await supabaseAdmin
    .from("bookings")
    .select("*, cargo:cargo_requests(*), truck:trucks(*)")
    .eq("id", id).single();
  if (!b) throw apiError(404, "BOOKING_NOT_FOUND", "Booking not found.");
  const isOwner = b.truck.owner_id === profile.id;
  const isSme = b.cargo.sme_id === profile.id;
  if (!isOwner && !isSme) throw apiError(403, "FORBIDDEN", "Not your booking.");
  return { booking: b, isOwner, isSme };
}

// POST /bookings — SME requests a booking from a recommendation
r.post("/", async (req, res, next) => {
  try {
    if (req.profile.role !== "sme") throw apiError(403, "FORBIDDEN_ROLE", "Only shippers can request bookings.");
    const { cargo_id, truck_id, trip_id, match_score, agreed_price_inr } = req.body || {};
    if (!cargo_id || !truck_id) throw apiError(400, "VALIDATION", "cargo_id and truck_id are required.");
    const { data: cargo } = await supabaseAdmin.from("cargo_requests").select("*").eq("cargo_id", cargo_id).single();
    if (!cargo || cargo.sme_id !== req.profile.id) throw apiError(403, "FORBIDDEN", "Not your cargo request.");
    if (!["open", "matched"].includes(cargo.status)) throw apiError(409, "CARGO_CLOSED", "This cargo request is no longer open.");
    const { data: truck } = await supabaseAdmin.from("trucks").select("*").eq("truck_id", truck_id).single();
    if (!truck) throw apiError(404, "TRUCK_NOT_FOUND", "Truck not found.");

    const { data: booking, error } = await supabaseAdmin.from("bookings")
      .insert({ cargo_id, truck_id, trip_id, match_score, agreed_price_inr, status: "pending" })
      .select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not create the booking.");
    await supabaseAdmin.from("cargo_requests").update({ status: "matched" }).eq("cargo_id", cargo_id);
    await notify(truck.owner_id, "booking_request", "New booking request",
      `${cargo.origin} → ${cargo.destination} · ${cargo.cargo_weight_tons} T · ₹${agreed_price_inr ?? "TBD"}`);
    res.status(201).json(booking);
  } catch (e) { next(e); }
});

// GET /bookings — my bookings (role-aware)
r.get("/", async (req, res, next) => {
  try {
    let q = supabaseAdmin.from("bookings").select("*, cargo:cargo_requests(*), truck:trucks(*)").order("created_at", { ascending: false });
    const { data: all } = await q;
    const mine = (all || []).filter((b) =>
      req.profile.role === "truck_owner" ? b.truck.owner_id === req.profile.id : b.cargo.sme_id === req.profile.id);
    res.json(mine);
  } catch (e) { next(e); }
});

r.get("/:id", async (req, res, next) => {
  try {
    const { booking } = await loadBookingForUser(req.params.id, req.profile);
    const { data: proofs } = await supabaseAdmin.from("digital_proof").select("*").eq("booking_id", booking.id);
    const { data: events } = await supabaseAdmin.from("booking_events").select("*").eq("booking_id", booking.id).order("created_at");
    res.json({ ...booking, proofs: proofs || [], events: events || [] });
  } catch (e) { next(e); }
});

// PATCH /bookings/:id/status — the ONLY way status changes (spec §41)
r.patch("/:id/status", async (req, res, next) => {
  try {
    const { to } = req.body || {};
    const { booking } = await loadBookingForUser(req.params.id, req.profile);
    const { data: proofRows } = await supabaseAdmin.from("digital_proof").select("proof_type").eq("booking_id", booking.id);
    const proofs = (proofRows || []).map((p) => p.proof_type);
    const check = canTransition(booking.status, to, req.profile.role, { proofs });
    if (!check.ok) {
      const msgs = {
        INVALID_TRANSITION: `Cannot move from ${booking.status} to ${to}.`,
        FORBIDDEN_ROLE: "Your account type cannot perform this step.",
        PROOF_REQUIRED: `Upload ${check.proof} proof first.`,
      };
      throw apiError(409, check.error, msgs[check.error] || "Transition not allowed.");
    }
    await supabaseAdmin.from("bookings").update({ status: to }).eq("id", booking.id);
    await supabaseAdmin.from("booking_events").insert({ booking_id: booking.id, from_status: booking.status, to_status: to, actor_id: req.profile.id });

    const other = req.profile.role === "sme" ? booking.truck.owner_id : booking.cargo.sme_id;
    await notify(other, "booking_status", "Booking " + to.replace("_", " "),
      `${booking.cargo.origin} → ${booking.cargo.destination}`);

    if (to === "completed") {
      const distance = booking.cargo.distance_km || routeDistanceKm(booking.cargo.origin, booking.cargo.destination) || 0;
      const impact = computeImpact({
        distance_km: distance,
        cargo_weight_tons: booking.cargo.cargo_weight_tons,
        truck_capacity_tons: booking.truck.default_capacity_tons,
        agreed_price_inr: booking.agreed_price_inr || 0,
      });
      await supabaseAdmin.from("impact_records").upsert({ booking_id: booking.id, ...impact });
      await supabaseAdmin.from("cargo_requests").update({ status: "delivered" }).eq("cargo_id", booking.cargo_id);
    }
    res.json({ id: booking.id, status: to });
  } catch (e) { next(e); }
});

export default r;
