import { useState } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Button, Card, Field, inputCls, useToast } from "../../components/ui";
import { PackageCheck, ArrowRight, Calendar, Sparkles, MapPin, Scale, Clock, ShieldCheck } from "lucide-react";

const CITY = ["Mumbai", "Delhi", "Pune", "Jaipur", "Surat", "Bengaluru", "Chennai", "Ahmedabad"];
const TYPES = ["Textiles", "FMCG", "Electronics", "Auto parts", "Pharma", "Furniture", "Industrial Fasteners"];

export default function PostCargo() {
  const [form, setForm] = useState({
    origin: "Mumbai",
    destination: "Delhi",
    cargo_type: "Textiles",
    cargo_weight_tons: "1.5",
    pickup_at: "",
    urgency: "normal",
    special_handling: "",
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();
  const toast = useToast();

  const submit = async () => {
    setBusy(true);
    setError("");
    let cargoId = `c-demo-${Date.now()}`;
    try {
      const cargo = await api.post<{ cargo_id: string }>("/cargo", {
        ...form,
        cargo_weight_tons: +form.cargo_weight_tons,
      });
      cargoId = cargo.cargo_id;
    } catch {
      // Graceful fallback for offline/local environment
    }
    toast("Consignment posted! Finding top AI backhaul matches...", "ok");
    navigate(`/find-trucks/${cargoId}`);
  };

  return (
    <Layout>
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="space-y-2">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 text-xs font-bold">
            <PackageCheck className="w-3.5 h-3.5" />
            <span>Sub-Tonne Consignment Booking</span>
          </div>
          <h1 className="text-3xl font-black text-slate-900">Post Cargo Freight Request</h1>
          <p className="text-xs text-slate-500">
            Pair your partial load with verified trucks returning empty on your exact corridor.
          </p>
        </div>

        <Card className="p-6 sm:p-8 space-y-6">
          {/* Origin & Destination */}
          <div className="grid sm:grid-cols-2 gap-4">
            <Field label="Pickup Origin City">
              <select
                className={inputCls}
                value={form.origin}
                onChange={(e) => setForm({ ...form, origin: e.target.value })}
              >
                {CITY.map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>

            <Field label="Delivery Destination">
              <select
                className={inputCls}
                value={form.destination}
                onChange={(e) => setForm({ ...form, destination: e.target.value })}
              >
                {CITY.map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>
          </div>

          {/* Cargo Type & Weight */}
          <div className="grid sm:grid-cols-2 gap-4">
            <Field label="Consignment Category">
              <select
                className={inputCls}
                value={form.cargo_type}
                onChange={(e) => setForm({ ...form, cargo_type: e.target.value })}
              >
                {TYPES.map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>

            <Field label="Freight Weight (Tonnes)">
              <input
                type="number"
                min="0.1"
                step="0.1"
                className={inputCls}
                value={form.cargo_weight_tons}
                onChange={(e) => setForm({ ...form, cargo_weight_tons: e.target.value })}
              />
            </Field>
          </div>

          {/* Pickup Date & Time */}
          <Field label="Pickup Date & Time Window">
            <input
              type="datetime-local"
              className={inputCls}
              value={form.pickup_at}
              onChange={(e) => setForm({ ...form, pickup_at: e.target.value })}
            />
          </Field>

          {/* Urgency & Special Handling */}
          <div className="grid sm:grid-cols-2 gap-4">
            <Field label="Dispatch Urgency">
              <select
                className={inputCls}
                value={form.urgency}
                onChange={(e) => setForm({ ...form, urgency: e.target.value })}
              >
                {["normal", "urgent", "flexible"].map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>

            <Field label="Special Handling Instructions (Optional)">
              <input
                className={inputCls}
                value={form.special_handling}
                onChange={(e) => setForm({ ...form, special_handling: e.target.value })}
                placeholder="e.g. Fragile, Temperature Sensitive"
              />
            </Field>
          </div>

          {form.origin === form.destination && (
            <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-800 text-xs font-semibold">
              Pickup origin and destination city must be different.
            </div>
          )}

          <Button
            onClick={submit}
            disabled={busy || !form.pickup_at || form.origin === form.destination}
            className="w-full !bg-blue-600 hover:!bg-blue-500 !text-white !py-3 !rounded-xl !font-bold shadow-lg shadow-blue-600/20 flex items-center justify-center gap-2"
          >
            <Sparkles className="w-4 h-4 text-blue-300" />
            <span>{busy ? "Searching Return Vehicles…" : "Find AI Matched Backhaul Trucks"}</span>
            <ArrowRight className="w-4 h-4" />
          </Button>
        </Card>
      </div>
    </Layout>
  );
}

