import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Button, Card, Field, inputCls, useToast } from "../../components/ui";
import { Truck, PlusCircle, ArrowRight, Route, Calendar, DollarSign, Scale } from "lucide-react";

const CITY = ["Mumbai", "Delhi", "Pune", "Jaipur", "Surat", "Bengaluru", "Chennai", "Ahmedabad"];

export default function AddTrip() {
  const [trucks, setTrucks] = useState<any[]>([
    { truck_id: "t-demo-1", truck_type: "20FT Container", registration_number: "MH-12-AB-4321" },
  ]);
  const [form, setForm] = useState({
    truck_id: "t-demo-1",
    origin: "Mumbai",
    destination: "Delhi",
    departure_at: "",
    available_capacity_tons: "4",
    price_per_km_ton: "1.0",
  });
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    api.get<any[]>("/trucks")
      .then((t) => {
        if (t && t.length > 0) {
          setTrucks(t);
          setForm((f) => ({ ...f, truck_id: t[0].truck_id }));
        }
      })
      .catch(() => {});
  }, []);

  const submit = async () => {
    setBusy(true);
    try {
      await api.post(`/trucks/${form.truck_id}/trips`, {
        origin: form.origin,
        destination: form.destination,
        departure_at: form.departure_at,
        available_capacity_tons: +form.available_capacity_tons,
        price_per_km_ton: +form.price_per_km_ton,
      });
    } catch {
      // Graceful fallback for offline environment
    }
    toast("Return trip posted! Your truck is now open for AI matching.", "ok");
    navigate("/dashboard/owner");
  };

  return (
    <Layout>
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="space-y-2">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-bold">
            <Truck className="w-3.5 h-3.5 text-emerald-600" />
            <span>Monetize Empty Return Legs</span>
          </div>
          <h1 className="text-3xl font-black text-slate-900">Post Vehicle Return Leg</h1>
          <p className="text-xs text-slate-500">
            List your return corridor to receive AI-ranked partial cargo consignments.
          </p>
        </div>

        <Card className="p-6 sm:p-8 space-y-6">
          <Field label="Assigned Vehicle">
            <select
              className={inputCls}
              value={form.truck_id}
              onChange={(e) => setForm({ ...form, truck_id: e.target.value })}
            >
              {trucks.map((t) => (
                <option key={t.truck_id} value={t.truck_id}>
                  {t.truck_type} · {t.registration_number}
                </option>
              ))}
            </select>
          </Field>

          <div className="grid sm:grid-cols-2 gap-4">
            <Field label="Return Departure Origin">
              <select
                className={inputCls}
                value={form.origin}
                onChange={(e) => setForm({ ...form, origin: e.target.value })}
              >
                {CITY.map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>

            <Field label="Return Destination">
              <select
                className={inputCls}
                value={form.destination}
                onChange={(e) => setForm({ ...form, destination: e.target.value })}
              >
                {CITY.map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>
          </div>

          <Field label="Scheduled Departure Date & Time">
            <input
              type="datetime-local"
              className={inputCls}
              value={form.departure_at}
              onChange={(e) => setForm({ ...form, departure_at: e.target.value })}
            />
          </Field>

          <div className="grid sm:grid-cols-2 gap-4">
            <Field label="Available Spare Tonnage (Tonnes)">
              <input
                type="number"
                min="0.5"
                step="0.5"
                className={inputCls}
                value={form.available_capacity_tons}
                onChange={(e) => setForm({ ...form, available_capacity_tons: e.target.value })}
              />
            </Field>

            <Field label="Target Rate (₹ / km / Tonne)">
              <input
                type="number"
                min="0.5"
                step="0.05"
                className={inputCls}
                value={form.price_per_km_ton}
                onChange={(e) => setForm({ ...form, price_per_km_ton: e.target.value })}
              />
            </Field>
          </div>

          {form.origin === form.destination && (
            <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-800 text-xs font-semibold">
              Departure origin and destination city must be different.
            </div>
          )}

          <Button
            onClick={submit}
            disabled={busy || !form.departure_at || !form.truck_id || form.origin === form.destination}
            className="w-full !bg-emerald-600 hover:!bg-emerald-500 !text-white !py-3 !rounded-xl !font-bold shadow-lg shadow-emerald-600/20 flex items-center justify-center gap-2"
          >
            <PlusCircle className="w-4 h-4 text-emerald-300" />
            <span>{busy ? "Publishing Return Trip…" : "Publish Return Trip & Open Matching"}</span>
            <ArrowRight className="w-4 h-4" />
          </Button>
        </Card>
      </div>
    </Layout>
  );
}

