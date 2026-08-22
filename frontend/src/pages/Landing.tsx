import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import {
  BadgeCheck, CalendarCheck, Clock, MapPin, Navigation, ShieldCheck,
  Tag, Truck, Users, Package, User, Menu
} from "lucide-react";
import Logo from "../components/Logo";
import { Card } from "../components/ui";

const POPULAR_INDIAN_CITIES = [
  "Delhi, DL", "Mumbai, MH", "Bengaluru, KA", "Hyderabad, TG", "Chennai, TN",
  "Kolkata, WB", "Pune, MH", "Ahmedabad, GJ", "Jaipur, RJ", "Lucknow, UP",
  "Surat, GJ", "Kanpur, UP", "Nagpur, MH", "Indore, MP", "Thane, MH",
  "Bhopal, MP", "Visakhapatnam, AP", "Patna, BR", "Vadodara, GJ", "Ghaziabad, UP",
  "Ludhiana, PB", "Agra, UP", "Nashik, MH", "Faridabad, HR", "Meerut, UP",
  "Rajkot, GJ", "Varanasi, UP", "Amritsar, PB", "Navi Mumbai, MH", "Coimbatore, TN"
];

function HeroTruckGraphic() {
  return (
    <div className="relative w-full max-w-lg aspect-[4/3] rounded-3xl overflow-hidden bg-gradient-to-b from-amber-50/80 via-white to-amber-100/60 p-4 flex flex-col justify-between border border-amber-200/60 shadow-xl">
      {/* Background City Skyline & Map Pin */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        {/* Yellow Location Pin Overhead */}
        <div className="absolute top-4 right-12 w-10 h-10 text-[#FFC800] drop-shadow-md">
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
          </svg>
        </div>
        {/* City Skyline Outline */}
        <div className="absolute bottom-16 inset-x-0 h-24 opacity-15 flex items-end justify-around px-4">
          <div className="w-8 h-20 bg-slate-900 rounded-t-sm"></div>
          <div className="w-12 h-28 bg-slate-900 rounded-t-sm"></div>
          <div className="w-10 h-16 bg-slate-900 rounded-t-sm"></div>
          <div className="w-16 h-24 bg-slate-900 rounded-t-sm"></div>
          <div className="w-14 h-32 bg-slate-900 rounded-t-sm"></div>
        </div>
      </div>

      {/* Top Badge Overlay */}
      <div className="relative z-10 flex items-center justify-between">
        <div className="bg-white/90 backdrop-blur border border-slate-200/80 rounded-full px-3 py-1 shadow-sm flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
          <span className="text-[10px] font-black text-slate-900 uppercase tracking-wider">25,000+ Verified Trucks</span>
        </div>
      </div>

      {/* Detailed SVG White Container Truck with Redo Branding */}
      <div className="relative z-10 w-full flex items-center justify-center my-auto">
        <svg viewBox="0 0 600 320" className="w-full h-auto drop-shadow-2xl overflow-visible">
          <defs>
            <linearGradient id="containerGrad" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="#FFFFFF" />
              <stop offset="100%" stopColor="#F1F5F9" />
            </linearGradient>
            <linearGradient id="cabinGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#FFFFFF" />
              <stop offset="100%" stopColor="#E2E8F0" />
            </linearGradient>
          </defs>

          {/* Shadow underneath */}
          <ellipse cx="300" cy="275" rx="270" ry="18" fill="#0F172A" opacity="0.25" />

          {/* 1. Large White Container Box */}
          <rect x="50" y="50" width="340" height="175" rx="8" fill="url(#containerGrad)" stroke="#CBD5E1" strokeWidth="2" />
          
          {/* Container Corrugation Vertical Lines */}
          {[90, 130, 170, 210, 250, 290, 330, 370].map((x) => (
            <line key={x} x1={x} y1="52" x2={x} y2="223" stroke="#E2E8F0" strokeWidth="1.5" />
          ))}

          {/* Yellow Bottom Accent Stripe on Container */}
          <rect x="50" y="210" width="340" height="15" fill="#FFC800" />

          {/* EXACT REDO LOGO ON CONTAINER SIDE */}
          <g transform="translate(90, 95)">
            {/* Redo Chevron Mark */}
            <path d="M0 45 L18 5 H33 C42 5 48 11 45 20 C42 27 35 30 28 30 L38 45 H28 L20 30 H16 L10 45 H0 Z" fill="#0F172A" />
            <path d="M14 12 L20 0 H28 L22 12 H14 Z" fill="#FFC800" />
            
            {/* Redo Text */}
            <text x="56" y="38" fill="#0F172A" fontSize="42" fontFamily="sans-serif" fontWeight="900" letterSpacing="-1">
              redo
            </text>
            <text x="56" y="54" fill="#64748B" fontSize="12" fontFamily="sans-serif" fontWeight="800" letterSpacing="2">
              TRANSPORT &amp; LOGISTICS
            </text>
          </g>

          {/* 2. Truck Cabin */}
          <path d="M390 90 L460 90 Q495 90 510 135 L525 180 Q530 200 530 225 H390 V90 Z" fill="url(#cabinGrad)" stroke="#94A3B8" strokeWidth="2" />

          {/* Windshield Glass */}
          <path d="M440 100 L480 100 Q498 100 508 135 L514 150 H440 V100 Z" fill="#1E293B" />
          
          {/* Side Mirror */}
          <rect x="430" y="115" width="8" height="25" rx="3" fill="#0F172A" />

          {/* Front Bumper & Radiator Grille */}
          <rect x="480" y="165" width="45" height="50" rx="4" fill="#0F172A" />
          <line x1="485" y1="175" x2="520" y2="175" stroke="#475569" strokeWidth="2" />
          <line x1="485" y1="185" x2="520" y2="185" stroke="#475569" strokeWidth="2" />
          <line x1="485" y1="195" x2="520" y2="195" stroke="#475569" strokeWidth="2" />

          {/* License Plate */}
          <rect x="485" y="202" width="35" height="10" rx="2" fill="#FFC800" />
          <text x="487" y="210" fill="#0F172A" fontSize="7" fontFamily="sans-serif" fontWeight="900">REDO 2026</text>

          {/* Headlights */}
          <circle cx="522" cy="180" r="7" fill="#FEF08A" stroke="#EAB308" strokeWidth="2" />

          {/* 3. Wheels */}
          {/* Rear Wheels */}
          <circle cx="120" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="120" cy="245" r="14" fill="#94A3B8" />

          <circle cx="180" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="180" cy="245" r="14" fill="#94A3B8" />

          {/* Middle Wheels */}
          <circle cx="310" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="310" cy="245" r="14" fill="#94A3B8" />

          {/* Front Wheels */}
          <circle cx="450" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="450" cy="245" r="14" fill="#94A3B8" />
        </svg>
      </div>

      {/* Yellow Curved Road Strip matching Mockup 1 */}
      <div className="relative z-10 w-full bg-white rounded-2xl p-3 shadow-lg border border-slate-200 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-[#FFC800] text-slate-950 flex items-center justify-center font-black">
            <Truck size={18} />
          </div>
          <div>
            <span className="text-xs font-black text-slate-900 block">Empty Backhaul Container Trucks</span>
            <span className="text-[10px] text-slate-500 font-medium">Verified return capacity across India</span>
          </div>
        </div>
        <div className="text-right">
          <span className="text-xs font-black text-emerald-600 block">Bharosa Wahi</span>
          <span className="text-[10px] text-amber-600 font-bold">Deal Sahi.</span>
        </div>
      </div>
    </div>
  );
}

export default function Landing() {
  const navigate = useNavigate();
  const [fromLoc, setFromLoc] = useState("Delhi, DL");
  const [toLoc, setToLoc] = useState("Mumbai, MH");
  const [truckType, setTruckType] = useState("17 Feet");
  const [loadType, setLoadType] = useState("Full Truck Load (FTL)");
  const [dateVal, setDateVal] = useState(new Date().toISOString().split("T")[0]);

  const [fromSuggestions, setFromSuggestions] = useState<string[]>([]);
  const [toSuggestions, setToSuggestions] = useState<string[]>([]);
  const [showFromDropdown, setShowFromDropdown] = useState(false);
  const [showToDropdown, setShowToDropdown] = useState(false);

  const handleFromChange = (val: string) => {
    setFromLoc(val);
    if (val.trim().length > 0) {
      const matches = POPULAR_INDIAN_CITIES.filter((c) =>
        c.toLowerCase().includes(val.toLowerCase())
      );
      setFromSuggestions(matches);
      setShowFromDropdown(true);
    } else {
      setShowFromDropdown(false);
    }
  };

  const handleToChange = (val: string) => {
    setToLoc(val);
    if (val.trim().length > 0) {
      const matches = POPULAR_INDIAN_CITIES.filter((c) =>
        c.toLowerCase().includes(val.toLowerCase())
      );
      setToSuggestions(matches);
      setShowToDropdown(true);
    } else {
      setShowToDropdown(false);
    }
  };

  const handleUseCurrentLocation = () => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setFromLoc(`Delhi NCR (GPS: ${pos.coords.latitude.toFixed(2)}, ${pos.coords.longitude.toFixed(2)})`);
        },
        () => {
          setFromLoc("Delhi, DL (Current Location)");
        }
      );
    } else {
      setFromLoc("Delhi, DL (Current Location)");
    }
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    navigate(`/book?from=${encodeURIComponent(fromLoc)}&to=${encodeURIComponent(toLoc)}&type=${encodeURIComponent(truckType)}&load=${encodeURIComponent(loadType)}&date=${dateVal}`);
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 font-sans selection:bg-amber-400">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white border-b border-slate-200/80 shadow-sm">
        <div className="mx-auto max-w-7xl px-6 h-16 flex items-center justify-between">
          <Link to="/">
            <Logo />
          </Link>
          <nav className="hidden lg:flex items-center gap-8 text-xs font-bold text-slate-700">
            <a href="#book" className="hover:text-amber-500 transition border-b-2 border-amber-400 pb-0.5">Home</a>
            <a href="#book" className="hover:text-amber-500 transition">Book a Truck</a>
            <Link to="/shipments" className="hover:text-amber-500 transition">My Bookings</Link>
            <Link to="/shipments" className="hover:text-amber-500 transition">Live Tracking</Link>
            <Link to="/rate-card" className="hover:text-amber-500 transition">Services</Link>
            <Link to="/rate-card" className="hover:text-amber-500 transition">Pricing</Link>
          </nav>
          <div className="flex items-center gap-3">
            <button
              onClick={() => navigate("/login")}
              className="rounded-xl bg-[#FFC800] hover:bg-amber-400 text-slate-950 px-5 py-2.5 text-xs font-black transition shadow-sm flex items-center gap-2"
            >
              <User size={14} /> Login / Sign Up
            </button>
            <button className="lg:hidden text-slate-700 p-2">
              <Menu size={20} />
            </button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative max-w-7xl mx-auto px-6 pt-8 pb-12 grid gap-8 lg:grid-cols-[380px_1fr] items-center">
        {/* Left Search Widget */}
        <Card id="book" className="p-6 bg-white border border-slate-200/80 rounded-3xl shadow-xl space-y-4 relative z-20">
          <div>
            <h2 className="font-black text-slate-900 text-lg tracking-tight">Book an Empty Truck</h2>
            <p className="text-xs text-slate-500 mt-0.5">Find and book the best truck for your cargo</p>
          </div>

          <form onSubmit={handleSearch} className="space-y-3">
            {/* From */}
            <div className="relative space-y-1">
              <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 focus-within:ring-2 focus-within:ring-amber-400">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-400 shrink-0 mr-2.5"></span>
                <div className="flex-1">
                  <label className="block text-[10px] font-bold text-slate-500 uppercase">From</label>
                  <input
                    type="text"
                    value={fromLoc}
                    onChange={(e) => handleFromChange(e.target.value)}
                    onFocus={() => setShowFromDropdown(true)}
                    placeholder="Enter pickup location"
                    className="w-full bg-transparent text-xs font-bold text-slate-900 focus:outline-none placeholder-slate-400"
                  />
                </div>
                <button type="button" onClick={handleUseCurrentLocation} title="Use GPS" className="text-slate-400 hover:text-amber-600 p-1">
                  <Navigation size={14} />
                </button>
              </div>

              {showFromDropdown && fromSuggestions.length > 0 && (
                <div className="absolute left-0 right-0 top-full mt-1 bg-white border border-slate-200 rounded-xl shadow-xl z-30 max-h-48 overflow-y-auto py-1">
                  {fromSuggestions.map((city) => (
                    <div
                      key={city}
                      onClick={() => {
                        setFromLoc(city);
                        setShowFromDropdown(false);
                      }}
                      className="px-3 py-2 text-xs font-medium text-slate-700 hover:bg-amber-50 hover:text-slate-950 cursor-pointer flex items-center gap-2"
                    >
                      <MapPin size={12} className="text-amber-500" /> {city}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* To */}
            <div className="relative space-y-1">
              <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 focus-within:ring-2 focus-within:ring-amber-400">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0 mr-2.5"></span>
                <div className="flex-1">
                  <label className="block text-[10px] font-bold text-slate-500 uppercase">To</label>
                  <input
                    type="text"
                    value={toLoc}
                    onChange={(e) => handleToChange(e.target.value)}
                    onFocus={() => setShowToDropdown(true)}
                    placeholder="Enter delivery location"
                    className="w-full bg-transparent text-xs font-bold text-slate-900 focus:outline-none placeholder-slate-400"
                  />
                </div>
                <span className="text-slate-400 p-1"><MapPin size={14} /></span>
              </div>

              {showToDropdown && toSuggestions.length > 0 && (
                <div className="absolute left-0 right-0 top-full mt-1 bg-white border border-slate-200 rounded-xl shadow-xl z-30 max-h-48 overflow-y-auto py-1">
                  {toSuggestions.map((city) => (
                    <div
                      key={city}
                      onClick={() => {
                        setToLoc(city);
                        setShowToDropdown(false);
                      }}
                      className="px-3 py-2 text-xs font-medium text-slate-700 hover:bg-amber-50 hover:text-slate-950 cursor-pointer flex items-center gap-2"
                    >
                      <MapPin size={12} className="text-emerald-500" /> {city}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Truck Type */}
            <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2">
              <Truck size={16} className="text-slate-500 mr-2.5" />
              <div className="flex-1">
                <label className="block text-[10px] font-bold text-slate-500 uppercase">Truck Type</label>
                <select
                  value={truckType}
                  onChange={(e) => setTruckType(e.target.value)}
                  className="w-full bg-transparent text-xs font-bold text-slate-900 focus:outline-none cursor-pointer"
                >
                  <option value="Mini Truck">Mini Truck (1.5 Ton)</option>
                  <option value="Pickup">Pickup (2 Ton)</option>
                  <option value="14 Feet">14 Feet (5 Ton)</option>
                  <option value="17 Feet">17 Feet (7 Ton)</option>
                  <option value="19 Feet">19 Feet (10 Ton)</option>
                  <option value="24 Feet">24 Feet (15 Ton)</option>
                  <option value="32 Feet">32 Feet (21 Ton)</option>
                </select>
              </div>
            </div>

            {/* Load Type */}
            <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2">
              <Package size={16} className="text-slate-500 mr-2.5" />
              <div className="flex-1">
                <label className="block text-[10px] font-bold text-slate-500 uppercase">Load Type</label>
                <select
                  value={loadType}
                  onChange={(e) => setLoadType(e.target.value)}
                  className="w-full bg-transparent text-xs font-bold text-slate-900 focus:outline-none cursor-pointer"
                >
                  <option value="Full Truck Load (FTL)">Full Truck Load (FTL)</option>
                  <option value="Part Load (LTL)">Part Load (LTL / Backhaul)</option>
                </select>
              </div>
            </div>

            {/* When */}
            <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2">
              <CalendarCheck size={16} className="text-slate-500 mr-2.5" />
              <div className="flex-1">
                <label className="block text-[10px] font-bold text-slate-500 uppercase">When</label>
                <input
                  type="date"
                  value={dateVal}
                  onChange={(e) => setDateVal(e.target.value)}
                  className="w-full bg-transparent text-xs font-bold text-slate-900 focus:outline-none"
                />
              </div>
            </div>

            <button
              type="submit"
              className="mt-2 w-full rounded-xl bg-[#FFC800] hover:bg-amber-400 text-slate-950 py-3 font-black text-sm transition shadow-md flex items-center justify-center gap-2"
            >
              Search Trucks
            </button>
          </form>
        </Card>

        {/* Hero Title & White Container Truck Graphic matching Mockup 1 */}
        <div className="flex flex-col lg:flex-row items-center justify-between gap-6 relative">
          <div className="space-y-6 max-w-xl">
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-950 tracking-tight leading-none">
              Bharosa Wahi, <br />
              <span className="text-[#FFC800]">Deal Sahi.</span>
            </h1>
            <p className="text-base text-slate-600 font-medium">
              Book empty trucks easily for your cargo across India.
            </p>

            <div className="grid grid-cols-3 gap-4 pt-2">
              <div className="space-y-2">
                <div className="w-10 h-10 rounded-full bg-amber-100 text-slate-950 flex items-center justify-center font-bold">
                  <ShieldCheck size={20} className="text-amber-600" />
                </div>
                <div>
                  <h4 className="font-bold text-xs text-slate-900">Verified & Trusted</h4>
                  <p className="text-[10px] text-slate-500">100% verified truck owners</p>
                </div>
              </div>

              <div className="space-y-2">
                <div className="w-10 h-10 rounded-full bg-amber-100 text-slate-950 flex items-center justify-center font-bold">
                  <Tag size={20} className="text-amber-600" />
                </div>
                <div>
                  <h4 className="font-bold text-xs text-slate-900">Best Prices</h4>
                  <p className="text-[10px] text-slate-500">Compare and book at best prices</p>
                </div>
              </div>

              <div className="space-y-2">
                <div className="w-10 h-10 rounded-full bg-amber-100 text-slate-950 flex items-center justify-center font-bold">
                  <Clock size={20} className="text-amber-600" />
                </div>
                <div>
                  <h4 className="font-bold text-xs text-slate-900">Quick & Easy</h4>
                  <p className="text-[10px] text-slate-500">Book in just a few clicks</p>
                </div>
              </div>
            </div>
          </div>

          {/* Render Vector White Container Truck Graphic with Redo Branding */}
          <HeroTruckGraphic />
        </div>
      </section>

      {/* Stats Bar */}
      <section className="max-w-6xl mx-auto px-6 py-4">
        <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
          <div className="flex items-center justify-center gap-3">
            <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-amber-600">
              <Users size={20} />
            </div>
            <div className="text-left">
              <span className="text-xl font-black text-slate-900 block">10K+</span>
              <span className="text-xs text-slate-500 font-semibold">Happy Customers</span>
            </div>
          </div>

          <div className="flex items-center justify-center gap-3">
            <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-amber-600">
              <Truck size={20} />
            </div>
            <div className="text-left">
              <span className="text-xl font-black text-slate-900 block">50K+</span>
              <span className="text-xs text-slate-500 font-semibold">Trips Completed</span>
            </div>
          </div>

          <div className="flex items-center justify-center gap-3">
            <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-amber-600">
              <ShieldCheck size={20} />
            </div>
            <div className="text-left">
              <span className="text-xl font-black text-slate-900 block">25K+</span>
              <span className="text-xs text-slate-500 font-semibold">Verified Trucks</span>
            </div>
          </div>

          <div className="flex items-center justify-center gap-3">
            <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-amber-600">
              <MapPin size={20} />
            </div>
            <div className="text-left">
              <span className="text-xl font-black text-slate-900 block">29+</span>
              <span className="text-xs text-slate-500 font-semibold">Cities Covered</span>
            </div>
          </div>
        </div>
      </section>

      {/* How Redo Works? */}
      <section id="how" className="max-w-6xl mx-auto px-6 py-16 text-center space-y-12">
        <div>
          <h2 className="text-2xl font-black text-slate-900 tracking-tight">How Redo Works?</h2>
          <p className="text-xs text-slate-500 mt-1">Simple 4-step process to book your truck or load</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 relative">
          <div className="space-y-3 flex flex-col items-center">
            <div className="w-14 h-14 rounded-full bg-[#FFF7D6] text-slate-900 font-black text-lg flex items-center justify-center shadow-sm border border-amber-300">
              1
            </div>
            <h3 className="font-bold text-sm text-slate-900">Enter Locations</h3>
            <p className="text-xs text-slate-500 max-w-[200px]">Add your pickup and delivery locations</p>
          </div>

          <div className="space-y-3 flex flex-col items-center">
            <div className="w-14 h-14 rounded-full bg-[#FFF7D6] text-slate-900 font-black text-lg flex items-center justify-center shadow-sm border border-amber-300">
              2
            </div>
            <h3 className="font-bold text-sm text-slate-900">Choose Truck</h3>
            <p className="text-xs text-slate-500 max-w-[200px]">Select the right truck for your cargo</p>
          </div>

          <div className="space-y-3 flex flex-col items-center">
            <div className="w-14 h-14 rounded-full bg-[#FFF7D6] text-slate-900 font-black text-lg flex items-center justify-center shadow-sm border border-amber-300">
              3
            </div>
            <h3 className="font-bold text-sm text-slate-900">Confirm Booking</h3>
            <p className="text-xs text-slate-500 max-w-[200px]">Review details and confirm your booking</p>
          </div>

          <div className="space-y-3 flex flex-col items-center">
            <div className="w-14 h-14 rounded-full bg-[#FFF7D6] text-slate-900 font-black text-lg flex items-center justify-center shadow-sm border border-amber-300">
              4
            </div>
            <h3 className="font-bold text-sm text-slate-900">Truck on the Way</h3>
            <p className="text-xs text-slate-500 max-w-[200px]">Track your truck and deliver your cargo safely</p>
          </div>
        </div>
      </section>

      {/* For Truck Owners Banner */}
      <section id="owners" className="border-t border-slate-200 bg-white py-12">
        <div className="max-w-6xl mx-auto px-6 grid gap-6 md:grid-cols-2">
          <Card className="p-6 bg-[#FAF9F6] border border-amber-200/80 rounded-3xl">
            <h3 className="text-lg font-extrabold text-slate-900">
              More Loads. <span className="text-amber-500">More Earnings.</span>
            </h3>
            <p className="mt-1 text-xs text-slate-600">List your truck, fill your empty return trips and grow your business with Redo.</p>
            <button
              onClick={() => navigate("/signup?role=truck_owner")}
              className="mt-4 rounded-xl bg-[#FFC800] hover:bg-amber-400 text-slate-950 px-5 py-2.5 text-xs font-black shadow-sm transition"
            >
              List My Truck
            </button>
          </Card>

          <Card className="p-6 bg-[#FAF9F6] border border-slate-200 rounded-3xl">
            <h3 className="text-lg font-extrabold text-slate-900">Ship cargo affordably across India</h3>
            <p className="mt-1 text-xs text-slate-600">Full load or part load? Pay only for the return capacity you use on verified trucks.</p>
            <button
              onClick={() => navigate("/signup?role=sme")}
              className="mt-4 rounded-xl border-2 border-slate-900 text-slate-900 hover:bg-slate-900 hover:text-white px-5 py-2.5 text-xs font-black transition"
            >
              Book Cargo Transport
            </button>
          </Card>
        </div>
      </section>

      <footer className="border-t border-slate-200 bg-white py-6">
        <div className="max-w-6xl mx-auto px-6 flex flex-wrap items-center justify-between gap-3 text-xs text-slate-500 font-medium">
          <span>© 2026 Redo Transport &amp; Logistics · Bharosa Wahi, Deal Sahi.</span>
          <span>Smart Logistics Platform</span>
        </div>
      </footer>
    </div>
  );
}
