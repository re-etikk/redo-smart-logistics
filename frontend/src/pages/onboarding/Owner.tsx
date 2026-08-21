import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls, useToast } from "../../components/ui";

const CITY = ["Mumbai", "Delhi", "Pune", "Jaipur", "Surat"];
const STEPS = ["Personal", "Truck", "Return route", "Capacity", "Verification"];

export default function OwnerOnboarding() {
  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const { refreshProfile, profile } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();

  const [personal, setPersonal] = useState({ full_name: profile?.full_name || "", phone: profile?.phone || "" });
  const [truck, setTruck] = useState({ registration_number: "", truck_type: "22FT", body_type: "Closed container", default_capacity_tons: "9" });
  const [route, setRoute] = useState({ origin: "Mumbai", destination: "Delhi", departure_at: "" });
  const [cap, setCap] = useState({ available_capacity_tons: "4", accepted_cargo_types: "" });
  const [truckId, setTruckId] = useState<string | null>(null);

  const next = () => setStep((s) => Math.min(s + 1, STEPS.length - 1));
  const back = () => setStep((s) => Math.max(s - 1, 0));

  const savePersonal = async () => {
    setBusy(true); setError("");
    try { await api.patch("/auth/profile", personal); next(); }
    catch (e: any) { setError(e.message); } finally { setBusy(false); }
  };
  const saveTruck = async () => {
    setBusy(true); setError("");
    try {
      const t = await api.post<{ truck_id: string }>("/trucks", { ...truck, default_capacity_tons: +truck.default_capacity_tons });
      setTruckId(t.truck_id); next();
    } catch (e: any) { setError(e.message); } finally { setBusy(false); }
  };
  const saveTrip = async () => {
    if (!truckId) return;
    setBusy(true); setError("");
    try {
      await api.post(`/trucks/${truckId}/trips`, {
        ...route,
        available_capacity_tons: +cap.available_capacity_tons,
        accepted_cargo_types: cap.accepted_cargo_types ? cap.accepted_cargo_types.split(",").map((s) => s.trim()) : null,
      });
      next();
    } catch (e: any) { setError(e.message); } finally { setBusy(false); }
  };
  const finish = async () => {
    setBusy(true);
    try {
      await api.patch("/auth/profile", { onboarding_complete: true });
      await refreshProfile();
      toast("You are ready to receive cargo matches");
      navigate("/dashboard/owner");
    } catch (e: any) { setError(e.message); setBusy(false); }
  };

  return (
    <div className="min-h-screen bg-canvas">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center"><Logo /></div>
      </header>
      <main className="mx-auto max-w-lg px-4 py-8">
        <p className="text-xs font-semibold uppercase tracking-wide text-ink-faint">Step {step + 1} of {STEPS.length} · {STEPS[step]}</p>
        <Card className="mt-3 p-6 space-y-4">
          {step === 0 && (<>
            <Field label="Full name"><input className={inputCls} value={personal.full_name} onChange={(e) => setPersonal({ ...personal, full_name: e.target.value })} /></Field>
            <Field label="Phone" error={error}><input className={inputCls} value={personal.phone} onChange={(e) => setPersonal({ ...personal, phone: e.target.value })} /></Field>
            <Button className="w-full" onClick={savePersonal} disabled={busy || !personal.full_name}>Continue</Button>
          </>)}
          {step === 1 && (<>
            <Field label="Registration number"><input className={inputCls} value={truck.registration_number} onChange={(e) => setTruck({ ...truck, registration_number: e.target.value })} placeholder="DL 01 AB 4321" /></Field>
            <Field label="Truck type">
              <select className={inputCls} value={truck.truck_type} onChange={(e) => setTruck({ ...truck, truck_type: e.target.value })}>
                {["14FT", "17FT", "22FT", "32FT"].map((t) => <option key={t}>{t}</option>)}
              </select>
            </Field>
            <Field label="Body type">
              <select className={inputCls} value={truck.body_type} onChange={(e) => setTruck({ ...truck, body_type: e.target.value })}>
                {["Closed container", "Open body", "Refrigerated"].map((t) => <option key={t}>{t}</option>)}
              </select>
            </Field>
            <Field label="Total capacity (tonnes)" error={error}>
              <input type="number" min="1" step="0.5" className={inputCls} value={truck.default_capacity_tons} onChange={(e) => setTruck({ ...truck, default_capacity_tons: e.target.value })} />
            </Field>
            <div className="flex gap-3"><Button variant="secondary" onClick={back}>Back</Button>
              <Button className="flex-1" onClick={saveTruck} disabled={busy || !truck.registration_number}>Save truck</Button></div>
          </>)}
          {step === 2 && (<>
            <Field label="Return origin">
              <select className={inputCls} value={route.origin} onChange={(e) => setRoute({ ...route, origin: e.target.value })}>{CITY.map((c) => <option key={c}>{c}</option>)}</select>
            </Field>
            <Field label="Destination">
              <select className={inputCls} value={route.destination} onChange={(e) => setRoute({ ...route, destination: e.target.value })}>{CITY.map((c) => <option key={c}>{c}</option>)}</select>
            </Field>
            <Field label="Departure" error={route.origin === route.destination ? "Origin and destination must differ." : ""}>
              <input type="datetime-local" className={inputCls} value={route.departure_at} onChange={(e) => setRoute({ ...route, departure_at: e.target.value })} />
            </Field>
            <div className="flex gap-3"><Button variant="secondary" onClick={back}>Back</Button>
              <Button className="flex-1" onClick={next} disabled={!route.departure_at || route.origin === route.destination}>Continue</Button></div>
          </>)}
          {step === 3 && (<>
            <Field label="Available capacity on this return (tonnes)">
              <input type="number" min="0.5" step="0.5" className={inputCls} value={cap.available_capacity_tons} onChange={(e) => setCap({ ...cap, available_capacity_tons: e.target.value })} />
            </Field>
            <Field label="Accepted cargo types (optional, comma-separated)" error={error}>
              <input className={inputCls} value={cap.accepted_cargo_types} onChange={(e) => setCap({ ...cap, accepted_cargo_types: e.target.value })} placeholder="Textiles, FMCG" />
            </Field>
            <div className="flex gap-3"><Button variant="secondary" onClick={back}>Back</Button>
              <Button className="flex-1" onClick={saveTrip} disabled={busy}>Post return trip</Button></div>
          </>)}
          {step === 4 && (<>
            <p className="text-sm text-ink-soft">
              Upload your driving licence, vehicle RC and an identity document on the Verification page.
              For the demo, verification uses a clearly labeled <span className="font-semibold">demo verification</span> flow — never a fake DigiLocker badge.
            </p>
            <Button className="w-full" onClick={finish} disabled={busy}>Finish and go to dashboard</Button>
          </>)}
        </Card>
      </main>
    </div>
  );
}
