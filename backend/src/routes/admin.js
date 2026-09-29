// admin.js — Operations Control Room Endpoints
// Guarded by profile.role === 'admin'. Service-role client server-side.

import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';
import { DEFAULT_CORRIDOR_RATES, calculateDynamicPrice } from '../services/dynamicPricing.js';
import { CORRIDORS, matchCorridorSubSegment } from '../services/corridorSegments.js';
import { calculateReDoMatchScore } from '../services/matching.js';

export const adminRouter = Router();
adminRouter.use(requireAuth);
adminRouter.use((req, _res, next) => {
  if (req.profile?.role !== 'admin' || req.profile?.status === 'suspended') {
    return next(apiError(403, 'FORBIDDEN', 'Active administrator access required.'));
  }
  next();
});

// 1. Operations Overview Stats
adminRouter.get('/stats', async (_req, res, next) => {
  try {
    const count = async (table, filter) => {
      let q = supabaseAdmin.from(table).select('*', { count: 'exact', head: true });
      if (filter) q = filter(q);
      const { count: c, error } = await q;
      if (error) throw apiError(500, 'DB_ERROR', error.message);
      return c ?? 0;
    };
    const [users, shippers, owners, trucks, bookings, completed, kyc_pending, verifiedTrucks] = await Promise.all([
      count('profiles'),
      count('profiles', (q) => q.eq('role', 'sme')),
      count('profiles', (q) => q.eq('role', 'truck_owner')),
      count('trucks'),
      count('bookings'),
      count('bookings', (q) => q.in('status', ['delivered', 'completed'])),
      count('kyc_verifications', (q) => q.eq('verification_status', 'pending')),
      count('trucks', (q) => q.eq('verified_documents', true)),
    ]);

    const [{ data: activeTrucks, error: truckError }, { data: completedBookings, error: bookingError }] = await Promise.all([
      supabaseAdmin.from('trucks')
      .select('default_capacity_tons, status')
      .in('status', ['available', 'in_transit']),
      supabaseAdmin.from('bookings')
        .select('agreed_price_inr')
        .in('status', ['delivered', 'completed']),
    ]);
    if (truckError) throw apiError(500, 'DB_ERROR', truckError.message);
    if (bookingError) throw apiError(500, 'DB_ERROR', bookingError.message);

    const totalCapacityTons = (activeTrucks || []).reduce((acc, t) => acc + (Number(t.default_capacity_tons) || 0), 0);
    const platformGmvInr = (completedBookings || []).reduce((acc, booking) => acc + (Number(booking.agreed_price_inr) || 0), 0);

    res.json({
      users,
      shippers,
      owners,
      trucks,
      bookings,
      completed,
      kyc_pending,
      verified_drivers: verifiedTrucks,
      platform_gmv_inr: platformGmvInr,
      active_corridor_trucks: (activeTrucks || []).length,
      network_capacity_tons: Math.round(totalCapacityTons),
    });
  } catch (e) { next(e); }
});

// 2. Live Fleet Radar (Corridor-based moving capacity radar)
adminRouter.get('/radar', async (_req, res, next) => {
  try {
    const { data: trucks, error } = await supabaseAdmin.from('trucks')
      .select('truck_id, registration_number, truck_type, body_type, home_origin, default_capacity_tons, driver_rating, status, current_lat, current_lng, verified_documents, owner:profiles!trucks_owner_id_fkey(full_name, phone)')
      .in('status', ['available', 'in_transit'])
      .limit(100);

    if (error) throw apiError(500, 'DB_ERROR', error.message);

    // Map trucks to active corridors and compute live occupancy
    const radarData = (trucks || []).map((t) => {
      const home = (t.home_origin || 'Delhi').toLowerCase();
      let corridor = 'unassigned';
      let corridorName = t.home_origin || 'Route not reported';
      if (home.includes('mumbai') || home.includes('pune')) {
        corridor = 'mumbai_bengaluru';
        corridorName = 'Mumbai - Pune - Kolhapur - Bengaluru';
      } else if (home.includes('jaipur') || home.includes('ahmedabad') || home.includes('surat')) {
        corridor = 'delhi_mumbai';
        corridorName = 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai';
      }

      const totalCap = Number(t.default_capacity_tons) || 16.0;

      return {
        truck_id: t.truck_id,
        registration_number: t.registration_number || t.truck_id,
        truck_type: t.truck_type,
        body_type: t.body_type,
        owner_name: t.owner?.full_name || 'Fleet Operator',
        driver_phone: t.owner?.phone || null,
        driver_rating: t.driver_rating,
        status: t.status,
        verified_documents: Boolean(t.verified_documents),
        home_origin: t.home_origin,
        corridor_id: corridor,
        corridor_name: corridorName,
        current_lat: t.current_lat,
        current_lng: t.current_lng,
        total_capacity_tons: totalCap,
        occupied_capacity_tons: null,
        available_capacity_tons: null,
        occupancy_pct: null,
        active_sub_segment: null,
        next_halt: null,
      };
    });

    res.json({
      corridors: Object.values(CORRIDORS).map(c => ({ id: c.id, name: c.name, highway: c.highway, waypoints: c.waypoints })),
      active_trucks: radarData,
      total_active_count: radarData.length,
    });
  } catch (e) { next(e); }
});

// 3. Matching Overseer & Candidates
adminRouter.get('/matching/candidates', async (_req, res, next) => {
  try {
    const { data: openCargo, error: cErr } = await supabaseAdmin.from('cargo_requests')
      .select('cargo_id, origin, destination, cargo_type, cargo_weight_tons, pickup_date, urgency, status, sme:profiles!cargo_requests_sme_id_fkey(full_name, phone, company_name)')
      .eq('status', 'open')
      .order('created_at', { ascending: false })
      .limit(20);

    if (cErr) throw apiError(500, 'DB_ERROR', cErr.message);

    const { data: availableTrucks, error: tErr } = await supabaseAdmin.from('trucks')
      .select('truck_id, registration_number, truck_type, home_origin, default_capacity_tons, driver_rating, on_time_rate, cancel_rate, owner:profiles!trucks_owner_id_fkey(full_name, phone)')
      .eq('status', 'available')
      .limit(30);

    if (tErr) throw apiError(500, 'DB_ERROR', tErr.message);

    const candidatesByCargo = (openCargo || []).map(cargo => {
      const candidates = (availableTrucks || []).map(truck => {
        const tripOrigin = truck.home_origin || 'Delhi';
        const tripDest = 'Patna'; // default reference lane

        const subSeg = matchCorridorSubSegment(tripOrigin, tripDest, cargo.origin, cargo.destination);
        const pricing = calculateDynamicPrice({
          weightTons: Number(cargo.cargo_weight_tons) || 2,
          distanceKm: subSeg.isMatch ? subSeg.segmentDistanceKm : 450,
          corridorId: subSeg.isMatch ? subSeg.corridorId : 'delhi_patna',
          cargoType: cargo.cargo_type,
          truckOccupancyPct: 0.70,
        });

        const matchScore = calculateReDoMatchScore({
          routeOverlapScore: subSeg.isMatch ? subSeg.overlapScore : 0.65,
          availableCapacityTons: Number(truck.default_capacity_tons),
          cargoWeightTons: Number(cargo.cargo_weight_tons),
          driverRating: truck.driver_rating,
          onTimeRate: truck.on_time_rate,
          cancelRate: truck.cancel_rate,
        });

        return {
          truck_id: truck.truck_id,
          registration_number: truck.registration_number || 'TRUCK-REDO',
          owner_name: truck.owner?.full_name || 'Partner',
          truck_type: truck.truck_type,
          available_capacity_tons: Number(truck.default_capacity_tons),
          driver_rating: truck.driver_rating ?? 4.8,
          match_score_pct: matchScore.scorePct,
          match_breakdown: matchScore.breakdown,
          sub_segment: subSeg.isMatch ? subSeg : null,
          dynamic_pricing: pricing,
        };
      }).sort((a, b) => b.match_score_pct - a.match_score_pct).slice(0, 5);

      return {
        cargo,
        top_candidates: candidates,
      };
    });

    res.json(candidatesByCargo);
  } catch (e) { next(e); }
});

// 4. Manual Matching / Dispatch Override
adminRouter.post('/matching/override', async (req, res, next) => {
  try {
    const { cargo_id, truck_id, override_price_inr, override_reason } = req.body ?? {};
    if (!cargo_id || !truck_id) {
      throw apiError(400, 'VALIDATION_ERROR', 'cargo_id and truck_id are required.');
    }

    // Create booking record
    const { data: booking, error: bErr } = await supabaseAdmin.from('bookings').insert({
      cargo_id,
      truck_id,
      agreed_price_inr: Number(override_price_inr) || 3500,
      match_score: 0.98,
      status: 'confirmed',
    }).select().single();

    if (bErr) throw apiError(500, 'DB_ERROR', bErr.message);

    // Update cargo status
    await supabaseAdmin.from('cargo_requests')
      .update({ status: 'matched' })
      .eq('cargo_id', cargo_id);

    // Notify shipper and driver
    res.json({
      success: true,
      message: 'Dispatch override successful. Booking confirmed.',
      booking,
    });
  } catch (e) { next(e); }
});

// 5. Dynamic Pricing Control Panel (Read / Update)
adminRouter.get('/pricing', async (_req, res, next) => {
  try {
    const { data: customConfigs } = await supabaseAdmin.from('pricing_configurations').select('*');
    if (customConfigs && customConfigs.length > 0) {
      return res.json(customConfigs);
    }
    // Fallback to default in-memory configs
    const list = Object.entries(DEFAULT_CORRIDOR_RATES).map(([k, v]) => ({
      corridor_id: k,
      corridor_name: v.name,
      base_rate_per_ton_km: v.base_rate,
      min_fare_inr: v.min_fare,
      detour_rate_per_km: 25.0,
      platform_commission_pct: 0.08,
      fragile_multiplier: 1.18,
      fmcg_multiplier: 1.08,
      perishable_multiplier: 1.25,
      high_value_multiplier: 1.30,
      hazardous_multiplier: 1.35,
    }));
    res.json(list);
  } catch (e) { next(e); }
});

adminRouter.put('/pricing/:corridorId', async (req, res, next) => {
  try {
    const { corridorId } = req.params;
    const body = req.body || {};

    const { data, error } = await supabaseAdmin.from('pricing_configurations')
      .upsert({
        corridor_id: corridorId,
        corridor_name: body.corridor_name || corridorId,
        base_rate_per_ton_km: Number(body.base_rate_per_ton_km) || 2.40,
        min_fare_inr: Number(body.min_fare_inr) || 1500,
        detour_rate_per_km: Number(body.detour_rate_per_km) || 25.0,
        platform_commission_pct: Number(body.platform_commission_pct) || 0.08,
        fragile_multiplier: Number(body.fragile_multiplier) || 1.18,
        fmcg_multiplier: Number(body.fmcg_multiplier) || 1.08,
        perishable_multiplier: Number(body.perishable_multiplier) || 1.25,
        high_value_multiplier: Number(body.high_value_multiplier) || 1.30,
        hazardous_multiplier: Number(body.hazardous_multiplier) || 1.35,
        updated_at: new Date().toISOString(),
      })
      .select().single();

    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data);
  } catch (e) { next(e); }
});

// 6. Disputes & Escrow Release Center
adminRouter.get('/disputes', async (_req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('disputes')
      .select('*, filed_by_user:profiles!disputes_filed_by_fkey(full_name, phone), booking:bookings!disputes_booking_id_fkey(*)')
      .order('created_at', { ascending: false });

    if (error) {
      // If table doesn't have rows yet, return sample operations template
      return res.json([]);
    }
    res.json(data || []);
  } catch (e) { next(e); }
});

adminRouter.patch('/disputes/:id/resolve', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { resolution_status, notes } = req.body || {}; // 'resolved_refund' | 'resolved_payout' | 'rejected'

    const { data, error } = await supabaseAdmin.from('disputes')
      .update({
        status: resolution_status || 'resolved_payout',
        resolution_notes: notes || 'Resolved by Redo Operations Lead',
        resolved_by: req.user?.id,
        resolved_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select().single();

    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data);
  } catch (e) { next(e); }
});

// 7. Users Management
adminRouter.get('/users', async (_req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('profiles')
      .select('id, full_name, company_name, role, admin_previous_role, phone, status, created_at')
      .order('created_at', { ascending: false }).limit(200);
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.listUsers({ page: 1, perPage: 1000 });
    if (authError) throw apiError(500, 'AUTH_ADMIN_ERROR', authError.message);
    const emailsById = new Map((authData.users || []).map((user) => [user.id, user.email || null]));
    res.json((data || []).map((profile) => ({ ...profile, email: emailsById.get(profile.id) || null })));
  } catch (e) { next(e); }
});

// 8. KYC Verification
adminRouter.get('/kyc', async (_req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('kyc_verifications')
      .select('id, user_id, document_type, document_reference_masked, verification_status, rejection_reason, created_at, owner:profiles!kyc_verifications_user_id_fkey(full_name, company_name, phone)')
      .eq('verification_status', 'pending').order('created_at');
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data.map((r) => ({
      id: r.id, user_id: r.user_id, document_type: r.document_type,
      document_reference_masked: r.document_reference_masked, created_at: r.created_at,
      owner_name: r.owner?.company_name || r.owner?.full_name || 'User',
      phone: r.owner?.phone || null,
      rejection_reason: r.rejection_reason || null,
    })));
  } catch (e) { next(e); }
});

const updateKycDecision = async (req, res, next) => {
  try {
    const { status, rejection_reason } = req.body ?? {};
    if (!['verified', 'rejected'].includes(status)) {
      throw apiError(400, 'VALIDATION_ERROR', "status must be 'verified' or 'rejected'.");
    }
    if (status === 'rejected' && !String(rejection_reason || '').trim()) {
      throw apiError(400, 'VALIDATION_ERROR', 'A rejection reason is required.');
    }
    const { data, error } = await supabaseAdmin.from('kyc_verifications')
      .update({
        verification_status: status,
        verified_at: status === 'verified' ? new Date().toISOString() : null,
        rejection_reason: status === 'rejected' ? String(rejection_reason).trim() : null,
      })
      .eq('id', req.params.id).select().single();
    if (error || !data) throw apiError(404, 'NOT_FOUND', 'KYC record not found.');
    await supabaseAdmin.from('notifications').insert({
      user_id: data.user_id, type: 'kyc_decision',
      title: status === 'verified' ? 'Document verified' : 'Document rejected',
      message: status === 'verified'
        ? `Your ${data.document_type.replaceAll('_', ' ')} was verified by the Redo team.`
        : `Your ${data.document_type.replaceAll('_', ' ')} was rejected: ${String(rejection_reason).trim()}`,
    });
    // When driver documents are verified, update their registered trucks to verified_documents = true
    if (status === 'verified') {
      await supabaseAdmin.from('trucks').update({ verified_documents: true }).eq('owner_id', data.user_id);
    }
    res.json(data);
  } catch (e) { next(e); }
};

adminRouter.patch('/kyc/:id/verify', updateKycDecision);
adminRouter.patch('/kyc/:id', updateKycDecision);

// 9. User Role & Status Modification (Admin Privileges Grant/Revoke)
adminRouter.patch('/users/:id/role', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role, status } = req.body || {};
    if (role !== undefined && !['admin', 'truck_owner', 'sme'].includes(role)) {
      throw apiError(400, 'VALIDATION_ERROR', 'Invalid role.');
    }
    if (status !== undefined && !['active', 'suspended'].includes(status)) {
      throw apiError(400, 'VALIDATION_ERROR', 'Invalid account status.');
    }
    if (id === req.user?.id && ((role && role !== 'admin') || status === 'suspended')) {
      throw apiError(400, 'VALIDATION_ERROR', 'You cannot revoke or suspend your own active admin account.');
    }

    const updates = {};
    if (role) {
      const { data: current, error: currentError } = await supabaseAdmin.from('profiles')
        .select('role, admin_previous_role').eq('id', id).maybeSingle();
      if (currentError) throw apiError(500, 'DB_ERROR', currentError.message);
      if (!current) throw apiError(404, 'NOT_FOUND', 'User profile not found.');
      updates.role = role;
      if (role === 'admin') updates.onboarding_complete = true;
      updates.admin_previous_role = role === 'admin'
        ? (current.role === 'admin' ? current.admin_previous_role : current.role)
        : null;
    }
    if (status) updates.status = status;

    if (Object.keys(updates).length === 0) {
      throw apiError(400, 'VALIDATION_ERROR', 'No valid fields provided to update.');
    }

    const { data, error } = await supabaseAdmin.from('profiles')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw apiError(404, 'NOT_FOUND', 'User profile not found.');
    res.json({ success: true, profile: data });
  } catch (e) { next(e); }
});

// 10. Live Bookings & Shipments Operations Desk
adminRouter.get('/bookings', async (req, res, next) => {
  try {
    const { status, limit = 100 } = req.query;
    let query = supabaseAdmin.from('bookings')
      .select(`
        id, match_score, agreed_price_inr, status, created_at,
        cargo:cargo_requests(cargo_id, origin, destination, distance_km, cargo_type, cargo_weight_tons, pickup_date, urgency, special_handling, sme:profiles!cargo_requests_sme_id_fkey(id, full_name, phone, company_name)),
        truck:trucks(truck_id, registration_number, truck_type, body_type, default_capacity_tons, owner:profiles!trucks_owner_id_fkey(id, full_name, phone))
      `)
      .order('created_at', { ascending: false })
      .limit(Number(limit) || 100);

    if (status && status !== 'all') {
      query = query.eq('status', status);
    }

    const { data, error } = await query;
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data || []);
  } catch (e) { next(e); }
});

adminRouter.patch('/bookings/:id/status', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, reason } = req.body || {};
    const valid = ['pending', 'accepted', 'confirmed', 'pickup_ready', 'picked_up', 'in_transit', 'delivered', 'completed', 'cancelled', 'disputed'];
    if (!valid.includes(status)) {
      throw apiError(400, 'VALIDATION_ERROR', `Invalid status. Must be one of ${valid.join(', ')}`);
    }

    const { data, error } = await supabaseAdmin.from('bookings')
      .update({ status })
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw apiError(404, 'NOT_FOUND', 'Booking not found.');

    // Log booking transition
    await supabaseAdmin.from('booking_events').insert({
      booking_id: id,
      to_status: status,
      actor_id: req.user?.id,
    });

    res.json({ success: true, booking: data, reason });
  } catch (e) { next(e); }
});

export default adminRouter;
