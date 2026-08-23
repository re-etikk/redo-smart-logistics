import { useEffect, useState } from "react";
import { Building2, Home, MapPin, Star, Trash2 } from "lucide-react";
import Layout from "../components/Layout";
import { api } from "../lib/api";
import { Badge, Button, Card, CardSkeleton, EmptyState, Field, SectionHead, StatCard, inputCls, useToast } from "../components/ui";

interface Addr { id: string; label: string; type: string; address: string; city: string;
  state: string; pincode: string; contact_name: string; contact_phone: string; is_frequent: boolean; }

const BLANK = { label: "", type: "pickup", address: "", city: "", state: "", pincode: "", contact_name: "", contact_phone: "" };

export default function Addresses() {
  const [items, setItems] = useState<Addr[] | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<any>(BLANK);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const load = () => api.get<Addr[]>("/addresses").then(setItems).catch(() => setItems([]));
  useEffect(() => { load(); }, []);

  const save = async () => {
    setBusy(true);
    try { await api.post("/addresses", form); setShowForm(false); setForm(BLANK); toast("Address saved"); load(); }
    catch (e: any) { toast(e.message, "danger"); } finally { setBusy(false); }
  };
  const remove = async (id: string) => {
    if (!confirm("Delete this address?")) return;
    try { await api.patch(`/addresses/${id}`, { deleted: true }); toast("Address deleted"); load(); }
    catch (e: any) { toast(e.message, "danger"); }
  };
  const toggleFrequent = async (a: Addr) => {
    try { await api.patch(`/addresses/${a.id}`, { is_frequent: !a.is_frequent }); load(); }
    catch (e: any) { toast(e.message, "danger"); }
  };

  const list = items ?? [];
  return (
    <Layout>
      <SectionHead title="Addresses" sub="Manage all your pickup and delivery addresses for faster booking."
        action={<Button onClick={() => setShowForm((s) => !s)}>+ Add New Address</Button>} />
      <div className="mt-5 grid gap-4 grid-cols-2 xl:grid-cols-4">
        <StatCard icon={MapPin} label="Total Addresses" value={list.length} tone="info" />
        <StatCard icon={Home} label="Pickup Addresses" value={list.filter((a) => a.type === "pickup").length} tone="ok" />
        <StatCard icon={Building2} label="Delivery Addresses" value={list.filter((a) => a.type === "delivery").length} tone="warn" />
        <StatCard icon={Star} label="Frequently Used" value={list.filter((a) => a.is_frequent).length} tone="purple" />
      </div>

      {showForm && (
        <Card className="mt-5 p-5 grid sm:grid-cols-2 gap-4">
          <Field label="Label"><input className={inputCls} value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })} placeholder="Acme Warehouse, Bhiwandi" /></Field>
          <Field label="Type">
            <select className={inputCls} value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
              {["pickup", "delivery", "warehouse", "office"].map((t) => <option key={t}>{t}</option>)}
            </select>
          </Field>
          <div className="sm:col-span-2"><Field label="Address"><input className={inputCls} value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} /></Field></div>
          <Field label="City"><input className={inputCls} value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} /></Field>
          <Field label="State"><input className={inputCls} value={form.state} onChange={(e) => setForm({ ...form, state: e.target.value })} /></Field>
          <Field label="PIN Code"><input className={inputCls} value={form.pincode} onChange={(e) => setForm({ ...form, pincode: e.target.value })} /></Field>
          <Field label="Contact Person"><input className={inputCls} value={form.contact_name} onChange={(e) => setForm({ ...form, contact_name: e.target.value })} /></Field>
          <Field label="Contact Phone"><input className={inputCls} value={form.contact_phone} onChange={(e) => setForm({ ...form, contact_phone: e.target.value })} /></Field>
          <div className="sm:col-span-2 flex gap-3">
            <Button onClick={save} disabled={busy || !form.label || !form.city}>{busy ? "Saving…" : "Save Address"}</Button>
            <Button variant="secondary" onClick={() => setShowForm(false)}>Cancel</Button>
          </div>
        </Card>
      )}

      <div className="mt-5 grid gap-3">
        {items === null && <CardSkeleton />}
        {items?.length === 0 && !showForm && (
          <EmptyState title="No addresses yet." hint="Save pickup and delivery locations for one-tap booking."
            action={<Button onClick={() => setShowForm(true)}>Add New Address</Button>} />
        )}
        {list.map((a) => (
          <Card key={a.id} className="p-4 flex flex-wrap items-center gap-4">
            <span className={`h-10 w-10 rounded-xl grid place-items-center ${a.type === "pickup" ? "bg-ok-soft text-ok" : "bg-purple-soft text-purple"}`}>
              {a.type === "pickup" ? <Home size={18} /> : <Building2 size={18} />}
            </span>
            <div className="flex-1 min-w-[200px]">
              <p className="font-bold text-ink text-sm">{a.label}</p>
              <p className="text-xs text-ink-soft">{a.address}, {a.city}, {a.state} - {a.pincode}</p>
            </div>
            <Badge tone={a.type === "pickup" ? "ok" : "purple"}>{a.type}</Badge>
            <div className="text-xs text-ink-soft min-w-[130px]">
              <p className="font-semibold text-ink">{a.contact_name}</p><p>{a.contact_phone}</p>
            </div>
            <div className="flex gap-2">
              <Button variant="secondary" className="!px-3 !py-1.5 text-xs" onClick={() => toggleFrequent(a)}>
                <Star size={13} className={a.is_frequent ? "text-warn fill-current" : ""} /> {a.is_frequent ? "Frequent" : "Mark Frequent"}
              </Button>
              <Button variant="ghost" className="!px-2 !py-1.5" aria-label="Delete" onClick={() => remove(a.id)}><Trash2 size={15} className="text-danger" /></Button>
            </div>
          </Card>
        ))}
      </div>
    </Layout>
  );
}
