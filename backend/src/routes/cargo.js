import { Router } from "express";
import { supabaseAdmin } from "../lib/supabase.js";
import { apiError } from "../middleware/error.js";
import { routeDistanceKm, normCity } from "../services/matching.js";
import { selectNearbyDispatchTrucks, DISPATCH_WINDOW_SECONDS } from "../services/dispatchOffers.js";
import { sendDispatchOfferPush } from "../services/fcm.js";

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
      pickup_hour,
      pickup_lat,
      pickup_lng,
      package_count,
      quantity,
      dimensions,
      length_cm,
      width_cm,
      height_cm,
      is_fragile,
      is_temperature_sensitive,
      declared_value_inr,
      cargo_value,
      estimated_price_inr,
      offered_price_inr,
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
    const pickupLat = pickup_lat !== null && pickup_lat !== undefined && pickup_lat !== ''
      ? Number(pickup_lat)
      : null;
    const pickupLng = pickup_lng !== null && pickup_lng !== undefined && pickup_lng !== ''
      ? Number(pickup_lng)
      : null;
    const validPickupCoordinates = Number.isFinite(pickupLat) &&
      Number.isFinite(pickupLng) &&
      pickupLat >= -90 && pickupLat <= 90 &&
      pickupLng >= -180 && pickupLng <= 180;

    let resolvedDate = pickup_date || null;
    let resolvedHour = Number(pickup_hour) || 10;
    try {
      const d = new Date(resolvedPickupAt);
      if (!resolvedDate) resolvedDate = d.toISOString().slice(0, 10);
      if (!pickup_hour) resolvedHour = d.getHours();
    } catch (_) {}

    const parsedQuantity = Number(package_count || quantity) || 1;
    const resolvedDimensions = dimensions || (length_cm && width_cm && height_cm ? `${length_cm}x${width_cm}x${height_cm} cm` : null);
    const resolvedDeclaredValue = Number(declared_value_inr || cargo_value) || 0;
    const defaultEstimatedRate = Math.round(calculatedDist * Number(cargo_weight_tons) * 1.05 + 800);
    const finalEstimatedPrice = Number(estimated_price_inr || offered_price_inr) || defaultEstimatedRate;

    // Parse existing special_handling if provided as JSON or string
    let handlingMeta = {};
    if (typeof special_handling === "string" && special_handling.trim().startsWith("{")) {
      try { handlingMeta = JSON.parse(special_handling); } catch (_) {}
    } else if (typeof special_handling === "object" && special_handling !== null) {
      handlingMeta = { ...special_handling };
    }

    // Format special_handling JSON to comprehensively persist address, dimensions, quantity, handling flags & price
    const formattedSpecialHandling = JSON.stringify({
      pickup_address: pickup_address || handlingMeta.pickup_address || origin,
      drop_address: drop_address || handlingMeta.drop_address || destination,
      gstin: gstin || handlingMeta.gstin || null,
      package_count: parsedQuantity || handlingMeta.package_count || 1,
      dimensions: resolvedDimensions || handlingMeta.dimensions || null,
      length_cm: Number(length_cm) || handlingMeta.length_cm || null,
      width_cm: Number(width_cm) || handlingMeta.width_cm || null,
      height_cm: Number(height_cm) || handlingMeta.height_cm || null,
      is_fragile: is_fragile !== undefined ? Boolean(is_fragile) : (handlingMeta.is_fragile ?? false),
      is_temperature_sensitive: is_temperature_sensitive !== undefined ? Boolean(is_temperature_sensitive) : (handlingMeta.is_temperature_sensitive ?? false),
      declared_value_inr: resolvedDeclaredValue || handlingMeta.declared_value_inr || 0,
      estimated_price_inr: finalEstimatedPrice || handlingMeta.estimated_price_inr || defaultEstimatedRate,
      note: typeof special_handling === "string" && !special_handling.trim().startsWith("{") ? special_handling : handlingMeta.note || null,
    });

    const cargoRecord = {
      cargo_id,
      sme_id: req.profile.id,
      origin: origin.trim(),
      destination: destination.trim(),
      distance_km: calculatedDist,
      cargo_type: cargo_type.trim(),
      cargo_weight_tons: Number(cargo_weight_tons),
      pickup_at: resolvedPickupAt,
      pickup_lat: validPickupCoordinates ? pickupLat : null,
      pickup_lng: validPickupCoordinates ? pickupLng : null,
      pickup_date: resolvedDate,
      pickup_hour: resolvedHour,
      urgency: urgency || "normal",
      special_handling: formattedSpecialHandling,
      package_count: parsedQuantity,
      dimensions: resolvedDimensions,
      length_cm: Number(length_cm) || null,
      width_cm: Number(width_cm) || null,
      height_cm: Number(height_cm) || null,
      is_fragile: is_fragile !== undefined ? Boolean(is_fragile) : false,
      is_temperature_sensitive: is_temperature_sensitive !== undefined ? Boolean(is_temperature_sensitive) : false,
      declared_value_inr: resolvedDeclaredValue,
      status: "open",
      offered_price_inr: finalEstimatedPrice,
      estimated_price_inr: finalEstimatedPrice,
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
        pickup_lat: cargoRecord.pickup_lat,
        pickup_lng: cargoRecord.pickup_lng,
        pickup_date: resolvedDate,
        pickup_hour: resolvedHour,
        urgency: urgency || "normal",
        special_handling: formattedSpecialHandling,
        status: "open",
      }).select().single();

      if (!error && dbData) {
        activeCargoPool.set(cargo_id, { ...cargoRecord, ...dbData });
        if (cargoRecord.pickup_lat != null && cargoRecord.pickup_lng != null) {
          const { data: trucks } = await supabaseAdmin.from('trucks')
            .select('truck_id, owner_id, current_lat, current_lng, status, default_capacity_tons')
            .eq('status', 'available')
            .not('current_lat', 'is', null)
            .not('current_lng', 'is', null);
          const nearby = selectNearbyDispatchTrucks(cargoRecord, trucks || []);
          if (nearby.length) {
            const expiresAt = new Date(Date.now() + DISPATCH_WINDOW_SECONDS * 1000).toISOString();
            const offers = nearby.map(({ truck, distanceKm }) => ({
              cargo_id,
              driver_id: truck.owner_id,
              truck_id: truck.truck_id,
              distance_km: Number(distanceKm.toFixed(3)),
              expires_at: expiresAt,
            }));
            const { data: persistedOffers, error: offerError } = await supabaseAdmin.from('dispatch_offers').upsert(offers, {
              onConflict: 'cargo_id,truck_id',
              ignoreDuplicates: true,
            }).select('id, driver_id, truck_id, distance_km, expires_at');
            if (offerError) console.error('Nearby dispatch offers were not persisted:', offerError.message);
            else if (persistedOffers?.length) {
              try {
                const pushResult = await sendDispatchOfferPush(
                  persistedOffers.map((offer) => offer.driver_id),
                  cargoRecord,
                  persistedOffers,
                );
                if (!pushResult.configured) {
                  console.info('FCM service account not configured; dispatch remains available through Supabase Realtime.');
                }
              } catch (pushError) {
                console.error('Nearby dispatch FCM fan-out failed:', pushError.message);
              }
            }
          }
        }
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
// GET /cargo/:id/dispatch: Check live dispatch state for this cargo
r.get("/:id/dispatch", async (req, res, next) => {
  try {
    const id = req.params.id;
    // 1. Check if a booking was created for this cargo
    const { data: booking } = await supabaseAdmin.from("bookings")
      .select("*, truck:trucks(*, owner:profiles(full_name, phone))")
      .eq("cargo_id", id)
      .maybeSingle();

    if (booking) {
      return res.json({
        status: "assigned",
        booking,
        assigned_driver: {
          name: booking.truck?.owner?.full_name || "Assigned Driver",
          phone: booking.truck?.owner?.phone || "+91-9876543210",
          truck_reg: booking.truck?.registration_number || "",
          truck_type: booking.truck?.truck_type || "Commercial Truck",
          rating: booking.truck?.driver_rating || 4.8,
        },
      });
    }

    // 2. Fetch dispatch offers
    const { data: offers } = await supabaseAdmin.from("dispatch_offers")
      .select("id, driver_id, truck_id, distance_km, status, expires_at, created_at, truck:trucks(registration_number, truck_type, driver_rating, owner:profiles(full_name, phone))")
      .eq("cargo_id", id)
      .order("created_at", { ascending: false });

    // Check cargo status
    const cargo = activeCargoPool.get(id) || (await supabaseAdmin.from("cargo_requests").select("status").eq("cargo_id", id).maybeSingle())?.data;

    res.json({
      status: cargo?.status || "open",
      offers: offers || [],
      offers_count: offers?.length || 0,
      active_offers_count: (offers || []).filter(o => o.status === 'pending' && new Date(o.expires_at) > new Date()).length,
    });
  } catch (e) { next(e); }
});

// POST /cargo/:id/dispatch/retry: Re-trigger nearby dispatch for an open cargo
r.post("/:id/dispatch/retry", async (req, res, next) => {
  try {
    const id = req.params.id;
    const cargoRecord = activeCargoPool.get(id) || (await supabaseAdmin.from("cargo_requests").select("*").eq("cargo_id", id).maybeSingle())?.data;
    if (!cargoRecord) throw apiError(404, "NOT_FOUND", "Cargo not found.");
    if (cargoRecord.status !== "open") throw apiError(400, "INVALID_STATE", "Cargo is not open for dispatch.");

    let nearbyCount = 0;
    if (cargoRecord.pickup_lat != null && cargoRecord.pickup_lng != null) {
      const { data: trucks } = await supabaseAdmin.from('trucks')
        .select('truck_id, owner_id, current_lat, current_lng, status, default_capacity_tons')
        .eq('status', 'available')
        .not('current_lat', 'is', null)
        .not('current_lng', 'is', null);
      const nearby = selectNearbyDispatchTrucks(cargoRecord, trucks || []);
      if (nearby.length) {
        const expiresAt = new Date(Date.now() + DISPATCH_WINDOW_SECONDS * 1000).toISOString();
        const offers = nearby.map(({ truck, distanceKm }) => ({
          cargo_id: id,
          driver_id: truck.owner_id,
          truck_id: truck.truck_id,
          distance_km: Number(distanceKm.toFixed(3)),
          status: 'pending',
          expires_at: expiresAt,
        }));
        await supabaseAdmin.from('dispatch_offers').upsert(offers, {
          onConflict: 'cargo_id,truck_id',
        });
        nearbyCount = offers.length;
      }
    }
    res.json({ success: true, offers_sent: nearbyCount });
  } catch (e) { next(e); }
});

export default r;

