import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Button, Card, Field, inputCls, useToast } from "../../components/ui";

const CITY = ["Mumbai", "Delhi", "Pune", "Jaipur", "Surat"];

export default function AddTrip() {
  const [trucks, setTrucks] = useState<any[]>([]);
  const [form, setForm] = useState({ truck_id: "", origin: "Mumbai", destination: "Delhi", departure_at: "", available_capacity_tons: "4", price_per_km_ton: "1.0" });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const toast = useToast();
  const navigate = useNavigate();

  useEffect(() => { api.get<any[]>("/trucks").then((t) => { setTrucks(t); if (t[0]) setForm((f) => ({ ...f, truck_id: t[0].truck_id })); }); }, []);

  const submit = async () => {
    setBusy(true); setError("");
    try {
      await api.post(`/trucks/${form.truck_id}/trips`, {
        origin: form.origin, destination: form.destination, departure_at: form.departure_at,
        available_capacity_tons: +form.available_capacity_tons, price_per_km_ton: +form.price_per_km_ton,
      });
      toast("Return trip posted");
      navigate("/dashboard/owner");
    } catch (e: any) { setError(e.message); setBusy(false); }
  };

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Add return trip</h1>
      <Card className="mt-6 max-w-lg p-6 space-y-4">
        <Field label="Truck">
          <select className={inputCls} value={form.truck_id} onChange={(e) => setForm({ ...form, truck_id: e.target.value })}>
            {trucks.map((t) => <option key={t.truck_id} value={t.truck_id}>{t.truck_type} · {t.registration_number}</option>)}
          </select>
        </Field>
        <div className="grid grid-cols-2 gap-4">
          <Field label="Origin"><select className={inputCls} value={form.origin} onChange={(e) => setForm({ ...form, origin: e.target.value })}>{CITY.map((c) => <option key={c}>{c}</option>)}</select></Field>
          <Field label="Destination"><select className={inputCls} value={form.destination} onChange={(e) => setForm({ ...form, destination: e.target.value })}>{CITY.map((c) => <option key={c}>{c}</option>)}</select></Field>
        </div>
        <Field label="Departure"><input type="datetime-local" className={inputCls} value={form.departure_at} onChange={(e) => setForm({ ...form, departure_at: e.target.value })} /></Field>
        <div className="grid grid-cols-2 gap-4">
          <Field label="Available capacity (T)"><input type="number" min="0.5" step="0.5" className={inputCls} value={form.available_capacity_tons} onChange={(e) => setForm({ ...form, available_capacity_tons: e.target.value })} /></Field>
          <Field label="Rate (₹/km/T)" error={error}><input type="number" min="0.5" step="0.05" className={inputCls} value={form.price_per_km_ton} onChange={(e) => setForm({ ...form, price_per_km_ton: e.target.value })} /></Field>
        </div>
        <Button className="w-full" onClick={submit} disabled={busy || !form.departure_at || !form.truck_id || form.origin === form.destination}>
          {busy ? "Saving trip…" : "Post trip"}
        </Button>
      </Card>
    </Layout>
  );
}
