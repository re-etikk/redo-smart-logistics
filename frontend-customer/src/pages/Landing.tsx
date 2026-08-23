import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  ArrowRight, ShieldCheck, Zap, MapPin, Clock, Truck, CheckCircle2,
  FileText, Route, Radio, ArrowUpRight, ChevronRight, Menu, X, Star
} from "lucide-react";
import Logo from "../components/Logo";

export default function CustomerLanding() {
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
            <Link to="/">
              <Logo />
            </Link>

            {/* Desktop Nav Links */}
            <nav className="hidden md:flex items-center gap-7 text-xs font-bold text-slate-600">
              <Link to="/" className="text-amber-500 font-black relative py-1 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-amber-400">
                Home
              </Link>
              <a href="#how-it-works" className="hover:text-slate-900 transition">How It Works</a>
              <a href="#services" className="hover:text-slate-900 transition">Services</a>
              <a href="#pricing" className="hover:text-slate-900 transition">Pricing</a>
              <a href="#about" className="hover:text-slate-900 transition">About Us</a>
              <a href="#support" className="hover:text-slate-900 transition">Support</a>
            </nav>
          </div>

          {/* Right Action Buttons */}
          <div className="hidden sm:flex items-center gap-3">
            <Link
              to="/login"
              className="text-xs font-bold text-slate-700 hover:text-slate-950 px-4 py-2 rounded-xl transition"
            >
              Sign In
            </Link>
            <Link
              to="/signup"
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-5 py-2.5 rounded-full shadow-sm hover:shadow-md transition"
            >
              Create Account
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
            <a href="#services" onClick={() => setMobileMenuOpen(false)} className="block text-slate-600">Services</a>
            <a href="#pricing" onClick={() => setMobileMenuOpen(false)} className="block text-slate-600">Pricing</a>
            <div className="pt-3 border-t border-slate-100 flex gap-3">
              <Link to="/login" className="w-1/2 text-center py-2 font-bold border border-slate-200 rounded-xl">Sign In</Link>
              <Link to="/signup" className="w-1/2 text-center py-2 font-black bg-amber-400 rounded-xl">Create Account</Link>
            </div>
          </div>
        )}
      </header>

      {/* ========================================================================= */}
      {/* 2. HERO SECTION */}
      {/* ========================================================================= */}
      <section className="pt-8 pb-16 px-4 sm:px-8 max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-12 gap-10 items-center">
          
          {/* Left Column: Heading & CTAs */}
          <div className="lg:col-span-6 space-y-6">
            {/* Yellow Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-100/90 border border-amber-300/80 text-amber-900 text-xs font-bold shadow-xs">
              <Zap size={14} className="text-amber-600 fill-amber-500" />
              <span>India&apos;s Fastest Intercity Logistics Booking Platform</span>
            </div>

            {/* Main Headline */}
            <h1 className="text-3xl sm:text-5xl lg:text-5xl font-black tracking-tight text-slate-950 leading-[1.15]">
              Book Verified Trucks in Minutes,{" "}
              <span className="text-[#FBBF24]">Ship Freight Stress-Free.</span>
            </h1>

            {/* Subtitle */}
            <p className="text-sm sm:text-base text-slate-600 font-medium leading-relaxed max-w-xl">
              Instant transparent pricing, AI route optimization, and live GPS tracking for businesses, factories, and individual shippers across 500+ Indian cities.
            </p>

            {/* Action CTA Buttons */}
            <div className="flex flex-wrap items-center gap-3.5 pt-2">
              <Link
                to="/book"
                className="inline-flex items-center justify-center gap-2 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs sm:text-sm px-7 py-3.5 rounded-full shadow-md hover:shadow-lg transition transform hover:-translate-y-0.5"
              >
                <span>Book a Truck Now</span>
                <ArrowRight size={16} />
              </Link>
              <Link
                to="/rate-card"
                className="inline-flex items-center justify-center gap-2 bg-white hover:bg-slate-50 text-slate-800 border border-slate-200 font-bold text-xs sm:text-sm px-6 py-3.5 rounded-full shadow-xs transition"
              >
                <span>Check Rate Card</span>
              </Link>
            </div>

            {/* 4 Key Metric Badges */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-6">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <Truck size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">25,000+</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Verified Trucks</span>
                </div>
              </div>

              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <MapPin size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">19,000+</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Pan-India Pin Codes</span>
                </div>
              </div>

              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <Clock size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">&lt; 15 Mins</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Average Dispatch</span>
                </div>
              </div>

              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-black shrink-0">
                  <Zap size={16} />
                </div>
                <div>
                  <span className="font-black text-xs text-slate-900 block">Up to 22%</span>
                  <span className="text-[10px] text-slate-500 font-bold block">Cost Savings</span>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Hero Visual with Live Tracking Floating Card */}
          <div className="lg:col-span-6 relative flex items-center justify-center">
            <div className="relative w-full max-w-lg">
              <img
                src="/assets/customer_landing_hero.png"
                alt="REDO Verified Truck Booking"
                className="w-full h-auto object-contain rounded-3xl drop-shadow-xl"
              />
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 3. 4 FEATURE CARDS ROW */}
      {/* ========================================================================= */}
      <section className="py-10 px-4 sm:px-8 max-w-7xl mx-auto" id="services">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {/* Card 1 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3">
            <div className="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-black">
              <ShieldCheck size={20} />
            </div>
            <h3 className="font-black text-sm text-slate-900">Verified &amp; Trusted</h3>
            <p className="text-xs text-slate-500 leading-relaxed font-medium">
              All trucks and transporters are verified for safe &amp; secure deliveries with strict background checks.
            </p>
          </div>

          {/* Card 2 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3">
            <div className="w-10 h-10 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center font-black">
              <FileText size={20} />
            </div>
            <h3 className="font-black text-sm text-slate-900">Transparent Pricing</h3>
            <p className="text-xs text-slate-500 leading-relaxed font-medium">
              Get instant, all-inclusive quotes with zero hidden charges or middleman commissions.
            </p>
          </div>

          {/* Card 3 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3">
            <div className="w-10 h-10 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center font-black">
              <Route size={20} />
            </div>
            <h3 className="font-black text-sm text-slate-900">AI Route Optimization</h3>
            <p className="text-xs text-slate-500 leading-relaxed font-medium">
              Faster deliveries, optimized return backhauls, and lower logistics costs across national corridors.
            </p>
          </div>

          {/* Card 4 */}
          <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-3">
            <div className="w-10 h-10 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-black">
              <Radio size={20} />
            </div>
            <h3 className="font-black text-sm text-slate-900">Live GPS Tracking</h3>
            <p className="text-xs text-slate-500 leading-relaxed font-medium">
              Track your shipments in real-time with complete satellite telemetry and automated milestone alerts.
            </p>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 4. ENTERPRISE TRUST BAR AT BOTTOM */}
      {/* ========================================================================= */}
      <footer className="py-12 border-t border-slate-100 bg-[#FAF9F5] px-4 sm:px-8 text-center space-y-6">
        <p className="text-xs font-bold text-slate-500 uppercase tracking-wider">
          Powering logistics for thousands of businesses and individuals across India.
        </p>

        <div className="flex flex-wrap items-center justify-center gap-8 sm:gap-12 opacity-70 grayscale hover:grayscale-0 transition">
          <span className="font-black text-lg tracking-widest text-slate-800">TATA</span>
          <span className="font-bold text-base text-slate-800 flex items-center gap-1">
            <span className="text-rose-600 font-serif text-xl">ap</span> asianpaints
          </span>
          <span className="font-extrabold text-base text-slate-800">
            Dalmia <span className="text-[10px] block font-normal text-slate-500">Bharat Cement</span>
          </span>
          <span className="font-serif italic font-black text-lg text-slate-800">Godrej</span>
          <span className="font-black text-sm text-slate-800 tracking-wider">
            JK LAKSHMI <span className="text-[9px] block font-normal">CEMENT</span>
          </span>
          <span className="font-serif font-black text-base text-slate-800">WIPRO</span>
          <span className="font-serif font-bold text-base text-slate-800">PATANJALI</span>
        </div>
      </footer>
    </div>
  );
}
