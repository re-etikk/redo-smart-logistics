import { useState } from "react";
import {
  User, Lock, ChevronRight
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useAuth } from "../hooks/useAuth";

export default function OwnerSettings() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState("profile");

  return (
    <OwnerLayout activeTab="settings" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title matching Mockup 10 */}
        <div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">Settings</h1>
          <p className="text-xs text-slate-500 mt-0.5">Manage your account, preferences and business settings.</p>
        </div>

        {/* Sub Navigation Tabs */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm flex items-center gap-2 overflow-x-auto text-xs font-extrabold">
          <button onClick={() => setActiveTab("profile")} className={`px-4 py-2 rounded-xl transition ${activeTab === "profile" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Profile &amp; Account</button>
          <button onClick={() => setActiveTab("business")} className={`px-4 py-2 rounded-xl transition ${activeTab === "business" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Business</button>
          <button onClick={() => setActiveTab("notifications")} className={`px-4 py-2 rounded-xl transition ${activeTab === "notifications" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Notifications</button>
          <button onClick={() => setActiveTab("security")} className={`px-4 py-2 rounded-xl transition ${activeTab === "security" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Security</button>
          <button onClick={() => setActiveTab("preferences")} className={`px-4 py-2 rounded-xl transition ${activeTab === "preferences" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Preferences</button>
        </div>

        {/* Main Grid: Form Sections + Right Quick Actions Sidebar matching Mockup 10 */}
        <div className="grid gap-6 lg:grid-cols-[1fr_340px]">
          {/* Forms Column */}
          <div className="space-y-6">
            {/* Profile Information Card */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <h3 className="font-black text-slate-900 text-xs flex items-center gap-2">
                  <User size={16} className="text-amber-500" /> Profile Information
                </h3>
                <button className="bg-slate-50 border border-slate-200 text-slate-700 font-bold px-3 py-1 rounded-xl text-xs hover:bg-slate-100">
                  Edit
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-3">
                  <div>
                    <label className="text-[10px] font-bold text-slate-400 uppercase block mb-1">Full Name</label>
                    <input readOnly value={profile?.full_name || "Rohit Sharma"} className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900" />
                  </div>

                  <div>
                    <label className="text-[10px] font-bold text-slate-400 uppercase block mb-1">Email Address</label>
                    <input readOnly value="rohit.sharma@email.com" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900" />
                  </div>

                  <div>
                    <label className="text-[10px] font-bold text-slate-400 uppercase block mb-1">Phone Number</label>
                    <input readOnly value={profile?.phone || "+91 98765 43210"} className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900" />
                  </div>
                </div>

                {/* Profile Photo Upload */}
                <div className="flex flex-col items-center justify-center p-4 border border-slate-100 rounded-2xl space-y-3">
                  <div className="w-20 h-20 rounded-full bg-slate-900 text-white flex items-center justify-center font-black text-2xl border-2 border-amber-400 shadow-md">
                    {profile?.full_name?.charAt(0) || "R"}
                  </div>
                  <span className="text-[10px] text-slate-400 font-medium">JPG, PNG or GIF. Max size 2MB</span>
                  <button className="bg-slate-50 border border-slate-200 text-slate-700 font-bold px-4 py-1.5 rounded-xl text-xs hover:bg-slate-100">
                    Change Photo
                  </button>
                </div>
              </div>
            </div>

            {/* Change Password Card */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
              <h3 className="font-black text-slate-900 text-xs flex items-center gap-2 border-b border-slate-100 pb-3">
                <Lock size={16} className="text-purple-500" /> Change Password
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase block mb-1">Current Password</label>
                  <input type="password" placeholder="Enter current password" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900" />
                </div>

                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase block mb-1">New Password</label>
                  <input type="password" placeholder="Enter new password" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-900" />
                </div>
              </div>

              <button className="bg-purple-600 hover:bg-purple-700 text-white font-black px-5 py-2.5 rounded-xl shadow-sm text-xs transition">
                Update Password
              </button>
            </div>

            {/* Account Information Card */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
              <h3 className="font-black text-slate-900 text-xs border-b border-slate-100 pb-3">Account Information</h3>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs">
                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase block">Join Date</span>
                  <span className="font-bold text-slate-900 block pt-0.5">12 May 2024</span>
                </div>

                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase block">Account Status</span>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-100 text-emerald-800 inline-block mt-0.5">Active</span>
                </div>

                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase block">Account Type</span>
                  <span className="font-bold text-slate-900 block pt-0.5">Truck Owner</span>
                </div>

                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase block">Verification</span>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-100 text-emerald-800 inline-block mt-0.5">✔ Verified</span>
                </div>
              </div>
            </div>
          </div>

          {/* Right Quick Actions & App Info Sidebar matching Mockup 10 */}
          <div className="space-y-6">
            {/* Quick Actions */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
              <h4 className="font-black text-xs text-slate-900">Quick Actions</h4>

              <div className="space-y-2 text-xs font-bold">
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-amber-50 transition cursor-pointer">
                  <span className="text-slate-800">Update Profile</span>
                  <ChevronRight size={14} className="text-slate-400" />
                </div>
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-amber-50 transition cursor-pointer">
                  <span className="text-slate-800">Business Details</span>
                  <ChevronRight size={14} className="text-slate-400" />
                </div>
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-amber-50 transition cursor-pointer">
                  <span className="text-slate-800">Bank Details</span>
                  <ChevronRight size={14} className="text-slate-400" />
                </div>
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-amber-50 transition cursor-pointer">
                  <span className="text-slate-800">Documents</span>
                  <ChevronRight size={14} className="text-slate-400" />
                </div>
              </div>
            </div>

            {/* Preferences */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
              <h4 className="font-black text-xs text-slate-900">Preferences</h4>

              <div className="space-y-2 text-xs font-bold">
                <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50">
                  <span className="text-slate-500">Language</span>
                  <span className="text-slate-900">English</span>
                </div>
                <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50">
                  <span className="text-slate-500">Currency</span>
                  <span className="text-slate-900">INR (₹)</span>
                </div>
                <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50">
                  <span className="text-slate-500">Time Zone</span>
                  <span className="text-slate-900 text-[10px]">GMT+05:30 India</span>
                </div>
              </div>
            </div>

            {/* App Information */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-2 text-xs">
              <h4 className="font-black text-xs text-slate-900 pb-1">App Information</h4>
              <div className="flex items-center justify-between text-slate-500 font-medium">
                <span>Version</span>
                <span className="font-bold text-slate-900">1.2.0</span>
              </div>
              <div className="flex items-center justify-between text-slate-500 font-medium">
                <span>Last Updated</span>
                <span className="font-bold text-slate-900">20 May 2024</span>
              </div>
              <span className="inline-block text-[10px] font-extrabold text-emerald-700 bg-emerald-100 px-2.5 py-0.5 rounded-full mt-1">
                You are using the latest version
              </span>
            </div>
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
