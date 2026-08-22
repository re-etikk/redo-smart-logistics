import { useState } from "react";
import {
  Truck, CalendarCheck, IndianRupee, Search, Plus, MoreVertical, ShieldCheck, AlertTriangle, Check
} from "lucide-react";
import OwnerLayout from "../../components/OwnerLayout";

export default function MyTrucks() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");

  const truckList = [
    {
      id: "T1",
      name: "Eicher 17 Feet",
      status: "Active",
      type: "17 Feet",
      capacity: "7 Ton",
      body: "Enclosed",
      regNo: "HR55 AB 1234",
      insurance: "Valid till 20 Aug 2024",
      insuranceStatus: "valid",
      puc: "Valid till 10 Jul 2024",
      pucStatus: "valid",
      availability: "Available",
      location: "Delhi, Delhi",
      earnings: "₹45,600",
      bookings: "8",
      emoji: "🚛",
    },
    {
      id: "T2",
      name: "BharatBenz 19 Feet",
      status: "Active",
      type: "19 Feet",
      capacity: "10 Ton",
      body: "Enclosed",
      regNo: "HR55 CD 5678",
      insurance: "Valid till 18 Sep 2024",
      insuranceStatus: "valid",
      puc: "Valid till 05 Aug 2024",
      pucStatus: "valid",
      availability: "On Trip",
      location: "Mumbai, Maharashtra",
      earnings: "₹52,300",
      bookings: "10",
      emoji: "🚚",
    },
    {
      id: "T3",
      name: "Tata 14 Feet",
      status: "Inactive",
      type: "14 Feet",
      capacity: "5 Ton",
      body: "Open Body",
      regNo: "HR55 EF 9012",
      insurance: "Expired on 10 May 2024",
      insuranceStatus: "expired",
      puc: "Valid till 01 Jun 2024",
      pucStatus: "valid",
      availability: "Not Available",
      location: "Indore, Madhya Pradesh",
      earnings: "₹12,800",
      bookings: "3",
      emoji: "🚛",
    },
    {
      id: "T4",
      name: "Mahindra Pickup",
      status: "Active",
      type: "Pickup",
      capacity: "1.5 Ton",
      body: "Open Body",
      regNo: "HR55 GH 3456",
      insurance: "Valid till 15 Oct 2024",
      insuranceStatus: "valid",
      puc: "Valid till 20 Aug 2024",
      pucStatus: "valid",
      availability: "Available",
      location: "Delhi, Delhi",
      earnings: "₹9,250",
      bookings: "2",
      emoji: "🛻",
    },
    {
      id: "T5",
      name: "BharatBenz 32 Feet",
      status: "Active",
      type: "32 Feet",
      capacity: "16 Ton",
      body: "Tipper",
      regNo: "HR55 IJ 7890",
      insurance: "Valid till 25 Sep 2024",
      insuranceStatus: "valid",
      puc: "Valid till 12 Aug 2024",
      pucStatus: "valid",
      availability: "On Trip",
      location: "Bengaluru, Karnataka",
      earnings: "₹28,800",
      bookings: "5",
      emoji: "🚛",
    },
  ];

  const filteredTrucks = truckList.filter((t) => {
    const matchesSearch =
      t.name.toLowerCase().includes(search.toLowerCase()) ||
      t.regNo.toLowerCase().includes(search.toLowerCase()) ||
      t.type.toLowerCase().includes(search.toLowerCase());
    const matchesStatus =
      statusFilter === "all" ||
      (statusFilter === "active" && t.status === "Active") ||
      (statusFilter === "inactive" && t.status === "Inactive");
    return matchesSearch && matchesStatus;
  });

  return (
    <OwnerLayout activeTab="trucks" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title + Add New Truck Button matching Mockup 2 */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">My Trucks</h1>
            <p className="text-xs text-slate-500 mt-0.5">Manage your trucks, view status and track performance.</p>
          </div>

          <button
            className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-sm transition text-xs flex items-center gap-2"
          >
            <Plus size={16} /> Add New Truck
          </button>
        </div>

        {/* 4 Stat Cards matching Mockup 2 */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Trucks</span>
              <span className="text-xl font-black text-slate-900 block">5</span>
              <span className="text-[10px] font-bold text-emerald-600 block">Active</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Truck size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Active Trucks</span>
              <span className="text-xl font-black text-slate-900 block">4</span>
              <span className="text-[10px] font-bold text-blue-600 block">On the road</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <CalendarCheck size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Bookings</span>
              <span className="text-xl font-black text-slate-900 block">28</span>
              <span className="text-[10px] font-bold text-purple-600 block">This Month</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <CalendarCheck size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Earnings</span>
              <span className="text-xl font-black text-slate-900 block">₹1,48,750</span>
              <span className="text-[10px] font-bold text-amber-600 block">This Month</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <IndianRupee size={20} />
            </div>
          </div>
        </div>

        {/* Filter Toolbar matching Mockup 2 */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm grid grid-cols-1 sm:grid-cols-4 gap-3 text-xs">
          <div className="relative sm:col-span-2">
            <Search size={16} className="text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by truck number or type"
              className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 font-bold"
            />
          </div>

          <div>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900 font-bold focus:outline-none cursor-pointer"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>

          <div>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900 font-bold focus:outline-none cursor-pointer"
            >
              <option value="all">All Types</option>
              <option value="17">17 Feet</option>
              <option value="19">19 Feet</option>
              <option value="14">14 Feet</option>
              <option value="pickup">Pickup</option>
            </select>
          </div>
        </div>

        {/* Truck List Cards matching Mockup 2 */}
        <div className="space-y-3">
          {filteredTrucks.map((t) => (
            <div
              key={t.id}
              className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm hover:shadow-md transition flex flex-col md:flex-row items-start md:items-center justify-between gap-4"
            >
              {/* Left Truck Info */}
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-2xl bg-amber-50 border border-amber-200 flex items-center justify-center text-3xl shrink-0">
                  {t.emoji}
                </div>
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <h3 className="font-black text-slate-900 text-sm">{t.name}</h3>
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-black ${
                        t.status === "Active"
                          ? "bg-emerald-100 text-emerald-800"
                          : "bg-amber-100 text-amber-800"
                      }`}
                    >
                      {t.status}
                    </span>
                  </div>
                  <div className="text-[11px] text-slate-500 font-semibold flex flex-wrap items-center gap-2">
                    <span>{t.type}</span>
                    <span>|</span>
                    <span>{t.capacity}</span>
                    <span>|</span>
                    <span>{t.body}</span>
                  </div>
                  <div className="text-xs font-black text-slate-700">{t.regNo}</div>
                </div>
              </div>

              {/* Middle Documents Validity */}
              <div className="space-y-1 text-xs border-t md:border-t-0 md:border-l border-slate-100 pt-3 md:pt-0 md:pl-6">
                <div className="flex items-center gap-2">
                  {t.insuranceStatus === "valid" ? (
                    <Check size={14} className="text-emerald-500" />
                  ) : (
                    <AlertTriangle size={14} className="text-rose-500" />
                  )}
                  <span className={`text-[11px] font-semibold ${t.insuranceStatus === "expired" ? "text-rose-600 font-bold" : "text-slate-600"}`}>
                    Insurance: {t.insurance}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Check size={14} className="text-emerald-500" />
                  <span className="text-[11px] font-semibold text-slate-600">
                    PUC: {t.puc}
                  </span>
                </div>
              </div>

              {/* Right Availability & Earnings */}
              <div className="flex items-center justify-between md:justify-end gap-6 w-full md:w-auto border-t md:border-t-0 border-slate-100 pt-3 md:pt-0">
                <div className="text-left md:text-right">
                  <span className="text-[10px] font-bold text-slate-400 block uppercase">Availability</span>
                  <span
                    className={`text-xs font-black block ${
                      t.availability === "Available"
                        ? "text-emerald-600"
                        : t.availability === "On Trip"
                        ? "text-blue-600"
                        : "text-rose-600"
                    }`}
                  >
                    {t.availability}
                  </span>
                  <span className="text-[10px] text-slate-500 font-medium">{t.location}</span>
                </div>

                <div className="text-right">
                  <span className="text-[10px] font-bold text-slate-400 block uppercase">Earnings</span>
                  <span className="text-sm font-black text-slate-900 block">{t.earnings}</span>
                  <span className="text-[10px] text-slate-500 font-medium">Bookings: {t.bookings}</span>
                </div>

                <button className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-xl transition">
                  <MoreVertical size={18} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </OwnerLayout>
  );
}
