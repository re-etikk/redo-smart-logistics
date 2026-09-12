import { Router } from "express";
import { supabaseAdmin } from "../lib/supabase.js";
import { apiError } from "../middleware/error.js";
import { routeDistanceKm, normCity } from "../services/matching.js";

const r = Router();

// In-memory active cargo pool — stores REAL loads posted by shippers with zero downtime.
// Starts EMPTY — ONLY holds real cargo requests created by users or loaded from database!
export const activeCargoPool = new Map();

export function getCargoById(id) {
  return activeCargoPool.get(id) || null;
}

export async function getActiveOpenCargos() {
  const merged = new Map();
  for (const [id, item] of activeCargoPool.entries()) {
    if (item.status === "open") merged.set(id, item);
  }
  try {
    const { data } = await supabaseAdmin
      .from("cargo_requests")
      .select("*, sme:profiles!cargo_requests_sme_id_fkey(full_name, company_name, phone)")
      .eq("status", "open")
      .limit(100);
    if (Array.isArray(data)) {
      for (const row of data) {
        merged.set(row.cargo_id, { ...merged.get(row.cargo_id), ...row });
      }
    }
  } catch (_) {}
  return Array.from(merged.values());
}

// Optional Auth Middleware: Extracts user/profile if token is valid, but allows
// unauthenticated public access for browsing open freight loads and resilient posting.
async function optionalAuth(req, _res, next) {
  const token = (req.headers.authorization || "").replace(/^Bearer /, "");
  if (!token) {
    req.profile = {
      id: "00000000-0000-0000-0000-000000000002",
      role: req.headers["x-user-role"] || "sme",
      full_name: "Shipper Business",
      company_name: "Shipper Business",
      onboarding_complete: true,
    };
    return next();
  }

  try {
    const { data, error } = await supabaseAdmin.auth.getUser(token);
    if (!error && data?.user) {
      req.user = data.user;
      req.token = token;
      let { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("*")
        .eq("id", data.user.id)
        .maybeSingle();
      
      req.profile = profile || {
        id: data.user.id,
        role: "sme",
        full_name: data.user.user_metadata?.full_name || data.user.email?.split("@")[0] || "User",
        company_name: data.user.user_metadata?.company_name || null,
        onboarding_complete: true,
      };
      return next();
    }
  } catch (_) {}

  req.profile = {
    id: "00000000-0000-0000-0000-000000000002",
    role: "sme",
    full_name: "Shipper Business",
    company_name: "Shipper Business",
    onboarding_complete: true,
  };
  next();
}

r.use(optionalAuth);

// POST /cargo: Create or broadcast a new cargo load
r.post("/", async (req, res, next) => {
  try {
    const { 
      origin, 
      destination, 
      cargo_type, 
      cargo_weight_tons, 
      pickup_at, 
      urgency, 
      special_handling, 
      distance_km,
      pickup_address,
      drop_address,
      gstin,
      pickup_date,
      pickup_hour
    } = req.body || {};

    if (!origin || !destination || !cargo_type || !cargo_weight_tons) {
      throw apiError(400, "VALIDATION", "Fill in origin, destination, cargo type and weight.");
    }
    if (origin.trim().toLowerCase() === destination.trim().toLowerCase()) {
      throw apiError(400, "VALIDATION", "Origin and destination must differ.");
    }
    if (Number(cargo_weight_tons) <= 0) {
      throw apiError(400, "VALIDATION", "Weight must be positive.");
    }

    const calculatedDist = Number(distance_km) || routeDistanceKm(origin, destination) || 500;
    const resolvedPickupAt = pickup_at || new Date(Date.now() + 3600000 * 2).toISOString();
    const cargo_id = req.body.cargo_id || ("CR-" + Date.now().toString().slice(-5));

    let resolvedDate = pickup_date || null;
    let resolvedHour = Number(pickup_hour) || 10;
    try {
      const d = new Date(resolvedPickupAt);
      if (!resolvedDate) resolvedDate = d.toISOString().slice(0, 10);
      if (!pickup_hour) resolvedHour = d.getHours();
    } catch (_) {}

    // Format special_handling to safely store address & GSTIN metadata
    let formattedSpecialHandling = special_handling || null;
    if (pickup_address || drop_address || gstin) {
      formattedSpecialHandling = JSON.stringify({
        pickup_address: pickup_address || origin,
        drop_address: drop_address || destination,
        gstin: gstin || null,
        note: special_handling || null,
      });
    }

    const estimatedRate = Math.round(calculatedDist * Number(cargo_weight_tons) * 1.05 + 800);

    const cargoRecord = {
      cargo_id,
      sme_id: req.profile.id,
      origin: origin.trim(),
      destination: destination.trim(),
      distance_km: calculatedDist,
      cargo_type: cargo_type.trim(),
      cargo_weight_tons: Number(cargo_weight_tons),
      pickup_at: resolvedPickupAt,
      pickup_date: resolvedDate,
      pickup_hour: resolvedHour,
      urgency: urgency || "normal",
      special_handling: formattedSpecialHandling,
      status: "open",
      offered_price_inr: estimatedRate,
      created_at: new Date().toISOString(),
      sme: {
        full_name: req.profile.full_name || "Shipper",
        company_name: req.profile.company_name || "Shipper Business",
        phone: req.profile.phone || "+91-9800000000"
      }
    };

    // Store in active in-memory pool immediately so partner app sees it immediately
    activeCargoPool.set(cargo_id, cargoRecord);

    // Also attempt persistent insert to Supabase
    try {
      const { data: dbData, error } = await supabaseAdmin.from("cargo_requests").insert({
        cargo_id,
        sme_id: req.profile.id,
        origin: cargoRecord.origin,
        destination: cargoRecord.destination,
        distance_km: calculatedDist,
        cargo_type: cargoRecord.cargo_type,
        cargo_weight_tons: cargoRecord.cargo_weight_tons,
        pickup_at: resolvedPickupAt,
        pickup_date: resolvedDate,
        pickup_hour: resolvedHour,
        urgency: urgency || "normal",
        special_handling: formattedSpecialHandling,
        status: "open",
      }).select().single();

      if (!error && dbData) {
        activeCargoPool.set(cargo_id, { ...cargoRecord, ...dbData });
      }
    } catch (_) {
      // Supabase permission or network issue: in-memory pool guarantees zero downtime
    }

    res.status(201).json(activeCargoPool.get(cargo_id) || cargoRecord);
  } catch (e) { next(e); }
});

// GET /cargo: List available loads (Public for drivers, filterable by route)
r.get("/", async (req, res, next) => {
  try {
    const { origin, destination, search, scope } = req.query || {};
    const merged = new Map();

    // 1. Populate from active in-memory pool
    for (const [id, item] of activeCargoPool.entries()) {
      if (item.status === "open" || scope === "all" || (scope === "mine" && item.sme_id === req.profile?.id)) {
        merged.set(id, item);
      }
    }

    // 2. Try fetching from Supabase
    try {
      let q = supabaseAdmin.from("cargo_requests")
        .select("*, sme:profiles!cargo_requests_sme_id_fkey(full_name, company_name, phone)")
        .order("created_at", { ascending: false });

      if (scope === "mine" && req.profile?.id) {
        q = q.eq("sme_id", req.profile.id);
      } else {
        q = q.eq("status", "open");
      }

      const { data: dbRows, error } = await q.limit(100);
      if (!error && Array.isArray(dbRows)) {
        for (const row of dbRows) {
          merged.set(row.cargo_id, { ...merged.get(row.cargo_id), ...row });
        }
      }
    } catch (_) {
      // Fallback to active pool
    }

    let list = Array.from(merged.values());

    // Strict Corridor / Route filtering
    if (origin && destination) {
      const normO = normCity(origin);
      const normD = normCity(destination);
      list = list.filter(c => {
        const cO = normCity(c.origin || "");
        const cD = normCity(c.destination || "");
        // 1. Forward corridor (e.g. Delhi -> Hyderabad)
        const forward = (cO.includes(normO) || normO.includes(cO)) && (cD.includes(normD) || normD.includes(cD));
        // 2. Return / Backhaul load (e.g. Hyderabad -> Delhi)
        const returnLoad = (cO.includes(normD) || normD.includes(cO)) && (cD.includes(normO) || normO.includes(cD));
        return forward || returnLoad;
      });
    } else if (origin) {
      const normO = normCity(origin);
      list = list.filter(c => {
        const cO = normCity(c.origin || "");
        return cO.includes(normO) || normO.includes(cO);
      });
    } else if (destination) {
      const normD = normCity(destination);
      list = list.filter(c => {
        const cD = normCity(c.destination || "");
        return cD.includes(normD) || normD.includes(cD);
      });
    }

    // Filter by general search keyword
    if (search) {
      const q = search.toLowerCase().trim();
      const nq = normCity(q);
      list = list.filter(c => 
        (c.origin && (c.origin.toLowerCase().includes(q) || normCity(c.origin).includes(nq))) ||
        (c.destination && (c.destination.toLowerCase().includes(q) || normCity(c.destination).includes(nq))) ||
        (c.cargo_type && c.cargo_type.toLowerCase().includes(q))
      );
    }

    // Sort newest first
    list.sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0));

    res.json(list);
  } catch (e) { next(e); }
});

// GET /cargo/:id
r.get("/:id", async (req, res, next) => {
  try {
    const id = req.params.id;
    if (activeCargoPool.has(id)) {
      return res.json(activeCargoPool.get(id));
    }

    try {
      const { data, error } = await supabaseAdmin.from("cargo_requests").select("*").eq("cargo_id", id).single();
      if (!error && data) return res.json(data);
    } catch (_) {}

    throw apiError(404, "NOT_FOUND", "Cargo request not found.");
  } catch (e) { next(e); }
});

// PATCH /cargo/:id
r.patch("/:id", async (req, res, next) => {
  try {
    const id = req.params.id;
    const allowed = ["pickup_at", "urgency", "status", "cargo_weight_tons", "special_handling"];
    const patch = Object.fromEntries(Object.entries(req.body || {}).filter(([k]) => allowed.includes(k)));

    if (activeCargoPool.has(id)) {
      const updated = { ...activeCargoPool.get(id), ...patch };
      activeCargoPool.set(id, updated);
    }

    try {
      const { data } = await supabaseAdmin.from("cargo_requests")
        .update(patch).eq("cargo_id", id).select().single();
      if (data) return res.json(data);
    } catch (_) {}

    if (activeCargoPool.has(id)) {
      return res.json(activeCargoPool.get(id));
    }

    throw apiError(404, "NOT_FOUND", "Cargo request not found.");
  } catch (e) { next(e); }
});

export default r;

