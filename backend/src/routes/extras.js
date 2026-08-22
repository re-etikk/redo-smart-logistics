// extras.js — REDO Transport & Logistics additions:
// addresses, support desk, rate cards, invoices, earnings, reviews.
import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';

export const extrasRouter = Router();
extrasRouter.use(requireAuth);

// ---------- Addresses ----------
extrasRouter.get('/addresses', async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('addresses')
      .select('*').eq('user_id', req.user.id).eq('deleted', false)
      .order('is_frequent', { ascending: false }).order('created_at', { ascending: false });
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data);
  } catch (e) { next(e); }
});

extrasRouter.post('/addresses', async (req, res, next) => {
  try {
    const { label, type = 'pickup', address, city, state, pincode, contact_name, contact_phone } = req.body ?? {};
    if (!label || !city) throw apiError(400, 'VALIDATION_ERROR', 'label and city are required.');
    const { data, error } = await supabaseAdmin.from('addresses')
      .insert({ user_id: req.user.id, label, type, address, city, state, pincode, contact_name, contact_phone })
      .select().single();
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.status(201).json(data);
  } catch (e) { next(e); }
});

extrasRouter.patch('/addresses/:id', async (req, res, next) => {
  try {
    const allowed = ['label', 'type', 'address', 'city', 'state', 'pincode', 'contact_name', 'contact_phone', 'is_frequent', 'deleted'];
    const patch = Object.fromEntries(Object.entries(req.body ?? {}).filter(([k]) => allowed.includes(k)));
    if (!Object.keys(patch).length) throw apiError(400, 'VALIDATION_ERROR', 'No editable fields provided.');
    const { data, error } = await supabaseAdmin.from('addresses')
      .update(patch).eq('id', req.params.id).eq('user_id', req.user.id).select().single();
    if (error || !data) throw apiError(404, 'NOT_FOUND', 'Address not found.');
    res.json(data);
  } catch (e) { next(e); }
});

// ---------- Support ----------
extrasRouter.get('/support/tickets', async (req, res, next) => {
  try {
    const { data: tickets, error } = await supabaseAdmin.from('support_tickets')
      .select('*').eq('user_id', req.user.id).order('created_at', { ascending: false });
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    const ids = tickets.map((t) => t.id);
    let msgs = [];
    if (ids.length) {
      const { data } = await supabaseAdmin.from('support_messages')
        .select('*, author:profiles!support_messages_author_id_fkey(full_name, role)')
        .in('ticket_id', ids).order('created_at');
      msgs = data ?? [];
    }
    res.json(tickets.map((t) => ({
      ...t,
      messages: msgs.filter((m) => m.ticket_id === t.id).map((m) => ({
        body: m.body, created_at: m.created_at,
        author_name: m.author_id === req.user.id ? 'You'
          : m.author?.role === 'admin' ? 'Redo Support' : (m.author?.full_name ?? 'User'),
      })),
    })));
  } catch (e) { next(e); }
});

extrasRouter.post('/support/tickets', async (req, res, next) => {
  try {
    const { subject, description = '', category = 'General' } = req.body ?? {};
    if (!subject) throw apiError(400, 'VALIDATION_ERROR', 'subject is required.');
    const { data, error } = await supabaseAdmin.from('support_tickets')
      .insert({ user_id: req.user.id, subject, description, category }).select().single();
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.status(201).json(data);
  } catch (e) { next(e); }
});

extrasRouter.post('/support/tickets/:id/messages', async (req, res, next) => {
  try {
    const { body } = req.body ?? {};
    if (!body?.trim()) throw apiError(400, 'VALIDATION_ERROR', 'body is required.');
    const { data: ticket } = await supabaseAdmin.from('support_tickets')
      .select('id, user_id, status').eq('id', req.params.id).single();
    if (!ticket || ticket.user_id !== req.user.id) throw apiError(404, 'NOT_FOUND', 'Ticket not found.');
    if (['resolved', 'closed'].includes(ticket.status)) throw apiError(409, 'TICKET_CLOSED', 'Ticket is closed.');
    const { data, error } = await supabaseAdmin.from('support_messages')
      .insert({ ticket_id: ticket.id, author_id: req.user.id, body: body.trim() }).select().single();
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    await supabaseAdmin.from('support_tickets')
      .update({ status: 'in_progress', updated_at: new Date().toISOString() }).eq('id', ticket.id);
    res.status(201).json(data);
  } catch (e) { next(e); }
});

// ---------- Rate cards ----------
extrasRouter.get('/rates', async (_req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('rate_cards').select('*').order('origin');
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data);
  } catch (e) { next(e); }
});

// ---------- Invoices (shipper) ----------
extrasRouter.get('/invoices', async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('invoices')
      .select('*, booking:bookings(cargo_id, cargo:cargo_requests(origin, destination))')
      .eq('sme_id', req.user.id).order('created_at', { ascending: false });
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data.map((i) => ({
      id: i.id, invoice_no: i.invoice_no, booking_id: i.booking_id,
      route: i.booking?.cargo ? `${i.booking.cargo.origin} → ${i.booking.cargo.destination}` : i.booking?.cargo_id,
      base_inr: Number(i.base_inr), gst_inr: Number(i.gst_inr), total_inr: Number(i.total_inr),
      status: i.status, created_at: i.created_at,
    })));
  } catch (e) { next(e); }
});

// ---------- Earnings (truck owner) ----------
extrasRouter.get('/earnings', async (req, res, next) => {
  try {
    if (req.profile.role !== 'truck_owner') throw apiError(403, 'FORBIDDEN', 'Earnings are for truck owners.');
    const { data, error } = await supabaseAdmin.from('bookings')
      .select('id, cargo_id, status, agreed_price_inr, updated_at, created_at, cargo:cargo_requests(origin, destination)')
      .eq('truck_owner_id', req.user.id).order('created_at', { ascending: false });
    if (error) throw apiError(500, 'DB_ERROR', error.message);

    const ACTIVE = ['confirmed', 'pickup_ready', 'picked_up', 'in_transit', 'delivered'];
    const done = data.filter((b) => b.status === 'completed');
    const active = data.filter((b) => ACTIVE.includes(b.status));
    const sum = (rows) => rows.reduce((a, b) => a + Number(b.agreed_price_inr || 0), 0);

    res.json({
      totals: {
        completed_inr: sum(done),
        completed_trips: done.length,
        avg_per_trip_inr: done.length ? Math.round(sum(done) / done.length) : 0,
        pending_inr: sum(active),
        pending_trips: active.length,
      },
      transactions: [...done, ...active].map((b) => ({
        booking_id: b.id, cargo_id: b.cargo_id,
        route: b.cargo ? `${b.cargo.origin} → ${b.cargo.destination}` : '—',
        amount_inr: Number(b.agreed_price_inr || 0),
        settled: b.status === 'completed',
        date: b.updated_at ?? b.created_at,
      })),
    });
  } catch (e) { next(e); }
});

// ---------- Reviews received ----------
extrasRouter.get('/reviews', async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin.from('ratings')
      .select('id, score, comment, created_at, rater:profiles!ratings_rater_id_fkey(full_name, company_name)')
      .eq('ratee_id', req.user.id).order('created_at', { ascending: false });
    if (error) throw apiError(500, 'DB_ERROR', error.message);
    res.json(data.map((r) => ({
      id: r.id, score: r.score, comment: r.comment, created_at: r.created_at,
      rater_name: r.rater?.company_name || r.rater?.full_name || 'Shipper',
    })));
  } catch (e) { next(e); }
});

export default extrasRouter;
