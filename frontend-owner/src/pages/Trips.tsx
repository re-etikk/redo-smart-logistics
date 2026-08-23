import { useState, useEffect } from "react";
import {
  MapPin, Truck, CheckCircle2, Clock, XCircle, Navigation, ChevronRight, Filter,
  Phone, ShieldCheck, X, ArrowRight, User, Calendar
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { getTrucks, type TruckItem } from "../lib/truckStore";

interface TripItem {
  id: string;
  truckId: string;
  truckName: string;
  regNo: string;
  photoUrl: string;
  date: string;
  origin: string;
  dest: string;
  distance: string;
  driver: string;
  driverPhone: string;
  status: "Upcoming" | "On the Way" | "Completed" | "Cancelled";
  amount: string;
  paymentStatus: "Paid" | "Pending" | "Cancelled";
}

export default function Trips() {
  const [activeTab, setActiveTab] = useState("all");
  const [trips, setTrips] = useState<TripItem[]>([]);
  const [selectedTrip, setSelectedTrip] = useState<TripItem | null>(null);

  const loadTrips = () => {
    const fleet = getTrucks();
    const allTrips: TripItem[] = [];

    fleet.forEach((truck, index) => {
      if (truck.currentTrip) {
        allTrips.push({
          id: truck.currentTrip.id || `TRIP-${index + 101}`,
          truckId: truck.id,
          truckName: truck.name,
          regNo: truck.regNo,
          photoUrl: truck.photoUrl,
          date: truck.currentTrip.departureDate,
          origin: truck.currentTrip.origin,
          dest: truck.currentTrip.dest,
          distance: `${truck.currentTrip.distanceKm} km · Active Corridor`,
          driver: truck.driverName || "Sandeep Kumar",
          driverPhone: truck.driverPhone || "+91 98765 43210",
          status: truck.currentTrip.status,
          amount: truck.currentTrip.expectedEarning,
          paymentStatus: truck.currentTrip.status === "Completed" ? "Paid" : "Pending",
        });
      }
    });

    setTrips(allTrips);
  };

  useEffect(() => {
    loadTrips();
    window.addEventListener("redo_fleet_updated", loadTrips);
    return () => window.removeEventListener("redo_fleet_updated", loadTrips);
  }, []);

  const filteredTrips = trips.filter((t) => {
    if (activeTab === "ongoing") return t.status === "On the Way" || t.status === "Upcoming";
    if (activeTab === "completed") return t.status === "Completed";
    if (activeTab === "cancelled") return t.status === "Cancelled";
    return true;
  });

  const onTheRoadCount = trips.filter(t => t.status === "On the Way").length;
  const completedCount = trips.filter(t => t.status === "Completed").length;
  const cancelledCount = trips.filter(t => t.status === "Cancelled").length;

  return (
    <OwnerLayout activeTab="trips" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">Active Trips &amp; Routes</h1>
            <p className="text-xs text-slate-500 mt-0.5">Track your fleet trips, routes, driver updates, and freight payouts.</p>
          </div>
        </div>

        {/* 4 Stat Summary Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Trips</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-slate-900">{trips.length}</span>
              <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
                <Truck size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-slate-500 block">Registered Fleet Trips</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">On the Road</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-blue-600">{onTheRoadCount}</span>
              <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                <Navigation size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-blue-600 block">Live in Transit</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Completed</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-emerald-600">{completedCount}</span>
              <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <CheckCircle2 size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-emerald-600 block">Delivered &amp; Paid</span>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Cancelled</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-slate-900">{cancelledCount}</span>
              <div className="w-8 h-8 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
                <XCircle size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-slate-500 block">Disputed / Cancelled</span>
          </div>
        </div>

        {/* Tab Selector Filter */}
        <div className="flex items-center justify-between gap-4 border-b border-slate-200/80 pb-3">
          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveTab("all")}
              className={`px-4 py-2 rounded-xl text-xs font-black transition ${
                activeTab === "all" ? "bg-[#FFC800] text-slate-950 shadow-sm" : "bg-white text-slate-600 hover:bg-slate-50 border border-slate-200"
              }`}
            >
              All Trips ({trips.length})
            </button>
            <button
              onClick={() => setActiveTab("ongoing")}
              className={`px-4 py-2 rounded-xl text-xs font-black transition ${
                activeTab === "ongoing" ? "bg-[#FFC800] text-slate-950 shadow-sm" : "bg-white text-slate-600 hover:bg-slate-50 border border-slate-200"
              }`}
            >
              Ongoing ({onTheRoadCount})
            </button>
            <button
              onClick={() => setActiveTab("completed")}
              className={`px-4 py-2 rounded-xl text-xs font-black transition ${
                activeTab === "completed" ? "bg-[#FFC800] text-slate-950 shadow-sm" : "bg-white text-slate-600 hover:bg-slate-50 border border-slate-200"
              }`}
            >
              Completed ({completedCount})
            </button>
          </div>
        </div>

        {/* Trips Cards List with Real Photos */}
        <div className="space-y-4">
          {filteredTrips.map((trip) => (
            <div
              key={trip.id}
              className="bg-white border border-slate-200/80 rounded-3xl p-5 shadow-sm hover:shadow-md transition flex flex-col md:flex-row items-start md:items-center justify-between gap-5"
            >
              {/* Left: Truck Real Photo & Name */}
              <div className="flex items-center gap-4 min-w-[240px]">
                <div className="relative w-20 h-16 rounded-2xl bg-slate-900 overflow-hidden border border-slate-200 shrink-0 shadow-sm">
                  <img
                    src={trip.photoUrl}
                    alt={trip.truckName}
                    className="w-full h-full object-cover"
                  />
                  <span className="absolute bottom-1 left-1 right-1 bg-black/70 text-[9px] font-mono text-amber-400 font-bold px-1 rounded text-center truncate">
                    {trip.regNo}
                  </span>
                </div>
                <div>
                  <h3 className="font-black text-slate-900 text-sm">{trip.truckName}</h3>
                  <span className="text-[11px] text-slate-500 font-bold block">{trip.date}</span>
                </div>
              </div>

              {/* Middle: Route & Distance */}
              <div className="space-y-1 flex-1">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-900">
                  <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
                  <span>{trip.origin}</span>
                  <ArrowRight size={14} className="text-slate-400" />
                  <span className="w-2.5 h-2.5 rounded-full bg-rose-500"></span>
                  <span>{trip.dest}</span>
                </div>
                <p className="text-[11px] text-slate-500 font-semibold">{trip.distance}</p>
                <div className="flex items-center gap-1.5 text-[11px] font-bold text-slate-700">
                  <User size={13} className="text-amber-500" />
                  <span>Driver: {trip.driver}</span>
                </div>
              </div>

              {/* Status Badge */}
              <div className="min-w-[120px]">
                <span className={`px-3 py-1 rounded-full text-xs font-black inline-block shadow-sm ${
                  trip.status === "On the Way"
                    ? "bg-blue-100 text-blue-800"
                    : trip.status === "Completed"
                    ? "bg-emerald-100 text-emerald-800"
                    : trip.status === "Upcoming"
                    ? "bg-amber-100 text-amber-800"
                    : "bg-rose-100 text-rose-800"
                }`}>
                  {trip.status}
                </span>
              </div>

              {/* Earnings & View Action */}
              <div className="flex items-center justify-between md:justify-end gap-5 w-full md:w-auto border-t md:border-t-0 pt-3 md:pt-0 border-slate-100">
                <div className="text-left md:text-right">
                  <span className="text-[10px] uppercase font-bold text-slate-400 block">Trip Earning</span>
                  <span className="text-base font-black text-slate-900">{trip.amount}</span>
                  <span className={`text-[10px] font-bold block ${trip.paymentStatus === "Paid" ? "text-emerald-600" : "text-amber-600"}`}>
                    {trip.paymentStatus}
                  </span>
                </div>

                <button
                  onClick={() => setSelectedTrip(trip)}
                  className="bg-slate-900 hover:bg-slate-800 text-white font-black text-xs px-4 py-2.5 rounded-xl shadow-sm transition cursor-pointer whitespace-nowrap"
                >
                  View Details &gt;
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* TRIP DETAILS MODAL */}
      {/* ========================================================================= */}
      {selectedTrip && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-xl w-full max-h-[90vh] overflow-y-auto shadow-2xl p-6 space-y-6">
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div>
                <span className="text-[10px] font-mono font-bold text-amber-600 bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                  {selectedTrip.id}
                </span>
                <h2 className="text-lg font-black text-slate-900 mt-1">Trip Itinerary &amp; Details</h2>
              </div>
              <button
                onClick={() => setSelectedTrip(null)}
                className="p-2 text-slate-400 hover:text-slate-700 rounded-xl hover:bg-slate-100"
              >
                <X size={20} />
              </button>
            </div>

            {/* Truck Banner */}
            <div className="flex items-center gap-4 bg-slate-50 p-4 rounded-2xl border border-slate-100">
              <div className="w-20 h-16 rounded-xl overflow-hidden bg-slate-900 shrink-0 border border-slate-200">
                <img src={selectedTrip.photoUrl} alt={selectedTrip.truckName} className="w-full h-full object-cover" />
              </div>
              <div>
                <h3 className="font-black text-slate-900 text-sm">{selectedTrip.truckName}</h3>
                <span className="text-xs font-mono font-bold text-slate-500">{selectedTrip.regNo}</span>
              </div>
            </div>

            {/* Route Timeline */}
            <div className="bg-slate-50 p-4 rounded-2xl border border-slate-100 space-y-3">
              <span className="text-[10px] font-black uppercase text-slate-400 block">Corridor Milestones</span>
              <div className="space-y-3 text-xs font-bold">
                <div className="flex items-center gap-3">
                  <div className="w-6 h-6 rounded-full bg-emerald-500 text-white flex items-center justify-center text-xs">
                    ✓
                  </div>
                  <div>
                    <span className="text-slate-900 block">Origin: {selectedTrip.origin}</span>
                    <span className="text-[10px] text-slate-400 font-normal">Departure: {selectedTrip.date}</span>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-6 h-6 rounded-full bg-amber-400 text-slate-950 flex items-center justify-center text-xs">
                    ➔
                  </div>
                  <div>
                    <span className="text-slate-900 block">Destination: {selectedTrip.dest}</span>
                    <span className="text-[10px] text-slate-400 font-normal">Distance: {selectedTrip.distance}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Driver & Payout */}
            <div className="grid grid-cols-2 gap-3 text-xs font-bold">
              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 space-y-1">
                <span className="text-[10px] text-slate-400 uppercase block font-semibold">Assigned Driver</span>
                <span className="text-slate-900 block">{selectedTrip.driver}</span>
                <a href={`tel:${selectedTrip.driverPhone}`} className="text-emerald-700 font-extrabold flex items-center gap-1 mt-1 text-[11px]">
                  <Phone size={12} /> {selectedTrip.driverPhone}
                </a>
              </div>

              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 space-y-1">
                <span className="text-[10px] text-slate-400 uppercase block font-semibold">Trip Earning</span>
                <span className="text-slate-900 text-base font-black block">{selectedTrip.amount}</span>
                <span className="text-[10px] text-emerald-600 font-extrabold block">{selectedTrip.paymentStatus}</span>
              </div>
            </div>

            <div className="flex justify-end pt-4 border-t border-slate-100">
              <button
                onClick={() => setSelectedTrip(null)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition"
              >
                Close Trip Details
              </button>
            </div>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
