import { useState, useEffect, useRef } from "react";
import {
  Truck, CalendarCheck, IndianRupee, Search, Plus, MoreVertical, ShieldCheck,
  AlertTriangle, Check, X, Phone, FileText, MapPin, Upload, Image as ImageIcon,
  Trash2, Edit, CheckCircle2, User, Gauge
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import LocationSearchInput from "../components/LocationSearchInput";
import { getTrucks, addTruck, deleteTruck, updateTruck, PRESET_TRUCK_PHOTOS, type TruckItem } from "../lib/truckStore";

export default function MyTrucks() {
  const [trucks, setTrucks] = useState<TruckItem[]>([]);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");

  // Modals
  const [selectedTruck, setSelectedTruck] = useState<TruckItem | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // Add Truck Form State
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [newTruck, setNewTruck] = useState({
    name: "",
    regNo: "",
    type: "17 Feet",
    body: "Enclosed Container",
    capacity: "7.0 Ton",
    capacityTons: 7.0,
    availableCapacityTons: 5.0,
    routeOrigin: "Delhi NCR, Delhi",
    routeDest: "Mumbai, Maharashtra",
    departureDate: "24 Aug 2026, 09:00 AM",
    expectedRate: "₹24,500",
    status: "Active" as const,
    availability: "Available" as const,
    location: "Delhi NCR, Delhi",
    photoUrl: PRESET_TRUCK_PHOTOS[0].url,
    driverName: "",
    driverPhone: "",
    driverLicense: "",
    insuranceValidTill: "20 Dec 2026",
    fitnessValidTill: "15 Jan 2027",
    pucValidTill: "10 Oct 2026",
  });

  const loadFleet = () => {
    setTrucks(getTrucks());
  };

  useEffect(() => {
    loadFleet();
    window.addEventListener("redo_fleet_updated", loadFleet);
    return () => window.removeEventListener("redo_fleet_updated", loadFleet);
  }, []);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      if (event.target?.result) {
        setNewTruck(prev => ({ ...prev, photoUrl: event.target!.result as string }));
      }
    };
    reader.readAsDataURL(file);
  };

  const handleCreateTruck = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTruck.regNo || !newTruck.name) return;

    addTruck({
      ...newTruck,
      capacity: `${newTruck.capacityTons} Ton`,
      capacityTons: Number(newTruck.capacityTons) || 7.0,
      currentTrip: {
        id: `TRIP-${Date.now().toString().slice(-4)}`,
        origin: newTruck.routeOrigin || newTruck.location || "Delhi NCR",
        dest: newTruck.routeDest || "Mumbai, Maharashtra",
        departureDate: newTruck.departureDate || "Tomorrow, 09:00 AM",
        expectedEarning: newTruck.expectedRate || "₹24,500",
        distanceKm: 1420,
        status: "Upcoming",
      },
    });

    setIsAddModalOpen(false);
    loadFleet();
    // Reset
    setNewTruck({
      name: "",
      regNo: "",
      type: "17 Feet",
      body: "Enclosed Container",
      capacity: "7.0 Ton",
      capacityTons: 7.0,
      availableCapacityTons: 5.0,
      routeOrigin: "Delhi NCR, Delhi",
      routeDest: "Mumbai, Maharashtra",
      departureDate: "24 Aug 2026, 09:00 AM",
      expectedRate: "₹24,500",
      status: "Active",
      availability: "Available",
      location: "Delhi NCR, Delhi",
      photoUrl: PRESET_TRUCK_PHOTOS[0].url,
      driverName: "",
      driverPhone: "",
      driverLicense: "",
      insuranceValidTill: "20 Dec 2026",
      fitnessValidTill: "15 Jan 2027",
      pucValidTill: "10 Oct 2026",
    });
  };

  const handleDelete = (id: string) => {
    if (confirm("Are you sure you want to remove this truck from your fleet?")) {
      deleteTruck(id);
      setSelectedTruck(null);
      loadFleet();
    }
  };

  // Filter logic
  const filteredTrucks = trucks.filter((t) => {
    const matchesSearch =
      t.name.toLowerCase().includes(search.toLowerCase()) ||
      t.regNo.toLowerCase().includes(search.toLowerCase()) ||
      t.location.toLowerCase().includes(search.toLowerCase()) ||
      t.driverName.toLowerCase().includes(search.toLowerCase());

    const matchesStatus =
      statusFilter === "all" ||
      (statusFilter === "active" && t.status === "Active") ||
      (statusFilter === "inactive" && t.status === "Inactive") ||
      (statusFilter === "on_trip" && t.availability === "On Trip");

    const matchesType =
      typeFilter === "all" ||
      t.type.toLowerCase().includes(typeFilter.toLowerCase());

    return matchesSearch && matchesStatus && matchesType;
  });

  const activeCount = trucks.filter((t) => t.status === "Active").length;
  const onTripCount = trucks.filter((t) => t.availability === "On Trip").length;
  const availableCount = trucks.filter((t) => t.availability === "Available").length;

  return (
    <OwnerLayout activeTab="trucks" promoCardType="truck" onAddTruckClick={() => setIsAddModalOpen(true)}>
      <div className="space-y-6">
        {/* Header Title with Action Button */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">My Fleet</h1>
            <p className="text-xs text-slate-500 mt-0.5">Manage your registered commercial vehicles, drivers and documentation.</p>
          </div>

          <button
            onClick={() => setIsAddModalOpen(true)}
            className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-4 py-2.5 rounded-xl shadow-sm transition text-xs flex items-center gap-1.5 cursor-pointer"
          >
            <Plus size={16} /> Add New Truck
          </button>
        </div>

        {/* 4 Fleet Stat Summary Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Fleet</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-slate-900 dark:text-white">{trucks.length}</span>
              <div className="w-8 h-8 rounded-xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
                <Truck size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-slate-500 block">Registered Vehicles</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Available Trucks</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-slate-900 dark:text-white">{availableCount}</span>
              <div className="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                <Check size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-emerald-600 block">Ready for Loads</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">On the Road</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-slate-900 dark:text-white">{onTripCount}</span>
              <div className="w-8 h-8 rounded-xl bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
                <MapPin size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-blue-600 block">Active Corridors</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Verified RC</span>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-black text-slate-900 dark:text-white">{activeCount}</span>
              <div className="w-8 h-8 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
                <ShieldCheck size={16} />
              </div>
            </div>
            <span className="text-[10px] font-bold text-purple-600 block">100% Compliant</span>
          </div>
        </div>

        {/* Filter & Search Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="relative w-full md:w-80">
            <Search size={16} className="text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by RC, model, city, driver..."
              className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl pl-9 pr-4 py-2 text-xs font-bold text-slate-900 dark:text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>

          <div className="flex flex-wrap items-center gap-3 w-full md:w-auto text-xs font-bold">
            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-slate-700 dark:text-slate-300 focus:outline-none focus:ring-2 focus:ring-amber-400"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="on_trip">On Trip</option>
              <option value="inactive">Inactive</option>
            </select>

            {/* Type Filter */}
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-slate-700 dark:text-slate-300 focus:outline-none focus:ring-2 focus:ring-amber-400"
            >
              <option value="all">All Vehicle Types</option>
              <option value="14">14 Feet</option>
              <option value="17">17 Feet</option>
              <option value="19">19 Feet</option>
              <option value="22">22 Feet</option>
              <option value="32">32 Feet</option>
              <option value="pickup">Pickup</option>
            </select>
          </div>
        </div>

        {/* Truck List with Real Photos */}
        {filteredTrucks.length === 0 ? (
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-12 text-center space-y-4 shadow-sm">
            <div className="w-16 h-16 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center mx-auto text-2xl">
              🚛
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-black text-slate-900 dark:text-white">No trucks found</h3>
              <p className="text-xs text-slate-500">Try changing your filters or add a new truck to your fleet.</p>
            </div>
            <button
              onClick={() => setIsAddModalOpen(true)}
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-sm text-xs cursor-pointer"
            >
              + Add Your First Truck
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {filteredTrucks.map((truck) => (
              <div
                key={truck.id}
                className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl overflow-hidden shadow-sm hover:shadow-md transition flex flex-col justify-between"
              >
                {/* Truck Photo Header */}
                <div className="relative h-44 bg-slate-900 overflow-hidden group">
                  <img
                    src={truck.photoUrl}
                    alt={truck.name}
                    className="w-full h-full object-cover group-hover:scale-105 transition duration-500"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = PRESET_TRUCK_PHOTOS[0].url;
                    }}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 via-transparent to-black/20" />

                  {/* Top Badges */}
                  <div className="absolute top-3 left-3 flex items-center gap-2">
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider backdrop-blur-md shadow-sm ${
                      truck.availability === "Available"
                        ? "bg-emerald-500/90 text-white"
                        : truck.availability === "On Trip"
                        ? "bg-blue-500/90 text-white"
                        : "bg-slate-500/90 text-white"
                    }`}>
                      {truck.availability}
                    </span>
                    <span className="bg-black/60 backdrop-blur-md text-amber-400 font-mono font-bold text-[10px] px-2 py-1 rounded-full border border-amber-400/30">
                      {truck.type}
                    </span>
                  </div>

                  {/* Rating Badge */}
                  <div className="absolute top-3 right-3 bg-white/90 backdrop-blur-md text-slate-900 font-black text-xs px-2.5 py-1 rounded-full flex items-center gap-1 shadow-sm">
                    <span className="text-amber-500">★</span>
                    <span>{truck.rating}</span>
                  </div>

                  {/* Bottom Image Overlay Details */}
                  <div className="absolute bottom-3 left-3 right-3 text-white">
                    <span className="font-mono font-black text-xs tracking-wider bg-amber-400 text-slate-950 px-2 py-0.5 rounded-md inline-block shadow-sm mb-1">
                      {truck.regNo}
                    </span>
                    <h3 className="font-black text-base truncate">{truck.name}</h3>
                  </div>
                </div>

                {/* Card Body */}
                <div className="p-5 space-y-4 flex-1 flex flex-col justify-between">
                  <div className="space-y-3">
                    {/* Specs Grid */}
                    <div className="grid grid-cols-2 gap-2 text-xs font-bold bg-slate-50 dark:bg-slate-800/60 p-3 rounded-2xl border border-slate-100 dark:border-slate-700/60">
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase block font-semibold">Capacity</span>
                        <span className="text-slate-900 dark:text-white">{truck.capacity}</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase block font-semibold">Body Type</span>
                        <span className="text-slate-900 dark:text-white">{truck.body}</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase block font-semibold">Driver</span>
                        <span className="text-slate-900 dark:text-white truncate block">{truck.driverName || "Assigned Driver"}</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase block font-semibold">Location</span>
                        <span className="text-slate-900 dark:text-white truncate block">{truck.location}</span>
                      </div>
                    </div>

                    {/* Current Trip Status */}
                    {truck.currentTrip && (
                      <div className="text-xs p-2.5 rounded-xl bg-amber-50/70 dark:bg-slate-800 border border-amber-200/60 dark:border-slate-700 font-bold space-y-1">
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] uppercase text-amber-800 dark:text-amber-400 font-black">Active Route</span>
                          <span className="text-[10px] text-emerald-700 dark:text-emerald-400 font-extrabold">{truck.currentTrip.status}</span>
                        </div>
                        <p className="text-slate-900 dark:text-white text-xs">
                          {truck.currentTrip.origin} ➔ {truck.currentTrip.dest}
                        </p>
                      </div>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between gap-2">
                    <button
                      onClick={() => setSelectedTruck(truck)}
                      className="flex-1 bg-slate-900 hover:bg-slate-800 text-white font-black py-2.5 rounded-xl text-xs transition text-center shadow-sm cursor-pointer"
                    >
                      View Details &amp; Specs
                    </button>
                    <button
                      onClick={() => handleDelete(truck.id)}
                      className="p-2.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition cursor-pointer"
                      title="Delete Truck"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ========================================================================= */}
      {/* MODAL 1: VIEW TRUCK DETAILS */}
      {/* ========================================================================= */}
      {selectedTruck && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl space-y-6">
            {/* Modal Image Header */}
            <div className="relative h-64 bg-slate-950">
              <img
                src={selectedTruck.photoUrl}
                alt={selectedTruck.name}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/30 to-transparent" />

              <button
                onClick={() => setSelectedTruck(null)}
                className="absolute top-4 right-4 w-9 h-9 rounded-full bg-black/60 text-white flex items-center justify-center hover:bg-black transition cursor-pointer"
              >
                <X size={18} />
              </button>

              <div className="absolute bottom-4 left-6 right-6 text-white space-y-1">
                <div className="flex items-center gap-2">
                  <span className="font-mono font-black text-xs tracking-wider bg-amber-400 text-slate-950 px-2.5 py-0.5 rounded-md">
                    {selectedTruck.regNo}
                  </span>
                  <span className="bg-emerald-500 text-white font-black text-[10px] px-2.5 py-0.5 rounded-full flex items-center gap-1">
                    <ShieldCheck size={12} /> Verified RC
                  </span>
                </div>
                <h2 className="text-2xl font-black">{selectedTruck.name}</h2>
                <p className="text-xs text-slate-300 font-medium">
                  {selectedTruck.type} • {selectedTruck.body} • Base Hub: {selectedTruck.location}
                </p>
              </div>
            </div>

            {/* Modal Body */}
            <div className="p-6 pt-0 space-y-6">
              {/* Technical Specifications */}
              <div className="space-y-3">
                <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider flex items-center gap-1.5">
                  <Gauge size={16} className="text-amber-500" /> Vehicle Specifications
                </h3>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs font-bold">
                  <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100">
                    <span className="text-[10px] text-slate-400 uppercase block font-semibold">Tonnage</span>
                    <span className="text-slate-900 text-sm">{selectedTruck.capacity}</span>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100">
                    <span className="text-[10px] text-slate-400 uppercase block font-semibold">Length</span>
                    <span className="text-slate-900 text-sm">{selectedTruck.type}</span>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100">
                    <span className="text-[10px] text-slate-400 uppercase block font-semibold">Total Trips</span>
                    <span className="text-slate-900 text-sm">{selectedTruck.totalTrips} Completed</span>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100">
                    <span className="text-[10px] text-slate-400 uppercase block font-semibold">Total Revenue</span>
                    <span className="text-emerald-700 text-sm">{selectedTruck.totalEarnings}</span>
                  </div>
                </div>
              </div>

              {/* Assigned Driver Profile */}
              <div className="space-y-3">
                <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider flex items-center gap-1.5">
                  <User size={16} className="text-amber-500" /> Assigned Driver Information
                </h3>
                <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 flex items-center justify-between flex-wrap gap-3">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-amber-400 text-slate-950 font-black text-lg flex items-center justify-center shadow-sm">
                      {selectedTruck.driverName.charAt(0) || "D"}
                    </div>
                    <div>
                      <h4 className="font-black text-slate-900 text-sm">{selectedTruck.driverName || "Driver Not Assigned"}</h4>
                      <p className="text-xs text-slate-500 font-medium">Driving License: {selectedTruck.driverLicense}</p>
                    </div>
                  </div>
                  <a
                    href={`tel:${selectedTruck.driverPhone}`}
                    className="inline-flex items-center gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs px-4 py-2 rounded-xl shadow-sm transition"
                  >
                    <Phone size={14} /> Call Driver ({selectedTruck.driverPhone})
                  </a>
                </div>
              </div>

              {/* Document Validity Check */}
              <div className="space-y-3">
                <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider flex items-center gap-1.5">
                  <FileText size={16} className="text-amber-500" /> Compliance &amp; Permits
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs font-bold">
                  <div className="p-3 bg-emerald-50/60 border border-emerald-200 rounded-xl space-y-1">
                    <div className="flex items-center gap-1 text-emerald-800 font-black">
                      <CheckCircle2 size={14} /> Comprehensive Insurance
                    </div>
                    <span className="text-[10px] text-slate-600 block">Valid till {selectedTruck.insuranceValidTill}</span>
                  </div>
                  <div className="p-3 bg-emerald-50/60 border border-emerald-200 rounded-xl space-y-1">
                    <div className="flex items-center gap-1 text-emerald-800 font-black">
                      <CheckCircle2 size={14} /> Fitness Certificate
                    </div>
                    <span className="text-[10px] text-slate-600 block">Valid till {selectedTruck.fitnessValidTill}</span>
                  </div>
                  <div className="p-3 bg-emerald-50/60 border border-emerald-200 rounded-xl space-y-1">
                    <div className="flex items-center gap-1 text-emerald-800 font-black">
                      <CheckCircle2 size={14} /> PUC &amp; National Permit
                    </div>
                    <span className="text-[10px] text-slate-600 block">Valid till {selectedTruck.pucValidTill}</span>
                  </div>
                </div>
              </div>

              {/* Modal Actions */}
              <div className="flex items-center justify-between gap-3 pt-4 border-t border-slate-100">
                <button
                  onClick={() => handleDelete(selectedTruck.id)}
                  className="px-4 py-2.5 rounded-xl border border-rose-200 text-rose-600 font-bold text-xs hover:bg-rose-50 transition"
                >
                  Delete Truck
                </button>
                <button
                  onClick={() => setSelectedTruck(null)}
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition"
                >
                  Close Details
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 2: ADD NEW TRUCK */}
      {/* ========================================================================= */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl p-6 space-y-6">
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div>
                <h2 className="text-xl font-black text-slate-900">Add New Commercial Vehicle</h2>
                <p className="text-xs text-slate-500">Add your truck with genuine photos and start earning backhaul revenue.</p>
              </div>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="p-2 text-slate-400 hover:text-slate-700 rounded-xl hover:bg-slate-100"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateTruck} className="space-y-4 text-xs font-bold">
              {/* Photo Selector */}
              <div className="space-y-2">
                <label className="text-slate-800 block">Truck Photo (Upload or Select Real Preset) *</label>

                <div className="flex items-center gap-4">
                  <div className="w-28 h-20 rounded-2xl bg-slate-900 overflow-hidden border-2 border-amber-400 shrink-0 shadow-sm">
                    <img
                      src={newTruck.photoUrl}
                      alt="Preview"
                      className="w-full h-full object-cover"
                    />
                  </div>

                  <div className="flex-1 space-y-2">
                    <input
                      type="file"
                      ref={fileInputRef}
                      onChange={handleFileUpload}
                      accept="image/*"
                      className="hidden"
                    />
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      className="bg-slate-100 hover:bg-slate-200 text-slate-800 px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition"
                    >
                      <Upload size={14} /> Upload Custom Photo from Device
                    </button>
                    <p className="text-[10px] text-slate-400">Or pick an authentic Indian truck preset below:</p>
                  </div>
                </div>

                {/* Presets */}
                <div className="grid grid-cols-3 sm:grid-cols-6 gap-2 pt-1">
                  {PRESET_TRUCK_PHOTOS.map((preset, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setNewTruck({ ...newTruck, photoUrl: preset.url })}
                      className={`relative h-14 rounded-xl overflow-hidden border-2 transition ${
                        newTruck.photoUrl === preset.url ? "border-amber-500 ring-2 ring-amber-400/40" : "border-slate-200 opacity-70 hover:opacity-100"
                      }`}
                    >
                      <img src={preset.url} alt={preset.label} className="w-full h-full object-cover" />
                    </button>
                  ))}
                </div>
              </div>

              {/* Model Name & RC Number */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-slate-700 block mb-1">Truck Model &amp; Make *</label>
                  <input
                    required
                    value={newTruck.name}
                    onChange={(e) => setNewTruck({ ...newTruck, name: e.target.value })}
                    placeholder="e.g. Eicher Pro 2049"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
                <div>
                  <label className="text-slate-700 block mb-1">Registration Number (RC) *</label>
                  <input
                    required
                    value={newTruck.regNo}
                    onChange={(e) => setNewTruck({ ...newTruck, regNo: e.target.value.toUpperCase() })}
                    placeholder="e.g. DL 01 AB 1234"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 text-slate-900 uppercase font-mono focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
              </div>

              {/* Type, Body, Capacity */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="text-slate-700 block mb-1">Vehicle Length</label>
                  <select
                    value={newTruck.type}
                    onChange={(e) => setNewTruck({ ...newTruck, type: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  >
                    <option>14 Feet</option>
                    <option>17 Feet</option>
                    <option>19 Feet</option>
                    <option>22 Feet</option>
                    <option>32 Feet Single Axle</option>
                    <option>32 Feet Multi Axle</option>
                    <option>Pickup / Mini Truck</option>
                  </select>
                </div>
                <div>
                  <label className="text-slate-700 block mb-1">Body Type</label>
                  <select
                    value={newTruck.body}
                    onChange={(e) => setNewTruck({ ...newTruck, body: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  >
                    <option>Enclosed Container</option>
                    <option>Open Body</option>
                    <option>Tarpaulin Covered</option>
                    <option>Flatbed</option>
                    <option>Tipper</option>
                  </select>
                </div>
                <div>
                  <label className="text-slate-700 block mb-1">Max Payload (Tons)</label>
                  <input
                    type="number"
                    step="0.5"
                    value={newTruck.capacityTons}
                    onChange={(e) => setNewTruck({ ...newTruck, capacityTons: parseFloat(e.target.value) || 0 })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  />
                </div>
              </div>

              {/* Route Availability & Empty Capacity Corridor */}
              <div className="p-4 rounded-2xl bg-amber-50/80 border border-amber-200/80 space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-black text-amber-900 uppercase tracking-wider flex items-center gap-1.5">
                    <MapPin size={14} className="text-amber-600" /> Route Corridor &amp; Empty Space Availability
                  </h4>
                  <span className="text-[10px] bg-amber-200/80 text-amber-900 font-bold px-2 py-0.5 rounded-full">
                    Instant AI Backhaul Matching
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <LocationSearchInput
                      required
                      value={newTruck.routeOrigin}
                      onChange={(val) => setNewTruck({ ...newTruck, routeOrigin: val })}
                      label="Departure Origin (Route From) *"
                      iconType="pickup"
                      placeholder="e.g. Delhi NCR, Gurgaon, Okhla..."
                    />
                  </div>
                  <div>
                    <LocationSearchInput
                      required
                      value={newTruck.routeDest}
                      onChange={(val) => setNewTruck({ ...newTruck, routeDest: val })}
                      label="Destination Hub (Route To) *"
                      iconType="drop"
                      placeholder="e.g. Mumbai, Bhiwandi, Pune..."
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div>
                    <label className="text-slate-700 block mb-1">Empty Space Available (Tons)</label>
                    <input
                      type="number"
                      step="0.5"
                      value={newTruck.availableCapacityTons}
                      onChange={(e) => setNewTruck({ ...newTruck, availableCapacityTons: parseFloat(e.target.value) || 0 })}
                      className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    />
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Available Departure Date</label>
                    <input
                      value={newTruck.departureDate}
                      onChange={(e) => setNewTruck({ ...newTruck, departureDate: e.target.value })}
                      placeholder="e.g. 24 Aug 2026, 09:00 AM"
                      className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    />
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Target Freight Rate (₹)</label>
                    <input
                      value={newTruck.expectedRate}
                      onChange={(e) => setNewTruck({ ...newTruck, expectedRate: e.target.value })}
                      placeholder="e.g. ₹24,500"
                      className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                    />
                  </div>
                </div>
              </div>

              {/* Driver Details */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="text-slate-700 block mb-1">Assigned Driver Name</label>
                  <input
                    value={newTruck.driverName}
                    onChange={(e) => setNewTruck({ ...newTruck, driverName: e.target.value })}
                    placeholder="Driver Name"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  />
                </div>
                <div>
                  <label className="text-slate-700 block mb-1">Driver Phone Number</label>
                  <input
                    value={newTruck.driverPhone}
                    onChange={(e) => setNewTruck({ ...newTruck, driverPhone: e.target.value })}
                    placeholder="+91 98765 43210"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  />
                </div>
                <div>
                  <label className="text-slate-700 block mb-1">Base Hub City</label>
                  <input
                    value={newTruck.location}
                    onChange={(e) => setNewTruck({ ...newTruck, location: e.target.value })}
                    placeholder="e.g. Delhi NCR"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2.5 rounded-xl border border-slate-200 text-slate-700 font-bold hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl shadow-md transition cursor-pointer"
                >
                  Save &amp; Activate Truck
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
