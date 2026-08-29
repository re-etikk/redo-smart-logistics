// tracking, proof, ratings, impact, notifications, profile, health/diagnostics
import { Router } from "express";
import { supabaseAdmin } from "../lib/supabase.js";
import { requireAuth } from "../middleware/auth.js";
import { apiError } from "../middleware/error.js";
import { mlHealth } from "../services/ml.js";

const r = Router();

// ---- health (public) + diagnostics (auth, dev page consumes it) ----
r.get("/health", (_req, res) => res.json({ status: "ok" }));
r.get("/diagnostics", requireAuth, async (_req, res) => {
  const ml = await mlHealth();
  const { error } = await supabaseAdmin.from("profiles").select("id").limit(1);
  res.json({
    backend: "connected",
    supabase: error ? "error" : "connected",
    ml_service: ml.status === "ok" ? `connected (${ml.model_backend})` : "down",
  });
});

r.use(requireAuth);

// ---- profile sync (called right after signup) ----
r.post("/auth/profile", async (req, res, next) => {
  try {
    const { full_name, phone, role, company_name } = req.body || {};
    if (!full_name || !role || !["truck_owner", "sme"].includes(role)) {
      throw apiError(400, "VALIDATION", "Name and a valid role are required.");
    }
    const { data, error } = await supabaseAdmin.from("profiles").upsert({
      id: req.user.id, full_name, phone, role, company_name,
    }).select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not save your profile.");
    res.json(data);
  } catch (e) { next(e); }
});

r.get("/auth/profile", async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from("profiles").select("*").eq("id", req.user.id).single();
    if (error && error.code !== 'PGRST116') throw apiError(500, "DB_ERROR", error.message);
    res.json(data || { id: req.user.id, onboarding_complete: false });
  } catch (e) { next(e); }
});

r.patch("/auth/profile", async (req, res, next) => {
  try {
    const allowed = ["full_name", "phone", "company_name", "avatar_url", "onboarding_complete", "role"];
    const patch = Object.fromEntries(Object.entries(req.body || {}).filter(([k]) => allowed.includes(k)));
    const { data, error } = await supabaseAdmin.from("profiles").upsert({
      id: req.user.id,
      role: patch.role || req.profile?.role || "truck_owner",
      ...patch,
    }).select().single();
    if (error) throw apiError(500, "DB_ERROR", error.message || "Could not update your profile.");
    res.json(data);
  } catch (e) { next(e); }
});

// ---- tracking (tied to real bookings; simulated events are flagged) ----
async function assertBookingParty(bookingId, profile) {
  const { data: b } = await supabaseAdmin.from("bookings")
    .select("id, cargo:cargo_requests(sme_id, origin, destination), truck:trucks(owner_id)")
    .eq("id", bookingId).single();
  if (!b) throw apiError(404, "BOOKING_NOT_FOUND", "Booking not found.");
  if (b.cargo.sme_id !== profile.id && b.truck.owner_id !== profile.id) {
    throw apiError(403, "FORBIDDEN", "Not your booking.");
  }
  return b;
}

r.get("/tracking/:booking_id", async (req, res, next) => {
  try {
    await assertBookingParty(req.params.booking_id, req.profile);
    const { data } = await supabaseAdmin.from("tracking_events").select("*")
      .eq("booking_id", req.params.booking_id).order("timestamp", { ascending: false }).limit(50);
    res.json(data || []);
  } catch (e) { next(e); }
});

r.post("/tracking/:booking_id/events", async (req, res, next) => {
  try {
    const b = await assertBookingParty(req.params.booking_id, req.profile);
    const { lat, lng, progress_pct, eta_minutes, is_simulated } = req.body || {};
    if (lat == null || lng == null) throw apiError(400, "VALIDATION", "lat and lng are required.");
    const { data, error } = await supabaseAdmin.from("tracking_events").insert({
      booking_id: b.id, lat, lng, progress_pct, eta_minutes,
      is_simulated: is_simulated !== false, // default true; real GPS must opt out explicitly
    }).select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not record tracking event.");
    res.status(201).json(data);
  } catch (e) { next(e); }
});

// ---- digital proof metadata (file itself goes to Supabase Storage) ----
r.post("/proof", async (req, res, next) => {
  try {
    const { booking_id, proof_type, photo_url, gps_lat, gps_lng } = req.body || {};
    if (!booking_id || !["pickup", "delivery"].includes(proof_type)) {
      throw apiError(400, "VALIDATION", "booking_id and a valid proof_type are required.");
    }
    await assertBookingParty(booking_id, req.profile);
    const { data, error } = await supabaseAdmin.from("digital_proof").upsert({
      booking_id, proof_type, photo_url, gps_lat, gps_lng, confirmed_by: req.profile.id,
    }, { onConflict: "booking_id,proof_type" }).select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not save the proof.");
    res.status(201).json(data);
  } catch (e) { next(e); }
});

r.get("/proof/:booking_id", async (req, res, next) => {
  try {
    await assertBookingParty(req.params.booking_id, req.profile);
    const { data } = await supabaseAdmin.from("digital_proof").select("*").eq("booking_id", req.params.booking_id);
    res.json(data || []);
  } catch (e) { next(e); }
});

// ---- ratings ----
r.post("/ratings", async (req, res, next) => {
  try {
    const { booking_id, score, comment } = req.body || {};
    if (!booking_id || !(score >= 1 && score <= 5)) throw apiError(400, "VALIDATION", "Score must be 1–5.");
    const b = await assertBookingParty(booking_id, req.profile);
    const rated_user = req.profile.id === b.cargo.sme_id ? b.truck.owner_id : b.cargo.sme_id;
    const { data, error } = await supabaseAdmin.from("ratings")
      .insert({ booking_id, rated_by: req.profile.id, rated_user, score, comment }).select().single();
    if (error) throw apiError(409, "ALREADY_RATED", "You have already rated this booking.");
    res.status(201).json(data);
  } catch (e) { next(e); }
});

// ---- impact ----
r.get("/impact", async (req, res, next) => {
  try {
    const { data: all } = await supabaseAdmin.from("impact_records")
      .select("*, booking:bookings(cargo:cargo_requests(sme_id), truck:trucks(owner_id))");
    const mine = (all || []).filter((x) =>
      req.profile.role === "sme" ? x.booking.cargo.sme_id === req.profile.id : x.booking.truck.owner_id === req.profile.id);
    const sum = (k) => +mine.reduce((a, x) => a + Number(x[k] || 0), 0).toFixed(1);
    res.json({
      records: mine.length,
      totals: {
        empty_km_avoided: sum("empty_km_avoided"),
        truck_owner_income_inr: sum("truck_owner_income_inr"),
        sme_saving_inr: sum("sme_saving_inr"),
        fuel_avoided_liters: sum("fuel_avoided_liters"),
        co2_avoided_kg: sum("co2_avoided_kg"),
        avg_utilization_gain_pct: mine.length ? +(sum("utilization_gain_pct") / mine.length).toFixed(1) : 0,
      },
      is_estimated: true,
    });
  } catch (e) { next(e); }
});

// ---- notifications ----
r.get("/notifications", async (req, res, next) => {
  try {
    const { data } = await supabaseAdmin.from("notifications").select("*")
      .eq("user_id", req.profile.id).order("created_at", { ascending: false }).limit(50);
    res.json(data || []);
  } catch (e) { next(e); }
});
r.patch("/notifications/:id/read", async (req, res, next) => {
  try {
    await supabaseAdmin.from("notifications").update({ read: true })
      .eq("id", req.params.id).eq("user_id", req.profile.id);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

export default r;
