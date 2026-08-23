import { Link } from "react-router-dom";
import Logo from "../components/Logo";
import {
  ArrowRight,
  ShieldCheck,
  Zap,
  MapPin,
  TrendingDown,
  Clock,
  Truck,
  CheckCircle2,
  PhoneCall,
} from "lucide-react";

export default function Landing() {
  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 font-sans selection:bg-amber-400">
      {/* Navbar */}
      <header className="sticky top-0 z-30 bg-white/90 backdrop-blur border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <Logo />
          <div className="flex items-center gap-3">
            <Link
              to="/login"
              className="text-xs font-bold text-slate-700 hover:text-slate-900 px-4 py-2 rounded-xl transition"
            >
              Sign In
            </Link>
            <Link
              to="/signup"
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-4 py-2.5 rounded-xl shadow-sm transition"
            >
              Create Account
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-16 md:py-24 px-6 text-center max-w-5xl mx-auto space-y-8">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-100/80 border border-amber-300 text-amber-900 text-xs font-bold shadow-sm">
          <Zap size={14} className="text-amber-600 fill-amber-500" />
          <span>India&apos;s Fastest Intercity Logistics Booking Platform</span>
        </div>

        <h1 className="text-4xl md:text-6xl font-black tracking-tight text-slate-950 leading-[1.15]">
          Book Verified Trucks in Minutes, <br />
          <span className="text-amber-500 underline decoration-amber-300 underline-offset-8">
            Ship Freight Stress-Free.
          </span>
        </h1>

        <p className="text-base md:text-lg text-slate-600 max-w-2xl mx-auto font-medium">
          Instant transparent pricing, AI route optimization, and live GPS tracking for businesses, factories, and individual shippers across 500+ Indian cities.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
          <Link
            to="/book"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-sm px-8 py-3.5 rounded-2xl shadow-lg hover:shadow-xl transition transform hover:-translate-y-0.5"
          >
            <span>Book a Truck Now</span>
            <ArrowRight size={18} />
          </Link>
          <Link
            to="/rate-card"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-white hover:bg-slate-50 text-slate-800 border border-slate-300 font-bold text-sm px-8 py-3.5 rounded-2xl shadow-sm transition"
          >
            <span>Check Rate Card</span>
          </Link>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 pt-12 max-w-4xl mx-auto">
          {[
            { label: "Verified Trucks", value: "25,000+" },
            { label: "Pan-India Pin Codes", value: "19,000+" },
            { label: "Average Dispatch", value: "< 15 Mins" },
            { label: "Cost Savings", value: "Up to 22%" },
          ].map((stat, i) => (
            <div key={i} className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm text-center">
              <div className="text-2xl md:text-3xl font-black text-slate-900">{stat.value}</div>
              <div className="text-xs font-semibold text-slate-500 mt-1">{stat.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-16 bg-white border-y border-slate-200 px-6">
        <div className="max-w-6xl mx-auto space-y-12">
          <div className="text-center space-y-2">
            <h2 className="text-2xl md:text-3xl font-black text-slate-900">
              Why Shippers Choose REDO
            </h2>
            <p className="text-sm text-slate-500">Built for modern businesses with strict deadlines</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[
              {
                icon: ShieldCheck,
                color: "bg-emerald-50 text-emerald-600",
                title: "100% Verified Drivers & Fleets",
                desc: "All vehicles & drivers are verified with Aadhaar, DL, RC, Fitness, and comprehensive insurance checks.",
              },
              {
                icon: TrendingDown,
                color: "bg-amber-50 text-amber-600",
                title: "Dynamic Smart Pricing",
                desc: "Transparent spot pricing without broker commissions. Pay only for the tonnage and distance you need.",
              },
              {
                icon: Clock,
                color: "bg-blue-50 text-blue-600",
                title: "Live GPS & Milestone Alerts",
                desc: "Track your goods round the clock with live maps, digital POD uploads, and instant WhatsApp updates.",
              },
            ].map((f, i) => (
              <div key={i} className="p-6 rounded-3xl bg-slate-50 border border-slate-200/80 space-y-4 hover:shadow-md transition">
                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${f.color}`}>
                  <f.icon size={24} />
                </div>
                <h3 className="text-base font-black text-slate-900">{f.title}</h3>
                <p className="text-xs text-slate-600 leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-16 px-6 max-w-5xl mx-auto space-y-12">
        <div className="text-center space-y-2">
          <h2 className="text-2xl md:text-3xl font-black text-slate-900">How to Book in 3 Steps</h2>
          <p className="text-sm text-slate-500">From booking to delivery in minutes</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
          <div className="space-y-3">
            <div className="w-10 h-10 rounded-full bg-amber-400 text-slate-950 font-black text-base flex items-center justify-center mx-auto shadow-sm">
              1
            </div>
            <h4 className="font-black text-sm text-slate-900">Enter Pickup & Destination</h4>
            <p className="text-xs text-slate-600">Select city, cargo type, and weight requirement.</p>
          </div>
          <div className="space-y-3">
            <div className="w-10 h-10 rounded-full bg-amber-400 text-slate-950 font-black text-base flex items-center justify-center mx-auto shadow-sm">
              2
            </div>
            <h4 className="font-black text-sm text-slate-900">Choose Verified Truck</h4>
            <p className="text-xs text-slate-600">Review instant pricing, driver ratings, and vehicle sizes.</p>
          </div>
          <div className="space-y-3">
            <div className="w-10 h-10 rounded-full bg-amber-400 text-slate-950 font-black text-base flex items-center justify-center mx-auto shadow-sm">
              3
            </div>
            <h4 className="font-black text-sm text-slate-900">Track & Pay Securely</h4>
            <p className="text-xs text-slate-600">Monitor trip on live map. Pay only upon verified delivery.</p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-950 text-white py-12 px-6">
        <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6 border-b border-slate-800 pb-8">
          <div>
            <div className="font-black text-2xl tracking-tight text-white flex items-center gap-2">
              <span>redo</span>
              <span className="text-amber-400 text-xs px-2 py-0.5 rounded bg-amber-400/10 border border-amber-400/30">
                CUSTOMER
              </span>
            </div>
            <p className="text-xs text-slate-400 mt-2">
              Next-generation freight logistics across India.
            </p>
          </div>

          <div className="flex items-center gap-6 text-xs font-semibold text-slate-300">
            <Link to="/book" className="hover:text-amber-400 transition">Book Shipment</Link>
            <Link to="/rate-card" className="hover:text-amber-400 transition">Rate Card</Link>
            <Link to="/support" className="hover:text-amber-400 transition">24/7 Support</Link>
            <Link to="/login" className="hover:text-amber-400 transition">Login</Link>
          </div>
        </div>

        <div className="max-w-6xl mx-auto pt-6 text-center text-xs text-slate-500">
          © {new Date().getFullYear()} REDO Transport & Logistics. All rights reserved.
        </div>
      </footer>
    </div>
  );
}
