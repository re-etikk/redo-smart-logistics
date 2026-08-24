import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  Box, CheckCircle2, Download, IndianRupee, MapPin, Package, Truck,
  Navigation, Phone, ArrowRight, ShieldCheck, Clock, Eye, AlertCircle
} from "lucide-react";
import Layout from "../components/Layout";
import { useAuth } from "../hooks/useAuth";
import { useTranslation } from "../lib/i18n";
import { getShipmentStats, getShipments, type ShipmentItem } from "../lib/shipmentStore";
import LiveTrackingMap from "../components/LiveTrackingMap";

export default function CustomerDashboard() {
  const { session, profile } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const [stats, setStats] = useState(() => getShipmentStats());
  const [activeTab, setActiveTab] = useState<"active" | "delivered">("active");

  const refreshData = () => {
    setStats(getShipmentStats());
  };

  useEffect(() => {
    refreshData();
    window.addEventListener("redo_shipment_updated", refreshData);
    window.addEventListener("redo_cargo_updated", refreshData);

    const interval = setInterval(refreshData, 3000);

    return () => {
      window.removeEventListener("redo_shipment_updated", refreshData);
      window.removeEventListener("redo_cargo_updated", refreshData);
      clearInterval(interval);
    };
  }, []);

  const googleName = session?.user?.user_metadata?.full_name || session?.user?.user_metadata?.name || (session?.user?.email ? session.user.email.split('@')[0] : "");
  const displayName = session?.user ? (googleName || profile?.full_name) : (profile?.full_name || "Enterprise Shipper");

  return (
    <Layout>
      <div className="space-y-6 text-slate-900 dark:text-white py-2">
        {/* Welcome Header */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <span className="text-[10px] uppercase font-black tracking-wider text-amber-500 block">
              REDO Smart Logistics Portal
            </span>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              Welcome back, {displayName}! 👋
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Manage your live freight shipments, view real-time GPS telemetry and download official GST tax invoices.
            </p>
          </div>

          <button
            onClick={() => navigate("/book")}
            className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-2xl shadow-md transition text-xs flex items-center gap-2 cursor-pointer"
          >
            <Box size={16} />
            <span>+ Book New Shipment</span>
          </button>
        </div>

        {/* 4 Stat Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Shipments</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-slate-900 dark:text-white">{stats.totalCount || 0}</span>
              <div className="w-8 h-8 rounded-xl bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
                <Package size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-slate-500 block">Booked Consignments</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">In Transit</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-amber-600 dark:text-amber-400">{stats.inTransitCount || 0}</span>
              <div className="w-8 h-8 rounded-xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
                <Truck size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-amber-600 block">Live GPS Active</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Delivered</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400">{stats.deliveredCount || 0}</span>
              <div className="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                <CheckCircle2 size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-emerald-600 block">Signed e-POD</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Freight Spend</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-purple-600 dark:text-purple-400">
                ₹{(stats.totalSpendInr || 0).toLocaleString("en-IN")}
              </span>
              <div className="w-8 h-8 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
                <IndianRupee size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-purple-600 block">100% Tax Deductible (ITC)</span>
          </div>
        </div>

        {/* Live GPS Tracking Map Section */}
        {(stats.inTransitCount || 0) > 0 && (
          <LiveTrackingMap shipments={stats.allShipments || []} />
        )}

        {/* Separated Shipments Sections (Active vs Delivered Tabs) */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-5">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border-b border-slate-100 dark:border-slate-800 pb-3">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setActiveTab("active")}
                className={`px-4 py-2 rounded-xl text-xs font-black transition cursor-pointer flex items-center gap-2 ${
                  activeTab === "active"
                    ? "bg-[#FFC800] text-slate-950 shadow-sm"
                    : "text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                }`}
              >
                <Truck size={15} />
                <span>Active Highway Shipments ({stats.inTransitCount || 0})</span>
              </button>

              <button
                onClick={() => setActiveTab("delivered")}
                className={`px-4 py-2 rounded-xl text-xs font-black transition cursor-pointer flex items-center gap-2 ${
                  activeTab === "delivered"
                    ? "bg-[#FFC800] text-slate-950 shadow-sm"
                    : "text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                }`}
              >
                <CheckCircle2 size={15} />
                <span>Past Completed &amp; Delivered ({stats.deliveredCount || 0})</span>
              </button>
            </div>

            <Link to="/shipments" className="text-xs font-black text-amber-600 dark:text-amber-400 hover:underline flex items-center gap-1">
              <span>View Full Ledger</span>
              <ArrowRight size={13} />
            </Link>
          </div>

          {/* Tab Content List */}
          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {(activeTab === "active" ? (stats.activeShipments || []) : (stats.deliveredShipments || [])).map((shp) => (
              <div key={shp.id} className="py-4 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
                <div className="flex items-center gap-3.5">
                  <div className="w-14 h-14 rounded-2xl overflow-hidden bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shrink-0 shadow-sm">
                    <img src={shp.truckPhoto} alt={shp.truckModel} className="w-full h-full object-cover" />
                  </div>

                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs font-black text-amber-500">{shp.id}</span>
                      <span className={`text-[9px] font-black px-2 py-0.5 rounded-full ${
                        shp.status === "Delivered"
                          ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400"
                          : "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400"
                      }`}>
                        {shp.status}
                      </span>
                    </div>

                    <h4 className="font-black text-sm text-slate-900 dark:text-white">
                      {shp.origin} ➔ {shp.destination}
                    </h4>

                    <div className="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400 font-bold">
                      <span>{shp.cargoType}</span>
                      <span>•</span>
                      <span>{shp.weightTons} Tons</span>
                      <span>•</span>
                      <span className="text-slate-900 dark:text-white font-black">Driver: {shp.driverName} ({shp.truckRegNo})</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between md:justify-end gap-4 w-full md:w-auto">
                  <div className="text-right">
                    <span className="text-sm font-black text-slate-900 dark:text-white block">
                      ₹{shp.priceInr.toLocaleString("en-IN")}
                    </span>
                    <span className="text-[10px] text-slate-400 font-bold block">{shp.bookedAt}</span>
                  </div>

                  {shp.driverPhone && (
                    <a
                      href={`tel:${shp.driverPhone}`}
                      className="bg-emerald-600 hover:bg-emerald-500 text-white font-black px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition whitespace-nowrap"
                    >
                      <Phone size={13} />
                      <span>Call Driver</span>
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}
