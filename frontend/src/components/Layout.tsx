import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { Button } from "./ui";
import type { ReactNode } from "react";
import { Truck, PackageCheck, Bell, User, LogOut, ShieldCheck, LayoutDashboard, PlusCircle, BookmarkCheck, Leaf, Sparkles } from "lucide-react";

const NAV = {
  truck_owner: [
    { to: "/dashboard/owner", label: "Overview", icon: LayoutDashboard },
    { to: "/trips/new", label: "Add Return Trip", icon: PlusCircle },
    { to: "/bookings", label: "Bookings", icon: BookmarkCheck },
    { to: "/impact", label: "Green Impact", icon: Leaf },
    { to: "/verification", label: "Vehicle KYC", icon: ShieldCheck },
  ],
  sme: [
    { to: "/dashboard/sme", label: "Overview", icon: LayoutDashboard },
    { to: "/post-cargo", label: "Post Freight", icon: PlusCircle },
    { to: "/bookings", label: "Bookings", icon: BookmarkCheck },
    { to: "/impact", label: "Green Impact", icon: Leaf },
    { to: "/profile", label: "Business Profile", icon: User },
  ],
};

export function Logo({ dark }: { dark?: boolean }) {
  return (
    <div className="flex items-center gap-2">
      <div className={`w-8 h-8 rounded-xl flex items-center justify-center font-black text-sm tracking-tighter ${dark ? "bg-blue-600 text-white shadow-glow" : "bg-slate-900 text-white"}`}>
        R
      </div>
      <span className={`font-black tracking-tight text-lg ${dark ? "text-white" : "text-slate-900"}`}>
        RE<span className="text-blue-600">DO</span>
        <span className={`ml-2 hidden sm:inline-block text-[10px] font-bold tracking-wider uppercase px-2 py-0.5 rounded-full ${dark ? "bg-slate-800 text-slate-300 border border-slate-700" : "bg-slate-100 text-slate-600 border border-slate-200"}`}>
          Commercial Logistics
        </span>
      </span>
    </div>
  );
}

export default function Layout({ children }: { children: ReactNode }) {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();
  const nav = NAV[profile?.role ?? "sme"];

  return (
    <div className="min-h-screen bg-slate-50/80 text-slate-900 pb-20 md:pb-12">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white/90 backdrop-blur-md border-b border-slate-200/80 shadow-xs">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 h-16 flex items-center justify-between">
          <button
            onClick={() => navigate(profile?.role === "sme" ? "/dashboard/sme" : "/dashboard/owner")}
            className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 rounded-xl"
          >
            <Logo />
          </button>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-1 bg-slate-100/80 p-1 border border-slate-200/60 rounded-2xl" aria-label="Main Navigation">
            {nav.map((n) => {
              const Icon = n.icon;
              return (
                <NavLink
                  key={n.to}
                  to={n.to}
                  className={({ isActive }) =>
                    `flex items-center gap-2 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
                      isActive ? "bg-slate-900 text-white shadow-sm" : "text-slate-600 hover:text-slate-900 hover:bg-white/60"
                    }`
                  }
                >
                  <Icon className="w-3.5 h-3.5" />
                  <span>{n.label}</span>
                </NavLink>
              );
            })}
          </nav>

          {/* Actions */}
          <div className="flex items-center gap-2.5">
            {/* Role Badge */}
            <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200/80">
              {profile?.role === "sme" ? <PackageCheck className="w-3.5 h-3.5 text-blue-600" /> : <Truck className="w-3.5 h-3.5 text-emerald-600" />}
              <span>{profile?.role === "sme" ? "SME Shipper" : "Fleet Owner"}</span>
            </span>

            <NavLink
              to="/notifications"
              aria-label="Notifications"
              className="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200/80 border border-slate-200/80 text-slate-700 flex items-center justify-center transition"
            >
              <Bell className="w-4 h-4" />
            </NavLink>

            {/* Profile Avatar DP */}
            <NavLink
              to="/profile"
              aria-label="Profile"
              className="w-9 h-9 rounded-xl bg-blue-600 text-white flex items-center justify-center text-xs font-black shadow-sm overflow-hidden border border-slate-200"
            >
              {profile?.avatar_url ? (
                <img src={profile.avatar_url} alt={profile.full_name} className="w-full h-full object-cover" />
              ) : (
                (profile?.full_name ?? "U")[0].toUpperCase()
              )}
            </NavLink>

            <Button
              variant="ghost"
              className="!py-1.5 !px-2.5 !text-xs !font-bold text-slate-600 hover:text-rose-600 hidden sm:inline-flex"
              onClick={async () => {
                await signOut();
                navigate("/login");
              }}
            >
              <LogOut className="w-3.5 h-3.5" />
              <span>Exit</span>
            </Button>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="mx-auto max-w-7xl px-4 sm:px-6 py-6 sm:py-8">{children}</main>

      {/* Mobile Navigation Footer */}
      <nav aria-label="Mobile Navigation" className="md:hidden fixed bottom-0 inset-x-0 z-40 bg-white/95 backdrop-blur-lg border-t border-slate-200/80 grid grid-cols-5 py-2 px-1">
        {nav.map((n) => {
          const Icon = n.icon
          return (
            <NavLink
              key={n.to}
              to={n.to}
              className={({ isActive }) =>
                `flex flex-col items-center gap-1 py-1.5 text-[10px] font-bold transition-all ${
                  isActive ? "text-blue-600" : "text-slate-500 hover:text-slate-800"
                }`
              }
            >
              <Icon className="w-4 h-4" />
              <span className="truncate max-w-[64px]">{n.label.split(" ")[0]}</span>
            </NavLink>
          )
        })}
      </nav>
    </div>
  )
}

