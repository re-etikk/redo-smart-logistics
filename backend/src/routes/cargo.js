import { Router } from "express";
import { supabaseAdmin } from "../lib/supabase.js";
import { requireAuth } from "../middleware/auth.js";
import { apiError } from "../middleware/error.js";
import { routeDistanceKm } from "../services/matching.js";

const r = Router();
r.use(requireAuth);

r.post("/", async (req, res, next) => {
  try {
    const { origin, destination, cargo_type, cargo_weight_tons, pickup_at, urgency, special_handling, distance_km } = req.body || {};
    if (!origin || !destination || !cargo_type || !cargo_weight_tons || !pickup_at) {
      throw apiError(400, "VALIDATION", "Fill in origin, destination, cargo type, weight and pickup time.");
    }
    if (origin === destination) throw apiError(400, "VALIDATION", "Origin and destination must differ.");
    if (Number(cargo_weight_tons) <= 0) throw apiError(400, "VALIDATION", "Weight must be positive.");

    // Ensure role is sme for profile
    if (req.profile.role !== "sme") {
      await supabaseAdmin.from("profiles").update({ role: "sme" }).eq("id", req.profile.id);
      req.profile.role = "sme";
    }

    const calculatedDist = Number(distance_km) || routeDistanceKm(origin, destination) || 500;
    const cargo_id = "C" + Date.now().toString(36).toUpperCase();
    const { data, error } = await supabaseAdmin.from("cargo_requests").insert({
      cargo_id,
      sme_id: req.profile.id,
      origin,
      destination,
      distance_km: calculatedDist,
      cargo_type,
      cargo_weight_tons: Number(cargo_weight_tons),
      pickup_at,
      urgency: urgency || "normal",
      special_handling: special_handling || null,
      status: "open",
    }).select().single();
    if (error) throw apiError(500, "DB_ERROR", "Could not save your cargo request: " + error.message);
    res.status(201).json(data);
  } catch (e) { next(e); }
});

r.get("/", async (req, res, next) => {
  try {
    const { origin, destination, search } = req.query || {};
    let q = supabaseAdmin.from("cargo_requests").select("*").order("created_at", { ascending: false });
    if (req.profile.role === "sme") {
      q = q.eq("sme_id", req.profile.id);
    } else {
      q = q.eq("status", "open");
    }

    if (origin) {
      q = q.ilike("origin", `%${origin}%`);
    }
    if (destination) {
      q = q.ilike("destination", `%${destination}%`);
    }
    if (search) {
      q = q.or(`origin.ilike.%${search}%,destination.ilike.%${search}%,cargo_type.ilike.%${search}%`);
    }

    const { data } = await q.limit(100);
    res.json(data || []);
  } catch (e) { next(e); }
});

r.get("/:id", async (req, res, next) => {
  try {
    const { data } = await supabaseAdmin.from("cargo_requests").select("*").eq("cargo_id", req.params.id).single();
    if (!data) throw apiError(404, "NOT_FOUND", "Cargo request not found.");
    res.json(data);
  } catch (e) { next(e); }
});

r.patch("/:id", async (req, res, next) => {
  try {
    const allowed = ["pickup_at", "urgency", "status", "cargo_weight_tons", "special_handling"];
    const patch = Object.fromEntries(Object.entries(req.body || {}).filter(([k]) => allowed.includes(k)));
    const { data, error } = await supabaseAdmin.from("cargo_requests")
      .update(patch).eq("cargo_id", req.params.id).eq("sme_id", req.profile.id).select().single();
    if (error || !data) throw apiError(404, "NOT_FOUND", "Cargo request not found or not yours.");
    res.json(data);
  } catch (e) { next(e); }
});

export default r;
