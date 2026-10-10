import Logo from './Logo';
export { default as Logo } from './Logo';
import { useState, useEffect, type ReactNode } from "react";
import { NavLink, Link, useNavigate, useLocation } from "react-router-dom";
import {
  LayoutDashboard, MapPin, Route, IndianRupee, HelpCircle,
  Home, FileText, Bell, LogOut, Menu, X, ShieldCheck, Package, CreditCard, ArrowUpRight,
  Search, Sparkles, AlertTriangle, Truck, CheckSquare, PhoneCall, ShieldAlert,
  Sliders, Activity, FileCheck, LifeBuoy, ChevronDown, ChevronRight
} from "lucide-react";
import { useAuth } from "../hooks/useAuth";
import { api } from "../services/api";
import OmniSearchModal from "./OmniSearchModal";
import OperationsAiDrawer from "./OperationsAiDrawer";

interface NavGroup {
  title: string;
  items: { to: string; label: string; icon: any; badge?: number }[];
}

export default function Layout({ children }: { children: ReactNode }) {
  const { profile, session, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [drawer, setDrawer] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [aiDrawerOpen, setAiDrawerOpen] = useState(false);
  const [pendingKycCount, setPendingKycCount] = useState<number>(0);
  const [systemHealth, setSystemHealth] = useState<string>("HEALTHY");

  // Fetch quick operational badges
  useEffect(() => {
    let mounted = true;
    const fetchBadges = async () => {
      try {
        const stats = await api.get<any>("/admin/stats");
        if (mounted && stats?.kyc_pending !== undefined) {
          setPendingKycCount(stats.kyc_pending);
        }
      } catch (_) {}

      try {
        const health = await api.get<any>("/admin/system/health");
        if (mounted && health?.status) {
          setSystemHealth(health.status);
        }
      } catch (_) {}
    };

    fetchBadges();
    const interval = setInterval(fetchBadges, 30000); // 30s poll
    return () => {
      mounted = false;
      clearInterval(interval);
    };
  }, []);

  // Keyboard shortcut '/' to trigger omni search
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "/" && (e.target as HTMLElement).tagName !== "INPUT" && (e.target as HTMLElement).tagName !== "TEXTAREA") {
        e.preventDefault();
        setSearchOpen(true);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const handleSignOut = async () => {
    await signOut();
    navigate("/login");
  };

  const navGroups: NavGroup[] = [
    {
      title: "Command Center",
      items: [
        { to: "/admin", label: "Executive Dashboard", icon: LayoutDashboard },
      ],
    },
    {
      title: "Operations",
      items: [
        { to: "/admin/bookings", label: "Shipments & Bookings", icon: Package },
        { to: "/admin/trips", label: "Active Trips & En-Route", icon: Activity },
        { to: "/admin/radar", label: "Live Fleet Radar", icon: MapPin },
        { to: "/admin/matching", label: "Corridor Matching", icon: Route },
      ],
    },
    {
      title: "Verification Center",
      items: [
        { to: "/admin/verification/partners", label: "Partner Verification", icon: ShieldCheck, badge: pendingKycCount },
        { to: "/admin/verification/vehicles", label: "Vehicle Compliance", icon: Truck },
        { to: "/admin/verification/cargo", label: "Cargo Compliance", icon: FileCheck },
        { to: "/admin/verification/documents", label: "Document Registry", icon: FileText },
      ],
    },
    {
      title: "Users & Accounts",
      items: [
        { to: "/admin/users", label: "User Directory", icon: Home },
      ],
    },
    {
      title: "Finance & Settlements",
      items: [
        { to: "/admin/payments", label: "Razorpay Payments", icon: CreditCard },
        { to: "/admin/payouts", label: "Driver Payouts", icon: ArrowUpRight },
        { to: "/admin/disputes", label: "Disputes & Escrow", icon: HelpCircle },
      ],
    },
    {
      title: "Communication",
      items: [
        { to: "/admin/communication/tickets", label: "Support Tickets", icon: LifeBuoy },
        { to: "/admin/communication/calls", label: "Call Signaling Logs", icon: PhoneCall },
        { to: "/admin/communication/notifications", label: "Platform Broadcasts", icon: Bell },
      ],
    },
    {
      title: "Configuration",
      items: [
        { to: "/admin/pricing", label: "Dynamic Pricing Engine", icon: IndianRupee },
      ],
    },
    {
      title: "System & Compliance",
      items: [
        { to: "/admin/system/alerts", label: "Operations Alerts", icon: AlertTriangle },
        { to: "/admin/system/audit-logs", label: "Immutable Audit Logs", icon: ShieldAlert },
        { to: "/admin/system/health", label: "API & Service Health", icon: Sliders },
      ],
    },
  ];

  const SideNav = (
    <nav className="flex-1 overflow-y-auto px-2 py-3 space-y-4 text-xs font-semibold" aria-label="Admin Operations Navigation">
      {navGroups.map((group, gIdx) => (
        <div key={gIdx} className="space-y-1">
          <div className="px-3 pb-1 text-[10px] font-black uppercase tracking-wider text-slate-500">
            {group.title}
          </div>
          {group.items.map(({ to, label, icon: Icon, badge }) => (
            <NavLink
              key={to}
              to={to}
              end={to === "/admin"}
              onClick={() => setDrawer(false)}
              className={({ isActive }) =>
                `flex items-center justify-between rounded-xl px-3 py-2 text-xs font-semibold transition ${
                  isActive
                    ? "bg-amber-500/15 text-amber-400 border border-amber-500/20 font-bold shadow-xs"
                    : "text-slate-400 hover:text-white hover:bg-slate-800/60"
                }`
              }
            >
              {({ isActive }) => (
                <>
                  <div className="flex items-center gap-2.5 min-w-0">
                    <Icon size={16} className={isActive ? "text-amber-400" : "text-slate-500"} strokeWidth={2.2} />
                    <span className="truncate">{label}</span>
                  </div>
                  {badge !== undefined && badge > 0 && (
                    <span className="px-1.5 py-0.2 rounded-full bg-amber-500/20 text-amber-400 border border-amber-500/30 text-[10px] font-black">
                      {badge}
                    </span>
                  )}
                </>
              )}
            </NavLink>
          ))}
        </div>
      ))}
    </nav>
  );

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col antialiased">
      {/* Top Cockpit Header */}
      <header className="sticky top-0 z-40 bg-slate-950/95 backdrop-blur-md border-b border-slate-800">
        <div className="mx-auto flex h-14 w-full px-4 sm:px-6 items-center justify-between gap-4">
          {/* Logo & Mobile Menu Toggle */}
          <div className="flex items-center gap-3">
            <button
              onClick={() => setDrawer(true)}
              className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 md:hidden"
              aria-label="Toggle Navigation"
            >
              <Menu size={20} />
            </button>
            <Link to="/admin" className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-amber-400 text-slate-950 font-black flex items-center justify-center text-base shadow-sm shadow-amber-400/20">
                R
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-black tracking-tight text-white">REDO</span>
                  <span className="px-1.5 py-0.5 rounded bg-amber-500/20 border border-amber-500/30 text-[9px] font-black text-amber-400 tracking-wider">
                    OPERATIONS
                  </span>
                </div>
                <span className="text-[10px] font-medium text-slate-400 -mt-0.5">Control Center</span>
              </div>
            </Link>
          </div>

          {/* Omni Search Button */}
          <div className="flex-1 max-w-md hidden sm:block">
            <button
              onClick={() => setSearchOpen(true)}
              className="w-full flex items-center justify-between px-3.5 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-400 hover:border-slate-700 transition"
            >
              <div className="flex items-center gap-2">
                <Search size={14} className="text-slate-500" />
                <span>Search shipments, trucks, shippers, tickets...</span>
              </div>
              <kbd className="px-1.5 py-0.5 text-[10px] font-bold text-slate-400 bg-slate-800 border border-slate-700 rounded">
                /
              </kbd>
            </button>
          </div>

          {/* Right Action Icons */}
          <div className="flex items-center gap-2.5">
            {/* Mobile Search Icon */}
            <button
              onClick={() => setSearchOpen(true)}
              className="sm:hidden p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
              title="Omni Search"
            >
              <Search size={18} />
            </button>

            {/* Operations AI Trigger */}
            <button
              onClick={() => setAiDrawerOpen(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-400 hover:bg-amber-500 text-slate-950 font-black text-xs transition shadow-sm shadow-amber-400/20"
              title="REDO Operations AI Copilot"
            >
              <Sparkles size={14} />
              <span className="hidden md:inline">Operations AI</span>
            </button>

            {/* Live Service Health Pill */}
            <Link
              to="/admin/system/health"
              className={`hidden lg:flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-bold transition border ${
                systemHealth === "HEALTHY"
                  ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-400 hover:bg-emerald-500/20"
                  : "bg-rose-500/10 border-rose-500/20 text-rose-400 hover:bg-rose-500/20"
              }`}
            >
              <span className={`w-2 h-2 rounded-full ${systemHealth === "HEALTHY" ? "bg-emerald-400 animate-pulse" : "bg-rose-400"}`} />
              <span>{systemHealth}</span>
            </Link>

            {/* Pending Verification Counter Button */}
            <Link
              to="/admin/verification/partners"
              className="relative p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition"
              title="Verification Queue"
            >
              <ShieldCheck size={18} />
              {pendingKycCount > 0 && (
                <span className="absolute top-1 right-1 w-4 h-4 rounded-full bg-amber-400 text-slate-950 font-black text-[9px] flex items-center justify-center">
                  {pendingKycCount}
                </span>
              )}
            </Link>

            {/* Admin Profile & Logout */}
            <div className="flex items-center gap-2 pl-2 border-l border-slate-800">
              <div className="hidden xl:flex flex-col text-right">
                <span className="text-xs font-bold text-slate-200 truncate max-w-[120px]">
                  {session?.user.email || profile?.full_name || "Administrator"}
                </span>
                <span className="text-[10px] text-amber-400 font-semibold">{profile?.role || "admin"}</span>
              </div>
              <button
                onClick={handleSignOut}
                className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-slate-800/80 transition"
                title="Sign Out"
              >
                <LogOut size={16} />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Workspace Frame */}
      <div className="mx-auto flex w-full max-w-[1600px] flex-1 px-3 sm:px-6 py-4 md:gap-5">
        {/* Desktop Sidebar */}
        <aside className="hidden w-64 shrink-0 md:flex flex-col rounded-2xl bg-slate-900/70 border border-slate-800 p-1.5 h-[calc(100vh-5.5rem)] sticky top-18 backdrop-blur-md shadow-xl">
          {SideNav}
          <div className="p-3 border-t border-slate-800/80 text-[10px] text-slate-500 flex flex-col gap-0.5">
            <div className="flex items-center justify-between">
              <span className="text-slate-300 font-bold">REDO Operations v2.0</span>
              <span className="text-emerald-400 font-bold">ONLINE</span>
            </div>
            <span>Moving Capacity & Backhaul Network</span>
          </div>
        </aside>

        {/* Mobile Drawer */}
        {drawer && (
          <div className="fixed inset-0 z-50 flex md:hidden">
            <div className="fixed inset-0 bg-black/75 backdrop-blur-xs" onClick={() => setDrawer(false)} />
            <div className="relative flex w-72 flex-col bg-slate-900 border-r border-slate-800 p-3 text-white">
              <div className="flex items-center justify-between pb-3 px-2 border-b border-slate-800">
                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded bg-amber-400 text-slate-950 font-black flex items-center justify-center text-xs">
                    R
                  </div>
                  <span className="text-xs font-black text-white">REDO Operations</span>
                </div>
                <button onClick={() => setDrawer(false)} className="p-1 text-slate-400">
                  <X size={18} />
                </button>
              </div>
              {SideNav}
            </div>
          </div>
        )}

        {/* Main Operational Pane */}
        <main className="flex-1 min-w-0">{children}</main>
      </div>

      {/* Omni Search Modal */}
      <OmniSearchModal isOpen={searchOpen} onClose={() => setSearchOpen(false)} />

      {/* Operations AI Drawer */}
      <OperationsAiDrawer isOpen={aiDrawerOpen} onClose={() => setAiDrawerOpen(false)} />
    </div>
  );
}
