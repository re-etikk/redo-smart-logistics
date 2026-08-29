import { useEffect, useState } from "react";
import { CalendarCheck, IndianRupee, Truck as TruckIcon } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, EmptyState, Field, SectionHead, StatCard, inputCls, useToast } from "../../components/ui";

const BLANK = { registration_number: "", truck_type: "22FT", body_type: "Closed container", home_origin: "Delhi", default_capacity_tons: "9" };
const CITIES = ["Mumbai", "Delhi", "Pune", "Jaipur", "Surat"];
const tomorrow10 = () => { const d = new Date(Date.now() + 864e5); d.setHours(10, 0, 0, 0);
  return new Date(d.getTime() - d.getTimezoneOffset() * 6e4).toISOString().slice(0, 16); };

export default function MyTrucks() {
  const [trucks, setTrucks] = useState<any[] | null>(null);
  const [earnings, setEarnings] = useState<any | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<any>(BLANK);
  const [busy, setBusy] = useState(false);
  const [tripFor, setTripFor] = useState<string | null>(null);
  const [trip, setTrip] = useState<any>({ origin: "Mumbai", destination: "Delhi", departure_at: tomorrow10(), available_capacity_tons: "" });
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
  const postTrip = async (t: any) => {
    setBusy(true);
    try {
      await api.post(`/trucks/${t.truck_id}/trips`, {
        origin: trip.origin, destination: trip.destination,
        departure_at: new Date(trip.departure_at).toISOString(),
        available_capacity_tons: +(trip.available_capacity_tons || t.default_capacity_tons),
      });
      setTripFor(null);
      toast("Return trip posted — you will now appear in shipper matches on this corridor");
    } catch (e: any) { toast(e.message, "danger"); } finally { setBusy(false); }
  };

  const list = trucks ?? [];
  return (
    <Layout>
      <SectionHead title="My Trucks" sub="Manage your trucks and post empty return trips — trips are what shippers get matched against."
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
            <Button variant="secondary" className="!px-3 !py-1.5 text-xs"
              onClick={() => setTripFor(tripFor === t.truck_id ? null : t.truck_id)}>
              + Post Return Trip
            </Button>
            {tripFor === t.truck_id && (
              <div className="w-full mt-2 grid sm:grid-cols-5 gap-3 items-end rounded-xl bg-canvas p-3">
                <Field label="From (empty at)">
                  <select className={inputCls} value={trip.origin} onChange={(e) => setTrip({ ...trip, origin: e.target.value })}>
                    {CITIES.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>
                <Field label="Returning to">
                  <select className={inputCls} value={trip.destination} onChange={(e) => setTrip({ ...trip, destination: e.target.value })}>
                    {CITIES.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>
                <Field label="Departure">
                  <input type="datetime-local" className={inputCls} value={trip.departure_at}
                    onChange={(e) => setTrip({ ...trip, departure_at: e.target.value })} />
                </Field>
                <Field label={`Free capacity (≤${t.default_capacity_tons} T)`}>
                  <input type="number" step="0.5" min="0.5" max={t.default_capacity_tons} className={inputCls}
                    placeholder={String(t.default_capacity_tons)} value={trip.available_capacity_tons}
                    onChange={(e) => setTrip({ ...trip, available_capacity_tons: e.target.value })} />
                </Field>
                <Button disabled={busy || trip.origin === trip.destination} onClick={() => postTrip(t)}>
                  {busy ? "Posting…" : "Post Trip"}
                </Button>
                {trip.origin === trip.destination && <p className="sm:col-span-5 text-xs text-danger font-medium">From and To must differ.</p>}
              </div>
            )}
          </Card>
        ))}
      </div>
    </Layout>
  );
}
