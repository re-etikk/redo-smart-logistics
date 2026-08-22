import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Logo } from "../components/Layout";
import { Button, Card, Badge } from "../components/ui";
import { Truck, PackageCheck, Route, ShieldCheck, TrendingUp, Sparkles, ArrowRight, CheckCircle2, Leaf, BarChart3, Calculator } from "lucide-react";

function InteractiveRouteSimulator() {
  const [selectedRoute, setSelectedRoute] = useState(0);

  const routes = [
    { from: "Mumbai", to: "Delhi", dist: "1,420 km", capacity: "3.5 Tonnes", earnings: "₹18,400", time: "24 hrs" },
    { from: "Bengaluru", to: "Chennai", dist: "346 km", capacity: "2.0 Tonnes", earnings: "₹6,800", time: "7 hrs" },
    { from: "Ahmedabad", to: "Jaipur", dist: "657 km", capacity: "4.0 Tonnes", earnings: "₹11,200", time: "12 hrs" },
  ];

  const current = routes[selectedRoute];

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-2xl text-white relative overflow-hidden">
      <div className="absolute top-0 right-0 p-8 opacity-10 pointer-events-none">
        <Route className="w-64 h-64 text-blue-400" />
      </div>

      <div className="relative z-10 space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-xs font-extrabold uppercase tracking-wider text-slate-400">Live AI Route Simulator</span>
          </div>
          <Badge tone="accent">94% Match Confidence</Badge>
        </div>

        {/* Route Selector Chips */}
        <div className="flex flex-wrap gap-2">
          {routes.map((r, i) => (
            <button
              key={r.from + r.to}
              onClick={() => setSelectedRoute(i)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                selectedRoute === i
                  ? "bg-blue-600 text-white shadow-md"
                  : "bg-slate-800 text-slate-400 hover:text-white"
              }`}
            >
              {r.from} ➔ {r.to}
            </button>
          ))}
        </div>

        {/* Route Progress Visual */}
        <div className="bg-slate-950/80 border border-slate-800/80 rounded-2xl p-5 space-y-4">
          <div className="flex items-center justify-between text-sm font-bold">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-xl bg-blue-500/20 border border-blue-500/30 flex items-center justify-center text-blue-400">
                <Truck className="w-4 h-4" />
              </div>
              <div>
                <div className="text-white">{current.from} ➔ {current.to}</div>
                <div className="text-xs font-normal text-slate-400">Return Leg Optimization</div>
              </div>
            </div>
            <div className="text-right">
              <div className="text-emerald-400 text-lg font-black">{current.earnings}</div>
              <div className="text-[10px] text-slate-400 uppercase font-semibold">Est. Extra Income</div>
            </div>
          </div>

          <div className="space-y-1">
            <div className="flex justify-between text-xs text-slate-400 font-medium">
              <span>Spare Capacity Matched</span>
              <span className="text-blue-400 font-bold">{current.capacity}</span>
            </div>
            <div className="h-3 rounded-full bg-slate-800 overflow-hidden p-0.5">
              <div className="h-full rounded-full bg-gradient-to-r from-blue-500 to-emerald-400 w-3/4 animate-pulse" />
            </div>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3 text-center">
          <div className="bg-slate-800/50 p-3 rounded-xl border border-slate-800">
            <div className="text-xs text-slate-400 font-semibold">Distance</div>
            <div className="text-sm font-bold text-white mt-0.5">{current.dist}</div>
          </div>
          <div className="bg-slate-800/50 p-3 rounded-xl border border-slate-800">
            <div className="text-xs text-slate-400 font-semibold">Transit ETA</div>
            <div className="text-sm font-bold text-white mt-0.5">{current.time}</div>
          </div>
          <div className="bg-slate-800/50 p-3 rounded-xl border border-slate-800">
            <div className="text-xs text-slate-400 font-semibold">CO₂ Offset</div>
            <div className="text-sm font-bold text-emerald-400 mt-0.5">240 kg</div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Landing() {
  const navigate = useNavigate();
  const [tripsPerMonth, setTripsPerMonth] = useState(6);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans selection:bg-blue-600 selection:text-white">
      {/* Top Header Navigation */}
      <header className="sticky top-0 z-50 bg-slate-950/80 backdrop-blur-xl border-b border-slate-800/80">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 h-16 flex items-center justify-between">
          <Logo dark />
          <nav className="hidden md:flex items-center gap-6 text-xs font-bold text-slate-400" aria-label="Landing Navigation">
            <a href="#how" className="hover:text-white transition">How It Works</a>
            <a href="#calculator" className="hover:text-white transition">Backhaul Calculator</a>
            <a href="#owners" className="hover:text-white transition">For Fleet Owners</a>
            <a href="#smes" className="hover:text-white transition">For SME Shippers</a>
          </nav>
          <div className="flex items-center gap-3">
            <Link to="/login">
              <Button variant="ghost" className="!text-slate-300 hover:!text-white hover:!bg-slate-800 !text-xs !font-bold">
                Sign In
              </Button>
            </Link>
            <Link to="/login">
              <Button className="!bg-blue-600 hover:!bg-blue-500 !text-white !text-xs !font-bold shadow-lg shadow-blue-600/20">
                Quick Demo Access
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative overflow-hidden pt-16 sm:pt-24 pb-20 max-w-7xl mx-auto px-4 sm:px-6">
        {/* Glow Spheres */}
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-blue-600/10 rounded-full blur-[120px] pointer-events-none" />

        <div className="grid lg:grid-cols-12 gap-12 items-center">
          <div className="lg:col-span-6 space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-bold">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Smart Backhaul & Partial Cargo Matching Engine</span>
            </div>

            <h1 className="text-4xl sm:text-6xl font-black text-white tracking-tight leading-[1.1]">
              Make Every <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-emerald-400">Return Leg</span> Earn Revenue.
            </h1>

            <p className="text-slate-400 text-base sm:text-lg leading-relaxed max-w-xl font-normal">
              We don't search for new trucks — we pair partial SME freight with verified trucks <span className="text-slate-200 font-semibold">already returning empty on the exact same route</span>.
            </p>

            <div className="flex flex-wrap items-center gap-4 pt-2">
              <Button
                onClick={() => navigate("/login")}
                className="!bg-blue-600 hover:!bg-blue-500 !text-white !py-3.5 !px-6 !rounded-2xl !font-bold shadow-xl shadow-blue-600/25 flex items-center gap-2"
              >
                <span>Ship Freight / Find Return Cargo</span>
                <ArrowRight className="w-4 h-4" />
              </Button>
            </div>

            {/* Impact Pill */}
            <div className="p-4 rounded-2xl bg-slate-900/90 border border-slate-800/90 text-xs text-slate-400 flex items-start gap-3">
              <BarChart3 className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
              <div>
                <span className="font-bold text-slate-200">NITI Aayog Freight Benchmark:</span> Up to <span className="text-white font-bold">43% of truck kilometres</span> in India run empty. REDO eliminates this deadhaul waste.
              </div>
            </div>
          </div>

          <div className="lg:col-span-6">
            <InteractiveRouteSimulator />
          </div>
        </div>
      </section>

      {/* Interactive Backhaul ROI Calculator */}
      <section id="calculator" className="py-16 bg-slate-900/60 border-y border-slate-800/80">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="max-w-3xl mx-auto text-center space-y-3 mb-10">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold">
              <Calculator className="w-3.5 h-3.5" />
              <span>Backhaul Earnings Calculator</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-white">How much can your fleet earn?</h2>
            <p className="text-sm text-slate-400">Estimate extra monthly revenue generated by filling empty return trips with REDO.</p>
          </div>

          <div className="max-w-xl mx-auto bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 space-y-6">
            <div>
              <div className="flex justify-between items-center text-xs font-bold text-slate-300 mb-2">
                <span>Monthly Return Legs:</span>
                <span className="text-blue-400 text-base font-extrabold">{tripsPerMonth} Trips / month</span>
              </div>
              <input
                type="range"
                min="1"
                max="25"
                value={tripsPerMonth}
                onChange={(e) => setTripsPerMonth(Number(e.target.value))}
                className="w-full accent-blue-600 bg-slate-800 h-2 rounded-lg cursor-pointer"
              />
            </div>

            <div className="grid grid-cols-2 gap-4 pt-2">
              <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800">
                <div className="text-xs text-slate-400 font-semibold">Extra Monthly Revenue</div>
                <div className="text-2xl font-black text-emerald-400 mt-1">₹{(tripsPerMonth * 14200).toLocaleString()}</div>
              </div>
              <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800">
                <div className="text-xs text-slate-400 font-semibold">CO₂ Emissions Saved</div>
                <div className="text-2xl font-black text-blue-400 mt-1">{(tripsPerMonth * 0.38).toFixed(1)} Tonnes</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How it Works Grid */}
      <section id="how" className="py-20 max-w-7xl mx-auto px-4 sm:px-6">
        <div className="text-center space-y-3 mb-14">
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white">How REDO Backhaul Works</h2>
          <p className="text-sm text-slate-400 max-w-lg mx-auto">Three seamless steps to match unused truck capacity with partial SME cargo.</p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {[
            {
              num: "01",
              title: "Post Trip / Cargo",
              desc: "Truck owners list empty return legs with spare tonnage capacity. SMEs list 1–5 tonne partial shipments.",
              icon: Truck,
            },
            {
              num: "02",
              title: "ML Match & Rank",
              desc: "Hard route & timing filters narrow candidates; ML algorithms score and rank top cost-effective matches.",
              icon: Route,
            },
            {
              num: "03",
              title: "Deliver & Trust",
              desc: "Digital OTP pickup, real-time GPS tracking, electronic proof of delivery (e-POD), and green impact reporting.",
              icon: ShieldCheck,
            },
          ].map((item) => {
            const Icon = item.icon;
            return (
              <div key={item.num} className="bg-slate-900/80 border border-slate-800 p-8 rounded-3xl relative hover:border-slate-700 transition">
                <div className="text-4xl font-black text-slate-800 mb-4">{item.num}</div>
                <div className="w-12 h-12 rounded-2xl bg-blue-600/10 border border-blue-500/20 text-blue-400 flex items-center justify-center mb-5">
                  <Icon className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold text-white mb-2">{item.title}</h3>
                <p className="text-xs text-slate-400 leading-relaxed">{item.desc}</p>
              </div>
            );
          })}
        </div>
      </section>

      {/* Role Comparison */}
      <section className="py-16 max-w-7xl mx-auto px-4 sm:px-6 grid lg:grid-cols-2 gap-8">
        <div id="owners" className="bg-slate-900 border border-slate-800 rounded-3xl p-8 space-y-6">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-emerald-500/10 text-emerald-400">
              <Truck className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-white">For Fleet & Truck Owners</h3>
              <p className="text-xs text-slate-400">Monetize empty return trips</p>
            </div>
          </div>
          <ul className="space-y-3 text-xs text-slate-300 font-medium">
            <li className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-emerald-400" /> Earn up to ₹18,000 extra per return leg</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-emerald-400" /> Guaranteed partial load payouts & fast escrow</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-emerald-400" /> Flexible departure times & capacity controls</li>
          </ul>
          <Button onClick={() => navigate("/login")} className="w-full !bg-emerald-600 hover:!bg-emerald-500 !text-white !font-bold">
            Sign In as Fleet Owner
          </Button>
        </div>

        <div id="smes" className="bg-slate-900 border border-slate-800 rounded-3xl p-8 space-y-6">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-blue-500/10 text-blue-400">
              <PackageCheck className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-white">For SME Shippers</h3>
              <p className="text-xs text-slate-400">Ship sub-tonne freight affordably</p>
            </div>
          </div>
          <ul className="space-y-3 text-xs text-slate-300 font-medium">
            <li className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-blue-400" /> Pay only for your cargo weight, not full truck</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-blue-400" /> Verified truck drivers & GPS live tracking</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-blue-400" /> Automated digital proof of delivery (e-POD)</li>
          </ul>
          <Button onClick={() => navigate("/login")} className="w-full !bg-blue-600 hover:!bg-blue-500 !text-white !font-bold">
            Sign In as SME Shipper
          </Button>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-800/80 py-8 bg-slate-950">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 flex flex-wrap items-center justify-between gap-4 text-xs text-slate-500">
          <span>REDO Commercial Backhaul Platform · Match. Consolidate. Track. Optimize.</span>
          <span>Built for Smart India Hackathon</span>
        </div>
      </footer>
    </div>
  );
}

