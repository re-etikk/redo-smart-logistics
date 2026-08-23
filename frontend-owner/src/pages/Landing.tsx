import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  ArrowRight, ShieldCheck, Zap, MapPin, Clock, Truck, CheckCircle2,
  IndianRupee, Headphones, Play, ChevronRight, Menu, X, Star, Users, Navigation
} from "lucide-react";
import Logo from "../components/Logo";

export default function OwnerLanding() {
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-[#FDFCF9] text-slate-900 font-sans selection:bg-amber-400">
      {/* ========================================================================= */}
      {/* 1. TOP NAVBAR */}
      {/* ========================================================================= */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-100 shadow-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-8 h-20 flex items-center justify-between">
          <div className="flex items-center gap-10">
            <Link to="/" className="flex items-center gap-2">
              <Logo />
              <span className="text-amber-500 font-black text-xs uppercase tracking-widest bg-amber-50 dark:bg-amber-950/60 px-2 py-0.5 rounded-md border border-amber-300">
                OWNER
              </span>
            </Link>

            {/* Desktop Nav Links */}
            <nav className="hidden md:flex items-center gap-7 text-xs font-bold text-slate-600">
              <Link to="/" className="text-amber-500 font-black relative py-1 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-amber-400">
                Home
              </Link>
              <a href="#how-it-works" className="hover:text-slate-900 transition">How It Works</a>
              <a href="#benefits" className="hover:text-slate-900 transition">Benefits</a>
              <a href="#features" className="hover:text-slate-900 transition">Features</a>
              <a href="#pricing" className="hover:text-slate-900 transition">Pricing</a>
              <a href="#support" className="hover:text-slate-900 transition">Support</a>
              <a href="#about" className="hover:text-slate-900 transition">About Us</a>
            </nav>
          </div>

          {/* Right Action Buttons */}
          <div className="hidden sm:flex items-center gap-3">
            <Link
              to="/login"
              className="text-xs font-bold text-slate-700 hover:text-slate-950 px-4 py-2 border border-slate-200 rounded-xl transition"
            >
              Login
            </Link>
            <Link
              to="/signup"
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-5 py-2.5 rounded-full shadow-sm hover:shadow-md transition flex items-center gap-1.5"
            >
              <span>Register as Truck Owner</span>
              <ArrowRight size={14} />
            </Link>
          </div>

          {/* Mobile Hamburger */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 text-slate-700 hover:text-slate-900"
          >
            {mobileMenuOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>

        {/* Mobile Dropdown */}
        {mobileMenuOpen && (
          <div className="md:hidden bg-white border-b border-slate-200 px-6 py-4 space-y-3 text-xs font-bold shadow-lg">
            <Link to="/" onClick={() => setMobileMenuOpen(false)} className="block text-amber-500 font-black">Home</Link>
            <a href="#how-it-works" onClick={() => setMobileMenuOpen(false)} className="block text-slate-600">How It Works</a>
            <a href="#benefits" onClick={() => setMobileMenuOpen(false)} className="block text-slate-600">Benefits</a>
            <a href="#features" onClick={() => setMobileMenuOpen(false)} className="block text-slate-600">Features</a>
            <div className="pt-3 border-t border-slate-100 flex gap-3">
              <Link to="/login" className="w-1/2 text-center py-2 font-bold border border-slate-200 rounded-xl">Login</Link>
              <Link to="/signup" className="w-1/2 text-center py-2 font-black bg-amber-400 rounded-xl">Register</Link>
            </div>
          </div>
        )}
      </header>

      {/* ========================================================================= */}
      {/* 2. HERO SECTION */}
      {/* ========================================================================= */}
      <section className="pt-8 pb-16 px-4 sm:px-8 max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-12 gap-10 items-center">
          
          {/* Left Column */}
          <div className="lg:col-span-6 space-y-6">
            {/* Yellow Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-100/90 border border-amber-300/80 text-amber-900 text-xs font-bold shadow-xs">
              <Zap size={14} className="text-amber-600 fill-amber-500" />
              <span>India&apos;s Smartest Freight Platform</span>
            </div>

            {/* Main Headline */}
            <h1 className="text-3xl sm:text-5xl lg:text-5xl font-black tracking-tight text-slate-950 leading-[1.15]">
              Grow Your Trucking Business with{" "}
              <span className="text-[#FBBF24]">REDO</span>
            </h1>

            {/* Subtitle */}
            <p className="text-sm sm:text-base text-slate-600 font-medium leading-relaxed max-w-xl">
              Register your trucks, get matched with verified loads, manage your business, and earn more — all in one place.
            </p>

            {/* Action CTA Buttons */}
            <div className="flex flex-wrap items-center gap-3.5 pt-2">
              <Link
                to="/signup"
                className="inline-flex items-center justify-center gap-2 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs sm:text-sm px-7 py-3.5 rounded-full shadow-md hover:shadow-lg transition transform hover:-translate-y-0.5"
              >
                <span>Register as Truck Owner</span>
                <ArrowRight size={16} />
              </Link>
              <button
                onClick={() => navigate("/login")}
                className="inline-flex items-center justify-center gap-2 bg-white hover:bg-slate-50 text-slate-800 border border-slate-200 font-bold text-xs sm:text-sm px-6 py-3.5 rounded-full shadow-xs transition cursor-pointer"
              >
                <Play size={14} className="fill-slate-800" />
                <span>How It Works</span>
              </button>
            </div>

            {/* 4 Benefit Badges */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-6">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <Truck size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">10K+</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Truck Owners Trust REDO</span>
                </div>
              </div>

              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <ShieldCheck size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">50K+</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Loads Delivered Successfully</span>
                </div>
              </div>

              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <IndianRupee size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">Fast &amp; Secure</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Payments Direct to Bank</span>
                </div>
              </div>

              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <Headphones size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">24x7</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Support Always Here</span>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Hero Visual with Find Loads Card */}
          <div className="lg:col-span-6 relative flex items-center justify-center">
            <div className="relative w-full max-w-lg">
              <img
                src="/assets/owner_landing_hero.png"
                alt="REDO Truck Owner Fleet Platform"
                className="w-full h-auto object-contain rounded-3xl drop-shadow-xl"
              />
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 3. 4 FEATURE CARDS ROW */}
      {/* ========================================================================= */}
      <section className="py-10 px-4 sm:px-8 max-w-7xl mx-auto" id="features">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {/* Card 1 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center font-black">
                <MapPin size={20} />
              </div>
              <h3 className="font-black text-sm text-slate-900">Get Matched with Loads</h3>
              <p className="text-xs text-slate-500 leading-relaxed font-medium">
                Find high-paying loads on your preferred return routes and eliminate empty dry runs.
              </p>
            </div>
            <Link to="/login" className="text-xs font-black text-blue-600 hover:underline inline-flex items-center gap-1 pt-2">
              <span>Learn more</span>
              <ArrowRight size={13} />
            </Link>
          </div>

          {/* Card 2 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-black">
                <IndianRupee size={20} />
              </div>
              <h3 className="font-black text-sm text-slate-900">Track Earnings</h3>
              <p className="text-xs text-slate-500 leading-relaxed font-medium">
                Detailed freight insights, toll tax allowances, and complete visibility of all digital payouts.
              </p>
            </div>
            <Link to="/login" className="text-xs font-black text-emerald-600 hover:underline inline-flex items-center gap-1 pt-2">
              <span>Learn more</span>
              <ArrowRight size={13} />
            </Link>
          </div>

          {/* Card 3 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center font-black">
                <Truck size={20} />
              </div>
              <h3 className="font-black text-sm text-slate-900">Manage Fleet</h3>
              <p className="text-xs text-slate-500 leading-relaxed font-medium">
                Manage your trucks, assigned drivers and vehicle KYC documents in one unified portal.
              </p>
            </div>
            <Link to="/login" className="text-xs font-black text-purple-600 hover:underline inline-flex items-center gap-1 pt-2">
              <span>Learn more</span>
              <ArrowRight size={13} />
            </Link>
          </div>

          {/* Card 4 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-black">
                <ShieldCheck size={20} />
              </div>
              <h3 className="font-black text-sm text-slate-900">Fast Payments</h3>
              <p className="text-xs text-slate-500 leading-relaxed font-medium">
                Get paid directly into your verified bank account within 24 hours of electronic POD signoff.
              </p>
            </div>
            <Link to="/login" className="text-xs font-black text-amber-600 hover:underline inline-flex items-center gap-1 pt-2">
              <span>Learn more</span>
              <ArrowRight size={13} />
            </Link>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 4. TRUST BAR AT BOTTOM */}
      {/* ========================================================================= */}
      <footer className="py-12 border-t border-slate-100 bg-[#FAF9F5] px-4 sm:px-8">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6 text-center md:text-left">
          <div className="font-black text-sm text-slate-900">
            Trusted by Truck Owners Across India
          </div>

          <div className="flex flex-wrap items-center justify-center gap-6 sm:gap-10 text-xs font-bold text-slate-700">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center font-black">
                <Users size={14} />
              </div>
              <span><strong>10,000+</strong> Active Truck Owners</span>
            </div>

            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center font-black">
                <CheckCircle2 size={14} />
              </div>
              <span><strong>50,000+</strong> Loads Completed</span>
            </div>

            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-purple-100 text-purple-700 flex items-center justify-center font-black">
                <MapPin size={14} />
              </div>
              <span><strong>500+</strong> Cities Covered</span>
            </div>

            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-amber-100 text-amber-700 flex items-center justify-center font-black">
                <Star size={14} className="fill-amber-500 text-amber-500" />
              </div>
              <span><strong>4.8 ★</strong> Owner Rating</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
