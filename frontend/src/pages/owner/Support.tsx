import { useState } from "react";
import {
  MessageSquare, CheckCircle2, Clock, Plus, ChevronRight, Phone, Mail, FileText
} from "lucide-react";
import OwnerLayout from "../../components/OwnerLayout";

export default function OwnerSupport() {
  const [activeTab, setActiveTab] = useState("my");

  const ticketList = [
    { id: "S1", title: "Payment not received for Trip ID: TRIP124567", desc: "I have completed the trip but payment is not reflected in my wallet.", ticketNo: "#SUP12456", date: "19 Jun 2024, 09:30 AM", status: "Open", statusTone: "bg-[#FFC800]/20 text-slate-950 font-black" },
    { id: "S2", title: "Wallet balance deduction issue", desc: "Amount was deducted but booking was not confirmed.", ticketNo: "#SUP12455", date: "18 Jun 2024, 02:15 PM", status: "In Progress", statusTone: "bg-amber-100 text-amber-800 font-black" },
    { id: "S3", title: "Need help with document upload", desc: "Facing issue while uploading insurance certificate.", ticketNo: "#SUP12438", date: "16 Jun 2024, 11:20 AM", status: "Open", statusTone: "bg-blue-100 text-blue-800 font-black" },
    { id: "S4", title: "How to add a new truck?", desc: "I want to add another truck. Please help me with the process.", ticketNo: "#SUP12420", date: "12 Jun 2024, 04:45 PM", status: "Resolved", statusTone: "bg-emerald-100 text-emerald-800 font-black" },
    { id: "S5", title: "Incorrect toll deduction", desc: "Extra toll charges were deducted for Trip ID: TRIP124450", ticketNo: "#SUP12410", date: "08 Jun 2024, 10:05 AM", status: "Resolved", statusTone: "bg-emerald-100 text-emerald-800 font-black" },
  ];

  return (
    <OwnerLayout activeTab="support" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title matching Mockup 9 */}
        <div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">Support</h1>
          <p className="text-xs text-slate-500 mt-0.5">We're here to help! Raise a request or check the status of your queries.</p>
        </div>

        {/* 3 Stat Cards matching Mockup 9 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Tickets</span>
              <span className="text-xl font-black text-slate-900 block">12</span>
              <span className="text-[10px] font-bold text-slate-500 block">All Time</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <FileText size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Open Tickets</span>
              <span className="text-xl font-black text-slate-900 block">3</span>
              <span className="text-[10px] font-bold text-amber-600 block">Requires Attention</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <Clock size={20} />
            </div>
          </div>

          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Resolved Tickets</span>
              <span className="text-xl font-black text-slate-900 block">9</span>
              <span className="text-[10px] font-bold text-emerald-600 block">All Time</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <CheckCircle2 size={20} />
            </div>
          </div>
        </div>

        {/* Main Grid: Support Tickets + Categories & Helpline Sidebar matching Mockup 9 */}
        <div className="grid gap-6 lg:grid-cols-[1fr_340px]">
          {/* Tickets List Column */}
          <div className="space-y-4">
            {/* Header Tabs + New Support Ticket Button */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm flex items-center justify-between gap-4">
              <div className="flex items-center gap-2 text-xs font-extrabold">
                <button onClick={() => setActiveTab("my")} className={`px-4 py-2 rounded-xl transition ${activeTab === "my" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>My Tickets</button>
                <button onClick={() => setActiveTab("closed")} className={`px-4 py-2 rounded-xl transition ${activeTab === "closed" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Closed Tickets</button>
              </div>

              <button className="bg-slate-950 hover:bg-slate-800 text-white font-black px-4 py-2 rounded-xl shadow-sm text-xs transition flex items-center gap-1.5">
                <Plus size={14} /> New Support Ticket
              </button>
            </div>

            {/* Tickets List */}
            <div className="space-y-3">
              {ticketList.map((t) => (
                <div key={t.id} className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm hover:shadow-md transition flex items-center justify-between gap-4">
                  <div className="flex items-start gap-4">
                    <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold shrink-0 mt-0.5">
                      <MessageSquare size={18} />
                    </div>
                    <div className="space-y-1">
                      <h4 className="font-black text-slate-900 text-xs">{t.title}</h4>
                      <p className="text-[11px] text-slate-500 font-medium">{t.desc}</p>
                      <div className="text-[10px] text-slate-400 font-bold">
                        {t.ticketNo} · {t.date}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <span className={`px-3 py-1 rounded-full text-[10px] ${t.statusTone}`}>
                      {t.status}
                    </span>
                    <ChevronRight size={16} className="text-slate-400" />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right Help Categories & FAQs Sidebar matching Mockup 9 */}
          <div className="space-y-6">
            {/* How can we help you Card */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
              <h4 className="font-black text-xs text-slate-900">How can we help you?</h4>
              <p className="text-[10px] text-slate-500 font-medium">Choose a category to get started</p>

              <div className="space-y-2 text-xs font-bold pt-1">
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-amber-50 transition cursor-pointer">
                  <div className="flex items-center gap-2.5">
                    <div className="w-7 h-7 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center text-xs">💳</div>
                    <div>
                      <span className="block text-slate-900">Payments &amp; Wallet</span>
                      <span className="text-[9px] text-slate-400 font-medium">Issues related to payments</span>
                    </div>
                  </div>
                  <ChevronRight size={14} className="text-slate-400" />
                </div>

                <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-amber-50 transition cursor-pointer">
                  <div className="flex items-center gap-2.5">
                    <div className="w-7 h-7 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center text-xs">🚚</div>
                    <div>
                      <span className="block text-slate-900">Trips &amp; Bookings</span>
                      <span className="text-[9px] text-slate-400 font-medium">Trip issues &amp; rescheduling</span>
                    </div>
                  </div>
                  <ChevronRight size={14} className="text-slate-400" />
                </div>

                <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-amber-50 transition cursor-pointer">
                  <div className="flex items-center gap-2.5">
                    <div className="w-7 h-7 rounded-lg bg-purple-100 text-purple-700 flex items-center justify-center text-xs">👤</div>
                    <div>
                      <span className="block text-slate-900">Account &amp; Profile</span>
                      <span className="text-[9px] text-slate-400 font-medium">KYC &amp; profile settings</span>
                    </div>
                  </div>
                  <ChevronRight size={14} className="text-slate-400" />
                </div>
              </div>
            </div>

            {/* FAQs & Contact Info */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
              <h4 className="font-black text-xs text-slate-900">Still need help?</h4>
              <p className="text-[10px] text-slate-500 font-medium">Our support team is available 24/7</p>

              <div className="space-y-2 text-xs font-bold pt-1">
                <div className="flex items-center gap-2 text-slate-800">
                  <Phone size={14} className="text-amber-500" /> +91 98765 43210
                </div>
                <div className="flex items-center gap-2 text-slate-800">
                  <Mail size={14} className="text-amber-500" /> support@redo.com
                </div>
                <span className="inline-block text-[10px] font-extrabold text-emerald-700 bg-emerald-100 px-2.5 py-1 rounded-full mt-1">
                  Average response time: 15 mins
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
