// AppShell — sidebar + header per REDO Transport & Logistics design.
// Keeps the same default export name so every existing page picks it up.
import { useEffect, useState, type ReactNode } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  Bell, BookOpen, Box, CalendarCheck, FileText, HelpCircle, Home, IndianRupee,
  LayoutDashboard, LogOut, MapPin, Menu, Package, Route, Settings, Star,
  Truck, Wallet, X,
} from "lucide-react";
import { useAuth } from "../hooks/useAuth";
import { api } from "../services/api";
import Logo from "./Logo";
export { default as Logo } from "./Logo";
import { Badge } from "./ui";

type Item = { to: string; label: string; icon: any };

const NAV: Record<string, Item[]> = {
  sme: [
    { to: "/dashboard/sme", label: "Dashboard", icon: LayoutDashboard },
    { to: "/shipments", label: "My Shipments", icon: Package },
    { to: "/book", label: "Book Shipment", icon: Box },
    { to: "/invoices", label: "Invoices & Payments", icon: FileText },
    { to: "/addresses", label: "Addresses", icon: MapPin },
    { to: "/support", label: "Support", icon: HelpCircle },
    { to: "/rate-card", label: "Rate Card", icon: BookOpen },
    { to: "/notifications", label: "Notifications", icon: Bell },
    { to: "/settings", label: "Profile Settings", icon: Settings },
  ],
  truck_owner: [
    { to: "/dashboard/owner", label: "Dashboard", icon: LayoutDashboard },
    { to: "/trucks", label: "My Trucks", icon: Truck },
    { to: "/loads", label: "Available Loads", icon: Box },
    { to: "/shipments", label: "My Bookings", icon: CalendarCheck },
    { to: "/earnings", label: "Earnings", icon: IndianRupee },
    { to: "/trips", label: "Trips", icon: Route },
    { to: "/documents", label: "Documents", icon: FileText },
    { to: "/reviews", label: "Reviews", icon: Star },
    { to: "/support", label: "Support", icon: HelpCircle },
    { to: "/settings", label: "Settings", icon: Settings },
  ],
  admin: [
    { to: "/admin", label: "Dashboard", icon: LayoutDashboard },
    { to: "/admin/users", label: "Users", icon: Home },
    { to: "/admin/kyc", label: "KYC Verification", icon: FileText },
    { to: "/notifications", label: "Notifications", icon: Bell },
  ],
};

const THEME: Record<string, string> = {
  sme: "theme-shipper", truck_owner: "theme-owner", admin: "theme-admin",
};
const ROLE_LABEL: Record<string, string> = {
  sme: "Shipper", truck_owner: "Truck Owner", admin: "Admin",
};

export default function Layout({ children }: { children: ReactNode }) {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();
  const [drawer, setDrawer] = useState(false);
  const [unread, setUnread] = useState(0);
  const [wallet, setWallet] = useState<number | null>(null);
  const role = profile?.role ?? "sme";
  const nav = NAV[role];
  const isDemo = profile?.full_name?.includes("(Demo)");

  useEffect(() => {
    api.get<any[]>("/notifications").then((n) => setUnread(n.filter((x) => !x.read).length)).catch(() => {});
    if (role === "truck_owner") {
      api.get<any>("/earnings").then((e) => setWallet(e.totals?.pending_inr ?? 0)).catch(() => {});
    }
  }, [role]);

  const SideNav = (
    <nav className="flex-1 overflow-y-auto px-3 py-2 space-y-1" aria-label="Main">
      {nav.map(({ to, label, icon: Icon }) => (
        <NavLink key={to} to={to} end={to === "/admin"} onClick={() => setDrawer(false)}
          className={({ isActive }) =>
            `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition
             ${isActive ? "bg-accent-soft text-ink" : "text-ink-soft hover:bg-ink/5"}`}>
          {({ isActive }) => (<>
            <Icon size={18} className={isActive ? "text-accent" : "text-ink-faint"} strokeWidth={2.2} />
            {label}
            {label === "Notifications" && unread > 0 && (
              <span className="ml-auto rounded-full bg-danger text-white text-[10px] font-bold px-1.5 py-0.5">{unread}</span>
            )}
          </>)}
        </NavLink>
      ))}
    </nav>
  );

  return (
    <div className={`${THEME[role]} min-h-screen bg-canvas`}>
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-line">
        <div className="h-16 px-4 flex items-center gap-3">
          <button className="lg:hidden p-2 rounded-lg hover:bg-ink/5" aria-label="Menu" onClick={() => setDrawer(true)}>
            <Menu size={20} />
          </button>
          <button onClick={() => navigate(nav[0].to)} className="shrink-0"><Logo /></button>
          <div className="ml-auto flex items-center gap-2 sm:gap-4">
            {role === "truck_owner" && wallet !== null && (
              <div className="hidden sm:flex items-center gap-2 rounded-xl border border-line px-3 py-1.5">
                <Wallet size={18} className="text-ink-faint" />
                <span className="text-[11px] font-medium text-ink-faint leading-none">Wallet Balance
                  <span className="block text-sm font-extrabold text-ink">₹{wallet.toLocaleString("en-IN")}</span>
                </span>
              </div>
            )}
            <NavLink to="/notifications" aria-label="Notifications" className="relative p-2 rounded-full hover:bg-ink/5">
              <Bell size={19} />
              {unread > 0 && <span className="absolute -top-0.5 -right-0.5 h-4 min-w-4 px-0.5 rounded-full bg-brand text-brand-ink text-[10px] font-bold grid place-items-center">{unread}</span>}
            </NavLink>
            <button onClick={async () => { await signOut(); navigate("/"); }}
              className="flex items-center gap-2 rounded-xl hover:bg-ink/5 px-2 py-1.5" aria-label="Account">
              <span className="h-9 w-9 rounded-full bg-accent text-accent-fg grid place-items-center font-bold text-sm">
                {(profile?.full_name ?? "?")[0]}
              </span>
              <span className="hidden md:block text-left leading-tight">
                <span className="block text-sm font-bold text-ink">{profile?.full_name}</span>
                <span className="block text-[11px] font-medium text-ink-faint">{profile?.company_name || ROLE_LABEL[role]}</span>
              </span>
              <LogOut size={15} className="hidden md:block text-ink-faint" />
            </button>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar (desktop) */}
        <aside className="hidden lg:flex w-64 shrink-0 flex-col bg-white border-r border-line min-h-[calc(100vh-4rem)] sticky top-16 self-start">
          <div className="p-4 flex items-center gap-3 border-b border-line">
            <span className="h-11 w-11 rounded-full bg-accent text-accent-fg grid place-items-center font-bold">
              {(profile?.full_name ?? "?")[0]}
            </span>
            <div className="min-w-0">
              <p className="text-sm font-bold text-ink truncate">{profile?.full_name}</p>
              <p className="text-[11px] font-medium text-ink-faint">{ROLE_LABEL[role]}</p>
              <span className="mt-0.5 inline-flex"><Badge tone="ok">{isDemo ? "Demo · Verified" : "Verified"}</Badge></span>
            </div>
          </div>
          {SideNav}
          <div className="m-3 rounded-xl bg-accent-soft p-4">
            <p className="text-sm font-bold text-ink">{role === "truck_owner" ? "More Trips, More Earnings!" : "Need help?"}</p>
            <p className="mt-1 text-xs text-ink-soft">
              {role === "truck_owner" ? "Keep your trucks active and earn more with Redo." : "Our support team is here to assist you."}
            </p>
            <button onClick={() => navigate(role === "truck_owner" ? "/trucks" : "/support")}
              className="mt-3 rounded-lg bg-accent text-accent-fg text-xs font-bold px-3 py-2">
              {role === "truck_owner" ? "Add New Truck" : "Contact Support"}
            </button>
          </div>
        </aside>

        {/* Sidebar (mobile drawer) */}
        {drawer && (
          <div className="fixed inset-0 z-50 lg:hidden" role="dialog" aria-modal="true">
            <div className="absolute inset-0 bg-ink/40" onClick={() => setDrawer(false)} />
            <div className="absolute inset-y-0 left-0 w-72 bg-white flex flex-col shadow-lift">
              <div className="h-16 px-4 flex items-center justify-between border-b border-line">
                <Logo />
                <button className="p-2" aria-label="Close menu" onClick={() => setDrawer(false)}><X size={20} /></button>
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
