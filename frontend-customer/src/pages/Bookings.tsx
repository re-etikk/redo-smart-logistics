import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  CheckCircle2, Clock, Package, Truck, XCircle, Phone, MapPin,
  Eye, Star, ShieldCheck, X, Navigation, AlertCircle, ArrowRight
} from "lucide-react";
import Layout from "../components/Layout";
import { useTranslation } from "../lib/i18n";
import { getSharedCargoList, type CargoItem } from "../lib/cargoStore";
import { getTrucks } from "../lib/truckStore";

interface LiveShipmentItem {
  id: string;
  consignmentId: string;
  origin: string;
  destination: string;
  cargoType: string;
  weightTons: number;
  priceInr: number;
  status: "In Transit" | "Driver En Route" | "Scheduled Loading" | "Delivered";
  truckModel: string;
  truckRegNo: string;
  truckPhoto: string;
  driverName: string;
  driverPhone: string;
  driverRating: number;
  etaText: string;
  progressPercent: number;
  bookedAt: string;
  cargoPhotoUrl?: string;
}

export default function CustomerBookings() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [tab, setTab] = useState("all");
  const [search, setSearch] = useState("");
  const [selectedShipment, setSelectedShipment] = useState<LiveShipmentItem | null>(null);

  const [shipments, setShipments] = useState<LiveShipmentItem[]>([
    {
      id: "SHP-901",
      consignmentId: "CARGO-101",
      origin: "Mumbai (Bhiwandi Logistics Park)",
      destination: "Delhi NCR (Okhla Industrial Area)",
      cargoType: "Automobile Components & Spare Parts",
      weightTons: 4.5,
      priceInr: 24500,
      status: "In Transit",
      truckModel: "Eicher Pro 2049 (17 Feet)",
      truckRegNo: "HR 55 AB 1234",
      truckPhoto: "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80",
      driverName: "Mukesh Yadav",
      driverPhone: "+91 98112 34567",
      driverRating: 4.9,
      etaText: "Arriving in 3 hrs 20 mins (Near Jaipur Toll)",
      progressPercent: 70,
      bookedAt: "Today, 09:30 AM",
      cargoPhotoUrl: "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80",
    },
    {
      id: "SHP-902",
      consignmentId: "CARGO-102",
      origin: "Delhi (Kundli Industrial Area)",
      destination: "Indore (Pithampur Hub)",
      cargoType: "FMCG Packaged Goods",
      weightTons: 3.2,
      priceInr: 16800,
      status: "Driver En Route",
      truckModel: "BharatBenz 1917R (19 Feet)",
      truckRegNo: "HR 55 CD 5678",
      truckPhoto: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80",
      driverName: "Jaswinder Singh",
      driverPhone: "+91 98765 12345",
      driverRating: 4.8,
      etaText: "Driver arriving at Pickup Hub in 22 mins",
      progressPercent: 25,
      bookedAt: "Today, 11:15 AM",
    },
    {
      id: "SHP-903",
      consignmentId: "CARGO-103",
      origin: "Bengaluru (Peenya)",
      destination: "Chennai (Sriperumbudur)",
      cargoType: "Textile Bales & Cotton Rolls",
      weightTons: 6.0,
      priceInr: 14500,
      status: "Delivered",
      truckModel: "Tata Ultra T.7 (14 Feet)",
      truckRegNo: "KA 01 EF 9012",
      truckPhoto: "https://images.unsplash.com/photo-1586191582150-a8d29837936a?auto=format&fit=crop&w=600&q=80",
      driverName: "Sanjay Verma",
      driverPhone: "+91 98450 99887",
      driverRating: 4.9,
      etaText: "Delivered successfully • POD Signed",
      progressPercent: 100,
      bookedAt: "Yesterday, 04:00 PM",
    },
  ]);

  useEffect(() => {
    // Check if any cargo in cargoStore is newly posted
    const shared = getSharedCargoList();
    if (shared.length > 0) {
      const latest = shared[0];
      const fleet = getTrucks();
      const trk = fleet[0];

      if (!shipments.some(s => s.consignmentId === latest.id)) {
        const newShipment: LiveShipmentItem = {
          id: `SHP-${Date.now().toString().slice(-4)}`,
          consignmentId: latest.id,
          origin: latest.origin,
          destination: latest.destination,
          cargoType: latest.cargoType,
          weightTons: latest.weightTons,
          priceInr: latest.offeredPriceInr,
          status: "Driver En Route",
          truckModel: trk ? trk.modelName : "Eicher Pro 17 Feet",
          truckRegNo: trk ? trk.regNumber : "HR 55 AB 1234",
          truckPhoto: trk ? trk.photoUrl : "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80",
          driverName: trk ? trk.driverName : "Mukesh Yadav",
          driverPhone: trk ? trk.driverPhone : "+91 98112 34567",
          driverRating: trk ? trk.driverRating : 4.9,
          etaText: "Driver dispatched • Arriving at pickup in ~28 mins",
          progressPercent: 30,
          bookedAt: "Just now",
          cargoPhotoUrl: latest.cargoPhotoUrl,
        };
        setShipments(prev => [newShipment, ...prev]);
      }
    }
  }, []);

  const filtered = shipments.filter(s => {
    const matchesSearch =
      s.origin.toLowerCase().includes(search.toLowerCase()) ||
      s.destination.toLowerCase().includes(search.toLowerCase()) ||
      s.cargoType.toLowerCase().includes(search.toLowerCase()) ||
      s.id.toLowerCase().includes(search.toLowerCase());

    const matchesTab =
      tab === "all" ||
      (tab === "transit" && (s.status === "In Transit" || s.status === "Driver En Route")) ||
      (tab === "delivered" && s.status === "Delivered");

    return matchesSearch && matchesTab;
  });

  return (
    <Layout>
      <div className="max-w-5xl mx-auto space-y-6 py-4 text-slate-900 dark:text-white">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              {t("myShipments")} &amp; Live Tracking
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Live driver tracking, contact information, milestone alerts, and electronic proof of delivery (e-POD).
            </p>
          </div>

          <button
            onClick={() => navigate("/book")}
            className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
          >
            + Book New Shipment
          </button>
        </div>

        {/* 3 Stat Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Shipments</span>
            <span className="text-2xl font-black text-slate-900 dark:text-white block">{shipments.length}</span>
            <span className="text-[10px] font-bold text-slate-500 block">All time consignments</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Active On Highway</span>
            <span className="text-2xl font-black text-amber-600 dark:text-amber-400 block">
              {shipments.filter(s => s.status !== "Delivered").length}
            </span>
            <span className="text-[10px] font-bold text-amber-600 block">Live GPS Active</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Successfully Delivered</span>
            <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400 block">
              {shipments.filter(s => s.status === "Delivered").length}
            </span>
            <span className="text-[10px] font-bold text-emerald-600 block">100% Verified e-POD</span>
          </div>
        </div>

        {/* Filter Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-bold text-xs">
            <button
              onClick={() => setTab("all")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                tab === "all" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
            >
              All Shipments ({shipments.length})
            </button>
            <button
              onClick={() => setTab("transit")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                tab === "transit" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
            >
              Active / In Transit
            </button>
            <button
              onClick={() => setTab("delivered")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                tab === "delivered" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
            >
              Delivered
            </button>
          </div>

          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search shipments..."
            className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2 text-xs font-bold w-full sm:w-64"
          />
        </div>

        {/* Shipments List */}
        <div className="space-y-4">
          {filtered.map((shp) => (
            <div
              key={shp.id}
              className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm hover:shadow-md transition space-y-4"
            >
              {/* Header Info */}
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
                <div className="flex items-center gap-2.5">
                  <span className="text-xs font-black font-mono text-amber-500">{shp.id}</span>
                  <span className="text-[10px] text-slate-400 font-bold">• Consignment {shp.consignmentId}</span>
                  <span className={`text-[9px] font-black px-2.5 py-0.5 rounded-full ${
                    shp.status === "Delivered"
                      ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400"
                      : "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400"
                  }`}>
                    {shp.status}
                  </span>
                </div>

                <div className="flex items-center gap-2">
                  <span className="text-sm font-black text-slate-900 dark:text-white">
                    ₹{shp.priceInr.toLocaleString("en-IN")}
                  </span>
                  <span className="text-[10px] text-slate-400 font-bold">({shp.bookedAt})</span>
                </div>
              </div>

              {/* Middle Row: Truck & Driver Details with Direct Call Button */}
              <div className="grid md:grid-cols-2 gap-4">
                {/* Route & Cargo */}
                <div className="space-y-2">
                  <div className="space-y-1 text-xs font-bold">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0" />
                      <span className="text-slate-900 dark:text-white font-black">{shp.origin}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-rose-500 shrink-0" />
                      <span className="text-slate-900 dark:text-white font-black">{shp.destination}</span>
                    </div>
                  </div>

                  <p className="text-xs text-slate-500 dark:text-slate-400 font-bold">
                    {shp.cargoType} • {shp.weightTons} Tons
                  </p>
                </div>

                {/* Assigned Truck & Driver Card */}
                <div className="bg-slate-50 dark:bg-slate-800/80 p-4 rounded-2xl border border-slate-200/60 dark:border-slate-700 flex items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl overflow-hidden bg-slate-200 shrink-0 border border-slate-300 dark:border-slate-600">
                      <img src={shp.truckPhoto} alt={shp.truckModel} className="w-full h-full object-cover" />
                    </div>
                    <div className="space-y-0.5">
                      <h4 className="text-xs font-black text-slate-900 dark:text-white">{shp.truckModel}</h4>
                      <p className="text-[10px] font-mono font-bold text-amber-600 dark:text-amber-400">{shp.truckRegNo}</p>
                      <p className="text-[10px] text-slate-400 font-bold">
                        Driver: <strong>{shp.driverName}</strong> (★ {shp.driverRating})
                      </p>
                    </div>
                  </div>

                  {/* Direct Phone Call Button */}
                  <a
                    href={`tel:${shp.driverPhone}`}
                    className="bg-emerald-600 hover:bg-emerald-500 text-white font-black px-3.5 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition whitespace-nowrap"
                  >
                    <Phone size={13} />
                    <span>Call Driver</span>
                  </a>
                </div>
              </div>

              {/* Real-Time ETA Status Bar */}
              <div className="p-3.5 bg-amber-500/10 border border-amber-400/40 rounded-2xl flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-800 dark:text-slate-200">
                  <Navigation size={15} className="text-amber-500 shrink-0" />
                  <span><strong>Live Status:</strong> {shp.etaText}</span>
                </div>

                <button
                  onClick={() => setSelectedShipment(shp)}
                  className="text-xs font-black text-amber-600 dark:text-amber-400 hover:underline flex items-center gap-1 cursor-pointer"
                >
                  <span>View Timeline &amp; e-POD</span>
                  <ArrowRight size={13} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* SHIPMENT TIMELINE & EPOD MODAL */}
      {/* ========================================================================= */}
      {selectedShipment && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-lg w-full shadow-2xl p-6 space-y-5 text-xs font-bold text-slate-900 dark:text-white">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <span className="text-[10px] font-mono text-amber-500 font-bold block">LIVE SHIPMENT TIMELINE</span>
                <h3 className="text-base font-black">{selectedShipment.id} • {selectedShipment.truckModel}</h3>
              </div>
              <button onClick={() => setSelectedShipment(null)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            {/* Milestones */}
            <div className="space-y-3 pl-2">
              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-emerald-500 text-white flex items-center justify-center text-[10px]">✓</div>
                <div>
                  <h5 className="font-black text-xs">Booking Confirmed &amp; Driver Assigned</h5>
                  <p className="text-[10px] text-slate-400">Assigned driver {selectedShipment.driverName} ({selectedShipment.driverPhone})</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-emerald-500 text-white flex items-center justify-center text-[10px]">✓</div>
                <div>
                  <h5 className="font-black text-xs">Vehicle Arrived &amp; Loaded at Origin Hub</h5>
                  <p className="text-[10px] text-slate-400">E-Way Bill verified with GPS seal</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-amber-400 text-slate-950 flex items-center justify-center text-[10px] font-black">●</div>
                <div>
                  <h5 className="font-black text-xs">Highway Transit &amp; Real-time GPS Telemetry</h5>
                  <p className="text-[10px] text-amber-600 dark:text-amber-400">{selectedShipment.etaText}</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] ${
                  selectedShipment.status === "Delivered" ? "bg-emerald-500 text-white" : "bg-slate-200 dark:bg-slate-700 text-slate-400"
                }`}>
                  {selectedShipment.status === "Delivered" ? "✓" : "○"}
                </div>
                <div>
                  <h5 className="font-black text-xs">Final Destination Delivery &amp; OTP Handover</h5>
                  <p className="text-[10px] text-slate-400">Recipient signature and e-POD upload</p>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700">
              <div>
                <span className="text-[10px] text-slate-400 block uppercase">Driver Contact</span>
                <span className="font-black text-sm">{selectedShipment.driverName}</span>
                <span className="text-[10px] text-slate-400 block">{selectedShipment.driverPhone}</span>
              </div>

              <a
                href={`tel:${selectedShipment.driverPhone}`}
                className="bg-emerald-600 hover:bg-emerald-500 text-white font-black px-4 py-2 rounded-xl text-xs flex items-center gap-1.5"
              >
                <Phone size={13} /> Call Driver
              </a>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}
