import Logo from './Logo';
export { default as Logo } from './Logo';
import { useState, type ReactNode } from "react";
import { NavLink, Link, useNavigate } from "react-router-dom";
import {
  LayoutDashboard, MapPin, Route, IndianRupee, HelpCircle,
  Home, FileText, Bell, LogOut, Menu, X, ShieldCheck
} from "lucide-react";
import { useAuth } from "../hooks/useAuth";

type Item = { to: string; label: string; icon: any };

const ADMIN_NAV: Item[] = [
  { to: "/admin", label: "Executive Dashboard", icon: LayoutDashboard },
  { to: "/admin/radar", label: "Live Fleet Radar", icon: MapPin },
  { to: "/admin/matching", label: "Corridor Matching", icon: Route },
  { to: "/admin/pricing", label: "Dynamic Pricing Engine", icon: IndianRupee },
  { to: "/admin/disputes", label: "Disputes & Escrow Desk", icon: HelpCircle },
  { to: "/admin/users", label: "User Directory", icon: Home },
  { to: "/admin/kyc", label: "KYC Verifications", icon: FileText },
];

export default function Layout({ children }: { children: ReactNode }) {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();
  const [drawer, setDrawer] = useState(false);

  const handleSignOut = async () => {
    await signOut();
    navigate("/login");
  };

  const SideNav = (
    <nav className="flex-1 overflow-y-auto px-3 py-3 space-y-1.5" aria-label="Admin Navigation">
      <div className="px-3 pb-2 text-[10px] font-black uppercase tracking-wider text-slate-500">
        Operations Control
      </div>
      {ADMIN_NAV.map(({ to, label, icon: Icon }) => (
        <NavLink
          key={to}
          to={to}
          end={to === "/admin"}
          onClick={() => setDrawer(false)}
          className={({ isActive }) =>
            `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition ${
              isActive
                ? "bg-amber-500/15 text-amber-400 border border-amber-500/20 font-bold"
                : "text-slate-400 hover:text-white hover:bg-slate-800/60"
            }`
          }
        >
          {({ isActive }) => (
            <>
              <Icon size={18} className={isActive ? "text-amber-400" : "text-slate-500"} strokeWidth={2.2} />
              <span>{label}</span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  );

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col antialiased">
      {/* Top Cockpit Header */}
      <header className="sticky top-0 z-40 bg-slate-950/90 backdrop-blur-md border-b border-slate-800">
        <div className="mx-auto flex h-14 max-w-7xl items-center justify-between px-4 sm:px-6">
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
                  <span className="px-1.5 py-0.5 rounded bg-amber-500/20 border border-amber-500/30 text-[10px] font-black text-amber-400 tracking-wider">
                    OPERATIONS
                  </span>
                </div>
                <span className="text-[10px] font-medium text-slate-400 -mt-0.5">Control Room</span>
              </div>
            </Link>
          </div>

          <div className="flex items-center gap-3">
            {/* Live Indicator */}
            <div className="hidden sm:flex items-center gap-2 px-2.5 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span>Live Radar Active</span>
            </div>

            {/* Admin Profile */}
            <div className="flex items-center gap-2 pl-2 border-l border-slate-800">
              <div className="hidden sm:flex flex-col text-right">
                <span className="text-xs font-bold text-slate-200">{profile?.full_name || "Operations Director"}</span>
                <span className="text-[10px] text-amber-400 font-semibold">Super Admin</span>
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

      <div className="mx-auto flex w-full max-w-7xl flex-1 px-4 py-4 sm:px-6 md:gap-6">
        {/* Desktop Sidebar */}
        <aside className="hidden w-64 shrink-0 md:flex flex-col rounded-2xl bg-slate-900/60 border border-slate-800 p-2 h-[calc(100vh-6rem)] sticky top-20 backdrop-blur-sm">
          {SideNav}
          <div className="p-3 border-t border-slate-800/80 text-[11px] text-slate-500 flex flex-col gap-1">
            <span className="text-slate-400 font-bold">REDO Logistics 2.0</span>
            <span>Live Capacity Network</span>
          </div>
        </aside>

        {/* Mobile Drawer */}
        {drawer && (
          <div className="fixed inset-0 z-50 flex md:hidden">
            <div className="fixed inset-0 bg-black/70 backdrop-blur-xs" onClick={() => setDrawer(false)} />
            <div className="relative flex w-72 flex-col bg-slate-900 border-r border-slate-800 p-3 text-white">
              <div className="flex items-center justify-between pb-3 px-2 border-b border-slate-800">
                <span className="text-sm font-black text-amber-400">REDO Control Room</span>
                <button onClick={() => setDrawer(false)} className="p-1 text-slate-400">
                  <X size={18} />
                </button>
              </div>
              {SideNav}
            </div>
          </div>
        )}

        {/* Main Content Pane */}
        <main className="flex-1 min-w-0">{children}</main>
      </div>
    </div>
  );
}
