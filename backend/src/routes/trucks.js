import { Router } from "express";
import { supabaseAdmin } from "../lib/supabase.js";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { apiError } from "../middleware/error.js";
import { routeDistanceKm } from "../services/matching.js";

const r = Router();
r.use(requireAuth);

r.post("/", requireRole("truck_owner"), async (req, res, next) => {
  try {
    const { truck_type, registration_number, body_type, home_origin, default_capacity_tons } = req.body || {};
    if (!truck_type || !registration_number || !default_capacity_tons) {
      throw apiError(400, "VALIDATION", "Truck type, registration number and capacity are required.");
    }
    const truck_id = "T" + Date.now().toString(36).toUpperCase();
    const { data, error } = await supabaseAdmin.from("trucks").insert({
      truck_id, owner_id: req.profile.id, truck_type, registration_number,
      body_type, home_origin, default_capacity_tons, status: "available",
    }).select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not save your truck.");
    res.status(201).json(data);
  } catch (e) { next(e); }
});

r.get("/", async (req, res, next) => {
  try {
    let q = supabaseAdmin.from("trucks").select("truck_id, owner_id, truck_type, registration_number, default_capacity_tons, driver_rating, on_time_rate, cancel_rate, verified_documents, status");
    if (req.profile.role === "truck_owner") q = q.eq("owner_id", req.profile.id);
    const { data } = await q.limit(100);
    res.json(data || []);
  } catch (e) { next(e); }
});

r.patch("/:id", requireRole("truck_owner"), async (req, res, next) => {
  try {
    const allowed = ["status", "gps_enabled", "current_lat", "current_lng", "body_type", "home_origin"];
    const patch = Object.fromEntries(Object.entries(req.body || {}).filter(([k]) => allowed.includes(k)));
    const { data, error } = await supabaseAdmin.from("trucks")
      .update(patch).eq("truck_id", req.params.id).eq("owner_id", req.profile.id).select().single();
    if (error || !data) throw apiError(404, "NOT_FOUND", "Truck not found or not yours.");
    res.json(data);
  } catch (e) { next(e); }
});

// Trips (return legs with spare capacity)
r.post("/:id/trips", requireRole("truck_owner"), async (req, res, next) => {
  try {
    const { origin, destination, departure_at, available_capacity_tons, price_per_km_ton, accepted_cargo_types } = req.body || {};
    if (!origin || !destination || !departure_at || !available_capacity_tons) {
      throw apiError(400, "VALIDATION", "Route, departure and available capacity are required.");
    }
    const { data: truck } = await supabaseAdmin.from("trucks").select("*").eq("truck_id", req.params.id).single();
    if (!truck || truck.owner_id !== req.profile.id) throw apiError(403, "FORBIDDEN", "Not your truck.");
    if (Number(available_capacity_tons) > Number(truck.default_capacity_tons)) {
      throw apiError(400, "VALIDATION", "Available capacity cannot exceed truck capacity.");
    }
    const { data, error } = await supabaseAdmin.from("truck_trips").insert({
      truck_id: truck.truck_id, origin, destination,
      distance_km: routeDistanceKm(origin, destination),
      departure_at, available_capacity_tons,
      price_per_km_ton: price_per_km_ton || 1.0,
      accepted_cargo_types: accepted_cargo_types || null,
      open_for_matching: true,
    }).select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not save your trip.");
    res.status(201).json(data);
  } catch (e) { next(e); }
});

r.get("/:id/trips", async (req, res, next) => {
  try {
    const { data } = await supabaseAdmin.from("truck_trips").select("*")
      .eq("truck_id", req.params.id).order("departure_at", { ascending: false }).limit(20);
    res.json(data || []);
  } catch (e) { next(e); }
});

export default r;
