import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import {
  User, Lock, ChevronRight, Building2, Bell, Shield, Sliders, CheckCircle2,
  Phone, Mail, FileText, Landmark, Upload, Moon, Sun, Globe, Save, Check,
  AlertTriangle
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useAuth } from "../hooks/useAuth";
import { getUserProfile, saveUserProfile, type UserProfileData } from "../lib/profileStore";
import {
  getInitialTheme, applyTheme, getInitialLanguage, setLanguage,
  SUPPORTED_LANGUAGES, type ThemeMode, type LanguageCode
} from "../lib/themeStore";

export default function OwnerSettings() {
  const navigate = useNavigate();
  const { session } = useAuth();

  const [activeTab, setActiveTab] = useState<"profile" | "business" | "notifications" | "security" | "preferences">("profile");
  const [profile, setProfile] = useState<UserProfileData>(() => getUserProfile());

  // Edit states
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [formData, setFormData] = useState<UserProfileData>(() => getUserProfile());
  const [savedSuccess, setSavedSuccess] = useState(false);

  // Theme & Language
  const [theme, setTheme] = useState<ThemeMode>(() => getInitialTheme());
  const [lang, setLang] = useState<LanguageCode>(() => getInitialLanguage());

  // Password state
  const [passwordState, setPasswordState] = useState({ current: "", newPass: "", confirm: "" });
  const [passwordMsg, setPasswordMsg] = useState("");

  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const prof = getUserProfile();
    if (session?.user?.email) {
      prof.email = session.user.email;
    }
    setProfile(prof);
    setFormData(prof);
  }, [session]);

  const handleProfileSave = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const updated = saveUserProfile(formData);
    setProfile(updated);
    setIsEditingProfile(false);
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      if (event.target?.result) {
        const photoUrl = event.target.result as string;
        setFormData(prev => ({ ...prev, avatar_url: photoUrl }));
        saveUserProfile({ avatar_url: photoUrl });
        setProfile(prev => ({ ...prev, avatar_url: photoUrl }));
      }
    };
    reader.readAsDataURL(file);
  };

  const handleThemeChange = (newTheme: ThemeMode) => {
    setTheme(newTheme);
    applyTheme(newTheme);
  };

  const handleLanguageChange = (newLang: LanguageCode) => {
    setLang(newLang);
    setLanguage(newLang);
  };

  const handlePasswordSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!passwordState.newPass || passwordState.newPass !== passwordState.confirm) {
      setPasswordMsg("New passwords do not match!");
      return;
    }
    setPasswordMsg("Password updated successfully!");
    setPasswordState({ current: "", newPass: "", confirm: "" });
    setTimeout(() => setPasswordMsg(""), 3000);
  };

  return (
    <OwnerLayout activeTab="settings" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight">Account &amp; Platform Settings</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Manage your profile, business tax credentials, languages and security.</p>
          </div>

          {savedSuccess && (
            <div className="bg-emerald-500 text-white font-bold text-xs px-4 py-2 rounded-xl flex items-center gap-1.5 shadow-sm animate-fadeIn">
              <CheckCircle2 size={16} /> Changes Saved Successfully
            </div>
          )}
        </div>

        {/* Sub Navigation Tabs */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-2 shadow-sm flex items-center gap-2 overflow-x-auto text-xs font-extrabold">
          <button
            onClick={() => setActiveTab("profile")}
            className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === "profile" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
            }`}
          >
            <User size={15} /> Profile &amp; Account
          </button>
          <button
            onClick={() => setActiveTab("business")}
            className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === "business" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
            }`}
          >
            <Building2 size={15} /> Business Details
          </button>
          <button
            onClick={() => setActiveTab("notifications")}
            className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === "notifications" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
            }`}
          >
            <Bell size={15} /> Notifications
          </button>
          <button
            onClick={() => setActiveTab("security")}
            className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === "security" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
            }`}
          >
            <Shield size={15} /> Security
          </button>
          <button
            onClick={() => setActiveTab("preferences")}
            className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === "preferences" ? "bg-[#FFC800] text-slate-950 font-black shadow-sm" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
            }`}
          >
            <Sliders size={15} /> Preferences
          </button>
        </div>

        {/* Main Grid: Form Sections + Right Quick Actions Sidebar */}
        <div className="grid gap-6 lg:grid-cols-[1fr_340px]">
          {/* Main Content Area */}
          <div className="space-y-6">
            {/* ========================================================================= */}
            {/* TAB 1: PROFILE & ACCOUNT */}
            {/* ========================================================================= */}
            {activeTab === "profile" && (
              <div className="space-y-6">
                <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-5">
                  <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
                    <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2">
                      <User size={16} className="text-amber-500" /> Personal &amp; Contact Details
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsEditingProfile(!isEditingProfile)}
                      className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-3.5 py-1.5 rounded-xl text-xs shadow-xs transition cursor-pointer"
                    >
                      {isEditingProfile ? "Cancel Editing" : "Edit Profile"}
                    </button>
                  </div>

                  <form onSubmit={handleProfileSave} className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                      <div className="space-y-3 text-xs font-bold">
                        <div>
                          <label className="text-[10px] text-slate-400 uppercase block mb-1">Full Name</label>
                          <input
                            disabled={!isEditingProfile}
                            value={formData.full_name}
                            onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                            className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs font-bold disabled:opacity-75 focus:outline-none focus:ring-2 focus:ring-amber-400"
                          />
                        </div>

                        <div>
                          <label className="text-[10px] text-slate-400 uppercase block mb-1">Email Address</label>
                          <input
                            disabled={!isEditingProfile}
                            type="email"
                            value={formData.email}
                            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                            className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs font-bold disabled:opacity-75 focus:outline-none focus:ring-2 focus:ring-amber-400"
                          />
                        </div>

                        <div>
                          <label className="text-[10px] text-slate-400 uppercase block mb-1">Mobile Phone Number</label>
                          <input
                            disabled={!isEditingProfile}
                            type="tel"
                            value={formData.phone}
                            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                            className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs font-bold disabled:opacity-75 focus:outline-none focus:ring-2 focus:ring-amber-400"
                          />
                        </div>
                      </div>

                      {/* Profile Photo Upload Section */}
                      <div className="flex flex-col items-center justify-center p-6 border border-slate-100 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50 rounded-2xl space-y-3 text-center">
                        <div className="relative w-24 h-24 rounded-full bg-slate-900 text-white flex items-center justify-center font-black text-3xl border-3 border-amber-400 shadow-md overflow-hidden">
                          {formData.avatar_url ? (
                            <img src={formData.avatar_url} alt="Profile" className="w-full h-full object-cover" />
                          ) : (
                            formData.full_name.charAt(0) || "R"
                          )}
                        </div>
                        <input
                          type="file"
                          ref={fileInputRef}
                          onChange={handlePhotoUpload}
                          accept="image/*"
                          className="hidden"
                        />
                        <button
                          type="button"
                          onClick={() => fileInputRef.current?.click()}
                          className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:bg-slate-100 font-bold px-4 py-1.5 rounded-xl text-xs shadow-xs transition cursor-pointer flex items-center gap-1.5"
                        >
                          <Upload size={13} /> Change Photo
                        </button>
                        <span className="text-[10px] text-slate-400">JPG, PNG or GIF. Max size 2MB</span>
                      </div>
                    </div>

                    {isEditingProfile && (
                      <div className="flex justify-end pt-2 border-t border-slate-100 dark:border-slate-800">
                        <button
                          type="submit"
                          className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition flex items-center gap-2 cursor-pointer"
                        >
                          <Save size={15} /> Save Changes
                        </button>
                      </div>
                    )}
                  </form>
                </div>

                {/* Change Password Card */}
                <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
                  <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
                    <Lock size={16} className="text-purple-500" /> Change Account Password
                  </h3>

                  <form onSubmit={handlePasswordSubmit} className="space-y-4 text-xs font-bold">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="text-[10px] text-slate-400 uppercase block mb-1">Current Password</label>
                        <input
                          type="password"
                          value={passwordState.current}
                          onChange={(e) => setPasswordState({ ...passwordState, current: e.target.value })}
                          placeholder="••••••••"
                          className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
                        />
                      </div>

                      <div>
                        <label className="text-[10px] text-slate-400 uppercase block mb-1">New Password</label>
                        <input
                          type="password"
                          value={passwordState.newPass}
                          onChange={(e) => setPasswordState({ ...passwordState, newPass: e.target.value })}
                          placeholder="••••••••"
                          className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
                        />
                      </div>
                    </div>

                    {passwordMsg && (
                      <p className="text-xs font-bold text-emerald-600">{passwordMsg}</p>
                    )}

                    <button
                      type="submit"
                      className="bg-purple-600 hover:bg-purple-700 text-white font-black px-5 py-2.5 rounded-xl shadow-sm text-xs transition cursor-pointer"
                    >
                      Update Password
                    </button>
                  </form>
                </div>
              </div>
            )}

            {/* ========================================================================= */}
            {/* TAB 2: BUSINESS DETAILS */}
            {/* ========================================================================= */}
            {activeTab === "business" && (
              <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-5">
                <div className="border-b border-slate-100 dark:border-slate-800 pb-3">
                  <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2">
                    <Building2 size={16} className="text-amber-500" /> Commercial Logistics &amp; Tax Profile
                  </h3>
                  <p className="text-xs text-slate-500 mt-1">Official registered enterprise and GST details for invoicing.</p>
                </div>

                <form onSubmit={handleProfileSave} className="space-y-4 text-xs font-bold">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="text-[10px] text-slate-400 uppercase block mb-1">Company / Enterprise Name</label>
                      <input
                        value={formData.company_name}
                        onChange={(e) => setFormData({ ...formData, company_name: e.target.value })}
                        placeholder="e.g. Chaurasia Freight Logistics"
                        className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                      />
                    </div>

                    <div>
                      <label className="text-[10px] text-slate-400 uppercase block mb-1">Business Structure</label>
                      <select
                        value={formData.business_type}
                        onChange={(e) => setFormData({ ...formData, business_type: e.target.value })}
                        className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                      >
                        <option>Fleet Owner &amp; Operator</option>
                        <option>Sole Proprietorship</option>
                        <option>Private Limited Logistics Firm</option>
                        <option>3PL Freight Forwarder</option>
                        <option>Individual Commercial Driver</option>
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="text-[10px] text-slate-400 uppercase block mb-1">GSTIN Number (Optional)</label>
                      <input
                        value={formData.gstin}
                        onChange={(e) => setFormData({ ...formData, gstin: e.target.value.toUpperCase() })}
                        placeholder="07AAAAA0000A1Z5"
                        className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 uppercase font-mono"
                      />
                    </div>

                    <div>
                      <label className="text-[10px] text-slate-400 uppercase block mb-1">PAN Card Number</label>
                      <input
                        value={formData.pan_number}
                        onChange={(e) => setFormData({ ...formData, pan_number: e.target.value.toUpperCase() })}
                        placeholder="ABCDE1234F"
                        className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 uppercase font-mono"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="text-[10px] text-slate-400 uppercase block mb-1">Primary Operating City / Hub</label>
                      <input
                        value={formData.city}
                        onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                        placeholder="e.g. Delhi NCR, Mumbai"
                        className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                      />
                    </div>

                    <div>
                      <label className="text-[10px] text-slate-400 uppercase block mb-1">Fleet Capacity Size</label>
                      <select
                        value={formData.fleet_size}
                        onChange={(e) => setFormData({ ...formData, fleet_size: e.target.value })}
                        className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                      >
                        <option>1-5 Trucks</option>
                        <option>5-20 Trucks</option>
                        <option>20-50 Trucks</option>
                        <option>50+ Trucks</option>
                      </select>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end">
                    <button
                      type="submit"
                      className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition flex items-center gap-2 cursor-pointer"
                    >
                      <Save size={15} /> Save Business Profile
                    </button>
                  </div>
                </form>
              </div>
            )}

            {/* ========================================================================= */}
            {/* TAB 3: NOTIFICATIONS */}
            {/* ========================================================================= */}
            {activeTab === "notifications" && (
              <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-5">
                <div className="border-b border-slate-100 dark:border-slate-800 pb-3">
                  <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2">
                    <Bell size={16} className="text-amber-500" /> Real-time Notification Preferences
                  </h3>
                  <p className="text-xs text-slate-500 mt-1">Choose how and when REDO alerts you for new freight matches.</p>
                </div>

                <div className="space-y-3 text-xs font-bold">
                  {[
                    { key: "newLoads", title: "New Return Load Match Alerts", desc: "Instant SMS/push when an SME posts cargo on your corridors" },
                    { key: "whatsapp", title: "WhatsApp Driver & Trip Updates", desc: "Receive trip milestones and digital POD links on WhatsApp" },
                    { key: "sms", title: "SMS Booking Confirmations & OTPs", desc: "Critical OTPs for driver pickup and delivery handovers" },
                    { key: "email", title: "Weekly Earnings Statements & Tax Invoices", desc: "PDF invoices and freight settlements sent to your email" },
                  ].map((item) => (
                    <div key={item.key} className="p-4 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200/60 dark:border-slate-700 flex items-center justify-between">
                      <div className="space-y-0.5 max-w-md">
                        <h4 className="text-slate-900 dark:text-white font-black">{item.title}</h4>
                        <p className="text-[11px] text-slate-500 dark:text-slate-400 font-normal">{item.desc}</p>
                      </div>
                      <input
                        type="checkbox"
                        checked={formData.notifications[item.key as keyof typeof formData.notifications]}
                        onChange={(e) => {
                          const updated = {
                            ...formData,
                            notifications: {
                              ...formData.notifications,
                              [item.key]: e.target.checked
                            }
                          };
                          setFormData(updated);
                          saveUserProfile(updated);
                        }}
                        className="w-5 h-5 rounded text-amber-500 focus:ring-amber-400 cursor-pointer"
                      />
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ========================================================================= */}
            {/* TAB 4: SECURITY */}
            {/* ========================================================================= */}
            {activeTab === "security" && (
              <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-5">
                <div className="border-b border-slate-100 dark:border-slate-800 pb-3">
                  <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2">
                    <Shield size={16} className="text-amber-500" /> Account Security &amp; 2FA
                  </h3>
                  <p className="text-xs text-slate-500 mt-1">Multi-factor authorization and active login session monitoring.</p>
                </div>

                <div className="space-y-4 text-xs font-bold">
                  <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200/60 dark:border-slate-700 flex items-center justify-between">
                    <div>
                      <h4 className="font-black text-slate-900 dark:text-white">Two-Factor Authentication (2FA)</h4>
                      <p className="text-[11px] text-slate-500 dark:text-slate-400 font-normal">Require SMS OTP verification on new device logins.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={formData.two_factor_auth}
                      onChange={(e) => {
                        const updated = { ...formData, two_factor_auth: e.target.checked };
                        setFormData(updated);
                        saveUserProfile(updated);
                      }}
                      className="w-5 h-5 rounded text-amber-500 cursor-pointer"
                    />
                  </div>

                  <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200/60 dark:border-slate-700 space-y-2">
                    <h4 className="font-black text-slate-900 dark:text-white">Active Login Sessions</h4>
                    <div className="flex items-center justify-between text-[11px] text-slate-600 dark:text-slate-400">
                      <span>Current Device (Chrome on Windows • Delhi, India)</span>
                      <span className="text-emerald-600 font-black">Active Now</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ========================================================================= */}
            {/* TAB 5: PREFERENCES (THEME & MULTI-LANGUAGE) */}
            {/* ========================================================================= */}
            {activeTab === "preferences" && (
              <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-5">
                <div className="border-b border-slate-100 dark:border-slate-800 pb-3">
                  <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2">
                    <Sliders size={16} className="text-amber-500" /> Language &amp; Display Theme
                  </h3>
                  <p className="text-xs text-slate-500 mt-1">Configure language, dark mode theme and locale formats.</p>
                </div>

                {/* Day / Dark Theme Selector */}
                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-800 dark:text-slate-200 block">Theme Mode</label>
                  <div className="grid grid-cols-2 gap-3 max-w-sm">
                    <button
                      type="button"
                      onClick={() => handleThemeChange("light")}
                      className={`p-3 rounded-2xl border flex items-center justify-center gap-2 font-bold text-xs transition cursor-pointer ${
                        theme === "light"
                          ? "bg-[#FFC800] text-slate-950 border-amber-400 font-black shadow-sm"
                          : "bg-slate-50 dark:bg-slate-800 border-slate-200 text-slate-700 dark:text-slate-300"
                      }`}
                    >
                      <Sun size={16} /> Day Mode (Light)
                    </button>
                    <button
                      type="button"
                      onClick={() => handleThemeChange("dark")}
                      className={`p-3 rounded-2xl border flex items-center justify-center gap-2 font-bold text-xs transition cursor-pointer ${
                        theme === "dark"
                          ? "bg-amber-400 text-slate-950 border-amber-400 font-black shadow-sm"
                          : "bg-slate-50 dark:bg-slate-800 border-slate-200 text-slate-700 dark:text-slate-300"
                      }`}
                    >
                      <Moon size={16} /> Night Mode (Dark)
                    </button>
                  </div>
                </div>

                {/* Language Grid Selector */}
                <div className="space-y-2 pt-2">
                  <label className="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                    <Globe size={15} className="text-amber-500" /> Platform Language
                  </label>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                    {SUPPORTED_LANGUAGES.map((l) => (
                      <button
                        key={l.code}
                        type="button"
                        onClick={() => handleLanguageChange(l.code)}
                        className={`p-3 rounded-2xl border text-left transition cursor-pointer ${
                          lang === l.code
                            ? "bg-amber-100 dark:bg-amber-950/60 border-amber-400 text-amber-900 dark:text-amber-300 font-black shadow-xs ring-1 ring-amber-400"
                            : "bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-100"
                        }`}
                      >
                        <span className="block text-xs">{l.nativeName}</span>
                        <span className="text-[10px] text-slate-400 font-normal">{l.name}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Region & Time Zone */}
                <div className="grid grid-cols-2 gap-3 pt-2 text-xs font-bold">
                  <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700">
                    <span className="text-[10px] text-slate-400 uppercase block font-semibold">Currency</span>
                    <span className="text-slate-900 dark:text-white">Indian Rupee (INR ₹)</span>
                  </div>
                  <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700">
                    <span className="text-[10px] text-slate-400 uppercase block font-semibold">Time Zone</span>
                    <span className="text-slate-900 dark:text-white">Asia/Kolkata (GMT+05:30)</span>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* ========================================================================= */}
          {/* RIGHT SIDEBAR: QUICK ACTIONS & PREFERENCES SUMMARY */}
          {/* ========================================================================= */}
          <div className="space-y-4">
            {/* Quick Actions Card */}
            <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-3">
              <h3 className="font-black text-xs uppercase tracking-wider text-slate-400">Quick Actions</h3>

              <div className="space-y-1.5 font-bold text-xs">
                <button
                  onClick={() => {
                    setActiveTab("profile");
                    setIsEditingProfile(true);
                  }}
                  className="w-full p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center justify-between text-left transition cursor-pointer border border-transparent hover:border-slate-200"
                >
                  <span className="flex items-center gap-2">
                    <User size={15} className="text-amber-500" /> Update Profile
                  </span>
                  <ChevronRight size={14} className="text-slate-400" />
                </button>

                <button
                  onClick={() => setActiveTab("business")}
                  className="w-full p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center justify-between text-left transition cursor-pointer border border-transparent hover:border-slate-200"
                >
                  <span className="flex items-center gap-2">
                    <Building2 size={15} className="text-amber-500" /> Business Details
                  </span>
                  <ChevronRight size={14} className="text-slate-400" />
                </button>

                <button
                  onClick={() => navigate("/payments")}
                  className="w-full p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center justify-between text-left transition cursor-pointer border border-transparent hover:border-slate-200"
                >
                  <span className="flex items-center gap-2">
                    <Landmark size={15} className="text-amber-500" /> Bank &amp; Payouts
                  </span>
                  <ChevronRight size={14} className="text-slate-400" />
                </button>

                <button
                  onClick={() => navigate("/documents")}
                  className="w-full p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center justify-between text-left transition cursor-pointer border border-transparent hover:border-slate-200"
                >
                  <span className="flex items-center gap-2">
                    <FileText size={15} className="text-amber-500" /> KYC Documents
                  </span>
                  <ChevronRight size={14} className="text-slate-400" />
                </button>
              </div>
            </div>

            {/* Account Summary Snapshot */}
            <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-3 text-xs font-bold">
              <span className="text-[10px] uppercase tracking-wider text-slate-400 font-bold block">Account Status</span>
              <div className="p-3 bg-amber-50/60 dark:bg-slate-800 rounded-2xl border border-amber-200/60 dark:border-slate-700 space-y-1">
                <span className="text-amber-800 dark:text-amber-400 font-black block">Role: Fleet Owner</span>
                <p className="text-[11px] text-slate-600 dark:text-slate-400 font-normal">
                  All systems operating at 100% efficiency.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
