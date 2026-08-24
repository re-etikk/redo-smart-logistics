import { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../components/Layout";
import {
  PackageCheck, ArrowRight, Calendar, Sparkles, MapPin, Scale, Clock,
  ShieldCheck, Upload, Camera, Check, Box, Truck, Zap, Info, X
} from "lucide-react";
import { postNewCargo } from "../lib/cargoStore";
import { searchLocations, estimateHighwayDistance, estimateFairPrice, type LocationHub } from "../lib/locationService";
import { useAuth } from "../hooks/useAuth";

export default function PostCargo() {
  const navigate = useNavigate();
  const { session, profile } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Form State
  const [origin, setOrigin] = useState("Delhi NCR (Okhla Industrial Area)");
  const [destination, setDestination] = useState("Mumbai (Bhiwandi Logistics Park)");
  const [cargoType, setCargoType] = useState("Automotive Components & Spare Parts");
  const [weightTons, setWeightTons] = useState("4.5");
  const [truckRequired, setTruckRequired] = useState("17-19 Feet Closed Container");
  const [pickupDate, setPickupDate] = useState("Today, 04:00 PM");
  const [urgency, setUrgency] = useState<"Immediate Dispatch" | "High Priority" | "Standard Delivery">("Immediate Dispatch");
  const [cargoPhoto, setCargoPhoto] = useState<string>("");
  const [cargoPhotoName, setCargoPhotoName] = useState<string>("");
  const [specialInstructions, setSpecialInstructions] = useState("");

  // Location suggestions
  const [originSuggestions, setOriginSuggestions] = useState<LocationHub[]>([]);
  const [destSuggestions, setDestSuggestions] = useState<LocationHub[]>([]);
  const [showOriginDrop, setShowOriginDrop] = useState(false);
  const [showDestDrop, setShowDestDrop] = useState(false);

  // Calculation
  const { distanceKm, transitHours } = estimateHighwayDistance(origin, destination);
  const estPrice = estimateFairPrice(distanceKm, parseFloat(weightTons) || 1);

  const handleOriginChange = (val: string) => {
    setOrigin(val);
    setOriginSuggestions(searchLocations(val));
    setShowOriginDrop(true);
  };

  const handleDestChange = (val: string) => {
    setDestination(val);
    setDestSuggestions(searchLocations(val));
    setShowDestDrop(true);
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setCargoPhotoName(file.name);
    const reader = new FileReader();
    reader.onload = (event) => {
      if (event.target?.result) {
        setCargoPhoto(event.target.result as string);
      }
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const newCargo = postNewCargo({
      origin,
      destination,
      cargoType,
      weightTons: parseFloat(weightTons) || 1,
      truckRequired,
      distanceKm,
      pickupDate,
      offeredPriceInr: estPrice,
      shipperName: profile?.full_name || session?.user?.user_metadata?.full_name || "Ritik Logistics",
      shipperPhone: profile?.phone || "+91 98765 43210",
      shipperEmail: session?.user?.email || "customer@redo.app",
      urgency,
      cargoPhotoUrl: cargoPhoto || undefined,
      specialInstructions: specialInstructions || undefined,
    });

    // Navigate to recommendations with new cargo ID
    navigate(`/recommendations?cargoId=${newCargo.id}`);
  };

  return (
    <Layout>
      <div className="max-w-3xl mx-auto space-y-6 py-4">
        {/* Title Header */}
        <div className="space-y-1.5">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 border border-amber-300 dark:border-amber-700 text-xs font-black">
            <PackageCheck size={14} className="text-amber-600" />
            <span>Backhaul Freight Consignment</span>
          </div>
          <h1 className="text-3xl font-black text-slate-950 dark:text-white tracking-tight">
            Post Cargo Consignment
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Enter your cargo details to immediately match with verified returning trucks on this corridor.
          </p>
        </div>

        {/* Main Post Form */}
        <form onSubmit={handleSubmit} className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 sm:p-8 shadow-sm space-y-6 text-xs font-bold text-slate-900 dark:text-white">
          
          {/* Corridor Pickup & Drop */}
          <div className="grid sm:grid-cols-2 gap-4 relative">
            {/* Origin */}
            <div className="relative">
              <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                <MapPin size={12} className="text-emerald-500" /> Pickup Origin Hub *
              </label>
              <input
                required
                value={origin}
                onChange={(e) => handleOriginChange(e.target.value)}
                onFocus={() => setShowOriginDrop(true)}
                placeholder="Type Indian City or Logistics Hub"
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
              {showOriginDrop && originSuggestions.length > 0 && (
                <div className="absolute top-full left-0 right-0 mt-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-xl z-20 max-h-48 overflow-y-auto py-1">
                  {originSuggestions.map((h, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => {
                        setOrigin(h.name);
                        setShowOriginDrop(false);
                      }}
                      className="w-full text-left px-3.5 py-2 hover:bg-amber-100 dark:hover:bg-slate-700 flex items-center justify-between"
                    >
                      <span>{h.name}</span>
                      <span className="text-[10px] text-slate-400">{h.hub}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Destination */}
            <div className="relative">
              <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                <MapPin size={12} className="text-rose-500" /> Delivery Destination Hub *
              </label>
              <input
                required
                value={destination}
                onChange={(e) => handleDestChange(e.target.value)}
                onFocus={() => setShowDestDrop(true)}
                placeholder="Type Indian City or Delivery Destination"
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
              {showDestDrop && destSuggestions.length > 0 && (
                <div className="absolute top-full left-0 right-0 mt-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-xl z-20 max-h-48 overflow-y-auto py-1">
                  {destSuggestions.map((h, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => {
                        setDestination(h.name);
                        setShowDestDrop(false);
                      }}
                      className="w-full text-left px-3.5 py-2 hover:bg-amber-100 dark:hover:bg-slate-700 flex items-center justify-between"
                    >
                      <span>{h.name}</span>
                      <span className="text-[10px] text-slate-400">{h.hub}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Highway Corridor Details Badge */}
          <div className="p-3.5 bg-amber-500/10 border border-amber-400/40 rounded-2xl flex items-center justify-between">
            <div className="flex items-center gap-2 text-slate-800 dark:text-slate-200">
              <Truck size={16} className="text-amber-500" />
              <span>Corridor Distance: <strong>{distanceKm} km</strong></span>
              <span>•</span>
              <span>Estimated Transit: <strong>~{transitHours} hrs</strong></span>
            </div>
            <span className="text-emerald-700 dark:text-emerald-400 font-black">
              Save up to 35% on Empty Return Backhauls
            </span>
          </div>

          {/* Cargo Type & Weight */}
          <div className="grid sm:grid-cols-3 gap-4">
            <div>
              <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                <Box size={12} /> Goods / Cargo Commodity *
              </label>
              <input
                required
                value={cargoType}
                onChange={(e) => setCargoType(e.target.value)}
                placeholder="e.g. FMCG, Electronics, Textiles"
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
              />
            </div>

            <div>
              <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                <Scale size={12} /> Cargo Weight (Tons) *
              </label>
              <input
                type="number"
                step="0.1"
                min="0.5"
                max="35"
                required
                value={weightTons}
                onChange={(e) => setWeightTons(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
              />
            </div>

            <div>
              <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                <Truck size={12} /> Vehicle Body Preferred
              </label>
              <select
                value={truckRequired}
                onChange={(e) => setTruckRequired(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
              >
                <option>17-19 Feet Closed Container</option>
                <option>14 Feet Open Body</option>
                <option>Mahindra Bolero Pickup</option>
                <option>32 Feet Multi-Axle Container</option>
                <option>20 Feet Flatbed Container</option>
              </select>
            </div>
          </div>

          {/* Schedule & Priority */}
          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                <Calendar size={12} /> Pickup Schedule Date &amp; Time *
              </label>
              <input
                required
                value={pickupDate}
                onChange={(e) => setPickupDate(e.target.value)}
                placeholder="e.g. Today 04:00 PM or Tomorrow Morning"
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
              />
            </div>

            <div>
              <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                <Zap size={12} /> Dispatch Priority
              </label>
              <select
                value={urgency}
                onChange={(e) => setUrgency(e.target.value as any)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
              >
                <option>Immediate Dispatch</option>
                <option>High Priority</option>
                <option>Standard Delivery</option>
              </select>
            </div>
          </div>

          {/* Real Cargo Photo Upload (Optional) */}
          <div>
            <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
              <Camera size={12} className="text-amber-500" /> Upload Consignment Photo (Optional — Shows real photo to truck owner)
            </label>
            <input
              type="file"
              ref={fileInputRef}
              onChange={handlePhotoUpload}
              accept="image/*"
              className="hidden"
            />
            {cargoPhoto ? (
              <div className="relative rounded-2xl overflow-hidden border border-amber-400 max-h-48 flex items-center justify-center bg-slate-900">
                <img src={cargoPhoto} alt="Cargo Preview" className="h-44 object-contain" />
                <button
                  type="button"
                  onClick={() => { setCargoPhoto(""); setCargoPhotoName(""); }}
                  className="absolute top-2 right-2 bg-rose-600 text-white p-1.5 rounded-full"
                >
                  <X size={14} />
                </button>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="w-full p-5 border-2 border-dashed border-slate-200 dark:border-slate-700 hover:border-amber-400 rounded-2xl flex flex-col items-center justify-center gap-1 bg-slate-50 dark:bg-slate-800/40 cursor-pointer transition"
              >
                <Upload size={20} className="text-amber-500" />
                <span className="font-bold">Click to Upload Cargo Photo or Take Picture</span>
                <span className="text-[10px] text-slate-400">Truck owners will see this actual consignment image</span>
              </button>
            )}
          </div>

          {/* Pricing & Rate Preview */}
          <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 flex items-center justify-between">
            <div>
              <span className="text-[10px] uppercase text-slate-400 block">Estimated Fair Freight</span>
              <span className="text-2xl font-black text-slate-900 dark:text-white">
                ₹{estPrice.toLocaleString("en-IN")}
              </span>
              <span className="text-[10px] text-emerald-600 dark:text-emerald-400 block">
                Includes toll, driver allowance &amp; goods transit insurance
              </span>
            </div>

            <button
              type="submit"
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-3 rounded-2xl shadow-md transition text-xs flex items-center gap-2 cursor-pointer"
            >
              <span>Post Consignment &amp; Match Trucks</span>
              <ArrowRight size={16} />
            </button>
          </div>
        </form>
      </div>
    </Layout>
  );
}
