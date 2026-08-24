import { useMemo, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import {
  Box, CheckCircle2, Clock, ShieldCheck, Truck, MapPin, Calendar, Scale,
  Zap, ArrowRight, ArrowLeft, Upload, Camera, X, Check, Phone, Info, Sparkles, Building2, User
} from "lucide-react";
import Layout from "../components/Layout";
import LocationSearchInput from "../components/LocationSearchInput";
import { useAuth } from "../hooks/useAuth";
import { postNewCargo } from "../lib/cargoStore";
import { searchLocations, estimateHighwayDistance, estimateFairPrice, type LocationHub } from "../lib/locationService";
import { useTranslation } from "../lib/i18n";

const STEPS = ["Shipment Type", "Route & Exact Address", "Cargo Details", "Review & Confirm"];

const QUICK_SLOTS = [
  { id: "immediate", label: "Immediate (Within 2 Hours)", desc: "Priority backhaul pickup", badge: "⚡ Fastest" },
  { id: "today_evening", label: "Today Evening (04:00 PM – 08:00 PM)", desc: "Same-day highway dispatch", badge: "Popular" },
  { id: "tomorrow_morning", label: "Tomorrow Morning (08:00 AM – 12:00 PM)", desc: "Standard morning loading", badge: "Economical" },
  { id: "custom", label: "Custom Date & Time", desc: "Select preferred calendar slot", badge: "Flexible" },
];

export default function BookShipment() {
  const navigate = useNavigate();
  const { session, profile } = useAuth();
  const { t } = useTranslation();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);

  // Form State
  const [shipmentType, setShipmentType] = useState<"LTL" | "FTL">("LTL");
  const [origin, setOrigin] = useState("Mumbai (Bhiwandi Logistics Park)");
  const [pickupAddress, setPickupAddress] = useState("Plot 42, Sector 58, Okhla Phase 3 Industrial Area, Near Metro, Delhi - 110020");
  const [pickupContactPerson, setPickupContactPerson] = useState("Rohan Verma");
  const [pickupContactPhone, setPickupContactPhone] = useState("+91 98765 43210");

  const [destination, setDestination] = useState("Delhi NCR (Okhla Industrial Area)");
  const [deliveryAddress, setDeliveryAddress] = useState("Gala No. 14, Indian Corporation Compound, Mankoli Naka, Bhiwandi, Maharashtra - 421302");
  const [deliveryContactPerson, setDeliveryContactPerson] = useState("Anil Deshmukh");
  const [deliveryContactPhone, setDeliveryContactPhone] = useState("+91 98220 54321");

  const [selectedSlot, setSelectedSlot] = useState("immediate");
  const [customDate, setCustomDate] = useState("");
  const [customTimeSlot, setCustomTimeSlot] = useState("Morning (08:00 AM - 12:00 PM)");
  const [urgency, setUrgency] = useState<"Immediate Dispatch" | "High Priority" | "Standard Delivery">("Immediate Dispatch");
  
  const [cargoType, setCargoType] = useState("Textiles & Garments");
  const [cargoWeightTons, setCargoWeightTons] = useState("2.5");
  const [truckRequired, setTruckRequired] = useState("17-19 Feet Closed Container");
  const [cargoPhoto, setCargoPhoto] = useState<string>("");
  const [specialHandling, setSpecialHandling] = useState<string[]>(["Fragile Cargo", "Waterproof Tarp"]);

  // Location suggestions
  const [originSuggestions, setOriginSuggestions] = useState<LocationHub[]>([]);
  const [destSuggestions, setDestSuggestions] = useState<LocationHub[]>([]);
  const [showOriginDrop, setShowOriginDrop] = useState(false);
  const [showDestDrop, setShowDestDrop] = useState(false);

  // Distance & Price Calculation
  const { distanceKm, transitHours } = estimateHighwayDistance(origin, destination);
  const estFreightInr = estimateFairPrice(distanceKm, parseFloat(cargoWeightTons) || 1);

  // Pickup Date Formatter
  const formattedPickup = useMemo(() => {
    if (selectedSlot === "immediate") return "Today (Immediate Dispatch ~2 hrs)";
    if (selectedSlot === "today_evening") return "Today Evening (04:00 PM – 08:00 PM)";
    if (selectedSlot === "tomorrow_morning") return "Tomorrow Morning (08:00 AM – 12:00 PM)";
    return customDate ? `${customDate} • ${customTimeSlot}` : "Custom Scheduled Date";
  }, [selectedSlot, customDate, customTimeSlot]);

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
    const reader = new FileReader();
    reader.onload = (event) => {
      if (event.target?.result) {
        setCargoPhoto(event.target.result as string);
      }
    };
    reader.readAsDataURL(file);
  };

  const toggleHandling = (item: string) => {
    setSpecialHandling(prev =>
      prev.includes(item) ? prev.filter(x => x !== item) : [...prev, item]
    );
  };

  const submitBooking = () => {
    setBusy(true);

    const newCargo = postNewCargo({
      origin,
      pickupAddress,
      pickupContactPerson,
      pickupContactPhone,
      destination,
      deliveryAddress,
      deliveryContactPerson,
      deliveryContactPhone,
      cargoType,
      weightTons: parseFloat(cargoWeightTons) || 1.5,
      truckRequired,
      distanceKm,
      pickupDate: formattedPickup,
      offeredPriceInr: estFreightInr,
      shipperName: profile?.full_name || session?.user?.user_metadata?.full_name || "Enterprise Shipper",
      shipperPhone: profile?.phone || "+91 98765 43210",
      shipperEmail: session?.user?.email || "customer@redo.app",
      urgency,
      cargoPhotoUrl: cargoPhoto || undefined,
      specialInstructions: specialHandling.join(", "),
    });

    navigate(`/recommendations?cargoId=${newCargo.id}`);
  };

  return (
    <Layout>
      <div className="max-w-4xl mx-auto space-y-6 py-4 text-slate-900 dark:text-white">
        {/* Header Title */}
        <div className="space-y-1">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 border border-amber-300 dark:border-amber-700 text-xs font-black">
            <Truck size={14} className="text-amber-600" />
            <span>Commercial Freight Booking</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
            Book Commercial Freight Shipment
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Enter exact pickup warehouse and delivery details. The driver will receive the precise GPS coordinates and contact phone.
          </p>
        </div>

        {/* Stepper Progress Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            {STEPS.map((s, idx) => (
              <div key={s} className="flex items-center flex-1 last:flex-none">
                <div className="flex items-center gap-2 cursor-pointer" onClick={() => idx < step && setStep(idx)}>
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center font-black text-xs transition ${
                    idx < step
                      ? "bg-emerald-500 text-white shadow-sm"
                      : idx === step
                      ? "bg-[#FFC800] text-slate-950 shadow-sm ring-4 ring-amber-400/20"
                      : "bg-slate-100 dark:bg-slate-800 text-slate-400 border border-slate-200 dark:border-slate-700"
                  }`}>
                    {idx < step ? <Check size={14} /> : idx + 1}
                  </div>
                  <span className={`hidden sm:inline-block text-xs font-black ${
                    idx === step ? "text-slate-900 dark:text-white" : "text-slate-400"
                  }`}>
                    {s}
                  </span>
                </div>
                {idx < STEPS.length - 1 && (
                  <div className={`flex-1 h-0.5 mx-2 sm:mx-4 rounded-full ${
                    idx < step ? "bg-emerald-500" : "bg-slate-200 dark:bg-slate-800"
                  }`} />
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Form Wizard Step Contents */}
        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          {/* Main Step Form */}
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 sm:p-8 shadow-sm space-y-6">
            
            {/* ================= STEP 0: SHIPMENT TYPE ================= */}
            {step === 0 && (
              <div className="space-y-5">
                <h3 className="font-black text-base">Select Load Type</h3>
                <div className="grid sm:grid-cols-2 gap-4">
                  <div
                    onClick={() => setShipmentType("LTL")}
                    className={`p-5 rounded-2xl border-2 transition cursor-pointer space-y-2 ${
                      shipmentType === "LTL"
                        ? "border-amber-400 bg-amber-50/50 dark:bg-amber-950/30 ring-2 ring-amber-400/20"
                        : "border-slate-200 dark:border-slate-700 hover:border-slate-300"
                    }`}
                  >
                    <div className="w-10 h-10 rounded-xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                      <Box size={20} />
                    </div>
                    <h4 className="font-black text-sm">Part Load / Backhaul (LTL)</h4>
                    <p className="text-xs text-slate-500 dark:text-slate-400 font-medium leading-relaxed">
                      Share empty returning truck space. Pay only for the tonnage you use and save up to 35%.
                    </p>
                    <span className="inline-block text-[10px] font-black text-emerald-600 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-full">
                      ✓ Best for 0.5T – 10T Loads
                    </span>
                  </div>

                  <div
                    onClick={() => setShipmentType("FTL")}
                    className={`p-5 rounded-2xl border-2 transition cursor-pointer space-y-2 ${
                      shipmentType === "FTL"
                        ? "border-amber-400 bg-amber-50/50 dark:bg-amber-950/30 ring-2 ring-amber-400/20"
                        : "border-slate-200 dark:border-slate-700 hover:border-slate-300"
                    }`}
                  >
                    <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-900 flex items-center justify-center font-black">
                      <Truck size={20} />
                    </div>
                    <h4 className="font-black text-sm">Full Dedicated Truck (FTL)</h4>
                    <p className="text-xs text-slate-500 dark:text-slate-400 font-medium leading-relaxed">
                      Book the entire vehicle exclusively for your cargo with direct non-stop transit.
                    </p>
                    <span className="inline-block text-[10px] font-black text-blue-600 bg-blue-50 dark:bg-blue-950/60 px-2 py-0.5 rounded-full">
                      ✓ Complete Container Security
                    </span>
                  </div>
                </div>
              </div>
            )}

            {/* ================= STEP 1: ROUTE & EXACT ADDRESSES ================= */}
            {step === 1 && (
              <div className="space-y-6 text-xs font-bold">
                <h3 className="font-black text-base">Route Corridor &amp; Exact Warehouse Addresses</h3>

                {/* Pickup Section */}
                <div className="p-4 bg-slate-50 dark:bg-slate-800/80 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-3">
                  <div className="flex items-center gap-2 text-emerald-600 dark:text-emerald-400 font-black">
                    <MapPin size={16} />
                    <span className="uppercase tracking-wider text-[11px]">1. Origin &amp; Pickup Address</span>
                  </div>

                  <div className="relative">
                    <LocationSearchInput
                      required
                      value={origin}
                      onChange={(val, hub) => {
                        setOrigin(val);
                        if (hub?.fullAddress && !pickupAddress) {
                          setPickupAddress(hub.fullAddress);
                        }
                      }}
                      label="Pickup City / Logistics Hub *"
                      iconType="pickup"
                      placeholder="Type city, industrial area or hub (e.g. Delhi NCR, Okhla, Mumbai...)"
                    />
                  </div>

                  <div>
                    <label className="text-[10px] uppercase text-slate-400 block mb-1">Exact Warehouse / Factory Address (Shows to Driver) *</label>
                    <input
                      required
                      value={pickupAddress}
                      onChange={(e) => setPickupAddress(e.target.value)}
                      placeholder="Plot No., Factory/Shed Name, Street, Landmark, Pincode"
                      className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold"
                    />
                  </div>

                  <div className="grid sm:grid-cols-2 gap-3">
                    <div>
                      <label className="text-[10px] uppercase text-slate-400 block mb-1">Pickup Contact Person *</label>
                      <input
                        value={pickupContactPerson}
                        onChange={(e) => setPickupContactPerson(e.target.value)}
                        placeholder="e.g. Ramesh Factory Manager"
                        className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 font-bold"
                      />
                    </div>
                    <div>
                      <label className="text-[10px] uppercase text-slate-400 block mb-1">Pickup Contact Phone *</label>
                      <input
                        value={pickupContactPhone}
                        onChange={(e) => setPickupContactPhone(e.target.value)}
                        placeholder="+91 98765 43210"
                        className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 font-bold"
                      />
                    </div>
                  </div>
                </div>

                {/* Delivery Section */}
                <div className="p-4 bg-slate-50 dark:bg-slate-800/80 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-3">
                  <div className="flex items-center gap-2 text-rose-600 dark:text-rose-400 font-black">
                    <Building2 size={16} />
                    <span className="uppercase tracking-wider text-[11px]">2. Destination &amp; Delivery Address</span>
                  </div>

                  <div className="relative">
                    <LocationSearchInput
                      required
                      value={destination}
                      onChange={(val, hub) => {
                        setDestination(val);
                        if (hub?.fullAddress && !deliveryAddress) {
                          setDeliveryAddress(hub.fullAddress);
                        }
                      }}
                      label="Delivery City / Destination Hub *"
                      iconType="drop"
                      placeholder="Type destination city, port or hub (e.g. Mumbai, Bhiwandi, Surat...)"
                    />
                  </div>

                  <div>
                    <label className="text-[10px] uppercase text-slate-400 block mb-1">Exact Consignee Delivery Address (Shows to Driver) *</label>
                    <input
                      required
                      value={deliveryAddress}
                      onChange={(e) => setDeliveryAddress(e.target.value)}
                      placeholder="Gala / Shop No., Building Name, Street, Landmark, Pincode"
                      className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold"
                    />
                  </div>

                  <div className="grid sm:grid-cols-2 gap-3">
                    <div>
                      <label className="text-[10px] uppercase text-slate-400 block mb-1">Consignee Contact Person *</label>
                      <input
                        value={deliveryContactPerson}
                        onChange={(e) => setDeliveryContactPerson(e.target.value)}
                        placeholder="e.g. Anil Receiver"
                        className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 font-bold"
                      />
                    </div>
                    <div>
                      <label className="text-[10px] uppercase text-slate-400 block mb-1">Consignee Contact Phone *</label>
                      <input
                        value={deliveryContactPhone}
                        onChange={(e) => setDeliveryContactPhone(e.target.value)}
                        placeholder="+91 98220 54321"
                        className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 font-bold"
                      />
                    </div>
                  </div>
                </div>

                {/* Pickup Window Picker */}
                <div className="space-y-3 pt-2">
                  <label className="text-[10px] uppercase text-slate-400 block flex items-center gap-1">
                    <Calendar size={12} className="text-amber-500" /> Preferred Pickup Window *
                  </label>

                  <div className="grid sm:grid-cols-2 gap-3">
                    {QUICK_SLOTS.map((slot) => (
                      <div
                        key={slot.id}
                        onClick={() => setSelectedSlot(slot.id)}
                        className={`p-3.5 rounded-2xl border-2 transition cursor-pointer space-y-1 ${
                          selectedSlot === slot.id
                            ? "border-amber-400 bg-amber-50/60 dark:bg-amber-950/40"
                            : "border-slate-200 dark:border-slate-700 hover:border-slate-300"
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-black text-xs text-slate-900 dark:text-white">{slot.label}</span>
                          <span className="text-[9px] font-bold px-2 py-0.5 rounded-full bg-amber-200 dark:bg-amber-900 text-amber-900 dark:text-amber-200">
                            {slot.badge}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 dark:text-slate-400 font-normal">{slot.desc}</p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ================= STEP 2: CARGO SPECS & PHOTO ================= */}
            {step === 2 && (
              <div className="space-y-5 text-xs font-bold">
                <h3 className="font-black text-base">Cargo Details &amp; Packaging</h3>

                <div className="grid sm:grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Cargo Commodity *</label>
                    <input
                      value={cargoType}
                      onChange={(e) => setCargoType(e.target.value)}
                      placeholder="e.g. FMCG, Textiles, Electronics"
                      className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold"
                    />
                  </div>

                  <div>
                    <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Total Weight (Tons) *</label>
                    <input
                      type="number"
                      step="0.1"
                      min="0.5"
                      max="35"
                      value={cargoWeightTons}
                      onChange={(e) => setCargoWeightTons(e.target.value)}
                      className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold"
                    />
                  </div>
                </div>

                <div>
                  <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Preferred Vehicle Body</label>
                  <select
                    value={truckRequired}
                    onChange={(e) => setTruckRequired(e.target.value)}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold"
                  >
                    <option>17-19 Feet Closed Container</option>
                    <option>14 Feet Open Body</option>
                    <option>Mahindra Bolero Pickup</option>
                    <option>32 Feet Multi-Axle Container</option>
                    <option>20 Feet Flatbed Container</option>
                  </select>
                </div>

                {/* Cargo Photo Upload */}
                <div>
                  <label className="text-[10px] uppercase text-slate-400 block mb-1.5 flex items-center gap-1">
                    <Camera size={12} className="text-amber-500" /> Upload Consignment Photo (Optional — Shows to Driver)
                  </label>
                  <input
                    type="file"
                    ref={fileInputRef}
                    onChange={handlePhotoUpload}
                    accept="image/*"
                    className="hidden"
                  />
                  {cargoPhoto ? (
                    <div className="relative rounded-2xl overflow-hidden border border-amber-400 max-h-40 flex items-center justify-center bg-slate-900">
                      <img src={cargoPhoto} alt="Cargo Preview" className="h-36 object-contain" />
                      <button
                        type="button"
                        onClick={() => setCargoPhoto("")}
                        className="absolute top-2 right-2 bg-rose-600 text-white p-1.5 rounded-full"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      className="w-full p-4 border-2 border-dashed border-slate-200 dark:border-slate-700 hover:border-amber-400 rounded-2xl flex flex-col items-center justify-center gap-1 bg-slate-50 dark:bg-slate-800/40 cursor-pointer transition"
                    >
                      <Upload size={18} className="text-amber-500" />
                      <span className="font-bold">Click to Upload Cargo Photo</span>
                      <span className="text-[10px] text-slate-400">Truck driver will see this real cargo photo</span>
                    </button>
                  )}
                </div>

                {/* Special Handling Options */}
                <div>
                  <label className="text-[10px] uppercase text-slate-400 block mb-1.5">Special Handling Tags</label>
                  <div className="flex flex-wrap gap-2">
                    {["Fragile Cargo", "Waterproof Tarp", "Stackable Boxes", "Hazardous Material", "Temperature Sensitive"].map((tag) => (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => toggleHandling(tag)}
                        className={`px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
                          specialHandling.includes(tag)
                            ? "bg-amber-400 text-slate-950 font-black"
                            : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300"
                        }`}
                      >
                        {specialHandling.includes(tag) ? "✓ " : "+ "} {tag}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ================= STEP 3: REVIEW & CONFIRM ================= */}
            {step === 3 && (
              <div className="space-y-5 text-xs font-bold">
                <h3 className="font-black text-base">Review &amp; Instant Matching</h3>

                <div className="bg-slate-50 dark:bg-slate-800 p-5 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-3">
                  <div className="flex justify-between border-b border-slate-200/60 dark:border-slate-700 pb-2">
                    <span className="text-slate-400">Load Type:</span>
                    <span className="font-black text-slate-900 dark:text-white">{shipmentType === "LTL" ? "Part Load Backhaul (LTL)" : "Dedicated Truck (FTL)"}</span>
                  </div>
                  <div className="flex justify-between border-b border-slate-200/60 dark:border-slate-700 pb-2">
                    <span className="text-slate-400">Route Corridor:</span>
                    <span className="font-black text-slate-900 dark:text-white">{origin} ➔ {destination}</span>
                  </div>
                  <div className="space-y-1 border-b border-slate-200/60 dark:border-slate-700 pb-2">
                    <span className="text-slate-400 block">Exact Pickup Address:</span>
                    <p className="text-slate-900 dark:text-white font-bold">{pickupAddress}</p>
                    <p className="text-[11px] text-slate-400 font-medium">Contact: {pickupContactPerson} ({pickupContactPhone})</p>
                  </div>
                  <div className="space-y-1 border-b border-slate-200/60 dark:border-slate-700 pb-2">
                    <span className="text-slate-400 block">Exact Delivery Address:</span>
                    <p className="text-slate-900 dark:text-white font-bold">{deliveryAddress}</p>
                    <p className="text-[11px] text-slate-400 font-medium">Contact: {deliveryContactPerson} ({deliveryContactPhone})</p>
                  </div>
                  <div className="flex justify-between border-b border-slate-200/60 dark:border-slate-700 pb-2">
                    <span className="text-slate-400">Pickup Window:</span>
                    <span className="text-amber-600 dark:text-amber-400 font-black">{formattedPickup}</span>
                  </div>
                  <div className="flex justify-between border-b border-slate-200/60 dark:border-slate-700 pb-2">
                    <span className="text-slate-400">Commodity &amp; Weight:</span>
                    <span>{cargoType} • {cargoWeightTons} Tons</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Estimated Fair Freight:</span>
                    <span className="text-base font-black text-slate-900 dark:text-white">₹{estFreightInr.toLocaleString("en-IN")}</span>
                  </div>
                </div>

                <div className="p-3.5 bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-300 dark:border-emerald-700 rounded-2xl flex items-center gap-2 text-emerald-800 dark:text-emerald-300">
                  <ShieldCheck size={18} />
                  <span>100% Escrow Protection • Goods Transit Insurance Included</span>
                </div>
              </div>
            )}

            {/* Navigation Buttons */}
            <div className="flex items-center justify-between pt-4 border-t border-slate-100 dark:border-slate-800">
              {step > 0 ? (
                <button
                  type="button"
                  onClick={() => setStep(step - 1)}
                  className="px-5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-xs font-bold flex items-center gap-1.5 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800"
                >
                  <ArrowLeft size={14} /> Back
                </button>
              ) : <div />}

              {step < STEPS.length - 1 ? (
                <button
                  type="button"
                  onClick={() => setStep(step + 1)}
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition cursor-pointer"
                >
                  Continue <ArrowRight size={14} />
                </button>
              ) : (
                <button
                  type="button"
                  onClick={submitBooking}
                  disabled={busy}
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-8 py-3 rounded-2xl text-xs flex items-center gap-2 shadow-md transition cursor-pointer"
                >
                  <CheckCircle2 size={16} /> Confirm &amp; Match Trucks
                </button>
              )}
            </div>
          </div>

          {/* Right Summary Card */}
          <div className="space-y-4">
            <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-4 text-xs font-bold">
              <h3 className="font-black text-sm uppercase tracking-wider text-slate-400">Live Summary</h3>
              
              <div className="space-y-2.5">
                <div>
                  <span className="text-[10px] text-slate-400 uppercase block">Corridor</span>
                  <p className="font-black text-xs truncate">{origin.split(" ")[0]} ➔ {destination.split(" ")[0]}</p>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 uppercase block">Distance</span>
                  <p className="font-black text-xs">{distanceKm} km (~{transitHours} hrs transit)</p>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 uppercase block">Pickup Schedule</span>
                  <p className="font-black text-xs text-amber-600 dark:text-amber-400">{formattedPickup}</p>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 uppercase block">Estimated Freight</span>
                  <p className="text-xl font-black text-slate-900 dark:text-white">₹{estFreightInr.toLocaleString("en-IN")}</p>
                </div>
              </div>
            </div>

            <div className="bg-amber-50/60 dark:bg-slate-900 border border-amber-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-2 text-xs">
              <span className="font-black text-slate-900 dark:text-white block">Why REDO Logistics?</span>
              <p className="text-[11px] text-slate-500 leading-relaxed font-medium">
                Direct verified fleet matching eliminates empty backhauls and guarantees verified drivers with zero broker commission.
              </p>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
