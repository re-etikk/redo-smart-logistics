import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  CheckCircle2, Clock, Package, Truck, XCircle, Phone, MapPin,
  Eye, Star, ShieldCheck, X, Navigation, AlertCircle, ArrowRight, Radio
} from "lucide-react";
import Layout from "../components/Layout";
import { useTranslation } from "../lib/i18n";
import { getShipments, getShipmentStats, type ShipmentItem } from "../lib/shipmentStore";
import LiveTrackingMap from "../components/LiveTrackingMap";

export default function CustomerBookings() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [tab, setTab] = useState<"all" | "transit" | "delivered">("all");
  const [search, setSearch] = useState("");
  const [selectedShipment, setSelectedShipment] = useState<ShipmentItem | null>(null);
  const [shipments, setShipments] = useState<ShipmentItem[]>(() => getShipments());

  const refreshShipments = () => {
    setShipments(getShipments());
  };

  useEffect(() => {
    refreshShipments();
    window.addEventListener("redo_shipment_updated", refreshShipments);
    window.addEventListener("redo_cargo_updated", refreshShipments);

    const interval = setInterval(refreshShipments, 3000);

    return () => {
      window.removeEventListener("redo_shipment_updated", refreshShipments);
      window.removeEventListener("redo_cargo_updated", refreshShipments);
      clearInterval(interval);
    };
  }, []);

  const stats = useMemo(() => {
    const inTransit = shipments.filter(s => s.status !== "Delivered");
    const delivered = shipments.filter(s => s.status === "Delivered");
    const spend = shipments.reduce((sum, s) => sum + (Number(s.priceInr) || 0), 0);
    return {
      total: shipments.length,
      inTransit: inTransit.length,
      delivered: delivered.length,
      spend,
    };
  }, [shipments]);

  const filtered = shipments.filter(s => {
    const matchesSearch =
      s.origin.toLowerCase().includes(search.toLowerCase()) ||
      s.destination.toLowerCase().includes(search.toLowerCase()) ||
      s.cargoType.toLowerCase().includes(search.toLowerCase()) ||
      s.id.toLowerCase().includes(search.toLowerCase()) ||
      s.driverName.toLowerCase().includes(search.toLowerCase());

    const matchesTab =
      tab === "all" ||
      (tab === "transit" && s.status !== "Delivered") ||
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
              {t("myShipments")} &amp; Live Highway Tracking
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Track active corridor progress, call assigned drivers directly, and download signed electronic delivery receipts (e-POD).
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
            <span className="text-2xl font-black text-slate-900 dark:text-white block">{stats.total}</span>
            <span className="text-[10px] font-bold text-slate-500 block">Total Freight Value: ₹{stats.spend.toLocaleString("en-IN")}</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Active On Highway</span>
            <span className="text-2xl font-black text-amber-600 dark:text-amber-400 block">{stats.inTransit}</span>
            <span className="text-[10px] font-bold text-amber-600 block">Live Telemetry Active</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Completed &amp; Delivered</span>
            <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400 block">{stats.delivered}</span>
            <span className="text-[10px] font-bold text-emerald-600 block">100% Verified e-POD</span>
          </div>
        </div>

        {/* Live GPS Tracking Map */}
        {stats.inTransit > 0 && (
          <LiveTrackingMap
            shipments={shipments}
            onSelectShipment={(s) => setSelectedShipment(s)}
          />
        )}

        {/* Filter Bar with Separated Active vs Delivered Tabs */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-4 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-bold text-xs">
            <button
              onClick={() => setTab("all")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                tab === "all" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
            >
              All Consignments ({shipments.length})
            </button>
            <button
              onClick={() => setTab("transit")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                tab === "transit" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
            >
              <Truck size={14} /> Active In-Transit ({stats.inTransit})
            </button>
            <button
              onClick={() => setTab("delivered")}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                tab === "delivered" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
            >
              <CheckCircle2 size={14} /> Delivered ({stats.delivered})
            </button>
          </div>

          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by ID, route, cargo, driver..."
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
                  <span className="text-[10px] text-slate-400 font-bold">• Ref: {shp.consignmentId}</span>
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

              {/* Middle Row: Route & Driver Info */}
              <div className="grid md:grid-cols-2 gap-4">
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

                {/* Driver Contact & Truck Card */}
                <div className="bg-slate-50 dark:bg-slate-800/80 p-4 rounded-2xl border border-slate-200/60 dark:border-slate-700 flex items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl overflow-hidden bg-slate-200 shrink-0 border border-slate-300 dark:border-slate-600 shadow-xs">
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

                  <a
                    href={`tel:${shp.driverPhone}`}
                    className="bg-emerald-600 hover:bg-emerald-500 text-white font-black px-3.5 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition whitespace-nowrap"
                  >
                    <Phone size={13} />
                    <span>Call Driver</span>
                  </a>
                </div>
              </div>

              {/* Progress & Live Telemetry Action */}
              <div className="p-3.5 bg-amber-500/10 border border-amber-400/40 rounded-2xl flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-800 dark:text-slate-200">
                  <Navigation size={15} className="text-amber-500 shrink-0" />
                  <span><strong>Status:</strong> {shp.etaText}</span>
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

          {filtered.length === 0 && (
            <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-12 text-center space-y-4">
              <div className="w-16 h-16 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 flex items-center justify-center mx-auto">
                <Package size={28} />
              </div>
              <div className="space-y-1">
                <h3 className="text-base font-black text-slate-900 dark:text-white">No Shipments Found</h3>
                <p className="text-xs text-slate-500 max-w-sm mx-auto">
                  You have not booked any shipments yet. Book your first commercial truck shipment to track live progress and get electronic PODs.
                </p>
              </div>
              <button
                onClick={() => navigate("/book")}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl shadow-sm transition text-xs inline-flex items-center gap-1.5 cursor-pointer"
              >
                + Book New Shipment
              </button>
            </div>
          )}
        </div>
      </div>

      {/* View Timeline Modal */}
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
                <span className="text-[10px] text-slate-400 block uppercase">Assigned Driver</span>
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
