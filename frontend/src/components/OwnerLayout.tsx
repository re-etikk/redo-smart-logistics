import { useState, type ReactNode } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import {
  LayoutDashboard, Truck, CalendarCheck, IndianRupee, MapPin, CreditCard,
  FileText, Star, Headset, Settings, Bell, Wallet, ChevronDown, User, Gift, ShieldCheck, Plus, Landmark, RefreshCw
} from "lucide-react";
import Logo from "./Logo";
import { useAuth } from "../hooks/useAuth";

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
  const { profile, signOut } = useAuth();
  const [profileOpen, setProfileOpen] = useState(false);

  const navItems = [
    { id: "dashboard", label: "Dashboard", path: "/owner/dashboard", icon: LayoutDashboard },
    { id: "trucks", label: "My Trucks", path: "/owner/trucks", icon: Truck },
    { id: "bookings", label: "My Bookings", path: "/owner/bookings", icon: CalendarCheck },
    { id: "earnings", label: "Earnings", path: "/owner/earnings", icon: IndianRupee },
    { id: "trips", label: "Trips", path: "/owner/trips", icon: MapPin },
    { id: "payments", label: "Payments", path: "/owner/payments", icon: CreditCard },
    { id: "documents", label: "Documents", path: "/owner/documents", icon: FileText },
    { id: "reviews", label: "Reviews", path: "/owner/reviews", icon: Star },
    { id: "support", label: "Support", path: "/owner/support", icon: Headset },
    { id: "settings", label: "Settings", path: "/owner/settings", icon: Settings },
  ];

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 font-sans selection:bg-amber-400">
      {/* Top Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-slate-200/80 shadow-sm">
        <div className="mx-auto max-w-[1500px] px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-6">
            <Link to="/">
              <Logo />
            </Link>

            {/* Horizontal Sub-Nav matching Mockup 1 */}
            <nav className="hidden xl:flex items-center gap-5 text-xs font-bold text-slate-700">
              <Link to="/owner/dashboard" className={`transition hover:text-amber-600 ${location.pathname === "/owner/dashboard" ? "text-amber-600 border-b-2 border-amber-400 pb-1" : ""}`}>
                Dashboard
              </Link>
              <Link to="/owner/trucks" className={`transition hover:text-amber-600 ${location.pathname === "/owner/trucks" ? "text-amber-600 border-b-2 border-amber-400 pb-1" : ""}`}>
                My Trucks
              </Link>
              <Link to="/owner/bookings" className={`transition hover:text-amber-600 ${location.pathname === "/owner/bookings" ? "text-amber-600 border-b-2 border-amber-400 pb-1" : ""}`}>
                My Bookings
              </Link>
              <Link to="/owner/earnings" className={`transition hover:text-amber-600 ${location.pathname === "/owner/earnings" ? "text-amber-600 border-b-2 border-amber-400 pb-1" : ""}`}>
                Earnings
              </Link>
              <Link to="/owner/trips" className={`transition hover:text-amber-600 ${location.pathname === "/owner/trips" ? "text-amber-600 border-b-2 border-amber-400 pb-1" : ""}`}>
                Trips
              </Link>
              <Link to="/owner/payments" className={`transition hover:text-amber-600 ${location.pathname === "/owner/payments" ? "text-amber-600 border-b-2 border-amber-400 pb-1" : ""}`}>
                Payments
              </Link>
              <Link to="/owner/support" className={`transition hover:text-amber-600 ${location.pathname === "/owner/support" ? "text-amber-600 border-b-2 border-amber-400 pb-1" : ""}`}>
                Support
              </Link>
            </nav>
          </div>

          {/* Header Right Actions matching Mockup 2 */}
          <div className="flex items-center gap-3">
            {/* Quick Role Switcher Button */}
            <button
              onClick={() => navigate("/dashboard/sme")}
              className="hidden md:flex items-center gap-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 px-3 py-1.5 rounded-xl text-xs font-bold transition shadow-sm"
              title="Switch to Customer/Shipper Portal"
            >
              <RefreshCw size={12} className="animate-spin-slow" />
              <span>Switch to Customer View</span>
            </button>

            {/* Wallet Balance Chip */}
            <div className="hidden sm:flex items-center gap-2 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 shadow-sm">
              <Wallet size={15} className="text-amber-500" />
              <div>
                <span className="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block leading-none">Wallet Balance</span>
                <span className="text-xs font-black text-slate-900">₹24,560</span>
              </div>
            </div>

            {/* Notifications Bell */}
            <button
              onClick={() => navigate("/notifications")}
              className="relative p-2 text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 transition"
              title="Notifications"
            >
              <Bell size={18} />
              <span className="absolute top-1 right-1 w-4 h-4 bg-amber-500 text-slate-950 text-[9px] font-black rounded-full flex items-center justify-center border-2 border-white">
                3
              </span>
            </button>

            {/* User Profile Dropdown */}
            <div className="relative">
              <button
                onClick={() => setProfileOpen(!profileOpen)}
                className="flex items-center gap-2.5 p-1 rounded-xl hover:bg-slate-100 transition"
              >
                <div className="w-8 h-8 rounded-full bg-slate-900 text-white flex items-center justify-center font-black text-xs border border-amber-400 shadow-sm">
                  {profile?.full_name?.charAt(0) || "R"}
                </div>
                <div className="hidden sm:block text-left">
                  <span className="text-xs font-black text-slate-900 block leading-tight">
                    {profile?.full_name || "Rohit Sharma"}
                  </span>
                  <span className="text-[10px] font-bold text-amber-600 block leading-tight">
                    Truck Owner
                  </span>
                </div>
                <ChevronDown size={14} className="text-slate-400" />
              </button>

              {profileOpen && (
                <div className="absolute right-0 mt-2 w-52 bg-white border border-slate-200 rounded-2xl shadow-xl z-50 py-1 font-bold text-xs space-y-1">
                  <button onClick={() => { setProfileOpen(false); navigate("/dashboard/sme"); }} className="w-full text-left px-4 py-2 hover:bg-blue-50 text-blue-700 flex items-center gap-2">
                    <RefreshCw size={14} /> Switch to Customer View
                  </button>
                  <Link to="/owner/settings" onClick={() => setProfileOpen(false)} className="px-4 py-2 hover:bg-slate-50 flex items-center gap-2 text-slate-700">
                    <User size={14} /> Profile Settings
                  </Link>
                  <Link to="/owner/documents" onClick={() => setProfileOpen(false)} className="px-4 py-2 hover:bg-slate-50 flex items-center gap-2 text-slate-700">
                    <ShieldCheck size={14} /> KYC Verification
                  </Link>
                  <button
                    onClick={async () => {
                      setProfileOpen(false);
                      await signOut();
                      navigate("/");
                    }}
                    className="w-full text-left px-4 py-2 hover:bg-rose-50 text-rose-600 font-bold border-t border-slate-100 flex items-center gap-2"
                  >
                    Logout
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Main Grid with Left Sidebar & Content */}
      <div className="mx-auto max-w-[1500px] px-6 py-6 grid gap-6 lg:grid-cols-[240px_1fr]">
        
        {/* Left Sidebar matching Mockup 1 & 2 */}
        <aside className="space-y-4">
          {/* Owner Profile Badge Card */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex items-center gap-3">
            <div className="relative w-12 h-12 rounded-2xl bg-amber-100 border border-amber-300 flex items-center justify-center text-2xl shrink-0 shadow-sm">
              🚛
            </div>
            <div className="min-w-0 flex-1">
              <span className="text-[10px] font-black uppercase text-slate-400 tracking-wider block">Owner</span>
              <h4 className="text-xs font-black text-slate-900 truncate">{profile?.full_name || "Rohit Sharma"}</h4>
              <span className="inline-flex items-center gap-1 text-[9px] font-black text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full mt-0.5">
                <ShieldCheck size={10} /> Verified
              </span>
            </div>
          </div>

          {/* Vertical Navigation Menu */}
          <nav className="bg-white border border-slate-200/80 rounded-2xl p-2 shadow-sm space-y-1">
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
                      : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                  }`}
                >
                  <Icon size={16} className={isActive ? "text-slate-950" : "text-slate-400"} />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>

          {/* Dynamic Sidebar Promo Card (Refer & Earn / Bank Details / Add Truck) */}
          {promoCardType === "bank" ? (
            <div className="bg-white border border-amber-200/80 rounded-2xl p-4 shadow-sm space-y-3 relative overflow-hidden">
              <div className="space-y-1">
                <span className="text-xs font-black text-slate-900 block">Get Paid Faster!</span>
                <p className="text-[10px] text-slate-500 font-medium leading-relaxed">
                  Add your bank account and UPI to receive payments quickly and securely.
                </p>
              </div>

              <button
                onClick={onAddBankClick || (() => navigate("/owner/settings"))}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs py-2.5 rounded-xl shadow-sm transition flex items-center justify-center gap-1.5"
              >
                <Landmark size={14} /> Add Bank Details
              </button>

              <div className="flex items-center justify-center pt-1">
                <div className="w-12 h-12 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-200">
                  <Landmark size={22} />
                </div>
              </div>
            </div>
          ) : promoCardType === "truck" ? (
            <div className="bg-white border border-amber-200/80 rounded-2xl p-4 shadow-sm space-y-3 relative overflow-hidden">
              <div className="space-y-1">
                <span className="text-xs font-black text-slate-900 block">Earn More, Every Trip!</span>
                <p className="text-[10px] text-slate-500 font-medium leading-relaxed">
                  Keep your trucks active and earn more with Redo.
                </p>
              </div>

              <button
                onClick={onAddTruckClick || (() => navigate("/owner/trucks"))}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs py-2.5 rounded-xl shadow-sm transition flex items-center justify-center gap-1.5"
              >
                <Plus size={14} /> Add New Truck
              </button>

              <div className="flex items-center justify-center pt-1 text-3xl">
                🚛
              </div>
            </div>
          ) : (
            <div className="bg-white border border-amber-200/80 rounded-2xl p-4 shadow-sm space-y-3 relative overflow-hidden">
              <div className="space-y-1">
                <span className="text-xs font-black text-slate-900 block">Refer &amp; Earn</span>
                <p className="text-[10px] text-slate-500 font-medium leading-relaxed">
                  Refer other truck owners and earn up to ₹500
                </p>
              </div>

              <button
                onClick={() => navigate("/owner/support")}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs py-2.5 rounded-xl shadow-sm transition flex items-center justify-center gap-1.5"
              >
                <Gift size={14} /> Refer Now
              </button>

              <div className="flex items-center justify-center pt-1 text-2xl">
                🤝 ₹500
              </div>
            </div>
          )}
        </aside>

        {/* Right Main Page View */}
        <main className="min-w-0 space-y-6">
          {children}
        </main>
      </div>
    </div>
  );
}
