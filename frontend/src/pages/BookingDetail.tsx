import { useCallback, useEffect, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import Layout from '../components/Layout';
import { api } from '../services/api';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import {
  Badge, Button, Card, CardSkeleton, Field, inputCls, statusLabel, statusTone, useToast,
} from '../components/ui';
import { BOOKING_FLOW, type Booking } from '../lib/types';

// Which "advance" action each role sees at each status (mirrors the backend
// state machine — the backend remains the enforcement point).
const NEXT: Record<string, { to: string; label: string; role: 'truck_owner' | 'sme'; needsProof?: 'pickup' | 'delivery' }> = {
  pending: { to: 'accepted', label: 'Accept request', role: 'truck_owner' },
  accepted: { to: 'confirmed', label: 'Confirm booking', role: 'sme' },
  confirmed: { to: 'pickup_ready', label: 'Mark ready for pickup', role: 'truck_owner' },
  pickup_ready: { to: 'picked_up', label: 'Mark picked up', role: 'truck_owner', needsProof: 'pickup' },
  picked_up: { to: 'in_transit', label: 'Start transit', role: 'truck_owner' },
  in_transit: { to: 'delivered', label: 'Mark delivered', role: 'truck_owner', needsProof: 'delivery' },
  delivered: { to: 'completed', label: 'Confirm delivery received', role: 'sme' },
};

function ProofUploader({ booking, type, onDone }: { booking: Booking; type: 'pickup' | 'delivery'; onDone: () => void }) {
  const [busy, setBusy] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const toast = useToast();
  const upload = async (file: File) => {
    setBusy(true);
    try {
      const { data: session } = await supabase.auth.getSession();
      const uid = session.session!.user.id;
      const bucket = type === 'pickup' ? 'pickup-proofs' : 'delivery-proofs';
      const path = `${uid}/${booking.id}-${type}-${Date.now()}.${file.name.split('.').pop()}`;
      const { error } = await supabase.storage.from(bucket).upload(path, file);
      if (error) throw new Error(error.message);
      await api.post('/proof', { booking_id: booking.id, proof_type: type, photo_url: `${bucket}/${path}` });
      toast(`${type === 'pickup' ? 'Pickup' : 'Delivery'} proof uploaded`);
      onDone();
    } catch (e: any) { toast(e.message, 'danger'); } finally { setBusy(false); }
  };
  return (
    <>
      <input ref={inputRef} type="file" accept="image/*" className="hidden"
        onChange={(e) => e.target.files?.[0] && upload(e.target.files[0])} />
      <Button variant="secondary" disabled={busy} onClick={() => inputRef.current?.click()}>
        {busy ? 'Uploading…' : `Upload ${type} proof`}
      </Button>
    </>
  );
}

export default function BookingDetail() {
  const { id = '' } = useParams();
  const { profile } = useAuth();
  const toast = useToast();
  const [b, setB] = useState<Booking | null>(null);
  const [busy, setBusy] = useState(false);
  const [ratingScore, setRatingScore] = useState(5);
  const [ratingComment, setRatingComment] = useState('');
  const [rated, setRated] = useState(false);

  const load = useCallback(() => { api.get<Booking>(`/bookings/${id}`).then(setB).catch(() => {}); }, [id]);
  useEffect(() => { load(); }, [load]);

  if (!b || !profile) return <Layout><CardSkeleton /></Layout>;

  const proofs = (b.proofs ?? []).map((p) => p.proof_type);
  const action = NEXT[b.status];
  const canAct = action && action.role === profile.role;
  const proofMissing = action?.needsProof && !proofs.includes(action.needsProof);
  const flowIdx = BOOKING_FLOW.indexOf(b.status);

  const transition = async (to: string) => {
    setBusy(true);
    try { await api.patch(`/bookings/${b.id}/status`, { to }); load(); toast(`Booking ${statusLabel(to).toLowerCase()}`); }
    catch (e: any) { toast(e.message, 'danger'); } finally { setBusy(false); }
  };

  const submitRating = async () => {
    try {
      await api.post('/ratings', { booking_id: b.id, score: ratingScore, comment: ratingComment });
      setRated(true); toast('Thanks for your rating');
    } catch (e: any) { toast(e.message, 'danger'); }
  };

  return (
    <Layout>
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-ink">{b.cargo.origin} → {b.cargo.destination}</h1>
          <p className="text-sm text-ink-soft mt-1">
            {b.cargo.cargo_type} · {b.cargo.cargo_weight_tons} T · {b.truck.truck_type} {b.truck.registration_number}
            {b.agreed_price_inr ? ` · ₹${Number(b.agreed_price_inr).toLocaleString('en-IN')}` : ''}
          </p>
        </div>
        <Badge tone={statusTone(b.status)}>{statusLabel(b.status)}</Badge>
      </div>

      {/* Status timeline — readable in 2 seconds (§82) */}
      <Card className="mt-6 p-5 overflow-x-auto">
        <ol className="flex items-center gap-0 min-w-[560px]" aria-label="Booking progress">
          {BOOKING_FLOW.map((s, i) => (
            <li key={s} className="flex items-center flex-1 last:flex-none">
              <div className="flex flex-col items-center gap-1">
                <span className={`h-6 w-6 rounded-full grid place-items-center text-[11px] font-bold
                  ${i < flowIdx ? 'bg-ok text-white' : i === flowIdx ? 'bg-accent text-white' : 'bg-ink/10 text-ink-faint'}`}>
                  {i < flowIdx ? '✓' : i === flowIdx ? '●' : '○'}
                </span>
                <span className={`text-[10px] font-semibold whitespace-nowrap ${i <= flowIdx ? 'text-ink' : 'text-ink-faint'}`}>
                  {statusLabel(s)}
                </span>
              </div>
              {i < BOOKING_FLOW.length - 1 && <div className={`h-0.5 flex-1 mx-1 ${i < flowIdx ? 'bg-ok' : 'bg-ink/10'}`} />}
            </li>
          ))}
        </ol>
      </Card>

      <div className="mt-6 grid gap-4 md:grid-cols-2">
        <Card className="p-5 space-y-3">
          <h2 className="font-bold text-ink">Actions</h2>
          {b.status === 'pending' && profile.role === 'truck_owner' && (
            <div className="flex gap-3">
              <Button onClick={() => transition('accepted')} disabled={busy}>Accept</Button>
              <Button variant="danger" onClick={() => transition('cancelled')} disabled={busy}>Reject</Button>
            </div>
          )}
          {canAct && b.status !== 'pending' && (
            <>
              {proofMissing && action.needsProof && (
                <p className="text-sm text-warn font-medium">Upload {action.needsProof} proof to continue.</p>
              )}
              <div className="flex flex-wrap gap-3">
                {action.needsProof && !proofs.includes(action.needsProof) && (
                  <ProofUploader booking={b} type={action.needsProof} onDone={load} />
                )}
                <Button onClick={() => transition(action.to)} disabled={busy || !!proofMissing}>{action.label}</Button>
              </div>
            </>
          )}
          {!canAct && action && (
            <p className="text-sm text-ink-faint">
              Waiting for the {action.role === 'sme' ? 'shipper' : 'truck owner'} to {action.label.toLowerCase()}.
            </p>
          )}
          {['picked_up', 'in_transit', 'delivered'].includes(b.status) && (
            <Link to={`/tracking/${b.id}`} className="inline-block text-sm font-semibold text-accent">Open tracking →</Link>
          )}
          {['delivered', 'completed'].includes(b.status) && profile.role === 'sme' && b.status !== 'disputed' && (
            <Button variant="ghost" onClick={() => transition('disputed')} disabled={busy}>Raise dispute</Button>
          )}
        </Card>

        <Card className="p-5">
          <h2 className="font-bold text-ink">Digital proof</h2>
          {(b.proofs ?? []).length === 0 && <p className="mt-2 text-sm text-ink-faint">No proof uploaded yet.</p>}
          <ul className="mt-2 space-y-2">
            {b.proofs?.map((p) => (
              <li key={p.proof_type} className="text-sm text-ink-soft">
                <span className="font-semibold text-ink">{statusLabel(p.proof_type)} proof</span> ·{' '}
                {new Date(p.timestamp).toLocaleString('en-IN')} · stored securely
              </li>
            ))}
          </ul>
        </Card>
      </div>

      {b.status === 'completed' && !rated && (
        <Card className="mt-4 p-5 max-w-lg">
          <h2 className="font-bold text-ink">Rate this {profile.role === 'sme' ? 'truck owner' : 'shipper'}</h2>
          <div className="mt-3 flex gap-1" role="radiogroup" aria-label="Score">
            {[1, 2, 3, 4, 5].map((n) => (
              <button key={n} aria-label={`${n} star${n > 1 ? 's' : ''}`} onClick={() => setRatingScore(n)}
                className={`text-2xl ${n <= ratingScore ? 'text-warn' : 'text-ink/20'}`}>★</button>
            ))}
          </div>
          <Field label="Comment (optional)">
            <textarea className={inputCls} rows={2} value={ratingComment} onChange={(e) => setRatingComment(e.target.value)} />
          </Field>
          <Button className="mt-3" onClick={submitRating}>Submit rating</Button>
        </Card>
      )}
    </Layout>
  );
}
