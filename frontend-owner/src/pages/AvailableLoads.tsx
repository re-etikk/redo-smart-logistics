import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  MapPin, Weight, Search, Filter, ArrowRight, ShieldCheck, Zap,
  CheckCircle2, Clock, Truck, Box, Phone, X, Check
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";
import { getTrucks } from "../lib/truckStore";

export default function AvailableLoads() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [search, setSearch] = useState("");
  const [filterType, setFilterType] = useState("all");
  const [selectedLoad, setSelectedLoad] = useState<any | null>(null);
  const [acceptedSuccess, setAcceptedSuccess] = useState(false);

  const trucks = getTrucks();

  const availableLoadsList = [
    {
      id: "LOAD-101",
      origin: "Delhi Hub (Okhla Phase 3)",
      destination: "Mumbai (Bhiwandi Logistics Park)",
      cargoType: "Automotive Components",
      weightTons: 6.5,
      truckRequired: "17-19 Feet Closed Container",
      distanceKm: 1420,
      pickupDate: "Today, 04:00 PM",
      priceOfferInr: 24500,
      shipperName: "Hero Moto Logistics",
      urgency: "Immediate Dispatch",
      urgencyTone: "bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-400",
      shipperRating: 4.9,
      verifiedShipper: true,
      cargoPhoto: "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "LOAD-102",
      origin: "Delhi (Kundli Industrial Area)",
      destination: "Indore (Pithampur Industrial Hub)",
      cargoType: "FMCG Packaged Goods",
      weightTons: 4.8,
      truckRequired: "14-17 Feet Open/Closed",
      distanceKm: 830,
      pickupDate: "Tomorrow, 09:00 AM",
      priceOfferInr: 16800,
      shipperName: "Dabur Distribution Pvt Ltd",
      urgency: "Standard",
      urgencyTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      shipperRating: 4.8,
      verifiedShipper: true,
      cargoPhoto: "https://images.unsplash.com/photo-1553413077-190dd305871c?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "LOAD-103",
      origin: "Delhi (Nangloi Transport Nagar)",
      destination: "Lucknow (Transport Nagar)",
      cargoType: "E-Commerce Heavy Parcels",
      weightTons: 2.2,
      truckRequired: "Mahindra Bolero Pickup",
      distanceKm: 550,
      pickupDate: "Today, 06:30 PM",
      priceOfferInr: 13500,
      shipperName: "Delhivery North Hub",
      urgency: "High Priority",
      urgencyTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400",
      shipperRating: 4.9,
      verifiedShipper: true,
      cargoPhoto: "https://images.unsplash.com/photo-1578575437130-527eed3abbec?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "LOAD-104",
      origin: "Bengaluru (Peenya Industrial Area)",
      destination: "Chennai (Sriperumbudur Hub)",
      cargoType: "Industrial Machinery & Tooling",
      weightTons: 18.0,
      truckRequired: "32 Feet Multi-Axle",
      distanceKm: 340,
      pickupDate: "Tomorrow, 11:00 AM",
      priceOfferInr: 29000,
      shipperName: "L&T Heavy Engineering",
      urgency: "Standard",
      urgencyTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      shipperRating: 5.0,
      verifiedShipper: true,
      cargoPhoto: "https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "LOAD-105",
      origin: "Ahmedabad (Sanand GIDC)",
      destination: "Jaipur (VKI Industrial Area)",
      cargoType: "Textile Bales & Cotton Rolls",
      weightTons: 8.5,
      truckRequired: "19-22 Feet Truck",
      distanceKm: 670,
      pickupDate: "24 May, 08:00 AM",
      priceOfferInr: 21000,
      shipperName: "Arvind Mills Logistics",
      urgency: "Standard",
      urgencyTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400",
      shipperRating: 4.7,
      verifiedShipper: true,
      cargoPhoto: "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80",
    },
  ];

  const filteredLoads = availableLoadsList.filter((l) => {
    const matchesSearch =
      l.origin.toLowerCase().includes(search.toLowerCase()) ||
      l.destination.toLowerCase().includes(search.toLowerCase()) ||
      l.cargoType.toLowerCase().includes(search.toLowerCase());

    const matchesFilter =
      filterType === "all" ||
      (filterType === "immediate" && l.urgency.includes("Immediate")) ||
      (filterType === "heavy" && l.weightTons > 6.0);

    return matchesSearch && matchesFilter;
  });

  const handleAcceptLoad = (load: any) => {
    setSelectedLoad(load);
    setAcceptedSuccess(false);
  };

  const confirmAcceptLoad = () => {
    setAcceptedSuccess(true);
    setTimeout(() => {
      setSelectedLoad(null);
      setAcceptedSuccess(false);
      navigate("/bookings");
    }, 1500);
  };

  return (
    <OwnerLayout activeTab="loads" promoCardType="truck">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight">{t("findLoads")} (Spot Backhaul Market)</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Instant cargo matching for your return trips. Accept freight consignments with guaranteed payment.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400">
              Active Fleet: <strong className="text-amber-500">{trucks.length} Trucks Available</strong>
            </span>
          </div>
        </div>

        {/* Filter and Search Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-bold text-xs overflow-x-auto w-full md:w-auto">
            <button
              onClick={() => setFilterType("all")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                filterType === "all" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              }`}
            >
              All Available Loads ({availableLoadsList.length})
            </button>
            <button
              onClick={() => setFilterType("immediate")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                filterType === "immediate" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              }`}
            >
              <Zap size={14} className="text-rose-500" /> Immediate Dispatch
            </button>
            <button
              onClick={() => setFilterType("heavy")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                filterType === "heavy" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              }`}
            >
              Heavy Tonnage (&gt;6T)
            </button>
          </div>

          <div className="relative w-full md:w-72">
            <Search size={15} className="text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by city, cargo or type..."
              className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl pl-9 pr-3.5 py-2 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>
        </div>

        {/* Loads Grid */}
        <div className="grid grid-cols-1 gap-4">
          {filteredLoads.map((load) => (
            <div
              key={load.id}
              className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm hover:shadow-md transition flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6"
            >
              {/* Origin / Dest & Cargo */}
              <div className="flex flex-col sm:flex-row items-start gap-4 flex-1">
                <div className="w-20 h-20 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0 shadow-sm">
                  <img src={load.cargoPhoto} alt={load.cargoType} className="w-full h-full object-cover" />
                </div>

                <div className="space-y-1.5">
                  <div className="flex items-center gap-2">
                    <span className="text-[10px] font-mono text-amber-500 font-black">{load.id}</span>
                    <span className={`text-[9px] font-black px-2 py-0.5 rounded-full ${load.urgencyTone}`}>
                      {load.urgency}
                    </span>
                    <span className="text-[10px] font-bold text-slate-400">⭐ {load.shipperRating}</span>
                  </div>

                  <div className="space-y-1 text-xs font-bold">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0" />
                      <span className="text-slate-900 dark:text-white font-black">{load.origin}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-rose-500 shrink-0" />
                      <span className="text-slate-900 dark:text-white font-black">{load.destination}</span>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-500 dark:text-slate-400 pt-1">
                    <span className="flex items-center gap-1">
                      <Box size={13} className="text-amber-500" /> {load.cargoType}
                    </span>
                    <span className="flex items-center gap-1">
                      <Weight size={13} className="text-amber-500" /> {load.weightTons} Tons
                    </span>
                    <span className="flex items-center gap-1">
                      <Truck size={13} className="text-amber-500" /> {load.truckRequired}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock size={13} className="text-amber-500" /> Pickup: {load.pickupDate}
                    </span>
                  </div>
                </div>
              </div>

              {/* Price & Action Button */}
              <div className="flex items-center justify-between lg:flex-col lg:items-end gap-3 w-full lg:w-auto border-t lg:border-t-0 pt-3 lg:pt-0 border-slate-100 dark:border-slate-800">
                <div className="lg:text-right">
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Offered Rate</span>
                  <span className="text-2xl font-black text-slate-900 dark:text-white">
                    ₹{load.priceOfferInr.toLocaleString("en-IN")}
                  </span>
                  <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold block">
                    100% Escrow Guaranteed
                  </span>
                </div>

                <button
                  onClick={() => handleAcceptLoad(load)}
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer whitespace-nowrap"
                >
                  <span>Accept Load &amp; Assign Truck</span>
                  <ArrowRight size={14} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* ACCEPT LOAD ASSIGNMENT MODAL */}
      {/* ========================================================================= */}
      {selectedLoad && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <span className="text-[10px] font-mono text-amber-500 font-black block">CONFIRM DISPATCH</span>
                <h3 className="text-base font-black">{selectedLoad.id} • {selectedLoad.cargoType}</h3>
              </div>
              <button onClick={() => setSelectedLoad(null)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            {acceptedSuccess ? (
              <div className="p-6 text-center space-y-3">
                <div className="w-14 h-14 rounded-full bg-emerald-100 text-emerald-600 mx-auto flex items-center justify-center font-black">
                  <Check size={28} />
                </div>
                <h4 className="text-lg font-black">Load Successfully Accepted!</h4>
                <p className="text-xs text-slate-400">Driver notified with pickup PIN. Redirecting to My Bookings...</p>
              </div>
            ) : (
              <>
                <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-2">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Route Corridor:</span>
                    <span>{selectedLoad.origin} ➔ {selectedLoad.destination}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Distance:</span>
                    <span>{selectedLoad.distanceKm} Kilometers</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Shipper Enterprise:</span>
                    <span className="font-black text-amber-600 dark:text-amber-400">{selectedLoad.shipperName}</span>
                  </div>
                </div>

                <div>
                  <label className="block mb-1.5">Select Truck from Your Fleet *</label>
                  <select className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-bold">
                    {trucks.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.modelName} ({t.regNumber}) — {t.capacityTons}T Available
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex items-center justify-between p-3.5 bg-amber-500/10 border border-amber-400/40 rounded-2xl">
                  <span className="text-slate-400">Freight Payout:</span>
                  <span className="text-lg font-black text-slate-900 dark:text-white">
                    ₹{selectedLoad.priceOfferInr.toLocaleString("en-IN")}
                  </span>
                </div>

                <button
                  onClick={confirmAcceptLoad}
                  className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2 cursor-pointer"
                >
                  <Check size={16} /> Confirm &amp; Accept Freight Load
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
