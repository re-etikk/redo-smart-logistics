// admin.js — operations console endpoints. Guarded by profile.role === 'admin';
// all data access uses the service-role client server-side (RLS untouched for users).
import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';

export const adminRouter = Router();
adminRouter.use(requireAuth);
adminRouter.use((req, _res, next) => {
  if (req.profile?.role !== 'admin') return next(apiError(403, 'FORBIDDEN', 'Admin access required.'));
  next();
});

adminRouter.get('/stats', async (_req, res, next) => {
  try {
    const count = async (table, filter) => {
      let q = supabaseAdmin.from(table).select('*', { count: 'exact', head: true });
      if (filter) q = filter(q);
      const { count: c, error } = await q;
      if (error) throw apiError(500, 'DB_ERROR', error.message);
      return c ?? 0;
    };
    const [users, shippers, owners, trucks, bookings, completed, kyc_pending] = await Promise.all([
      count('profiles'),
      count('profiles', (q) => q.eq('role', 'sme')),
      count('profiles', (q) => q.eq('role', 'truck_owner')),
      count('trucks'),
      count('bookings'),
      count('bookings', (q) => q.eq('status', 'completed')),
      count('kyc_verifications', (q) => q.eq('verification_status', 'pending')),
    ]);
    res.json({ users, shippers, owners, trucks, bookings, completed, kyc_pending });
  } catch (e) { next(e); }
});

adminRouter.get('/users', async (_req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('profiles')
      .select('id, full_name, company_name, role, phone, status, created_at')
      .order('created_at', { ascending: false }).limit(200);
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data);
  } catch (e) { next(e); }
});

adminRouter.get('/kyc', async (_req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('kyc_verifications')
      .select('id, user_id, document_type, document_reference_masked, verification_status, created_at, owner:profiles!kyc_verifications_user_id_fkey(full_name, company_name)')
      .eq('verification_status', 'pending').order('created_at');
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data.map((r) => ({
      id: r.id, user_id: r.user_id, document_type: r.document_type,
      document_reference_masked: r.document_reference_masked, created_at: r.created_at,
      owner_name: r.owner?.company_name || r.owner?.full_name || 'User',
    })));
  } catch (e) { next(e); }
});

adminRouter.patch('/kyc/:id', async (req, res, next) => {
  try {
    const { status } = req.body ?? {};
    if (!['verified', 'rejected'].includes(status)) {
      throw apiError(400, 'VALIDATION_ERROR', "status must be 'verified' or 'rejected'.");
    }
    const { data, error } = await supabaseAdmin.from('kyc_verifications')
      .update({ verification_status: status, verified_at: status === 'verified' ? new Date().toISOString() : null })
      .eq('id', req.params.id).select().single();
    if (error || !data) throw apiError(404, 'NOT_FOUND', 'KYC record not found.');
    await supabaseAdmin.from('notifications').insert({
      user_id: data.user_id, type: 'kyc_decision',
      title: status === 'verified' ? 'Document verified' : 'Document rejected',
      body: `Your ${data.document_type.replaceAll('_', ' ')} was ${status} by the Redo team.`,
    });
    res.json(data);
  } catch (e) { next(e); }
});
