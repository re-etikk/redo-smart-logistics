import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { api } from "../../lib/api";
import { useAuth } from "../../hooks/useAuth";
import Logo from "../../components/Logo";
import {
  Truck,
  User,
  Phone,
  FileCheck2,
  MapPin,
  ShieldCheck,
  CheckCircle2,
  Sparkles,
  ArrowRight,
  ArrowLeft,
  Calendar
} from "lucide-react";

const STEPS = ["Personal Info", "Truck Details", "Primary Route", "Ready to Earn"];

export default function OwnerOnboarding() {
  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const { refreshProfile, profile } = useAuth();
  const navigate = useNavigate();

  const [personal, setPersonal] = useState({
    full_name: profile?.full_name || "Rohit Sharma",
    phone: profile?.phone || "+91 98765 43210",
    pan_number: "ABCDE1234F",
    experience_years: "5",
  });

  const [truck, setTruck] = useState({
    registration_number: "DL 01 AB 1234",
    truck_type: "17 Feet",
    body_type: "Closed Container",
    default_capacity_tons: "7.5",
  });

  const [route, setRoute] = useState({
    origin: "Delhi NCR",
    destination: "Mumbai",
    departure_frequency: "Daily",
  });

  const next = () => setStep((s) => Math.min(s + 1, STEPS.length - 1));
  const back = () => setStep((s) => Math.max(s - 1, 0));

  const saveAndFinish = async () => {
    setBusy(true);
    setError("");
    try {
      // Save profile
      await api.patch("/auth/profile", {
        full_name: personal.full_name,
        phone: personal.phone,
        onboarding_complete: true,
      });

      // Register truck
      try {
        await api.post("/trucks", {
          ...truck,
          default_capacity_tons: parseFloat(truck.default_capacity_tons) || 7.5,
        });
      } catch {}

      await refreshProfile();
      navigate("/dashboard");
    } catch {
      // Local/demo fallback
      navigate("/dashboard");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 font-sans selection:bg-amber-400 flex flex-col justify-between">
      {/* Header */}
      <header className="bg-white border-b border-slate-200/80 sticky top-0 z-20">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link to="/">
            <Logo />
          </Link>
          <div className="flex items-center gap-2 text-xs font-bold text-slate-500">
            <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
            <span>Truck Owner Onboarding</span>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center p-4 py-10">
        <div className="w-full max-w-xl bg-white border border-slate-200/80 rounded-3xl p-8 shadow-xl space-y-6">
          {/* Step Progress Bar */}
          <div className="space-y-3 border-b border-slate-100 pb-4">
            <div className="flex items-center justify-between text-xs font-black text-slate-700">
              <span>Step {step + 1} of {STEPS.length}: <span className="text-amber-600">{STEPS[step]}</span></span>
              <span className="text-[10px] text-slate-400 font-mono font-bold">{Math.round(((step + 1) / STEPS.length) * 100)}% Complete</span>
            </div>
            <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
              <div
                className="bg-[#FFC800] h-full transition-all duration-300 rounded-full"
                style={{ width: `${((step + 1) / STEPS.length) * 100}%` }}
              ></div>
            </div>
          </div>

          {/* STEP 0: Personal Info */}
          {step === 0 && (
            <div className="space-y-4">
              <div className="space-y-1">
                <h2 className="text-xl font-black text-slate-900">Personal &amp; Contact Information</h2>
                <p className="text-xs text-slate-500">Tell us about yourself or your fleet company.</p>
              </div>

              <div className="space-y-3 text-xs font-bold">
                <div>
                  <label className="text-slate-700 block mb-1">Full Name / Owner Name</label>
                  <input
                    value={personal.full_name}
                    onChange={(e) => setPersonal({ ...personal, full_name: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
                <div>
                  <label className="text-slate-700 block mb-1">Mobile Phone Number</label>
                  <input
                    value={personal.phone}
                    onChange={(e) => setPersonal({ ...personal, phone: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-slate-700 block mb-1">PAN Number</label>
                    <input
                      value={personal.pan_number}
                      onChange={(e) => setPersonal({ ...personal, pan_number: e.target.value.toUpperCase() })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900 uppercase font-mono"
                    />
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Experience (Years)</label>
                    <select
                      value={personal.experience_years}
                      onChange={(e) => setPersonal({ ...personal, experience_years: e.target.value })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    >
                      <option value="1">1+ Year</option>
                      <option value="3">3+ Years</option>
                      <option value="5">5+ Years</option>
                      <option value="10">10+ Years</option>
                    </select>
                  </div>
                </div>
              </div>

              <button
                type="button"
                onClick={next}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2 mt-4"
              >
                <span>Continue to Truck Details</span>
                <ArrowRight size={16} />
              </button>
            </div>
          )}

          {/* STEP 1: Truck Details */}
          {step === 1 && (
            <div className="space-y-4">
              <div className="space-y-1">
                <h2 className="text-xl font-black text-slate-900">Add Your First Truck</h2>
                <p className="text-xs text-slate-500">Register your vehicle to start receiving instant load notifications.</p>
              </div>

              <div className="space-y-3 text-xs font-bold">
                <div>
                  <label className="text-slate-700 block mb-1">Vehicle Registration Number (RC)</label>
                  <input
                    value={truck.registration_number}
                    onChange={(e) => setTruck({ ...truck, registration_number: e.target.value.toUpperCase() })}
                    placeholder="e.g. MH 04 AB 1234"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-slate-900 uppercase font-mono focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-slate-700 block mb-1">Truck Type</label>
                    <select
                      value={truck.truck_type}
                      onChange={(e) => setTruck({ ...truck, truck_type: e.target.value })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    >
                      <option>14 Feet</option>
                      <option>17 Feet</option>
                      <option>19 Feet</option>
                      <option>22 Feet</option>
                      <option>32 Feet Single Axle</option>
                      <option>32 Feet Multi Axle</option>
                      <option>Tata Ace / Pickup</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Body Type</label>
                    <select
                      value={truck.body_type}
                      onChange={(e) => setTruck({ ...truck, body_type: e.target.value })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    >
                      <option>Closed Container</option>
                      <option>Open Body</option>
                      <option>Flatbed</option>
                      <option>Tipper</option>
                      <option>Refrigerated</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="text-slate-700 block mb-1">Payload Capacity (Tons)</label>
                  <input
                    type="number"
                    step="0.5"
                    value={truck.default_capacity_tons}
                    onChange={(e) => setTruck({ ...truck, default_capacity_tons: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-slate-900"
                  />
                </div>
              </div>

              <div className="flex gap-3 mt-4">
                <button
                  type="button"
                  onClick={back}
                  className="px-4 py-3 bg-slate-100 text-slate-700 font-bold rounded-xl text-xs hover:bg-slate-200 flex items-center gap-1"
                >
                  <ArrowLeft size={16} /> Back
                </button>
                <button
                  type="button"
                  onClick={next}
                  className="flex-1 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2"
                >
                  <span>Continue to Routes</span>
                  <ArrowRight size={16} />
                </button>
              </div>
            </div>
          )}

          {/* STEP 2: Primary Route */}
          {step === 2 && (
            <div className="space-y-4">
              <div className="space-y-1">
                <h2 className="text-xl font-black text-slate-900">Frequent Operating Corridors</h2>
                <p className="text-xs text-slate-500">Where does this vehicle usually operate?</p>
              </div>

              <div className="space-y-3 text-xs font-bold">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-slate-700 block mb-1">Base / Origin City</label>
                    <input
                      value={route.origin}
                      onChange={(e) => setRoute({ ...route, origin: e.target.value })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    />
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Destination City</label>
                    <input
                      value={route.destination}
                      onChange={(e) => setRoute({ ...route, destination: e.target.value })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    />
                  </div>
                </div>

                <div>
                  <label className="text-slate-700 block mb-1">Trip Frequency</label>
                  <select
                    value={route.departure_frequency}
                    onChange={(e) => setRoute({ ...route, departure_frequency: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  >
                    <option>Daily</option>
                    <option>2-3 Times a Week</option>
                    <option>Weekly</option>
                    <option>On-Demand / Flexible</option>
                  </select>
                </div>
              </div>

              <div className="flex gap-3 mt-4">
                <button
                  type="button"
                  onClick={back}
                  className="px-4 py-3 bg-slate-100 text-slate-700 font-bold rounded-xl text-xs hover:bg-slate-200 flex items-center gap-1"
                >
                  <ArrowLeft size={16} /> Back
                </button>
                <button
                  type="button"
                  onClick={next}
                  className="flex-1 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2"
                >
                  <span>Review &amp; Finish</span>
                  <ArrowRight size={16} />
                </button>
              </div>
            </div>
          )}

          {/* STEP 3: Ready to Earn */}
          {step === 3 && (
            <div className="space-y-5 text-center">
              <div className="w-16 h-16 rounded-3xl bg-amber-100 text-amber-900 border-2 border-amber-300 flex items-center justify-center text-3xl mx-auto shadow-sm">
                🚛
              </div>

              <div className="space-y-1">
                <h2 className="text-2xl font-black text-slate-900">You are All Set!</h2>
                <p className="text-xs text-slate-500">Your fleet is ready to receive return-load matches on the {route.origin} → {route.destination} corridor.</p>
              </div>

              <div className="bg-slate-50 rounded-2xl p-4 border border-slate-200 text-left text-xs font-bold space-y-2">
                <div className="flex justify-between">
                  <span className="text-slate-500">Owner:</span>
                  <span className="text-slate-900">{personal.full_name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Truck:</span>
                  <span className="text-slate-900">{truck.registration_number} ({truck.truck_type})</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Corridor:</span>
                  <span className="text-slate-900">{route.origin} ➔ {route.destination}</span>
                </div>
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={back}
                  className="px-4 py-3 bg-slate-100 text-slate-700 font-bold rounded-xl text-xs hover:bg-slate-200 flex items-center gap-1"
                >
                  <ArrowLeft size={16} /> Back
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={saveAndFinish}
                  className="flex-1 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2"
                >
                  <span>{busy ? "Activating Fleet..." : "Go to Dashboard & View Loads"}</span>
                  <CheckCircle2 size={16} />
                </button>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Footer */}
      <footer className="py-4 border-t border-slate-200/80 bg-white text-center text-xs text-slate-500">
        © {new Date().getFullYear()} REDO Transport &amp; Logistics. Driver &amp; Fleet Partner Network.
      </footer>
    </div>
  );
}
