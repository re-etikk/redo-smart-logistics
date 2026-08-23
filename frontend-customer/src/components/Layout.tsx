import { useEffect, useState, type ReactNode } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  Bell, BookOpen, Box, FileText, HelpCircle,
  LayoutDashboard, LogOut, MapPin, Menu, Package, PlusCircle, Settings, X,
} from "lucide-react";
import { useAuth } from "../hooks/useAuth";
import { api } from "../lib/api";
import Logo from "../components/Logo";
export { default as Logo } from "../components/Logo";
import { Badge } from "../components/ui";

type Item = { to: string; label: string; icon: any };

const NAV: Item[] = [
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/book", label: "Book Shipment", icon: Box },
  { to: "/post-cargo", label: "Post Load", icon: PlusCircle },
  { to: "/shipments", label: "My Shipments", icon: Package },
  { to: "/invoices", label: "Invoices & Payments", icon: FileText },
  { to: "/addresses", label: "Addresses", icon: MapPin },
  { to: "/rate-card", label: "Rate Card", icon: BookOpen },
  { to: "/support", label: "Support", icon: HelpCircle },
  { to: "/settings", label: "Profile & GST", icon: Settings },
];

export default function Layout({ children }: { children: ReactNode }) {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();
  const [drawer, setDrawer] = useState(false);
  const [unread, setUnread] = useState(0);

  useEffect(() => {
    api.get<any[]>("/notifications").then((n) => setUnread(n.filter((x) => !x.read).length)).catch(() => {});
  }, []);

  const SideNav = (
    <nav className="flex-1 overflow-y-auto px-3 py-2 space-y-1" aria-label="Main">
      {NAV.map(({ to, label, icon: Icon }) => (
        <NavLink
          key={to}
          to={to}
          end={to === "/dashboard"}
          onClick={() => setDrawer(false)}
          className={({ isActive }) =>
            `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition ${
              isActive ? "bg-amber-100/80 text-slate-900 border-l-4 border-amber-500 font-bold shadow-sm" : "text-slate-600 hover:bg-slate-100"
            }`
          }
        >
          {({ isActive }) => (
            <>
              <Icon size={18} className={isActive ? "text-amber-600" : "text-slate-400"} strokeWidth={2.2} />
              <span>{label}</span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  );

  return (
    <div className="theme-shipper min-h-screen bg-[#FAF9F6] text-slate-900 font-sans">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-slate-200">
        <div className="h-16 px-4 flex items-center justify-between max-w-[1400px] mx-auto w-full">
          <div className="flex items-center gap-3">
            <button className="lg:hidden p-2 rounded-lg hover:bg-slate-100" aria-label="Menu" onClick={() => setDrawer(true)}>
              <Menu size={20} />
            </button>
            <button onClick={() => navigate("/dashboard")} className="shrink-0">
              <Logo />
            </button>
          </div>

          <div className="flex items-center gap-3 sm:gap-4">
            <button
              onClick={() => navigate("/book")}
              className="hidden sm:inline-flex items-center gap-1.5 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-4 py-2 rounded-xl text-xs shadow-sm transition"
            >
              <Box size={16} />
              <span>Book a Truck</span>
            </button>

            <NavLink to="/notifications" aria-label="Notifications" className="relative p-2 rounded-full hover:bg-slate-100">
              <Bell size={19} className="text-slate-600" />
              {unread > 0 && (
                <span className="absolute top-1 right-1 h-4 min-w-4 px-1 rounded-full bg-amber-500 text-slate-950 text-[10px] font-bold grid place-items-center">
                  {unread}
                </span>
              )}
            </NavLink>

            <div className="flex items-center gap-2 border-l border-slate-200 pl-3">
              <span className="h-9 w-9 rounded-full bg-amber-400 text-slate-950 font-black text-sm flex items-center justify-center shadow-sm">
                {(profile?.full_name ?? "C")[0]}
              </span>
              <div className="hidden md:block text-left leading-tight">
                <span className="block text-xs font-black text-slate-900">{profile?.full_name || "Customer"}</span>
                <span className="block text-[10px] font-semibold text-slate-500">{profile?.company_name || "Shipper"}</span>
              </div>
              <button
                onClick={async () => { await signOut(); navigate("/login"); }}
                className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition"
                title="Sign out"
              >
                <LogOut size={16} />
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-[1400px] mx-auto flex">
        {/* Sidebar (desktop) */}
        <aside className="hidden lg:flex w-64 shrink-0 flex-col bg-white border-r border-slate-200 min-h-[calc(100vh-4rem)] sticky top-16 self-start">
          <div className="p-4 flex items-center gap-3 border-b border-slate-100">
            <span className="h-10 w-10 rounded-full bg-amber-100 text-amber-900 border border-amber-300 grid place-items-center font-bold text-sm">
              {(profile?.full_name ?? "C")[0]}
            </span>
            <div className="min-w-0">
              <p className="text-sm font-bold text-slate-900 truncate">{profile?.full_name || "Customer Account"}</p>
              <p className="text-[11px] font-medium text-slate-500">Shipper / SME</p>
              <span className="mt-0.5 inline-flex"><Badge tone="ok">Verified Shipper</Badge></span>
            </div>
          </div>

          {SideNav}

          <div className="m-3 rounded-2xl bg-amber-50 border border-amber-200 p-4">
            <p className="text-xs font-black text-slate-900">Need Immediate Dispatch?</p>
            <p className="mt-1 text-[11px] text-slate-600">
              Post an urgent load and get quotes in 5 minutes.
            </p>
            <button
              onClick={() => navigate("/post-cargo")}
              className="mt-3 w-full rounded-xl bg-[#FFC800] hover:bg-amber-400 text-slate-950 text-xs font-black py-2 shadow-sm transition text-center block"
            >
              Post Load Request
            </button>
          </div>
        </aside>

        {/* Sidebar (mobile drawer) */}
        {drawer && (
          <div className="fixed inset-0 z-50 lg:hidden" role="dialog" aria-modal="true">
            <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => setDrawer(false)} />
            <div className="absolute inset-y-0 left-0 w-72 bg-white flex flex-col shadow-2xl">
              <div className="h-16 px-4 flex items-center justify-between border-b border-slate-200">
                <Logo />
                <button className="p-2" aria-label="Close menu" onClick={() => setDrawer(false)}>
                  <X size={20} />
                </button>
              </div>
              {SideNav}
            </div>
          </div>
        )}

        <main className="flex-1 min-w-0 px-4 lg:px-8 py-6 max-w-[1200px]">{children}</main>
      </div>
    </div>
  );
}
