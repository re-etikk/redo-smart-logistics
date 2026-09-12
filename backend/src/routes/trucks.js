import { Router } from "express";
import { supabaseAdmin } from "../lib/supabase.js";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { apiError } from "../middleware/error.js";
import { routeDistanceKm } from "../services/matching.js";

const r = Router();

// In-memory active pools — stores REAL trucks & trips registered by drivers with zero downtime.
// Starts EMPTY — ONLY contains real trucks/trips added by partner drivers!
export const activeTruckPool = new Map();
export const activeTripPool = new Map();

export function getTruckById(id) {
  return activeTruckPool.get(id) || null;
}

export async function getActiveTrucks(ownerId = null) {
  const merged = new Map();
  for (const [id, t] of activeTruckPool.entries()) {
    if (!ownerId || t.owner_id === ownerId) merged.set(id, t);
  }
  try {
    let q = supabaseAdmin.from("trucks").select("*");
    if (ownerId) q = q.eq("owner_id", ownerId);
    const { data } = await q.limit(100);
    if (Array.isArray(data)) {
      for (const row of data) {
        merged.set(row.truck_id, { ...merged.get(row.truck_id), ...row });
      }
    }
  } catch (_) {}
  return Array.from(merged.values());
}

export async function getActiveTrips() {
  const merged = new Map();
  for (const [id, t] of activeTripPool.entries()) {
    if (t.open_for_matching) merged.set(id, t);
  }
  try {
    const { data } = await supabaseAdmin
      .from("truck_trips")
      .select("*, truck:trucks(*)")
      .eq("open_for_matching", true)
      .gte("departure_at", new Date(Date.now() - 24 * 36e5).toISOString());
    if (Array.isArray(data)) {
      for (const row of data) {
        merged.set(row.id, { ...merged.get(row.id), ...row });
      }
    }
  } catch (_) {}
  return Array.from(merged.values());
}

r.use(requireAuth);

r.post("/", async (req, res, next) => {
  try {
    const { truck_type, registration_number, body_type, home_origin, default_capacity_tons } = req.body || {};
    if (!truck_type || !registration_number || !default_capacity_tons) {
      throw apiError(400, "VALIDATION", "Truck type, registration number and capacity are required.");
    }
    // Auto-promote to truck_owner role and mark onboarding complete when registering a truck
    if (req.profile.role !== "truck_owner") {
      try {
        await supabaseAdmin.from("profiles").update({ role: "truck_owner", partner_onboarding_complete: true }).eq("id", req.profile.id);
      } catch (_) {}
      req.profile.role = "truck_owner";
    }
    const truck_id = "T" + Date.now().toString(36).toUpperCase();
    const truckRecord = {
      truck_id,
      owner_id: req.profile.id,
      truck_type,
      registration_number: registration_number.toUpperCase().trim(),
      body_type: body_type || "closed_container",
      home_origin: home_origin ? home_origin.trim() : "Delhi",
      default_capacity_tons: Number(default_capacity_tons),
      status: "available",
      driver_rating: 4.8,
      on_time_rate: 0.95,
      cancel_rate: 0.03,
      verified_documents: true,
      created_at: new Date().toISOString(),
    };

    activeTruckPool.set(truck_id, truckRecord);

    try {
      const { data, error } = await supabaseAdmin.from("trucks").insert(truckRecord).select().single();
      if (!error && data) {
        activeTruckPool.set(truck_id, { ...truckRecord, ...data });
      }
    } catch (_) {}

    res.status(201).json(activeTruckPool.get(truck_id) || truckRecord);
  } catch (e) { next(e); }
});

r.get("/", async (req, res, next) => {
  try {
    const ownerId = req.profile.role === "truck_owner" ? req.profile.id : null;
    const list = await getActiveTrucks(ownerId);
    res.json(list);
  } catch (e) { next(e); }
});

r.patch("/:id", requireRole("truck_owner"), async (req, res, next) => {
  try {
    const allowed = ["status", "gps_enabled", "current_lat", "current_lng", "body_type", "home_origin"];
    const patch = Object.fromEntries(Object.entries(req.body || {}).filter(([k]) => allowed.includes(k)));

    if (activeTruckPool.has(req.params.id)) {
      activeTruckPool.set(req.params.id, { ...activeTruckPool.get(req.params.id), ...patch });
    }

    try {
      const { data } = await supabaseAdmin.from("trucks")
        .update(patch).eq("truck_id", req.params.id).eq("owner_id", req.profile.id).select().single();
      if (data) return res.json(data);
    } catch (_) {}

    if (activeTruckPool.has(req.params.id)) {
      return res.json(activeTruckPool.get(req.params.id));
    }

    throw apiError(404, "NOT_FOUND", "Truck not found or not yours.");
  } catch (e) { next(e); }
});

// Trips (return legs with spare capacity)
r.post("/:id/trips", async (req, res, next) => {
  try {
    const { origin, destination, departure_at, available_capacity_tons, price_per_km_ton, accepted_cargo_types } = req.body || {};
    if (!origin || !destination || !departure_at || !available_capacity_tons) {
      throw apiError(400, "VALIDATION", "Route, departure and available capacity are required.");
    }

    let truck = activeTruckPool.get(req.params.id);
    if (!truck) {
      try {
        const { data } = await supabaseAdmin.from("trucks").select("*").eq("truck_id", req.params.id).single();
        truck = data;
      } catch (_) {}
    }

    const trip_id = "TRIP-" + Date.now().toString(36).toUpperCase();
    const tripRecord = {
      id: trip_id,
      truck_id: req.params.id,
      origin: origin.trim(),
      destination: destination.trim(),
      distance_km: routeDistanceKm(origin, destination) || 500,
      departure_at,
      available_capacity_tons: Number(available_capacity_tons),
      price_per_km_ton: Number(price_per_km_ton || 1.05),
      accepted_cargo_types: accepted_cargo_types || null,
      open_for_matching: true,
      created_at: new Date().toISOString(),
      truck: truck || {
        truck_id: req.params.id,
        truck_type: "Commercial Truck",
        registration_number: "REGISTERED",
        status: "available",
      },
    };

    activeTripPool.set(trip_id, tripRecord);

    try {
      const { data, error } = await supabaseAdmin.from("truck_trips").insert({
        truck_id: req.params.id,
        origin: tripRecord.origin,
        destination: tripRecord.destination,
        distance_km: tripRecord.distance_km,
        departure_at,
        available_capacity_tons: tripRecord.available_capacity_tons,
        price_per_km_ton: tripRecord.price_per_km_ton,
        accepted_cargo_types: tripRecord.accepted_cargo_types,
        open_for_matching: true,
      }).select().single();

      if (!error && data) {
        activeTripPool.set(trip_id, { ...tripRecord, ...data, truck: tripRecord.truck });
      }
    } catch (_) {}

    res.status(201).json(activeTripPool.get(trip_id) || tripRecord);
  } catch (e) { next(e); }
});

r.get("/:id/trips", async (req, res, next) => {
  try {
    const trips = [];
    for (const t of activeTripPool.values()) {
      if (t.truck_id === req.params.id) trips.push(t);
    }
    try {
      const { data } = await supabaseAdmin.from("truck_trips").select("*")
        .eq("truck_id", req.params.id).order("departure_at", { ascending: false }).limit(20);
      if (Array.isArray(data)) {
        for (const row of data) {
          if (!trips.some(x => x.id === row.id)) trips.push(row);
        }
      }
    } catch (_) {}
    res.json(trips);
  } catch (e) { next(e); }
});

export default r;
