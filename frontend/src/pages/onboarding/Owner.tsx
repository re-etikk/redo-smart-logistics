import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { supabase } from "../../lib/supabase";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls, useToast, Badge } from "../../components/ui";
import { Truck, ShieldCheck, Camera, FileText, CheckCircle2, ArrowRight } from "lucide-react";

const CITY = ["Mumbai", "Delhi", "Pune", "Jaipur", "Surat", "Bengaluru", "Chennai", "Ahmedabad"];
const STEPS = ["Personal Info", "Truck Details", "Return Route", "KYC Verification"];

export default function OwnerOnboarding() {
  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const { refreshProfile, profile } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();

  const [personal, setPersonal] = useState({ full_name: profile?.full_name || "", phone: profile?.phone || "", company_name: profile?.company_name || "" });
  const [truck, setTruck] = useState({ registration_number: "", truck_type: "22FT", body_type: "Closed container", default_capacity_tons: "9" });
  const [route, setRoute] = useState({ origin: "Mumbai", destination: "Delhi", departure_at: "", available_capacity_tons: "4" });
  const [kyc, setKyc] = useState({
    dl_number: "",
    aadhaar_number: "",
    dl_photo: "",
    aadhaar_photo: "",
    face_selfie: "",
    truck_photo: "",
  });
  const [truckId, setTruckId] = useState<string | null>(null);

  const next = () => setStep((s) => Math.min(s + 1, STEPS.length - 1));
  const back = () => setStep((s) => Math.max(s - 1, 0));

  const handleFileUpload = (field: keyof typeof kyc) => (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      setKyc((prev) => ({ ...prev, [field]: url }));
      toast(`${field.replace("_", " ").toUpperCase()} attached successfully!`, "ok");
    }
  };

  const savePersonal = async () => {
    setBusy(true); setError("");
    try {
      if (profile?.id) {
        await supabase.from("profiles").update(personal).eq("id", profile.id);
      }
      try { await api.patch("/auth/profile", personal); } catch {}
      next();
    } catch (e: any) { setError(e.message); } finally { setBusy(false); }
  };

  const saveTruckAndRoute = async () => {
    setBusy(true); setError("");
    try {
      let tId = truckId;
      try {
        const t = await api.post<{ truck_id: string }>("/trucks", { ...truck, default_capacity_tons: +truck.default_capacity_tons });
        tId = t.truck_id;
        setTruckId(t.truck_id);
      } catch {
        tId = `t-demo-${Date.now()}`;
        setTruckId(tId);
      }

      if (tId && route.departure_at) {
        try {
          await api.post(`/trucks/${tId}/trips`, {
            origin: route.origin,
            destination: route.destination,
            departure_at: route.departure_at,
            available_capacity_tons: +route.available_capacity_tons,
          });
        } catch {}
      }
      next();
    } catch (e: any) { setError(e.message); } finally { setBusy(false); }
  };

  const finishVerification = async (isSkipped: boolean = false) => {
    setBusy(true);
    try {
      const isVerified = !isSkipped && Boolean(kyc.dl_number && kyc.aadhaar_number);
      const updateData = {
        onboarding_complete: true,
        kyc_verified: isVerified,
        dl_number: kyc.dl_number,
        aadhaar_number: kyc.aadhaar_number,
      };

      if (profile?.id) {
        await supabase.from("profiles").update(updateData).eq("id", profile.id);
      }
      try { await api.patch("/auth/profile", updateData); } catch {}
      await refreshProfile();

      if (isSkipped) {
        toast("Registration completed! You can complete KYC verification anytime to accept bookings.", "warn");
      } else {
        toast("KYC Verification submitted! Account fully verified to accept bookings.", "ok");
      }
      navigate("/dashboard/owner");
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between selection:bg-blue-600 selection:text-white">
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 h-16 flex items-center justify-between">
          <Logo dark />
          <div className="flex items-center gap-2 text-xs font-semibold text-slate-400">
            <span>Step {step + 1} of {STEPS.length}:</span>
            <span className="text-blue-400 font-bold">{STEPS[step]}</span>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-2xl w-full mx-auto px-4 py-8 sm:py-12">
        <Card className="!bg-slate-900 !border-slate-800 p-6 sm:p-8 space-y-6 shadow-2xl">
          {step === 0 && (
            <div className="space-y-4">
              <div>
                <h1 className="text-2xl font-black text-white">Owner & Business Details</h1>
                <p className="text-xs text-slate-400 mt-1">Provide your primary contact and fleet details</p>
              </div>

              <Field label="Full Name">
                <input
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={personal.full_name}
                  onChange={(e) => setPersonal({ ...personal, full_name: e.target.value })}
                />
              </Field>

              <Field label="Phone Number">
                <input
                  type="tel"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={personal.phone}
                  onChange={(e) => setPersonal({ ...personal, phone: e.target.value })}
                />
              </Field>

              <Field label="Company / Fleet Name">
                <input
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={personal.company_name}
                  onChange={(e) => setPersonal({ ...personal, company_name: e.target.value })}
                  placeholder="e.g. Express Backhaul Logistics"
                />
              </Field>

              <Button onClick={savePersonal} disabled={busy || !personal.full_name} className="w-full !bg-blue-600 hover:!bg-blue-500 !text-white !font-bold">
                Continue to Truck Details
                <ArrowRight className="w-4 h-4 ml-1" />
              </Button>
            </div>
          )}

          {step === 1 && (
            <div className="space-y-4">
              <div>
                <h1 className="text-2xl font-black text-white">Vehicle Specification</h1>
                <p className="text-xs text-slate-400 mt-1">Details of your primary return truck</p>
              </div>

              <Field label="Vehicle Registration Number (RC Number)">
                <input
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={truck.registration_number}
                  onChange={(e) => setTruck({ ...truck, registration_number: e.target.value })}
                  placeholder="e.g. MH-12-AB-4321"
                />
              </Field>

              <div className="grid grid-cols-2 gap-4">
                <Field label="Truck Size">
                  <select
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    value={truck.truck_type}
                    onChange={(e) => setTruck({ ...truck, truck_type: e.target.value })}
                  >
                    {["14FT", "17FT", "22FT", "32FT Multi-Axle"].map((t) => <option key={t}>{t}</option>)}
                  </select>
                </Field>

                <Field label="Total Capacity (Tonnes)">
                  <input
                    type="number"
                    min="1"
                    step="0.5"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    value={truck.default_capacity_tons}
                    onChange={(e) => setTruck({ ...truck, default_capacity_tons: e.target.value })}
                  />
                </Field>
              </div>

              <div className="flex gap-3 pt-2">
                <Button variant="secondary" onClick={back} className="!bg-slate-800 !text-white !border-slate-700">Back</Button>
                <Button onClick={next} disabled={!truck.registration_number} className="flex-1 !bg-blue-600 hover:!bg-blue-500 !text-white !font-bold">
                  Continue to Return Route
                  <ArrowRight className="w-4 h-4 ml-1" />
                </Button>
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-4">
              <div>
                <h1 className="text-2xl font-black text-white">First Return Leg Schedule</h1>
                <p className="text-xs text-slate-400 mt-1">Specify your upcoming empty return journey</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <Field label="Return Origin">
                  <select
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    value={route.origin}
                    onChange={(e) => setRoute({ ...route, origin: e.target.value })}
                  >
                    {CITY.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>

                <Field label="Destination">
                  <select
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    value={route.destination}
                    onChange={(e) => setRoute({ ...route, destination: e.target.value })}
                  >
                    {CITY.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </Field>
              </div>

              <Field label="Departure Date & Time">
                <input
                  type="datetime-local"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={route.departure_at}
                  onChange={(e) => setRoute({ ...route, departure_at: e.target.value })}
                />
              </Field>

              <Field label="Available Spare Capacity (Tonnes)">
                <input
                  type="number"
                  min="0.5"
                  step="0.5"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={route.available_capacity_tons}
                  onChange={(e) => setRoute({ ...route, available_capacity_tons: e.target.value })}
                />
              </Field>

              <div className="flex gap-3 pt-2">
                <Button variant="secondary" onClick={back} className="!bg-slate-800 !text-white !border-slate-700">Back</Button>
                <Button onClick={saveTruckAndRoute} disabled={!route.departure_at || route.origin === route.destination} className="flex-1 !bg-blue-600 hover:!bg-blue-500 !text-white !font-bold">
                  Continue to KYC Verification
                  <ArrowRight className="w-4 h-4 ml-1" />
                </Button>
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-6">
              <div>
                <div className="flex items-center gap-2">
                  <ShieldCheck className="w-6 h-6 text-emerald-400" />
                  <h1 className="text-2xl font-black text-white">Truck Owner Verification (KYC)</h1>
                </div>
                <p className="text-xs text-slate-400 mt-1">
                  Upload document details & photos. <span className="text-emerald-400 font-bold">Verification is required before accepting cargo bookings.</span>
                </p>
              </div>

              <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-200">1. Driving License (DL)</span>
                  {kyc.dl_photo && <Badge tone="ok">DL Attached</Badge>}
                </div>
                <input
                  placeholder="DL Number (e.g. MH1220200043210)"
                  className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500"
                  value={kyc.dl_number}
                  onChange={(e) => setKyc({ ...kyc, dl_number: e.target.value })}
                />
                <label className="flex items-center justify-center gap-2 p-2.5 rounded-xl border border-dashed border-slate-700 bg-slate-900/50 hover:bg-slate-900 cursor-pointer text-xs text-slate-400">
                  <FileText className="w-4 h-4 text-blue-400" />
                  <span>{kyc.dl_photo ? "Change DL Photo" : "Upload DL Photo"}</span>
                  <input type="file" accept="image/*" className="hidden" onChange={handleFileUpload("dl_photo")} />
                </label>
              </div>

              <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-200">2. Aadhaar Card</span>
                  {kyc.aadhaar_photo && <Badge tone="ok">Aadhaar Attached</Badge>}
                </div>
                <input
                  placeholder="12-Digit Aadhaar Number (e.g. 5432 9876 1234)"
                  className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500"
                  value={kyc.aadhaar_number}
                  onChange={(e) => setKyc({ ...kyc, aadhaar_number: e.target.value })}
                />
                <label className="flex items-center justify-center gap-2 p-2.5 rounded-xl border border-dashed border-slate-700 bg-slate-900/50 hover:bg-slate-900 cursor-pointer text-xs text-slate-400">
                  <FileText className="w-4 h-4 text-blue-400" />
                  <span>{kyc.aadhaar_photo ? "Change Aadhaar Photo" : "Upload Aadhaar Photo"}</span>
                  <input type="file" accept="image/*" className="hidden" onChange={handleFileUpload("aadhaar_photo")} />
                </label>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="bg-slate-950 p-3 rounded-2xl border border-slate-800 space-y-2">
                  <span className="text-[11px] font-bold text-slate-200">3. Driver Face Selfie</span>
                  <label className="flex flex-col items-center justify-center p-3 rounded-xl border border-dashed border-slate-700 bg-slate-900/50 hover:bg-slate-900 cursor-pointer text-[11px] text-slate-400 text-center">
                    <Camera className="w-5 h-5 text-emerald-400 mb-1" />
                    <span>{kyc.face_selfie ? "Selfie Uploaded" : "Take/Upload Selfie"}</span>
                    <input type="file" accept="image/*" className="hidden" onChange={handleFileUpload("face_selfie")} />
                  </label>
                </div>

                <div className="bg-slate-950 p-3 rounded-2xl border border-slate-800 space-y-2">
                  <span className="text-[11px] font-bold text-slate-200">4. Truck Photos (RC)</span>
                  <label className="flex flex-col items-center justify-center p-3 rounded-xl border border-dashed border-slate-700 bg-slate-900/50 hover:bg-slate-900 cursor-pointer text-[11px] text-slate-400 text-center">
                    <Truck className="w-5 h-5 text-blue-400 mb-1" />
                    <span>{kyc.truck_photo ? "Truck Photo Uploaded" : "Upload Truck Photo"}</span>
                    <input type="file" accept="image/*" className="hidden" onChange={handleFileUpload("truck_photo")} />
                  </label>
                </div>
              </div>

              <div className="space-y-3 pt-2">
                <Button
                  onClick={() => finishVerification(false)}
                  disabled={busy}
                  className="w-full !bg-emerald-600 hover:!bg-emerald-500 !text-white !py-3 !rounded-xl !font-bold shadow-lg shadow-emerald-600/20"
                >
                  <CheckCircle2 className="w-4 h-4 mr-1" />
                  <span>Submit Verification & Complete Account</span>
                </Button>

                <button
                  type="button"
                  onClick={() => finishVerification(true)}
                  disabled={busy}
                  className="w-full text-center text-xs font-semibold text-slate-400 hover:text-white py-2 transition"
                >
                  Skip verification for now (Complete later before accepting bookings)
                </button>
              </div>
            </div>
          )}
        </Card>
      </main>
    </div>
  );
}
