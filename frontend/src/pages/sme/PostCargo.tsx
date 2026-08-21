import { useState } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Button, Card, Field, inputCls } from "../../components/ui";

const CITY = ["Mumbai", "Delhi", "Pune", "Jaipur", "Surat"];
const TYPES = ["Textiles", "FMCG", "Electronics", "Auto parts", "Pharma", "Furniture"];

export default function PostCargo() {
  const [form, setForm] = useState({ origin: "Mumbai", destination: "Delhi", cargo_type: "Textiles", cargo_weight_tons: "1.5", pickup_at: "", urgency: "normal", special_handling: "" });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const submit = async () => {
    setBusy(true); setError("");
    try {
      const cargo = await api.post<{ cargo_id: string }>("/cargo", { ...form, cargo_weight_tons: +form.cargo_weight_tons });
      navigate(`/find-trucks/${cargo.cargo_id}`);
    } catch (e: any) { setError(e.message); setBusy(false); }
  };

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Post cargo</h1>
      <Card className="mt-6 max-w-lg p-6 space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <Field label="Pickup city"><select className={inputCls} value={form.origin} onChange={(e) => setForm({ ...form, origin: e.target.value })}>{CITY.map((c) => <option key={c}>{c}</option>)}</select></Field>
          <Field label="Destination"><select className={inputCls} value={form.destination} onChange={(e) => setForm({ ...form, destination: e.target.value })}>{CITY.map((c) => <option key={c}>{c}</option>)}</select></Field>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Field label="Cargo type"><select className={inputCls} value={form.cargo_type} onChange={(e) => setForm({ ...form, cargo_type: e.target.value })}>{TYPES.map((c) => <option key={c}>{c}</option>)}</select></Field>
          <Field label="Weight (tonnes)"><input type="number" min="0.1" step="0.1" className={inputCls} value={form.cargo_weight_tons} onChange={(e) => setForm({ ...form, cargo_weight_tons: e.target.value })} /></Field>
        </div>
        <Field label="Pickup date and time"><input type="datetime-local" className={inputCls} value={form.pickup_at} onChange={(e) => setForm({ ...form, pickup_at: e.target.value })} /></Field>
        <div className="grid grid-cols-2 gap-4">
          <Field label="Urgency"><select className={inputCls} value={form.urgency} onChange={(e) => setForm({ ...form, urgency: e.target.value })}>{["normal", "urgent", "flexible"].map((c) => <option key={c}>{c}</option>)}</select></Field>
          <Field label="Special handling (optional)" error={error || (form.origin === form.destination ? "Origin and destination must differ." : "")}>
            <input className={inputCls} value={form.special_handling} onChange={(e) => setForm({ ...form, special_handling: e.target.value })} placeholder="Fragile" />
          </Field>
        </div>
        <Button className="w-full" onClick={submit} disabled={busy || !form.pickup_at || form.origin === form.destination}>
          {busy ? "Saving cargo…" : "Find backhaul trucks"}
        </Button>
      </Card>
    </Layout>
  );
}
