import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, CheckCircle2, Clock, ShieldCheck, Truck } from 'lucide-react';
import Layout from "../components/Layout";
import { api } from "../lib/api";
import { Button, Card, Field, SectionHead, inputCls, useToast } from "../components/ui";

const CITY = ['Mumbai', 'Delhi', 'Pune', 'Jaipur', 'Surat'];
const TYPES = ['Textiles', 'FMCG', 'Electronics', 'Auto parts', 'Pharma', 'Furniture'];
const STEPS = ['Basic Details', 'Pickup & Delivery', 'Cargo Details', 'Review & Confirm'];

export default function BookShipment() {
  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const toast = useToast();
  const [form, setForm] = useState({
    shipment_type: 'LTL', origin: 'Mumbai', destination: 'Delhi', pickup_at: '',
    cargo_type: 'Textiles', description: '', cargo_weight_tons: '1.5',
    urgency: 'normal', special_handling: [] as string[],
  });
  const set = (k: string, v: any) => setForm((f) => ({ ...f, [k]: v }));

  const summary: [string, string][] = useMemo(() => [
    ['Shipment Type', form.shipment_type === 'FTL' ? 'Full Truck Load' : 'Part Load (LTL)'],
    ['Pickup Location', form.origin],
    ['Delivery Location', form.destination],
    ['Cargo Type', form.cargo_type],
    ['Total Weight', `${form.cargo_weight_tons} T`],
    ['Pickup', form.pickup_at ? new Date(form.pickup_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : '—'],
  ], [form]);

  const toggleHandling = (h: string) => set('special_handling',
    form.special_handling.includes(h) ? form.special_handling.filter((x) => x !== h) : [...form.special_handling, h]);

  const submit = async () => {
    setBusy(true); setError('');
    try {
      const cargo = await api.post<{ cargo_id: string }>('/cargo', {
        origin: form.origin, destination: form.destination, cargo_type: form.cargo_type,
        cargo_weight_tons: +form.cargo_weight_tons, pickup_at: form.pickup_at, urgency: form.urgency,
        special_handling: [form.shipment_type, form.description, ...form.special_handling].filter(Boolean).join(' · ') || null,
      });
      toast('Shipment posted — finding matching trucks');
      navigate(`/find-trucks/${cargo.cargo_id}`);
    } catch (e: any) { setError(e.message); setBusy(false); }
  };

  const canNext = step === 1 ? (form.origin !== form.destination && !!form.pickup_at)
    : step === 2 ? +form.cargo_weight_tons > 0 : true;

  return (
    <Layout>
      <SectionHead title="Book Shipment" sub="Fill in the details below to book your shipment." />

      {/* Stepper */}
      <ol className="mt-6 flex items-center gap-0 overflow-x-auto" aria-label="Booking steps">
        {STEPS.map((s, i) => (
          <li key={s} className="flex items-center flex-1 last:flex-none min-w-fit">
            <div className="flex flex-col items-center gap-1 px-2">
              <span className={`h-8 w-8 rounded-full grid place-items-center text-sm font-bold
                ${i < step ? 'bg-ok text-white' : i === step ? 'bg-accent text-accent-fg' : 'bg-white border border-line text-ink-faint'}`}>
                {i < step ? '✓' : i + 1}
              </span>
              <span className={`text-[11px] font-semibold whitespace-nowrap ${i <= step ? 'text-ink' : 'text-ink-faint'}`}>{s}</span>
            </div>
            {i < STEPS.length - 1 && <div className={`h-0.5 flex-1 ${i < step ? 'bg-ok' : 'bg-line'}`} />}
          </li>
        ))}
      </ol>

      <div className="mt-6 grid gap-5 xl:grid-cols-[1fr_320px]">
        <div className="space-y-5">
          {step === 0 && (
            <Card className="p-5">
              <h2 className="font-bold text-ink">Shipment Type</h2>
              <div className="mt-3 grid sm:grid-cols-2 gap-3">
                {[
                  { k: 'FTL', t: 'Full Truck Load (FTL)', d: 'Dedicated truck for your shipment', icon: Truck },
                  { k: 'LTL', t: 'Part Load / LTL', d: 'Share backhaul space and pay for what you use', icon: Box },
                ].map(({ k, t, d, icon: Icon }) => (
                  <button key={k} onClick={() => set('shipment_type', k)} aria-pressed={form.shipment_type === k}
                    className={`rounded-xl border-2 p-4 text-left transition
                      ${form.shipment_type === k ? 'border-accent bg-accent-soft' : 'border-line hover:border-ink/30'}`}>
                    <Icon size={20} className="text-accent" />
                    <span className="mt-2 block font-bold text-ink text-sm">{t}</span>
                    <span className="block text-xs text-ink-soft mt-0.5">{d}</span>
                  </button>
                ))}
              </div>
            </Card>
          )}

          {step === 1 && (
            <Card className="p-5 space-y-4">
              <h2 className="font-bold text-ink">Route Details</h2>
              <div className="grid sm:grid-cols-2 gap-4">
                <Field label="Pickup Location *">
                  <select className={inputCls} value={form.origin} onChange={(e) => set('origin', e.target.value)}>
                    {CITY.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>
                <Field label="Delivery Location *" error={form.origin === form.destination ? 'Pickup and delivery must differ.' : ''}>
                  <select className={inputCls} value={form.destination} onChange={(e) => set('destination', e.target.value)}>
                    {CITY.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>
              </div>
              <div className="grid sm:grid-cols-2 gap-4">
                <Field label="Pickup Date & Time *">
                  <input type="datetime-local" className={inputCls} value={form.pickup_at} onChange={(e) => set('pickup_at', e.target.value)} />
                </Field>
                <Field label="Urgency">
                  <select className={inputCls} value={form.urgency} onChange={(e) => set('urgency', e.target.value)}>
                    {['normal', 'urgent', 'flexible'].map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>
              </div>
            </Card>
          )}

          {step === 2 && (
            <Card className="p-5 space-y-4">
              <h2 className="font-bold text-ink">Cargo Information</h2>
              <div className="grid sm:grid-cols-2 gap-4">
                <Field label="Cargo Type *">
                  <select className={inputCls} value={form.cargo_type} onChange={(e) => set('cargo_type', e.target.value)}>
                    {TYPES.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>
                <Field label="Total Weight (tonnes) *">
                  <input type="number" min="0.1" step="0.1" className={inputCls} value={form.cargo_weight_tons}
                    onChange={(e) => set('cargo_weight_tons', e.target.value)} />
                </Field>
              </div>
              <Field label="Goods Description">
                <input className={inputCls} value={form.description} onChange={(e) => set('description', e.target.value)}
                  placeholder="e.g. 40 cartons of finished garments" />
              </Field>
              <div>
                <p className="text-sm font-semibold text-ink">Additional Requirements <span className="text-ink-faint font-normal">(Optional)</span></p>
                <div className="mt-2 grid sm:grid-cols-2 gap-2">
                  {['Door Pickup', 'Door Delivery', 'Insurance', 'Fragile / Special Handling'].map((h) => (
                    <label key={h} className="flex items-center gap-2 rounded-lg border border-line px-3 py-2.5 text-sm font-medium cursor-pointer">
                      <input type="checkbox" checked={form.special_handling.includes(h)} onChange={() => toggleHandling(h)}
                        className="accent-[rgb(var(--accent))]" />
                      {h}
                    </label>
                  ))}
                </div>
              </div>
            </Card>
          )}

          {step === 3 && (
            <Card className="p-5">
              <h2 className="font-bold text-ink">Review & Confirm</h2>
              <dl className="mt-3 divide-y divide-line">
                {summary.map(([k, v]) => (
                  <div key={k} className="flex justify-between py-2.5 text-sm">
                    <dt className="text-ink-faint font-medium">{k}</dt><dd className="font-bold text-ink">{v}</dd>
                  </div>
                ))}
              </dl>
              {form.special_handling.length > 0 && (
                <p className="mt-2 text-xs text-ink-soft">Requirements: {form.special_handling.join(', ')}</p>
              )}
              {error && <p className="mt-3 text-sm font-medium text-danger">{error}</p>}
              <p className="mt-3 text-xs text-ink-faint">
                On confirm we post this shipment and run the two-stage matcher (hard filters + ML ranking) on live return-trip capacity.
              </p>
            </Card>
          )}

          <div className="flex justify-between">
            <Button variant="secondary" onClick={() => (step === 0 ? navigate(-1) : setStep(step - 1))}>
              {step === 0 ? 'Cancel' : 'Back'}
            </Button>
            {step < 3
              ? <Button onClick={() => setStep(step + 1)} disabled={!canNext}>Save & Continue →</Button>
              : <Button onClick={submit} disabled={busy}>{busy ? 'Finding trucks…' : 'Confirm & Find Trucks'}</Button>}
          </div>
        </div>

        {/* Summary sidebar */}
        <div className="space-y-4">
          <Card className="p-5">
            <h2 className="font-bold text-ink">Shipment Summary</h2>
            <dl className="mt-3 space-y-2 text-sm">
              {summary.map(([k, v]) => (
                <div key={k} className="flex justify-between gap-3">
                  <dt className="text-ink-faint">{k}</dt><dd className="font-semibold text-ink text-right">{v}</dd>
                </div>
              ))}
            </dl>
          </Card>
          <Card className="p-5 bg-accent-soft border-0">
            <p className="font-bold text-ink text-sm">Why book with Redo?</p>
            <ul className="mt-3 space-y-2.5 text-xs text-ink-soft">
              <li className="flex gap-2"><ShieldCheck size={15} className="text-ok shrink-0" /> Verified transporters with document checks</li>
              <li className="flex gap-2"><Clock size={15} className="text-info shrink-0" /> ML-ranked matches on live return capacity</li>
              <li className="flex gap-2"><CheckCircle2 size={15} className="text-warn shrink-0" /> Transparent pricing — pay for what you use</li>
            </ul>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
