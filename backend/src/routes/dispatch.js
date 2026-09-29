import { Router } from 'express';
import { supabaseAdmin, supabaseForUser } from '../lib/supabase.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';

const router = Router();
router.use(requireAuth, requireRole('truck_owner'));

router.get('/offers', async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('dispatch_offers')
      .select(`
        id, cargo_id, truck_id, distance_km, status, expires_at, created_at,
        cargo:cargo_requests(
          cargo_id, origin, destination, distance_km, cargo_type,
          cargo_weight_tons, pickup_at, urgency, special_handling,
          offered_price_inr, sme:profiles!cargo_requests_sme_id_fkey(full_name, company_name, phone)
        )
      `)
      .eq('driver_id', req.profile.id)
      .eq('status', 'pending')
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false });

    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data || []);
  } catch (error) { next(error); }
});

router.post('/offers/:id/accept', async (req, res, next) => {
  try {
    const { data, error } = await supabaseForUser(req.token).rpc('accept_dispatch_offer', {
      target_offer_id: req.params.id,
    });
    if (error) {
      const conflict = /already accepted|no longer available|not found/i.test(error.message);
      throw apiError(conflict ? 409 : 400, conflict ? 'OFFER_UNAVAILABLE' : 'DISPATCH_ERROR', error.message);
    }
    res.status(201).json(data);
  } catch (error) { next(error); }
});

router.post('/offers/:id/skip', async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('dispatch_offers')
      .update({ status: 'skipped' })
      .eq('id', req.params.id)
      .eq('driver_id', req.profile.id)
      .eq('status', 'pending')
      .select('id, status')
      .maybeSingle();

    if (error) throw apiError(500, 'DB_ERROR', error.message);
    if (!data) throw apiError(409, 'OFFER_UNAVAILABLE', 'Dispatch offer is no longer available.');
    res.json(data);
  } catch (error) { next(error); }
});

export default router;