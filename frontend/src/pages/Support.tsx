import { useEffect, useState } from 'react';
import { CheckCircle2, MessageCircle, Ticket } from 'lucide-react';
import Layout from '../components/Layout';
import { api } from '../services/api';
import { Badge, Button, Card, CardSkeleton, EmptyState, Field, SectionHead, StatCard, Tabs, inputCls, useToast } from '../components/ui';

interface Tkt { id: string; subject: string; description: string; category: string;
  status: string; created_at: string; messages?: { body: string; author_name: string; created_at: string }[]; }

const toneOf = (s: string) => (s === 'resolved' || s === 'closed' ? 'ok' : s === 'in_progress' ? 'warn' : 'danger');

export default function Support() {
  const [tickets, setTickets] = useState<Tkt[] | null>(null);
  const [tab, setTab] = useState('open');
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ subject: '', category: 'Trips & Bookings', description: '' });
  const [openId, setOpenId] = useState<string | null>(null);
  const [reply, setReply] = useState('');
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const load = () => api.get<Tkt[]>('/support/tickets').then(setTickets).catch(() => setTickets([]));
  useEffect(() => { load(); }, []);

  const submit = async () => {
    setBusy(true);
    try {
      await api.post('/support/tickets', form);
      setShowForm(false); setForm({ subject: '', category: 'Trips & Bookings', description: '' });
      toast('Ticket raised'); load();
    } catch (e: any) { toast(e.message, 'danger'); } finally { setBusy(false); }
  };
  const sendReply = async (id: string) => {
    if (!reply.trim()) return;
    try { await api.post(`/support/tickets/${id}/messages`, { body: reply }); setReply(''); load(); }
    catch (e: any) { toast(e.message, 'danger'); }
  };

  const list = (tickets ?? []).filter((t) =>
    tab === 'open' ? !['resolved', 'closed'].includes(t.status) : ['resolved', 'closed'].includes(t.status));

  return (
    <Layout>
      <SectionHead title="Support" sub="We are here to help! Raise a request or check the status of your queries."
        action={<Button onClick={() => setShowForm((s) => !s)}>+ New Support Ticket</Button>} />
      <div className="mt-5 grid gap-4 grid-cols-3">
        <StatCard icon={Ticket} label="Total Tickets" value={(tickets ?? []).length} tone="ok" />
        <StatCard icon={MessageCircle} label="Open Tickets" value={(tickets ?? []).filter((t) => !['resolved', 'closed'].includes(t.status)).length} tone="info" />
        <StatCard icon={CheckCircle2} label="Resolved" value={(tickets ?? []).filter((t) => ['resolved', 'closed'].includes(t.status)).length} tone="purple" />
      </div>

      {showForm && (
        <Card className="mt-5 p-5 space-y-4 max-w-xl">
          <Field label="Subject"><input className={inputCls} value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} /></Field>
          <Field label="Category">
            <select className={inputCls} value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })}>
              {['Payments & Wallet', 'Trips & Bookings', 'Account & Profile', 'Documents', 'Technical Issues'].map((c) => <option key={c}>{c}</option>)}
            </select>
          </Field>
          <Field label="Description"><textarea rows={3} className={inputCls} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field>
          <div className="flex gap-3">
            <Button onClick={submit} disabled={busy || !form.subject}>{busy ? 'Submitting…' : 'Submit Ticket'}</Button>
            <Button variant="secondary" onClick={() => setShowForm(false)}>Cancel</Button>
          </div>
        </Card>
      )}

      <Card className="mt-5 p-5">
        <Tabs active={tab} onChange={setTab} tabs={[{ key: 'open', label: 'My Tickets' }, { key: 'closed', label: 'Closed Tickets' }]} />
        {tickets === null ? <div className="mt-4"><CardSkeleton /></div> : list.length === 0 ? (
          <div className="mt-4"><EmptyState title="No tickets here." hint="Raise a ticket and our team will respond." /></div>
        ) : (
          <div className="mt-2 divide-y divide-line">
            {list.map((t) => (
              <div key={t.id} className="py-4">
                <button className="w-full text-left flex flex-wrap items-center gap-3" onClick={() => setOpenId(openId === t.id ? null : t.id)}>
                  <div className="flex-1 min-w-[200px]">
                    <p className="font-bold text-ink text-sm">{t.subject}</p>
                    <p className="text-xs text-ink-soft line-clamp-1">{t.description}</p>
                  </div>
                  <span className="text-xs text-ink-faint">{new Date(t.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</span>
                  <Badge tone={toneOf(t.status) as any}>{t.status.replace('_', ' ')}</Badge>
                </button>
                {openId === t.id && (
                  <div className="mt-3 rounded-xl bg-canvas p-4 space-y-3">
                    {(t.messages ?? []).map((m, i) => (
                      <p key={i} className="text-sm"><span className="font-bold text-ink">{m.author_name}: </span>
                        <span className="text-ink-soft">{m.body}</span></p>
                    ))}
                    {!['resolved', 'closed'].includes(t.status) && (
                      <div className="flex gap-2">
                        <input className={inputCls} value={reply} placeholder="Write a reply…" onChange={(e) => setReply(e.target.value)} />
                        <Button onClick={() => sendReply(t.id)}>Send</Button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </Card>
    </Layout>
  );
}
