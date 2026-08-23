import { useState } from "react";
import {
  Star, Users, ThumbsUp, CalendarCheck, Filter, ChevronRight, MessageSquare, ShieldCheck, Sparkles
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";

export default function Reviews() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState("all");

  const reviewList = [
    { id: "R1", name: "Arjun Singh", trip: "Trip ID: TRIP124567 (Delhi → Mumbai)", date: "19 Jun 2024", rating: 5, comment: "Excellent service! Truck was on time and delivery was smooth. Driver was professional and polite.", badge: "On-time Delivery", badgeTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400", initials: "AS", color: "bg-emerald-100 text-emerald-800" },
    { id: "R2", name: "Rakesh Patel", trip: "Trip ID: TRIP124556 (Delhi → Indore)", date: "18 Jun 2024", rating: 5, comment: "Very good experience. Goods delivered safely without any damage.", badge: "Safe Delivery", badgeTone: "bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-400", initials: "RP", color: "bg-blue-100 text-blue-800" },
    { id: "R3", name: "Pooja Kulkarni", trip: "Trip ID: TRIP124544 (Mumbai → Pune)", date: "17 Jun 2024", rating: 4, comment: "Good service. Driver was cooperative. Delivery was a little delayed due to traffic.", badge: "Good Service", badgeTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400", initials: "PK", color: "bg-amber-100 text-amber-800" },
    { id: "R4", name: "Vikram Kumar", trip: "Trip ID: TRIP124533 (Bengaluru → Chennai)", date: "15 Jun 2024", rating: 5, comment: "Awesome experience! Will book again.", badge: "On-time Delivery", badgeTone: "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400", initials: "VK", color: "bg-purple-100 text-purple-800" },
    { id: "R5", name: "Neha Gupta", trip: "Trip ID: TRIP124520 (Lucknow → Delhi)", date: "14 Jun 2024", rating: 4, comment: "Overall good. Communication can be improved.", badge: "Communication", badgeTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400", initials: "NG", color: "bg-rose-100 text-rose-800" },
  ];

  return (
    <OwnerLayout activeTab="reviews" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight">{t("reviews")} &amp; Driver Ratings</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Customer feedback and fleet performance reviews.</p>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2 shadow-sm">
            <CalendarCheck size={14} className="text-amber-500" />
            <span>20 May 2024 - 20 Jun 2024</span>
          </div>
        </div>

        {/* 4 Stat Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Overall Rating</span>
              <div className="flex items-center gap-1">
                <span className="text-xl font-black text-slate-900 dark:text-white">4.8</span>
                <Star size={16} className="text-amber-500 fill-amber-400" />
              </div>
              <span className="text-[10px] font-bold text-slate-500 block">(128 Reviews)</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <Star size={20} />
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Reviews</span>
              <span className="text-xl font-black text-slate-900 dark:text-white block">128</span>
              <span className="text-[10px] font-bold text-emerald-600 block">↑ 18.4% vs last month</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Users size={20} />
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Positive Rating</span>
              <span className="text-xl font-black text-slate-900 dark:text-white block">94%</span>
              <span className="text-[10px] font-bold text-emerald-600 block">↑ 2.1% vs last month</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <ThumbsUp size={20} />
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">5 Star Reviews</span>
              <span className="text-xl font-black text-slate-900 dark:text-white block">98</span>
              <span className="text-[10px] font-bold text-slate-500 block">Out of 128 reviews</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Star size={20} />
            </div>
          </div>
        </div>

        {/* Reviews List */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
            <h3 className="font-black text-xs uppercase tracking-wider text-slate-900 dark:text-white">Recent Customer Testimonials</h3>
            <div className="flex items-center gap-1">
              {["all", "5-star", "4-star", "critical"].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-3 py-1 rounded-xl capitalize text-xs font-bold transition cursor-pointer ${
                    activeTab === tab
                      ? "bg-[#FFC800] text-slate-950 font-black shadow-sm"
                      : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>

          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {reviewList.map((rev) => (
              <div key={rev.id} className="py-4 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 flex items-center justify-center font-black text-xs">
                      {rev.initials}
                    </div>
                    <div>
                      <h4 className="font-black text-xs sm:text-sm text-slate-900 dark:text-white">{rev.name}</h4>
                      <p className="text-[10px] text-slate-400">{rev.trip} • {rev.date}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-1 text-amber-500">
                    {Array.from({ length: rev.rating }).map((_, i) => (
                      <Star key={i} size={14} className="fill-amber-400" />
                    ))}
                  </div>
                </div>

                <p className="text-xs text-slate-600 dark:text-slate-300 font-medium pl-10">
                  "{rev.comment}"
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
