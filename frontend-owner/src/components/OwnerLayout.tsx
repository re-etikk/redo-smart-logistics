import { useState, useEffect, type ReactNode } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import {
  LayoutDashboard, Truck, CalendarCheck, IndianRupee, MapPin, CreditCard,
  FileText, Star, Headset, Settings, Bell, Wallet, ChevronDown, User, Gift,
  ShieldCheck, AlertTriangle, Plus, Landmark, Box, Moon, Sun, Globe, Phone, X, Check, Menu
} from "lucide-react";
import Logo from "../components/Logo";
import { useAuth } from "../hooks/useAuth";
import { getWallet } from "../lib/walletStore";
import { getKycStatus, type KycStatus } from "../lib/documentStore";
import { getUserProfile, saveUserProfile, type UserProfileData } from "../lib/profileStore";
import {
  getInitialTheme, applyTheme, getInitialLanguage, setLanguage,
  SUPPORTED_LANGUAGES, type ThemeMode, type LanguageCode
} from "../lib/themeStore";
import { useTranslation } from "../lib/i18n";

interface OwnerLayoutProps {
  children: ReactNode;
  activeTab?: string;
  promoCardType?: "refer" | "bank" | "truck";
  onAddTruckClick?: () => void;
  onAddBankClick?: () => void;
}

export default function OwnerLayout({
  children,
  activeTab = "dashboard",
  promoCardType = "refer",
  onAddTruckClick,
  onAddBankClick,
}: OwnerLayoutProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { session, profile, signOut } = useAuth();

  const [profileOpen, setProfileOpen] = useState(false);
  const [langMenuOpen, setLangMenuOpen] = useState(false);
  const [mobileDrawerOpen, setMobileDrawerOpen] = useState(false);

  // Dynamic Stores State
  const [walletBalance, setWalletBalance] = useState<number>(() => getWallet().balance);
  const [kycStatus, setKycStatus] = useState<KycStatus>(() => getKycStatus());
  const [userData, setUserData] = useState<UserProfileData>(() => getUserProfile());
  const [theme, setTheme] = useState<ThemeMode>(() => getInitialTheme());
  const [currentLang, setCurrentLang] = useState<LanguageCode>(() => getInitialLanguage());

  // Google Login Phone Prompt Modal
  const [showPhonePrompt, setShowPhonePrompt] = useState(false);
  const [tempPhone, setTempPhone] = useState("");

  const refreshAll = () => {
    setWalletBalance(getWallet().balance);
    setKycStatus(getKycStatus());
    const prof = getUserProfile();
    if (session?.user?.email && prof.email !== session.user.email) {
      prof.email = session.user.email;
    }
    const realGoogleName = session?.user?.user_metadata?.full_name || session?.user?.user_metadata?.name;
    if (realGoogleName && prof.full_name === "Ritik Chaurasia" && session?.user?.email && !session.user.email.includes("ritik")) {
      prof.full_name = realGoogleName;
    }
    setUserData(prof);
  };

  useEffect(() => {
    applyTheme(theme);
  }, [theme]);

  useEffect(() => {
    refreshAll();

    const prof = getUserProfile();
    if (!prof.phone || prof.phone === "+91 98765 43210" || prof.phone === "") {
      const hasDismissed = sessionStorage.getItem("redo_phone_prompt_dismissed");
      if (!hasDismissed && session?.user) {
        setShowPhonePrompt(true);
      }
    }

    const onWallet = () => setWalletBalance(getWallet().balance);
    const onDocs = () => setKycStatus(getKycStatus());
    const onProfile = (e: any) => setUserData(e.detail || getUserProfile());

    window.addEventListener("redo_wallet_updated", onWallet);
    window.addEventListener("redo_docs_updated", onDocs);
    window.addEventListener("redo_profile_updated", onProfile);

    return () => {
      window.removeEventListener("redo_wallet_updated", onWallet);
      window.removeEventListener("redo_docs_updated", onDocs);
      window.removeEventListener("redo_profile_updated", onProfile);
    };
  }, [session]);

  const toggleTheme = () => {
    const next = theme === "light" ? "dark" : "light";
    setTheme(next);
    applyTheme(next);
  };

  const handleSelectLanguage = (code: LanguageCode) => {
    setCurrentLang(code);
    setLanguage(code);
    setLangMenuOpen(false);
  };

  const savePhoneFromPrompt = (e: React.FormEvent) => {
    e.preventDefault();
    if (!tempPhone) return;
    saveUserProfile({ phone: tempPhone });
    setShowPhonePrompt(false);
    sessionStorage.setItem("redo_phone_prompt_dismissed", "true");
    refreshAll();
  };

  const { t } = useTranslation();

  const navItems = [
    { id: "dashboard", label: t("dashboard"), path: "/dashboard", icon: LayoutDashboard },
    { id: "trucks", label: t("myTrucks"), path: "/trucks", icon: Truck },
    { id: "loads", label: t("findLoads"), path: "/loads", icon: Box },
    { id: "bookings", label: t("myBookings"), path: "/bookings", icon: CalendarCheck },
    { id: "earnings", label: t("earnings"), path: "/earnings", icon: IndianRupee },
    { id: "trips", label: t("trips"), path: "/trips", icon: MapPin },
    { id: "payments", label: t("payments"), path: "/payments", icon: CreditCard },
    { id: "documents", label: t("documents"), path: "/documents", icon: FileText },
    { id: "reviews", label: t("reviews"), path: "/reviews", icon: Star },
    { id: "support", label: t("support"), path: "/support", icon: Headset },
    { id: "settings", label: t("settings"), path: "/settings", icon: Settings },
  ];

  // Dynamic user name from Google OAuth session
  const googleName = session?.user?.user_metadata?.full_name || session?.user?.user_metadata?.name || (session?.user?.email ? session.user.email.split('@')[0] : "");
  const displayName = session?.user ? (googleName || profile?.full_name || userData.full_name) : (userData.full_name || "Truck Owner");
  const displayEmail = session?.user?.email || userData.email || "owner@redo.app";

  return (
    <div className={`min-h-screen font-sans selection:bg-amber-400 transition-colors duration-200 ${
      theme === "dark" ? "bg-slate-950 text-slate-100 dark" : "bg-[#FAF9F6] text-slate-900"
    }`}>
      {/* Top Header */}
      <header className={`sticky top-0 z-40 border-b shadow-sm transition-colors ${
        theme === "dark" ? "bg-slate-900 border-slate-800 text-white" : "bg-white border-slate-200/80 text-slate-900"
      }`}>
        <div className="mx-auto max-w-[1500px] px-4 sm:px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-4 sm:gap-6">
            {/* 3 Lines Hamburger Menu Button for all screens */}
            <button
              onClick={() => setMobileDrawerOpen(true)}
              className={`p-2 rounded-xl border transition cursor-pointer ${
                theme === "dark" ? "bg-slate-800 border-slate-700 text-white hover:bg-slate-700" : "bg-slate-50 border-slate-200 text-slate-800 hover:bg-slate-100"
              }`}
              title="Open Navigation Menu"
              aria-label="Navigation Menu"
            >
              <Menu size={20} />
            </button>

            <Link to="/dashboard">
              <Logo />
            </Link>

            {/* Horizontal Sub-Nav */}
            <nav className="hidden xl:flex items-center gap-5 text-xs font-bold">
              <Link to="/dashboard" className={`transition hover:text-amber-500 ${location.pathname === "/dashboard" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("dashboard")}
              </Link>
              <Link to="/trucks" className={`transition hover:text-amber-500 ${location.pathname === "/trucks" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("myTrucks")}
              </Link>
              <Link to="/loads" className={`transition hover:text-amber-500 ${location.pathname === "/loads" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("findLoads")}
              </Link>
              <Link to="/bookings" className={`transition hover:text-amber-500 ${location.pathname === "/bookings" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("myBookings")}
              </Link>
              <Link to="/earnings" className={`transition hover:text-amber-500 ${location.pathname === "/earnings" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("earnings")}
              </Link>
              <Link to="/trips" className={`transition hover:text-amber-500 ${location.pathname === "/trips" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("trips")}
              </Link>
              <Link to="/payments" className={`transition hover:text-amber-500 ${location.pathname === "/payments" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("payments")}
              </Link>
              <Link to="/support" className={`transition hover:text-amber-500 ${location.pathname === "/support" ? "text-amber-500 border-b-2 border-amber-400 pb-1 font-black" : ""}`}>
                {t("support")}
              </Link>
            </nav>
          </div>

          {/* Header Right Actions */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Language Selector Dropdown */}
            <div className="relative">
              <button
                onClick={() => setLangMenuOpen(!langMenuOpen)}
                className={`p-2 rounded-xl border flex items-center gap-1 text-xs font-bold transition cursor-pointer ${
                  theme === "dark" ? "bg-slate-800 border-slate-700 hover:bg-slate-700" : "bg-slate-50 border-slate-200 hover:bg-slate-100"
                }`}
                title="Select Language"
              >
                <Globe size={15} className="text-amber-500" />
                <span className="uppercase text-[10px] font-mono">{currentLang}</span>
              </button>

              {langMenuOpen && (
                <div className={`absolute right-0 mt-2 w-48 rounded-2xl shadow-xl z-50 py-1 font-bold text-xs border ${
                  theme === "dark" ? "bg-slate-900 border-slate-800 text-slate-200" : "bg-white border-slate-200 text-slate-800"
                }`}>
                  <div className="px-3 py-1.5 text-[10px] uppercase font-mono text-slate-400 border-b border-slate-200/40">
                    Select Language
                  </div>
                  {SUPPORTED_LANGUAGES.map((l) => (
                    <button
                      key={l.code}
                      onClick={() => handleSelectLanguage(l.code)}
                      className={`w-full text-left px-3.5 py-2 flex items-center justify-between hover:bg-amber-400/20 transition cursor-pointer ${
                        currentLang === l.code ? "text-amber-500 font-black" : ""
                      }`}
                    >
                      <span>{l.nativeName} ({l.name})</span>
                      {currentLang === l.code && <Check size={14} className="text-amber-500" />}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Dark / Light Mode Toggle */}
            <button
              onClick={toggleTheme}
              className={`p-2 rounded-xl border transition cursor-pointer ${
                theme === "dark" ? "bg-slate-800 border-slate-700 text-amber-400 hover:bg-slate-700" : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100"
              }`}
              title={theme === "dark" ? "Switch to Day Mode" : "Switch to Dark Mode"}
            >
              {theme === "dark" ? <Sun size={17} /> : <Moon size={17} />}
            </button>

            {/* Wallet Balance Chip */}
            <Link
              to="/payments"
              className={`hidden sm:flex items-center gap-2 rounded-xl px-3 py-1.5 shadow-sm border transition cursor-pointer ${
                theme === "dark" ? "bg-slate-800 border-slate-700 hover:border-amber-500/50" : "bg-slate-50 border-slate-200 hover:border-amber-400"
              }`}
              title="Click to manage wallet and payouts"
            >
              <Wallet size={15} className="text-amber-500" />
              <div>
                <span className="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block leading-none">Wallet</span>
                <span className={`text-xs font-black ${theme === "dark" ? "text-white" : "text-slate-900"}`}>
                  ₹{walletBalance.toLocaleString("en-IN")}
                </span>
              </div>
            </Link>

            {/* User Profile Dropdown */}
            <div className="relative">
              <button
                onClick={() => setProfileOpen(!profileOpen)}
                className={`flex items-center gap-2 p-1.5 rounded-xl border transition cursor-pointer ${
                  theme === "dark" ? "bg-slate-800 border-slate-700 hover:bg-slate-700" : "bg-slate-50 border-slate-200 hover:bg-slate-100"
                }`}
              >
                <div className="w-8 h-8 rounded-full bg-slate-900 text-white flex items-center justify-center font-black text-xs border border-amber-400 shadow-sm overflow-hidden">
                  {userData.avatar_url ? (
                    <img src={userData.avatar_url} alt="User Avatar" className="w-full h-full object-cover" />
                  ) : (
                    displayName.charAt(0)
                  )}
                </div>
                <div className="hidden sm:block text-left">
                  <span className={`text-xs font-black block leading-tight truncate max-w-[120px] ${theme === "dark" ? "text-white" : "text-slate-900"}`}>
                    {displayName}
                  </span>
                  <span className="text-[10px] font-bold text-amber-500 block leading-tight">
                    Truck Owner
                  </span>
                </div>
                <ChevronDown size={14} className="text-slate-400" />
              </button>

              {profileOpen && (
                <div className={`absolute right-0 mt-2 w-56 rounded-2xl shadow-xl z-50 py-2 font-bold text-xs border ${
                  theme === "dark" ? "bg-slate-900 border-slate-800 text-slate-200" : "bg-white border-slate-200 text-slate-800"
                }`}>
                  <div className="px-4 py-2 border-b border-slate-200/40">
                    <p className="font-black text-xs truncate">{displayName}</p>
                    <p className="text-[10px] text-slate-400 font-mono truncate">{displayEmail}</p>
                  </div>
                  <Link to="/settings" onClick={() => setProfileOpen(false)} className="px-4 py-2.5 hover:bg-amber-400/20 flex items-center gap-2">
                    <User size={14} /> Profile Settings
                  </Link>
                  <Link to="/documents" onClick={() => setProfileOpen(false)} className="px-4 py-2.5 hover:bg-amber-400/20 flex items-center gap-2">
                    <ShieldCheck size={14} /> KYC &amp; Documents
                  </Link>
                  <button
                    onClick={async () => {
                      setProfileOpen(false);
                      await signOut();
                      navigate("/login");
                    }}
                    className="w-full text-left px-4 py-2.5 hover:bg-rose-500/20 text-rose-500 font-bold border-t border-slate-200/40 flex items-center gap-2 cursor-pointer"
                  >
                    Logout
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Slide-over Drawer for 3-Lines Hamburger Menu */}
      {mobileDrawerOpen && (
        <div className="fixed inset-0 z-50" role="dialog" aria-modal="true">
          <div className="absolute inset-0 bg-slate-950/60 backdrop-blur-sm animate-fadeIn" onClick={() => setMobileDrawerOpen(false)} />
          <div className={`absolute inset-y-0 left-0 w-80 shadow-2xl flex flex-col justify-between p-5 border-r animate-slideRight ${
            theme === "dark" ? "bg-slate-900 border-slate-800 text-white" : "bg-white border-slate-200 text-slate-900"
          }`}>
            <div className="space-y-4">
              <div className="flex items-center justify-between border-b border-slate-200/40 pb-4">
                <Logo />
                <button onClick={() => setMobileDrawerOpen(false)} className="p-1.5 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-400">
                  <X size={20} />
                </button>
              </div>

              {/* User badge */}
              <div className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200/60 dark:border-slate-700">
                <div className="w-10 h-10 rounded-full bg-slate-900 text-white flex items-center justify-center font-black text-sm border border-amber-400">
                  {displayName.charAt(0)}
                </div>
                <div className="min-w-0">
                  <h4 className="text-xs font-black truncate">{displayName}</h4>
                  <p className="text-[10px] text-slate-400 truncate">{displayEmail}</p>
                </div>
              </div>

              {/* Navigation Menu */}
              <nav className="space-y-1 overflow-y-auto max-h-[calc(100vh-280px)]">
                {navItems.map((item) => {
                  const Icon = item.icon;
                  const isActive = location.pathname === item.path;
                  return (
                    <Link
                      key={item.id}
                      to={item.path}
                      onClick={() => setMobileDrawerOpen(false)}
                      className={`flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-black transition ${
                        isActive
                          ? "bg-[#FFC800] text-slate-950 shadow-sm"
                          : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                      }`}
                    >
                      <Icon size={16} className={isActive ? "text-slate-950" : "text-amber-500"} />
                      <span>{item.label}</span>
                    </Link>
                  );
                })}
              </nav>
            </div>

            {/* Drawer Bottom Actions */}
            <div className="pt-4 border-t border-slate-200/40 space-y-2">
              <button
                onClick={toggleTheme}
                className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-between text-xs font-bold"
              >
                <span className="flex items-center gap-2">
                  {theme === "dark" ? <Moon size={15} className="text-amber-400" /> : <Sun size={15} className="text-amber-500" />}
                  <span>{theme === "dark" ? "Night Mode Active" : "Day Mode Active"}</span>
                </span>
                <span className="text-[10px] text-amber-500 font-mono">Switch</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Main Grid with Left Sidebar & Content */}
      <div className="mx-auto max-w-[1500px] px-4 sm:px-6 py-6 grid gap-6 lg:grid-cols-[240px_1fr]">
        
        {/* Left Sidebar (Desktop) */}
        <aside className="hidden lg:block space-y-4">
          {/* Owner Profile Badge Card with Dynamic KYC Verification */}
          <div className={`border rounded-2xl p-4 shadow-sm flex items-center gap-3 ${
            theme === "dark" ? "bg-slate-900 border-slate-800" : "bg-white border-slate-200/80"
          }`}>
            <div className="relative w-12 h-12 rounded-2xl bg-amber-100 dark:bg-amber-950/60 border border-amber-300 dark:border-amber-700 flex items-center justify-center text-2xl shrink-0 shadow-sm">
              🚛
            </div>
            <div className="min-w-0 flex-1">
              <span className="text-[10px] font-black uppercase text-slate-400 tracking-wider block">Owner</span>
              <h4 className="text-xs font-black truncate">{displayName}</h4>
              
              {/* Dynamic KYC Verified vs Pending Badge */}
              {kycStatus.isFullyVerified ? (
                <span className="inline-flex items-center gap-1 text-[9px] font-black text-emerald-700 bg-emerald-100 dark:bg-emerald-950/60 dark:text-emerald-400 px-2 py-0.5 rounded-full mt-1 border border-emerald-300/40">
                  <ShieldCheck size={11} /> Account Verified
                </span>
              ) : (
                <Link
                  to="/documents"
                  className="inline-flex items-center gap-1 text-[9px] font-black text-amber-800 bg-amber-100 dark:bg-amber-950/60 dark:text-amber-300 px-2 py-0.5 rounded-full mt-1 border border-amber-300/40 hover:underline"
                  title="Upload missing documents to complete verification"
                >
                  <AlertTriangle size={11} /> {kycStatus.label}
                </Link>
              )}
            </div>
          </div>

          {/* Vertical Navigation Menu */}
          <nav className={`border rounded-2xl p-2 shadow-sm space-y-1 ${
            theme === "dark" ? "bg-slate-900 border-slate-800" : "bg-white border-slate-200/80"
          }`}>
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path || activeTab === item.id;
              return (
                <Link
                  key={item.id}
                  to={item.path}
                  className={`flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-extrabold transition ${
                    isActive
                      ? "bg-[#FFC800] text-slate-950 shadow-sm font-black"
                      : theme === "dark"
                      ? "text-slate-300 hover:bg-slate-800 hover:text-white"
                      : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                  }`}
                >
                  <Icon size={16} className={isActive ? "text-slate-950" : "text-amber-500"} />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>

          {/* Dynamic Sidebar Promo Card */}
          {promoCardType === "bank" ? (
            <div className={`border rounded-2xl p-4 shadow-sm space-y-3 relative overflow-hidden ${
              theme === "dark" ? "bg-slate-900 border-amber-500/30" : "bg-white border-amber-200/80"
            }`}>
              <div className="space-y-1">
                <span className="text-xs font-black block">Get Paid Faster!</span>
                <p className="text-[10px] text-slate-400 font-medium leading-relaxed">
                  Add your bank account and UPI to receive payments quickly and securely.
                </p>
              </div>
              <button
                onClick={() => onAddBankClick ? onAddBankClick() : navigate("/payments")}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-[11px] py-2 rounded-xl shadow-xs transition flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <Landmark size={14} /> + Add Bank Details
              </button>
            </div>
          ) : (
            <div className={`border rounded-2xl p-4 shadow-sm space-y-3 relative overflow-hidden ${
              theme === "dark" ? "bg-slate-900 border-amber-500/30" : "bg-white border-amber-200/80"
            }`}>
              <div className="space-y-1">
                <span className="text-xs font-black block">Expand Your Fleet</span>
                <p className="text-[10px] text-slate-400 font-medium leading-relaxed">
                  Register more trucks to increase match chances and earn higher returns.
                </p>
              </div>
              <button
                onClick={() => onAddTruckClick ? onAddTruckClick() : navigate("/trucks")}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-[11px] py-2 rounded-xl shadow-xs transition flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <Plus size={14} /> + Add New Truck
              </button>
            </div>
          )}
        </aside>

        {/* Main Content Area */}
        <main className="min-w-0 space-y-6">
          {children}
        </main>
      </div>

      {/* ========================================================================= */}
      {/* GOOGLE SIGN-IN PHONE COMPLETION MODAL */}
      {/* ========================================================================= */}
      {showPhonePrompt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm animate-fadeIn">
          <div className={`border rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5 ${
            theme === "dark" ? "bg-slate-900 border-slate-800 text-white" : "bg-white border-slate-200 text-slate-900"
          }`}>
            <div className="flex items-center justify-between border-b border-slate-200/40 pb-3">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-amber-100 text-amber-900 flex items-center justify-center">
                  <Phone size={16} />
                </div>
                <h3 className="text-base font-black">Complete Your Account</h3>
              </div>
              <button
                onClick={() => {
                  setShowPhonePrompt(false);
                  sessionStorage.setItem("redo_phone_prompt_dismissed", "true");
                }}
                className="p-1.5 text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <p className="text-xs text-slate-400 font-medium">
              You logged in with Google ({displayEmail}). Please enter your mobile number for real-time load alerts &amp; OTP verification.
            </p>

            <form onSubmit={savePhoneFromPrompt} className="space-y-4 text-xs font-bold">
              <div>
                <label className="block mb-1">Mobile Number *</label>
                <input
                  type="tel"
                  required
                  value={tempPhone}
                  onChange={(e) => setTempPhone(e.target.value)}
                  placeholder="e.g. +91 98765 43210"
                  className={`w-full border rounded-xl px-4 py-2.5 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400 ${
                    theme === "dark" ? "bg-slate-800 border-slate-700 text-white" : "bg-slate-50 border-slate-200 text-slate-900"
                  }`}
                />
              </div>

              <button
                type="submit"
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2"
              >
                <span>Save Number &amp; Continue</span>
                <Check size={16} />
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
