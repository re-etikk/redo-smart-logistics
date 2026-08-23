import { useState } from "react";
import {
  Star, Users, ThumbsUp, CalendarCheck, Filter, ChevronRight, MessageSquare, ShieldCheck, Sparkles
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";

export default function Reviews() {
  const [activeTab, setActiveTab] = useState("all");

  const reviewList = [
    { id: "R1", name: "Arjun Singh", trip: "Trip ID: TRIP124567 (Delhi → Mumbai)", date: "19 Jun 2024", rating: 5, comment: "Excellent service! Truck was on time and delivery was smooth. Driver was professional and polite.", badge: "On-time Delivery", badgeTone: "bg-emerald-100 text-emerald-800", initials: "AS", color: "bg-emerald-100 text-emerald-800" },
    { id: "R2", name: "Rakesh Patel", trip: "Trip ID: TRIP124556 (Delhi → Indore)", date: "18 Jun 2024", rating: 5, comment: "Very good experience. Goods delivered safely without any damage.", badge: "Safe Delivery", badgeTone: "bg-blue-100 text-blue-800", initials: "RP", color: "bg-blue-100 text-blue-800" },
    { id: "R3", name: "Pooja Kulkarni", trip: "Trip ID: TRIP124544 (Mumbai → Pune)", date: "17 Jun 2024", rating: 4, comment: "Good service. Driver was cooperative. Delivery was a little delayed due to traffic.", badge: "Good Service", badgeTone: "bg-amber-100 text-amber-800", initials: "PK", color: "bg-amber-100 text-amber-800" },
    { id: "R4", name: "Vikram Kumar", trip: "Trip ID: TRIP124533 (Bengaluru → Chennai)", date: "15 Jun 2024", rating: 5, comment: "Awesome experience! Will book again.", badge: "On-time Delivery", badgeTone: "bg-emerald-100 text-emerald-800", initials: "VK", color: "bg-purple-100 text-purple-800" },
    { id: "R5", name: "Neha Gupta", trip: "Trip ID: TRIP124520 (Lucknow → Delhi)", date: "14 Jun 2024", rating: 4, comment: "Overall good. Communication can be improved.", badge: "Communication", badgeTone: "bg-amber-100 text-amber-800", initials: "NG", color: "bg-rose-100 text-rose-800" },
  ];

  return (
    <OwnerLayout activeTab="reviews" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title matching Mockup 8 */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">Reviews</h1>
            <p className="text-xs text-slate-500 mt-0.5">See what customers say about you and your service.</p>
          </div>

          <div className="bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-700 flex items-center gap-2 shadow-sm">
            <CalendarCheck size={14} className="text-amber-500" />
            <span>20 May 2024 - 20 Jun 2024</span>
          </div>
        </div>

        {/* 4 Stat Cards matching Mockup 8 */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Overall Rating</span>
              <div className="flex items-center gap-1">
                <span className="text-xl font-black text-slate-900">4.8</span>
                <Star size={16} className="text-amber-500 fill-amber-400" />
              </div>
              <span className="text-[10px] font-bold text-slate-500 block">(128 Reviews)</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Star size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Reviews</span>
              <span className="text-xl font-black text-slate-900 block">128</span>
              <span className="text-[10px] font-bold text-emerald-600 block">↑ 18.4% vs last month</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <Users size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">5 Star Reviews</span>
              <span className="text-xl font-black text-slate-900 block">104</span>
              <span className="text-[10px] font-bold text-slate-500 block">81.2% of total reviews</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <Star size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Happy Customers</span>
              <span className="text-xl font-black text-slate-900 block">96%</span>
              <span className="text-[10px] font-bold text-emerald-600 block">Would recommend you</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <ThumbsUp size={20} />
            </div>
          </div>
        </div>

        {/* Main Grid: Reviews List + Rating Breakdown Sidebar matching Mockup 8 */}
        <div className="grid gap-6 lg:grid-cols-[1fr_340px]">
          {/* Reviews List Column */}
          <div className="space-y-4">
            {/* Filter Tabs */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm flex items-center justify-between gap-4">
              <div className="flex items-center gap-2 text-xs font-extrabold overflow-x-auto">
                <button onClick={() => setActiveTab("all")} className={`px-3 py-1.5 rounded-xl transition ${activeTab === "all" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>All</button>
                <button onClick={() => setActiveTab("5")} className={`px-3 py-1.5 rounded-xl transition ${activeTab === "5" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>5 Star (104)</button>
                <button onClick={() => setActiveTab("4")} className={`px-3 py-1.5 rounded-xl transition ${activeTab === "4" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>4 Star (18)</button>
                <button onClick={() => setActiveTab("3")} className={`px-3 py-1.5 rounded-xl transition ${activeTab === "3" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>3 Star (4)</button>
              </div>

              <button className="p-2 border border-slate-200 rounded-xl hover:bg-slate-50 text-slate-600 text-xs font-bold flex items-center gap-1">
                <Filter size={14} /> Filter
              </button>
            </div>

            {/* Review Item Cards */}
            <div className="space-y-3">
              {reviewList.map((rev) => (
                <div key={rev.id} className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className={`w-9 h-9 rounded-full ${rev.color} font-black text-xs flex items-center justify-center`}>
                        {rev.initials}
                      </div>
                      <div>
                        <h4 className="font-black text-slate-900 text-xs">{rev.name}</h4>
                        <span className="text-[10px] text-slate-400 font-medium">{rev.trip}</span>
                      </div>
                    </div>

                    <span className="text-[10px] text-slate-400 font-bold">{rev.date}</span>
                  </div>

                  <div className="flex items-center gap-1">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <Star
                        key={star}
                        size={14}
                        className={star <= rev.rating ? "text-amber-500 fill-amber-400" : "text-slate-200"}
                      />
                    ))}
                  </div>

                  <p className="text-xs text-slate-700 font-medium leading-relaxed">
                    "{rev.comment}"
                  </p>

                  <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                    <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold ${rev.badgeTone}`}>
                      {rev.badge}
                    </span>

                    <button className="text-[11px] font-bold text-slate-600 hover:text-amber-600 flex items-center gap-1">
                      View Trip <ChevronRight size={12} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right Rating Breakdown & Insights Sidebar matching Mockup 8 */}
          <div className="space-y-6">
            {/* Rating Breakdown Card */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
              <h4 className="font-black text-xs text-slate-900">Rating Breakdown</h4>

              <div className="space-y-2 text-xs font-bold">
                <div className="flex items-center gap-3">
                  <span className="w-12 text-slate-600">5 Star</span>
                  <div className="flex-1 bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-emerald-500 h-full w-[81%] rounded-full"></div>
                  </div>
                  <span className="text-[10px] text-slate-400 w-12 text-right">104 (81.2%)</span>
                </div>

                <div className="flex items-center gap-3">
                  <span className="w-12 text-slate-600">4 Star</span>
                  <div className="flex-1 bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-emerald-400 h-full w-[14%] rounded-full"></div>
                  </div>
                  <span className="text-[10px] text-slate-400 w-12 text-right">18 (14.1%)</span>
                </div>

                <div className="flex items-center gap-3">
                  <span className="w-12 text-slate-600">3 Star</span>
                  <div className="flex-1 bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-amber-400 h-full w-[3%] rounded-full"></div>
                  </div>
                  <span className="text-[10px] text-slate-400 w-12 text-right">4 (3.1%)</span>
                </div>

                <div className="flex items-center gap-3">
                  <span className="w-12 text-slate-600">2 Star</span>
                  <div className="flex-1 bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-amber-500 h-full w-[1%] rounded-full"></div>
                  </div>
                  <span className="text-[10px] text-slate-400 w-12 text-right">1 (0.8%)</span>
                </div>
              </div>
            </div>

            {/* What Customers Like Card */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
              <h4 className="font-black text-xs text-slate-900">What Customers Like</h4>

              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50">
                  <span className="font-bold text-slate-800">On-time Delivery</span>
                  <span className="text-[10px] text-slate-400 font-bold">96 mentions</span>
                </div>

                <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50">
                  <span className="font-bold text-slate-800">Safe Handling</span>
                  <span className="text-[10px] text-slate-400 font-bold">89 mentions</span>
                </div>

                <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50">
                  <span className="font-bold text-slate-800">Professional Drivers</span>
                  <span className="text-[10px] text-slate-400 font-bold">76 mentions</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
