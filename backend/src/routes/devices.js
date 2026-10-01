import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';

const router = Router();
router.use(requireAuth, requireRole('truck_owner'));

router.put('/fcm-token', async (req, res, next) => {
  try {
    const { token, platform = 'android' } = req.body || {};
    if (typeof token !== 'string' || token.trim().length < 20) {
      throw apiError(400, 'VALIDATION', 'A valid FCM registration token is required.');
    }
    if (!['android', 'ios', 'web'].includes(platform)) {
      throw apiError(400, 'VALIDATION', 'platform must be android, ios, or web.');
    }

    const normalizedToken = token.trim();
    const { error: staleError } = await supabaseAdmin.from('user_devices')
      .delete()
      .eq('user_id', req.profile.id)
      .neq('fcm_token', normalizedToken);
    if (staleError) throw apiError(500, 'DB_ERROR', staleError.message);

    const { data: tokenOwner, error: ownerError } = await supabaseAdmin.from('user_devices')
      .select('user_id').eq('fcm_token', normalizedToken).maybeSingle();
    if (ownerError) throw apiError(500, 'DB_ERROR', ownerError.message);
    if (tokenOwner && tokenOwner.user_id !== req.profile.id) {
      const { error: reassignmentError } = await supabaseAdmin.from('user_devices')
        .delete().eq('fcm_token', normalizedToken);
      if (reassignmentError) throw apiError(500, 'DB_ERROR', reassignmentError.message);
    }

    const { data, error } = await supabaseAdmin.from('user_devices').upsert({
      user_id: req.profile.id,
      fcm_token: normalizedToken,
      platform,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'fcm_token' }).select('id, platform, updated_at').single();

    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json({ registered: true, device: data });
  } catch (error) { next(error); }
});

router.delete('/fcm-token', async (req, res, next) => {
  try {
    const { token } = req.body || {};
    if (typeof token !== 'string' || token.trim().length < 20) {
      throw apiError(400, 'VALIDATION', 'A valid FCM registration token is required.');
    }
    const { error } = await supabaseAdmin.from('user_devices')
      .delete().eq('user_id', req.profile.id).eq('fcm_token', token.trim());
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json({ registered: false });
  } catch (error) { next(error); }
});

export default router;