import { useEffect, useState } from "react";
import { CalendarCheck, IndianRupee, Truck as TruckIcon } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, EmptyState, Field, SectionHead, StatCard, inputCls, useToast } from "../../components/ui";

const BLANK = { registration_number: "", truck_type: "22FT", body_type: "Closed container", home_origin: "Delhi", default_capacity_tons: "9" };

export default function MyTrucks() {
  const [trucks, setTrucks] = useState<any[] | null>(null);
  const [earnings, setEarnings] = useState<any | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<any>(BLANK);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const load = () => api.get<any[]>("/trucks").then(setTrucks).catch(() => setTrucks([]));
  useEffect(() => { load(); api.get<any>("/earnings").then(setEarnings).catch(() => {}); }, []);

  const save = async () => {
    setBusy(true);
    try {
      await api.post("/trucks", { ...form, default_capacity_tons: +form.default_capacity_tons });
      setShowForm(false); setForm(BLANK); toast("Truck added"); load();
    } catch (e: any) { toast(e.message, "danger"); } finally { setBusy(false); }
  };
  const setStatus = async (t: any, status: string) => {
    try { await api.patch(`/trucks/${t.truck_id}`, { status }); load(); }
    catch (e: any) { toast(e.message, "danger"); }
  };

  const list = trucks ?? [];
  return (
    <Layout>
      <SectionHead title="My Trucks" sub="Manage your trucks, view status and track performance."
        action={<Button onClick={() => setShowForm((s) => !s)}>+ Add New Truck</Button>} />
      <div className="mt-5 grid gap-4 grid-cols-3">
        <StatCard icon={TruckIcon} label="Total Trucks" value={list.length} sub={`${list.filter((t) => t.status === "available").length} available`} tone="ok" />
        <StatCard icon={CalendarCheck} label="On Trip" value={list.filter((t) => t.status === "in_transit").length} tone="info" />
        <StatCard icon={IndianRupee} label="Total Earnings" value={`₹${Number(earnings?.totals?.completed_inr ?? 0).toLocaleString("en-IN")}`} tone="purple" />
      </div>

      {showForm && (
        <Card className="mt-5 p-5 grid sm:grid-cols-2 gap-4">
          <Field label="Registration Number"><input className={inputCls} value={form.registration_number} onChange={(e) => setForm({ ...form, registration_number: e.target.value })} placeholder="DL 01 AB 4321" /></Field>
          <Field label="Truck Type">
            <select className={inputCls} value={form.truck_type} onChange={(e) => setForm({ ...form, truck_type: e.target.value })}>
              {["14FT", "17FT", "22FT", "32FT"].map((t) => <option key={t}>{t}</option>)}
            </select>
          </Field>
          <Field label="Body Type">
            <select className={inputCls} value={form.body_type} onChange={(e) => setForm({ ...form, body_type: e.target.value })}>
              {["Closed container", "Open body", "Refrigerated", "Tipper"].map((t) => <option key={t}>{t}</option>)}
            </select>
          </Field>
          <Field label="Capacity (tonnes)"><input type="number" min="1" step="0.5" className={inputCls} value={form.default_capacity_tons} onChange={(e) => setForm({ ...form, default_capacity_tons: e.target.value })} /></Field>
          <div className="sm:col-span-2 flex gap-3">
            <Button onClick={save} disabled={busy || !form.registration_number}>{busy ? "Saving…" : "Save Truck"}</Button>
            <Button variant="secondary" onClick={() => setShowForm(false)}>Cancel</Button>
          </div>
        </Card>
      )}

      <div className="mt-5 grid gap-3">
        {trucks === null && <CardSkeleton />}
        {trucks?.length === 0 && !showForm && (
          <EmptyState title="No trucks yet." hint="Add your truck to start receiving load matches."
            action={<Button onClick={() => setShowForm(true)}>Add New Truck</Button>} />
        )}
        {list.map((t) => (
          <Card key={t.truck_id} className="p-4 flex flex-wrap items-center gap-4">
            <span className="h-12 w-12 rounded-xl bg-brand-soft text-brand-dark grid place-items-center"><TruckIcon size={22} /></span>
            <div className="flex-1 min-w-[180px]">
              <p className="font-bold text-ink">{t.truck_type} <span className="text-ink-faint font-medium">· {t.registration_number}</span></p>
              <p className="text-xs text-ink-soft">{t.default_capacity_tons} T capacity
                {t.driver_rating != null ? ` · rating ${Number(t.driver_rating).toFixed(1)}` : " · New — no ratings yet"}
                {t.on_time_rate != null ? ` · on-time ${Math.round(t.on_time_rate * 100)}%` : ""}</p>
            </div>
            <Badge tone={t.status === "available" ? "ok" : t.status === "in_transit" ? "accent" : "neutral"}>
              {t.status === "in_transit" ? "On Trip" : t.status[0].toUpperCase() + t.status.slice(1)}
            </Badge>
            <select className={inputCls + " !w-auto text-xs"} value={t.status} onChange={(e) => setStatus(t, e.target.value)} aria-label="Truck status">
              {["available", "in_transit", "offline"].map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          </Card>
        ))}
      </div>
    </Layout>
  );
}
