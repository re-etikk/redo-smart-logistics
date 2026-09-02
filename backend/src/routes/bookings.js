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

// 4-digit OTPs for secure pickup/delivery handover (Rapido/Porter-style).
const genOtp = () => String(Math.floor(1000 + Math.random() * 9000));

// Only the SME (shipper side) ever SEES the OTPs; the driver must be TOLD
// them at the dock and enter them — that's the whole point of the handshake.
function shapeForRole(b, role) {
  if (role === "sme") return b;
  const { pickup_otp, delivery_otp, ...rest } = b;
  return rest;
}

async function ensureOtps(b) {
  if (b.pickup_otp && b.delivery_otp) return b;
  const patch = {
    pickup_otp: b.pickup_otp || genOtp(),
    delivery_otp: b.delivery_otp || genOtp(),
  };
  await supabaseAdmin.from("bookings").update(patch).eq("id", b.id);
  return { ...b, ...patch };
}

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
    const { cargo_id, truck_id, trip_id, match_score, agreed_price_inr, owner_initiated } = req.body || {};
    if (!cargo_id || !truck_id) throw apiError(400, "VALIDATION", "cargo_id and truck_id are required.");
    const isOwnerFlow = owner_initiated === true;
    if (isOwnerFlow && req.profile.role !== "truck_owner")
      throw apiError(403, "FORBIDDEN_ROLE", "Only truck owners can accept loads.");
    if (!isOwnerFlow && req.profile.role !== "sme")
      throw apiError(403, "FORBIDDEN_ROLE", "Only shippers can request bookings.");
    const { data: cargo } = await supabaseAdmin.from("cargo_requests").select("*").eq("cargo_id", cargo_id).single();
    if (!cargo) throw apiError(404, "CARGO_NOT_FOUND", "Cargo request not found.");
    if (!isOwnerFlow && cargo.sme_id !== req.profile.id) throw apiError(403, "FORBIDDEN", "Not your cargo request.");
    if (!["open", "matched"].includes(cargo.status)) throw apiError(409, "CARGO_CLOSED", "This cargo request is no longer open.");
    const { data: truck } = await supabaseAdmin.from("trucks").select("*").eq("truck_id", truck_id).single();
    if (!truck) throw apiError(404, "TRUCK_NOT_FOUND", "Truck not found.");
    if (isOwnerFlow && truck.owner_id !== req.profile.id)
      throw apiError(403, "FORBIDDEN", "You can only accept loads with your own truck.");

    // Owner-accepted loads start at "accepted" (owner has already said yes);
    // the shipper then confirms — same state machine, no skipped steps.
    const initialStatus = isOwnerFlow ? "accepted" : "pending";
    const { data: booking, error } = await supabaseAdmin.from("bookings")
      .insert({ cargo_id, truck_id, trip_id, match_score, agreed_price_inr, status: initialStatus, pickup_otp: genOtp(), delivery_otp: genOtp() })
      .select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not create the booking.");
    await supabaseAdmin.from("cargo_requests").update({ status: "matched" }).eq("cargo_id", cargo_id);
    if (isOwnerFlow) {
      await supabaseAdmin.from("booking_events").insert({
        booking_id: booking.id, from_status: "pending", to_status: "accepted", actor_id: req.profile.id });
      await notify(cargo.sme_id, "booking_request", "A truck owner accepted your load",
        `${cargo.origin} → ${cargo.destination} · ${truck.truck_type} · ₹${agreed_price_inr ?? "TBD"} — please confirm.`);
    } else {
      await notify(truck.owner_id, "booking_request", "New booking request",
        `${cargo.origin} → ${cargo.destination} · ${cargo.cargo_weight_tons} T · ₹${agreed_price_inr ?? "TBD"}`);
    }
    res.status(201).json(booking);
  } catch (e) { next(e); }
});

// GET /bookings — my bookings (role-aware)
r.get("/", async (req, res, next) => {
  try {
    let q = supabaseAdmin.from("bookings").select("*, cargo:cargo_requests(*), truck:trucks(*)").order("created_at", { ascending: false });
    const { data: all } = await q;
    let mine = (all || []).filter((b) =>
      req.profile.role === "truck_owner" ? b.truck.owner_id === req.profile.id : b.cargo.sme_id === req.profile.id);
    if (req.profile.role === "sme") {
      mine = await Promise.all(mine.map((b) => ensureOtps(b))); // backfill old rows
    }
    res.json(mine.map((b) => shapeForRole(b, req.profile.role)));
  } catch (e) { next(e); }
});

r.get("/:id", async (req, res, next) => {
  try {
    const { booking } = await loadBookingForUser(req.params.id, req.profile);
    const { data: proofs } = await supabaseAdmin.from("digital_proof").select("*").eq("booking_id", booking.id);
    const { data: events } = await supabaseAdmin.from("booking_events").select("*").eq("booking_id", booking.id).order("created_at");
    const shaped = req.profile.role === "sme" ? await ensureOtps(booking) : booking;
    res.json({ ...shapeForRole(shaped, req.profile.role), proofs: proofs || [], events: events || [] });
  } catch (e) { next(e); }
});

// POST /bookings/:id/verify-otp — driver enters the OTP the shipper shares
// at the dock. Verified timestamps then gate picked_up / delivered below.
r.post("/:id/verify-otp", async (req, res, next) => {
  try {
    const { type, otp } = req.body || {};
    if (!["pickup", "delivery"].includes(type) || !otp)
      throw apiError(400, "VALIDATION", "type (pickup|delivery) and otp are required.");
    const { booking } = await loadBookingForUser(req.params.id, req.profile);
    if (req.profile.role !== "truck_owner")
      throw apiError(403, "FORBIDDEN", "Only the driver enters handover OTPs.");
    const withOtps = await ensureOtps(booking);
    const expected = type === "pickup" ? withOtps.pickup_otp : withOtps.delivery_otp;
    if (String(otp).trim() !== String(expected))
      throw apiError(409, "OTP_INVALID", "Incorrect OTP — ask the shipper for the " + type + " OTP.");
    const col = type === "pickup" ? "pickup_otp_verified_at" : "delivery_otp_verified_at";
    await supabaseAdmin.from("bookings").update({ [col]: new Date().toISOString() }).eq("id", booking.id);
    await notify(booking.cargo.sme_id, "booking_status", "OTP verified at " + type,
      `${booking.cargo.origin} → ${booking.cargo.destination} · secure handover confirmed.`);
    res.json({ ok: true, type });
  } catch (e) { next(e); }
});

// PATCH /bookings/:id/status — the ONLY way status changes (spec §41)
r.patch("/:id/status", async (req, res, next) => {
  try {
    const { to } = req.body || {};
    const { booking } = await loadBookingForUser(req.params.id, req.profile);
    const { data: proofRows } = await supabaseAdmin.from("digital_proof").select("proof_type").eq("booking_id", booking.id);
    const proofs = (proofRows || []).map((p) => p.proof_type);
    // Secure handover: OTP must be verified before goods change hands.
    if (to === "picked_up" && !booking.pickup_otp_verified_at)
      throw apiError(409, "OTP_REQUIRED", "Verify the shipper's pickup OTP first.");
    if (to === "delivered" && !booking.delivery_otp_verified_at)
      throw apiError(409, "OTP_REQUIRED", "Verify the delivery OTP first.");
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

      // Auto-generate the shipper invoice (18% GST). Idempotent via unique(booking_id).
      const base = Number(booking.agreed_price_inr || 0);
      if (base > 0) {
        const gst = Math.round(base * 0.18);
        await supabaseAdmin.from("invoices").upsert({
          booking_id: booking.id,
          invoice_no: "INV-" + booking.id.slice(0, 8).toUpperCase(),
          sme_id: booking.cargo.sme_id,
          base_inr: base, gst_inr: gst, total_inr: base + gst, status: "paid",
        }, { onConflict: "booking_id" });
      }
    }
    res.json({ id: booking.id, status: to });
  } catch (e) { next(e); }
});

export default r;
