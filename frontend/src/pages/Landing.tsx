import { useState, useRef, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import {
  BadgeCheck, CalendarCheck, Clock, MapPin, Navigation, ShieldCheck,
  Tag, Truck, Users, Package, User, Menu, X, ChevronDown, Check, Sparkles
} from "lucide-react";
import Logo from "../components/Logo";
import { Card } from "../components/ui";

interface LocationItem {
  city: string;
  state: string;
  hub: string;
  type: string;
}

const POPULAR_LOCATIONS: LocationItem[] = [
  { city: "Delhi NCR", state: "DL", hub: "Sanjay Gandhi Transport Nagar Hub", type: "Major Hub" },
  { city: "Delhi NCR", state: "DL", hub: "Okhla Industrial Area Phase 3", type: "Industrial Zone" },
  { city: "Delhi NCR", state: "DL", hub: "IGI Airport Cargo Terminal (DEL)", type: "Air Cargo Hub" },
  { city: "Mumbai", state: "MH", hub: "Bhiwandi Logistics & Freight Park", type: "Major Hub" },
  { city: "Mumbai", state: "MH", hub: "Bandra Kurla Complex (BKC)", type: "Commercial District" },
  { city: "Mumbai", state: "MH", hub: "Navi Mumbai APMC Market Hub", type: "Wholesale Market" },
  { city: "Bengaluru", state: "KA", hub: "Peenya Industrial Freight Terminal", type: "Industrial Zone" },
  { city: "Bengaluru", state: "KA", hub: "Whitefield Export Logistics Park", type: "Tech & Logistics" },
  { city: "Bengaluru", state: "KA", hub: "Nelamangala Highway Cargo Hub", type: "Highway Hub" },
  { city: "Hyderabad", state: "TG", hub: "Autonagar Heavy Freight Hub", type: "Major Hub" },
  { city: "Hyderabad", state: "TG", hub: "HITEC City Logistics Node", type: "Tech District" },
  { city: "Hyderabad", state: "TG", hub: "Shamshabad Air Cargo Zone", type: "Air Hub" },
  { city: "Chennai", state: "TN", hub: "Sriperumbudur Industrial Corridor", type: "Automotive Hub" },
  { city: "Chennai", state: "TN", hub: "Madhavaram Heavy Truck Terminal", type: "Major Hub" },
  { city: "Kolkata", state: "WB", hub: "Dankuni Freight Transport Hub", type: "East Freight Hub" },
  { city: "Kolkata", state: "WB", hub: "Howrah Railway Goods Yard", type: "Rail & Road Hub" },
  { city: "Pune", state: "MH", hub: "Chakan Industrial MIDC Area", type: "Auto & Heavy Hub" },
  { city: "Pune", state: "MH", hub: "Hinjewadi Logistics Park", type: "Commercial" },
  { city: "Ahmedabad", state: "GJ", hub: "Sanand Industrial Logistics Zone", type: "Industrial Park" },
  { city: "Ahmedabad", state: "GJ", hub: "Changodar Highway Freight Terminal", type: "Highway Hub" },
  { city: "Jaipur", state: "RJ", hub: "VKIA Transport Nagar", type: "North West Hub" },
  { city: "Lucknow", state: "UP", hub: "Amausi Transport Nagar Hub", type: "Central UP Hub" },
  { city: "Surat", state: "GJ", hub: "Kadodara Textile Freight Hub", type: "Textile Hub" },
  { city: "Nagpur", state: "MH", hub: "MIHAN Multi-Modal Hub", type: "National Center" },
  { city: "Indore", state: "MP", hub: "Pithampur Industrial Corridor", type: "MP Freight Zone" }
];

const TRUCK_TYPES = [
  { name: "Mini Truck", capacity: "1.5 Ton", desc: "Best for intra-city light goods", icon: "🚚" },
  { name: "Pickup", capacity: "2.0 Ton", desc: "Open/Closed body for fast delivery", icon: "🛻" },
  { name: "14 Feet", capacity: "5.0 Ton", desc: "Medium commercial vehicle (MCV)", icon: "🚛" },
  { name: "17 Feet", capacity: "7.0 Ton", desc: "Ideal for inter-city industrial goods", icon: "🚛" },
  { name: "19 Feet", capacity: "10.0 Ton", desc: "Heavy capacity container truck", icon: "🚚" },
  { name: "24 Feet", capacity: "15.0 Ton", desc: "Multi-axle heavy transport", icon: "🚛" },
  { name: "32 Feet", capacity: "21.0 Ton", desc: "XL Container truck for bulk cargo", icon: "🚛" },
];

const LOAD_TYPES = [
  { name: "Full Truck Load (FTL)", badge: "Dedicated", desc: "Book the entire container for your exclusive cargo" },
  { name: "Part Load (LTL / Backhaul)", badge: "Up to 40% Off", desc: "Pay only for used capacity on empty return trips" },
];

function HeroTruckGraphic() {
  return (
    <div className="relative w-full max-w-lg aspect-[4/3] rounded-3xl overflow-hidden bg-gradient-to-b from-amber-50/80 via-white to-amber-100/60 p-4 flex flex-col justify-between border border-amber-200/60 shadow-xl">
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-4 right-12 w-10 h-10 text-[#FFC800] drop-shadow-md">
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
          </svg>
        </div>
        <div className="absolute bottom-16 inset-x-0 h-24 opacity-15 flex items-end justify-around px-4">
          <div className="w-8 h-20 bg-slate-900 rounded-t-sm"></div>
          <div className="w-12 h-28 bg-slate-900 rounded-t-sm"></div>
          <div className="w-10 h-16 bg-slate-900 rounded-t-sm"></div>
          <div className="w-16 h-24 bg-slate-900 rounded-t-sm"></div>
          <div className="w-14 h-32 bg-slate-900 rounded-t-sm"></div>
        </div>
      </div>

      <div className="relative z-10 flex items-center justify-between">
        <div className="bg-white/90 backdrop-blur border border-slate-200/80 rounded-full px-3 py-1 shadow-sm flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
          <span className="text-[10px] font-black text-slate-900 uppercase tracking-wider">25,000+ Verified Trucks</span>
        </div>
      </div>

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

          <ellipse cx="300" cy="275" rx="270" ry="18" fill="#0F172A" opacity="0.25" />

          <rect x="50" y="50" width="340" height="175" rx="8" fill="url(#containerGrad)" stroke="#CBD5E1" strokeWidth="2" />
          {[90, 130, 170, 210, 250, 290, 330, 370].map((x) => (
            <line key={x} x1={x} y1="52" x2={x} y2="223" stroke="#E2E8F0" strokeWidth="1.5" />
          ))}

          <rect x="50" y="210" width="340" height="15" fill="#FFC800" />

          <g transform="translate(90, 95)">
            <path d="M0 45 L18 5 H33 C42 5 48 11 45 20 C42 27 35 30 28 30 L38 45 H28 L20 30 H16 L10 45 H0 Z" fill="#0F172A" />
            <path d="M14 12 L20 0 H28 L22 12 H14 Z" fill="#FFC800" />
            
            <text x="56" y="38" fill="#0F172A" fontSize="42" fontFamily="sans-serif" fontWeight="900" letterSpacing="-1">
              redo
            </text>
            <text x="56" y="54" fill="#64748B" fontSize="12" fontFamily="sans-serif" fontWeight="800" letterSpacing="2">
              TRANSPORT &amp; LOGISTICS
            </text>
          </g>

          <path d="M390 90 L460 90 Q495 90 510 135 L525 180 Q530 200 530 225 H390 V90 Z" fill="url(#cabinGrad)" stroke="#94A3B8" strokeWidth="2" />
          <path d="M440 100 L480 100 Q498 100 508 135 L514 150 H440 V100 Z" fill="#1E293B" />
          <rect x="430" y="115" width="8" height="25" rx="3" fill="#0F172A" />

          <rect x="480" y="165" width="45" height="50" rx="4" fill="#0F172A" />
          <line x1="485" y1="175" x2="520" y2="175" stroke="#475569" strokeWidth="2" />
          <line x1="485" y1="185" x2="520" y2="185" stroke="#475569" strokeWidth="2" />
          <line x1="485" y1="195" x2="520" y2="195" stroke="#475569" strokeWidth="2" />

          <rect x="485" y="202" width="35" height="10" rx="2" fill="#FFC800" />
          <text x="487" y="210" fill="#0F172A" fontSize="7" fontFamily="sans-serif" fontWeight="900">REDO 2026</text>

          <circle cx="522" cy="180" r="7" fill="#FEF08A" stroke="#EAB308" strokeWidth="2" />

          <circle cx="120" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="120" cy="245" r="14" fill="#94A3B8" />

          <circle cx="180" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="180" cy="245" r="14" fill="#94A3B8" />

          <circle cx="310" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="310" cy="245" r="14" fill="#94A3B8" />

          <circle cx="450" cy="245" r="28" fill="#0F172A" stroke="#334155" strokeWidth="4" />
          <circle cx="450" cy="245" r="14" fill="#94A3B8" />
        </svg>
      </div>

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
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Locations state
  const [fromLoc, setFromLoc] = useState("Delhi NCR, DL (Sanjay Gandhi Hub)");
  const [toLoc, setToLoc] = useState("Mumbai, MH (Bhiwandi Park)");
  const [showFromDropdown, setShowFromDropdown] = useState(false);
  const [showToDropdown, setShowToDropdown] = useState(false);
  const [fromFilter, setFromFilter] = useState("");
  const [toFilter, setToFilter] = useState("");

  // Truck & Load Selectors state
  const [selectedTruck, setSelectedTruck] = useState(TRUCK_TYPES[3]); // 17 Feet
  const [selectedLoad, setSelectedLoad] = useState(LOAD_TYPES[0]); // FTL
  const [showTruckModal, setShowTruckModal] = useState(false);
  const [showLoadModal, setShowLoadModal] = useState(false);

  // Date Picker state
  const todayStr = new Date().toISOString().split("T")[0];
  const [dateVal, setDateVal] = useState(todayStr);
  const [datePreset, setDatePreset] = useState("Today");
  const [showDateModal, setShowDateModal] = useState(false);

  const fromRef = useRef<HTMLDivElement>(null);
  const toRef = useRef<HTMLDivElement>(null);

  // Close dropdowns on outside click
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (fromRef.current && !fromRef.current.contains(e.target as Node)) {
        setShowFromDropdown(false);
      }
      if (toRef.current && !toRef.current.contains(e.target as Node)) {
        setShowToDropdown(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const filteredFromLocations = POPULAR_LOCATIONS.filter(
    (item) =>
      item.city.toLowerCase().includes(fromFilter.toLowerCase()) ||
      item.hub.toLowerCase().includes(fromFilter.toLowerCase()) ||
      item.state.toLowerCase().includes(fromFilter.toLowerCase())
  );

  const filteredToLocations = POPULAR_LOCATIONS.filter(
    (item) =>
      item.city.toLowerCase().includes(toFilter.toLowerCase()) ||
      item.hub.toLowerCase().includes(toFilter.toLowerCase()) ||
      item.state.toLowerCase().includes(toFilter.toLowerCase())
  );

  const handleUseCurrentLocation = (isFrom: boolean) => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const locStr = `Delhi NCR (GPS: ${pos.coords.latitude.toFixed(2)}, ${pos.coords.longitude.toFixed(2)})`;
          if (isFrom) {
            setFromLoc(locStr);
            setShowFromDropdown(false);
          } else {
            setToLoc(locStr);
            setShowToDropdown(false);
          }
        },
        () => {
          const locStr = isFrom ? "Delhi NCR, DL (Current Location)" : "Mumbai, MH (Current Location)";
          if (isFrom) {
            setFromLoc(locStr);
            setShowFromDropdown(false);
          } else {
            setToLoc(locStr);
            setShowToDropdown(false);
          }
        }
      );
    }
  };

  const handlePresetDate = (type: "today" | "tomorrow" | "dayAfter") => {
    const d = new Date();
    if (type === "tomorrow") d.setDate(d.getDate() + 1);
    if (type === "dayAfter") d.setDate(d.getDate() + 2);
    
    const formatted = d.toISOString().split("T")[0];
    setDateVal(formatted);
    setDatePreset(type === "today" ? "Today" : type === "tomorrow" ? "Tomorrow" : "Day After");
    setShowDateModal(false);
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    navigate(`/book?from=${encodeURIComponent(fromLoc)}&to=${encodeURIComponent(toLoc)}&type=${encodeURIComponent(selectedTruck.name)}&load=${encodeURIComponent(selectedLoad.name)}&date=${dateVal}`);
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
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="lg:hidden text-slate-900 p-2 rounded-xl hover:bg-slate-100 transition border border-slate-200"
              aria-label="Toggle Mobile Menu"
            >
              {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </div>
      </header>

      {/* Slide-out Mobile Menu Drawer */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 lg:hidden flex justify-end">
          <div className="fixed inset-0 bg-slate-950/40 backdrop-blur-sm" onClick={() => setMobileMenuOpen(false)}></div>
          <div className="relative w-72 bg-white h-full shadow-2xl p-6 flex flex-col justify-between border-l border-slate-200 z-10 animate-in slide-in-from-right duration-200">
            <div className="space-y-6">
              <div className="flex items-center justify-between border-b border-slate-100 pb-4">
                <Logo />
                <button onClick={() => setMobileMenuOpen(false)} className="text-slate-400 hover:text-slate-600 p-1">
                  <X size={20} />
                </button>
              </div>

              <nav className="flex flex-col gap-3 font-bold text-xs text-slate-700">
                <a href="#book" onClick={() => setMobileMenuOpen(false)} className="px-3 py-2 rounded-xl bg-amber-50 text-slate-950 border border-amber-200">Home</a>
                <a href="#book" onClick={() => setMobileMenuOpen(false)} className="px-3 py-2 rounded-xl hover:bg-slate-50">Book a Truck</a>
                <Link to="/shipments" onClick={() => setMobileMenuOpen(false)} className="px-3 py-2 rounded-xl hover:bg-slate-50">My Bookings</Link>
                <Link to="/shipments" onClick={() => setMobileMenuOpen(false)} className="px-3 py-2 rounded-xl hover:bg-slate-50">Live Tracking</Link>
                <Link to="/rate-card" onClick={() => setMobileMenuOpen(false)} className="px-3 py-2 rounded-xl hover:bg-slate-50">Services &amp; Pricing</Link>
                <Link to="/support" onClick={() => setMobileMenuOpen(false)} className="px-3 py-2 rounded-xl hover:bg-slate-50">Customer Support</Link>
              </nav>
            </div>

            <div className="space-y-3 pt-6 border-t border-slate-100">
              <button
                onClick={() => { setMobileMenuOpen(false); navigate("/login"); }}
                className="w-full rounded-xl bg-[#FFC800] hover:bg-amber-400 text-slate-950 py-3 text-xs font-black shadow-md flex items-center justify-center gap-2"
              >
                <User size={14} /> Login / Register Account
              </button>
              <p className="text-[10px] text-center text-slate-400">REDO — Smart Transport Platform</p>
            </div>
          </div>
        </div>
      )}

      {/* Hero Section */}
      <section className="relative max-w-7xl mx-auto px-6 pt-8 pb-12 grid gap-8 lg:grid-cols-[380px_1fr] items-center">
        
        {/* Left Search Widget (Mockup 1 Exact Custom Elements) */}
        <Card id="book" className="p-6 bg-white border border-slate-200/80 rounded-3xl shadow-xl space-y-4 relative z-20">
          <div>
            <h2 className="font-black text-slate-900 text-lg tracking-tight">Book an Empty Truck</h2>
            <p className="text-xs text-slate-500 mt-0.5">Find &amp; book backhaul empty trucks in seconds</p>
          </div>

          <form onSubmit={handleSearch} className="space-y-3">
            
            {/* 1. Rapido-Style FROM Location Field with Live Autocomplete */}
            <div className="relative space-y-1" ref={fromRef}>
              <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 focus-within:ring-2 focus-within:ring-amber-400 transition">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-400 shrink-0 mr-2.5 shadow-sm"></span>
                <div className="flex-1">
                  <label className="block text-[9px] font-black text-slate-400 uppercase tracking-wider">FROM (PICKUP)</label>
                  <input
                    type="text"
                    value={fromLoc}
                    onChange={(e) => {
                      setFromLoc(e.target.value);
                      setFromFilter(e.target.value);
                      setShowFromDropdown(true);
                    }}
                    onFocus={() => {
                      setFromFilter("");
                      setShowFromDropdown(true);
                    }}
                    placeholder="Search pickup city or transport hub"
                    className="w-full bg-transparent text-xs font-bold text-slate-900 focus:outline-none placeholder-slate-400 truncate"
                  />
                </div>
                <button
                  type="button"
                  onClick={() => handleUseCurrentLocation(true)}
                  title="Use Current GPS Location"
                  className="text-slate-400 hover:text-amber-600 p-1.5 hover:bg-amber-100/60 rounded-lg transition"
                >
                  <Navigation size={14} className="text-amber-600" />
                </button>
              </div>

              {/* Rapido-Style Location Suggestion Popup */}
              {showFromDropdown && (
                <div className="absolute left-0 right-0 top-full mt-1 bg-white border border-slate-200 rounded-2xl shadow-2xl z-40 max-h-64 overflow-y-auto py-2 space-y-1 divide-y divide-slate-100 animate-in fade-in slide-in-from-top-2 duration-150">
                  {/* GPS Option */}
                  <div
                    onClick={() => handleUseCurrentLocation(true)}
                    className="px-3.5 py-2 hover:bg-amber-50 cursor-pointer flex items-center gap-3 text-xs font-bold text-slate-900"
                  >
                    <div className="w-7 h-7 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center shrink-0">
                      <Navigation size={13} />
                    </div>
                    <div>
                      <span className="block text-slate-900 font-extrabold text-xs">Use Current GPS Location</span>
                      <span className="block text-[10px] text-slate-500 font-normal">Auto-detect via browser GPS</span>
                    </div>
                  </div>

                  {/* Filtered Cities / Hubs */}
                  {filteredFromLocations.map((item, idx) => (
                    <div
                      key={idx}
                      onClick={() => {
                        setFromLoc(`${item.city}, ${item.state} (${item.hub})`);
                        setShowFromDropdown(false);
                      }}
                      className="px-3.5 py-2.5 hover:bg-amber-50 cursor-pointer flex items-center justify-between text-xs transition"
                    >
                      <div className="flex items-start gap-2.5 min-w-0">
                        <div className="w-7 h-7 rounded-full bg-slate-100 text-slate-600 flex items-center justify-center shrink-0 mt-0.5">
                          <MapPin size={13} className="text-amber-500" />
                        </div>
                        <div className="min-w-0">
                          <span className="block font-black text-slate-900 text-xs truncate">
                            {item.city}, <span className="text-slate-500 font-semibold">{item.state}</span>
                          </span>
                          <span className="block text-[10px] text-slate-500 font-medium truncate">{item.hub}</span>
                        </div>
                      </div>
                      <span className="text-[9px] font-bold uppercase tracking-wider text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md shrink-0">
                        {item.type}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* 2. Rapido-Style TO Location Field */}
            <div className="relative space-y-1" ref={toRef}>
              <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 focus-within:ring-2 focus-within:ring-amber-400 transition">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0 mr-2.5 shadow-sm"></span>
                <div className="flex-1">
                  <label className="block text-[9px] font-black text-slate-400 uppercase tracking-wider">TO (DELIVERY)</label>
                  <input
                    type="text"
                    value={toLoc}
                    onChange={(e) => {
                      setToLoc(e.target.value);
                      setToFilter(e.target.value);
                      setShowToDropdown(true);
                    }}
                    onFocus={() => {
                      setToFilter("");
                      setShowToDropdown(true);
                    }}
                    placeholder="Search delivery city or freight hub"
                    className="w-full bg-transparent text-xs font-bold text-slate-900 focus:outline-none placeholder-slate-400 truncate"
                  />
                </div>
                <span className="text-slate-400 p-1"><MapPin size={14} className="text-emerald-500" /></span>
              </div>

              {/* Delivery Location Suggestion Popup */}
              {showToDropdown && (
                <div className="absolute left-0 right-0 top-full mt-1 bg-white border border-slate-200 rounded-2xl shadow-2xl z-40 max-h-64 overflow-y-auto py-2 space-y-1 divide-y divide-slate-100 animate-in fade-in slide-in-from-top-2 duration-150">
                  <div
                    onClick={() => handleUseCurrentLocation(false)}
                    className="px-3.5 py-2 hover:bg-emerald-50 cursor-pointer flex items-center gap-3 text-xs font-bold text-slate-900"
                  >
                    <div className="w-7 h-7 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center shrink-0">
                      <Navigation size={13} />
                    </div>
                    <div>
                      <span className="block text-slate-900 font-extrabold text-xs">Use Current GPS Location</span>
                      <span className="block text-[10px] text-slate-500 font-normal">Auto-detect delivery destination</span>
                    </div>
                  </div>

                  {filteredToLocations.map((item, idx) => (
                    <div
                      key={idx}
                      onClick={() => {
                        setToLoc(`${item.city}, ${item.state} (${item.hub})`);
                        setShowToDropdown(false);
                      }}
                      className="px-3.5 py-2.5 hover:bg-emerald-50 cursor-pointer flex items-center justify-between text-xs transition"
                    >
                      <div className="flex items-start gap-2.5 min-w-0">
                        <div className="w-7 h-7 rounded-full bg-slate-100 text-slate-600 flex items-center justify-center shrink-0 mt-0.5">
                          <MapPin size={13} className="text-emerald-500" />
                        </div>
                        <div className="min-w-0">
                          <span className="block font-black text-slate-900 text-xs truncate">
                            {item.city}, <span className="text-slate-500 font-semibold">{item.state}</span>
                          </span>
                          <span className="block text-[10px] text-slate-500 font-medium truncate">{item.hub}</span>
                        </div>
                      </div>
                      <span className="text-[9px] font-bold uppercase tracking-wider text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md shrink-0">
                        {item.type}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* 3. Theme Custom TRUCK TYPE Selector */}
            <div className="relative">
              <div
                onClick={() => setShowTruckModal(!showTruckModal)}
                className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 cursor-pointer hover:bg-slate-100/80 transition"
              >
                <div className="flex items-center gap-2.5 flex-1 min-w-0">
                  <span className="text-base">{selectedTruck.icon}</span>
                  <div className="flex-1 min-w-0">
                    <label className="block text-[9px] font-black text-slate-400 uppercase tracking-wider">TRUCK TYPE</label>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-black text-slate-900 truncate">{selectedTruck.name}</span>
                      <span className="text-[10px] font-extrabold text-amber-900 bg-amber-200/80 px-2 py-0.5 rounded-md shrink-0">
                        {selectedTruck.capacity}
                      </span>
                    </div>
                  </div>
                </div>
                <ChevronDown size={16} className={`text-slate-400 transition-transform duration-200 ${showTruckModal ? "rotate-180" : ""}`} />
              </div>

              {/* Custom Truck Type Picker Modal Dropdown */}
              {showTruckModal && (
                <div className="absolute left-0 right-0 top-full mt-1 bg-white border border-slate-200 rounded-2xl shadow-2xl z-40 p-2 space-y-1 animate-in fade-in slide-in-from-top-2 duration-150">
                  <div className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-3 py-1">Select Truck Fleet Spec</div>
                  {TRUCK_TYPES.map((t) => (
                    <div
                      key={t.name}
                      onClick={() => {
                        setSelectedTruck(t);
                        setShowTruckModal(false);
                      }}
                      className={`p-2.5 rounded-xl cursor-pointer transition flex items-center justify-between ${
                        selectedTruck.name === t.name
                          ? "bg-amber-100/90 border border-amber-300 shadow-sm"
                          : "hover:bg-slate-50"
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <span className="text-xl">{t.icon}</span>
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-extrabold text-xs text-slate-900">{t.name}</span>
                            <span className="text-[10px] font-extrabold text-amber-900 bg-amber-200 px-1.5 py-0.5 rounded">
                              {t.capacity}
                            </span>
                          </div>
                          <span className="block text-[10px] text-slate-500">{t.desc}</span>
                        </div>
                      </div>
                      {selectedTruck.name === t.name && <Check size={16} className="text-amber-900 font-bold" />}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* 4. Theme Custom LOAD TYPE Selector */}
            <div className="relative">
              <div
                onClick={() => setShowLoadModal(!showLoadModal)}
                className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 cursor-pointer hover:bg-slate-100/80 transition"
              >
                <div className="flex items-center gap-2.5 flex-1 min-w-0">
                  <Package size={16} className="text-amber-500 shrink-0" />
                  <div className="flex-1 min-w-0">
                    <label className="block text-[9px] font-black text-slate-400 uppercase tracking-wider">LOAD TYPE</label>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-black text-slate-900 truncate">{selectedLoad.name}</span>
                      <span className="text-[9px] font-bold text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded-md shrink-0">
                        {selectedLoad.badge}
                      </span>
                    </div>
                  </div>
                </div>
                <ChevronDown size={16} className={`text-slate-400 transition-transform duration-200 ${showLoadModal ? "rotate-180" : ""}`} />
              </div>

              {/* Custom Load Type Dropdown Modal */}
              {showLoadModal && (
                <div className="absolute left-0 right-0 top-full mt-1 bg-white border border-slate-200 rounded-2xl shadow-2xl z-40 p-2 space-y-1 animate-in fade-in slide-in-from-top-2 duration-150">
                  <div className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-3 py-1">Select Load Option</div>
                  {LOAD_TYPES.map((l) => (
                    <div
                      key={l.name}
                      onClick={() => {
                        setSelectedLoad(l);
                        setShowLoadModal(false);
                      }}
                      className={`p-2.5 rounded-xl cursor-pointer transition flex items-center justify-between ${
                        selectedLoad.name === l.name
                          ? "bg-amber-100/90 border border-amber-300 shadow-sm"
                          : "hover:bg-slate-50"
                      }`}
                    >
                      <div className="space-y-0.5">
                        <div className="flex items-center gap-2">
                          <span className="font-extrabold text-xs text-slate-900">{l.name}</span>
                          <span className="text-[9px] font-bold text-emerald-800 bg-emerald-100 px-1.5 py-0.5 rounded">
                            {l.badge}
                          </span>
                        </div>
                        <span className="block text-[10px] text-slate-500">{l.desc}</span>
                      </div>
                      {selectedLoad.name === l.name && <Check size={16} className="text-amber-900 font-bold" />}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* 5. Theme Custom WHEN (DATE) Picker */}
            <div className="relative">
              <div
                onClick={() => setShowDateModal(!showDateModal)}
                className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 cursor-pointer hover:bg-slate-100/80 transition"
              >
                <div className="flex items-center gap-2.5 flex-1 min-w-0">
                  <CalendarCheck size={16} className="text-amber-500 shrink-0" />
                  <div className="flex-1 min-w-0">
                    <label className="block text-[9px] font-black text-slate-400 uppercase tracking-wider">WHEN (PICKUP DATE)</label>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-black text-slate-900">{datePreset}</span>
                      <span className="text-[10px] font-semibold text-slate-500">({dateVal})</span>
                    </div>
                  </div>
                </div>
                <Sparkles size={14} className="text-amber-500" />
              </div>

              {/* Custom Theme Date Picker Dropdown */}
              {showDateModal && (
                <div className="absolute left-0 right-0 top-full mt-1 bg-white border border-slate-200 rounded-2xl shadow-2xl z-40 p-3 space-y-3 animate-in fade-in slide-in-from-top-2 duration-150">
                  <div className="text-[10px] font-black text-slate-400 uppercase tracking-wider">Quick Select Date</div>
                  
                  {/* Quick Chips */}
                  <div className="grid grid-cols-3 gap-2">
                    <button
                      type="button"
                      onClick={() => handlePresetDate("today")}
                      className={`py-2 text-xs font-extrabold rounded-xl border transition ${
                        datePreset === "Today"
                          ? "bg-[#FFC800] text-slate-950 border-amber-400 shadow-sm"
                          : "bg-slate-50 text-slate-700 hover:bg-amber-50 border-slate-200"
                      }`}
                    >
                      Today
                    </button>
                    <button
                      type="button"
                      onClick={() => handlePresetDate("tomorrow")}
                      className={`py-2 text-xs font-extrabold rounded-xl border transition ${
                        datePreset === "Tomorrow"
                          ? "bg-[#FFC800] text-slate-950 border-amber-400 shadow-sm"
                          : "bg-slate-50 text-slate-700 hover:bg-amber-50 border-slate-200"
                      }`}
                    >
                      Tomorrow
                    </button>
                    <button
                      type="button"
                      onClick={() => handlePresetDate("dayAfter")}
                      className={`py-2 text-xs font-extrabold rounded-xl border transition ${
                        datePreset === "Day After"
                          ? "bg-[#FFC800] text-slate-950 border-amber-400 shadow-sm"
                          : "bg-slate-50 text-slate-700 hover:bg-amber-50 border-slate-200"
                      }`}
                    >
                      Day After
                    </button>
                  </div>

                  <div className="pt-2 border-t border-slate-100">
                    <label className="block text-[10px] font-bold text-slate-500 mb-1">Pick Specific Calendar Date:</label>
                    <input
                      type="date"
                      value={dateVal}
                      min={todayStr}
                      onChange={(e) => {
                        setDateVal(e.target.value);
                        setDatePreset("Custom Date");
                        setShowDateModal(false);
                      }}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                    />
                  </div>
                </div>
              )}
            </div>

            <button
              type="submit"
              className="mt-3 w-full rounded-xl bg-[#FFC800] hover:bg-amber-400 text-slate-950 py-3 font-black text-sm transition shadow-md flex items-center justify-center gap-2"
            >
              Search Empty Trucks
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
                  <h4 className="font-bold text-xs text-slate-900">Verified &amp; Trusted</h4>
                  <p className="text-[10px] text-slate-500">100% verified truck owners</p>
                </div>
              </div>

              <div className="space-y-2">
                <div className="w-10 h-10 rounded-full bg-amber-100 text-slate-950 flex items-center justify-center font-bold">
                  <Tag size={20} className="text-amber-600" />
                </div>
                <div>
                  <h4 className="font-bold text-xs text-slate-900">Best Prices</h4>
                  <p className="text-[10px] text-slate-500">Compare &amp; book at best prices</p>
                </div>
              </div>

              <div className="space-y-2">
                <div className="w-10 h-10 rounded-full bg-amber-100 text-slate-950 flex items-center justify-center font-bold">
                  <Clock size={20} className="text-amber-600" />
                </div>
                <div>
                  <h4 className="font-bold text-xs text-slate-900">Quick &amp; Easy</h4>
                  <p className="text-[10px] text-slate-500">Book in just a few clicks</p>
                </div>
              </div>
            </div>
          </div>

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
