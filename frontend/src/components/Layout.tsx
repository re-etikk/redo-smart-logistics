import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { Button } from "./ui";
import type { ReactNode } from "react";

const NAV = {
  truck_owner: [
    { to: "/dashboard/owner", label: "Overview" },
    { to: "/trips/new", label: "Add trip" },
    { to: "/bookings", label: "Bookings" },
    { to: "/impact", label: "Impact" },
    { to: "/verification", label: "Verify" },
  ],
  sme: [
    { to: "/dashboard/sme", label: "Overview" },
    { to: "/post-cargo", label: "Post cargo" },
    { to: "/bookings", label: "Bookings" },
    { to: "/impact", label: "Impact" },
    { to: "/verification", label: "Verify" },
  ],
};

export function Logo({ dark }: { dark?: boolean }) {
  return (
    <span className={`font-extrabold tracking-tight text-lg ${dark ? "text-white" : "text-ink"}`}>
      RE<span className="text-accent">DO</span>
      <span className={`ml-2 hidden sm:inline text-[11px] font-semibold tracking-wide uppercase ${dark ? "text-white/60" : "text-ink-faint"}`}>
        Smart Backhaul Network
      </span>
    </span>
  );
}

export default function Layout({ children }: { children: ReactNode }) {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();
  const nav = NAV[profile?.role ?? "sme"];
  const isDemo = profile?.full_name?.includes("(Demo)");
  return (
    <div className="min-h-screen bg-canvas pb-20 md:pb-8">
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center justify-between">
          <button onClick={() => navigate(profile?.role === "sme" ? "/dashboard/sme" : "/dashboard/owner")}
            className="focus-visible:ring-2 focus-visible:ring-accent rounded"><Logo /></button>
          <nav className="hidden md:flex items-center gap-1" aria-label="Main">
            {nav.map((n) => (
              <NavLink key={n.to} to={n.to}
                className={({ isActive }) =>
                  `px-3 py-1.5 rounded-lg text-sm font-medium transition ${isActive ? "bg-ink text-white" : "text-ink-soft hover:bg-ink/5"}`}>
                {n.label}
              </NavLink>
            ))}
          </nav>
          <div className="flex items-center gap-2">
            {isDemo && <span className="rounded-md bg-warn-soft text-warn px-2 py-0.5 text-xs font-semibold">Demo account</span>}
            <NavLink to="/notifications" aria-label="Notifications"
              className="h-8 w-8 rounded-full bg-ink/5 text-ink-soft flex items-center justify-center hover:bg-ink/10">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" strokeLinecap="round" strokeLinejoin="round" />
                <path d="M13.7 21a2 2 0 0 1-3.4 0" strokeLinecap="round" />
              </svg>
            </NavLink>
            <NavLink to="/profile" aria-label="Profile"
              className="h-8 w-8 rounded-full bg-accent-soft text-accent flex items-center justify-center text-sm font-bold">
              {(profile?.full_name ?? "?")[0]}
            </NavLink>
            <Button variant="ghost" onClick={async () => { await signOut(); navigate("/"); }}>Sign out</Button>
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-6">{children}</main>
      <nav aria-label="Main mobile" className="md:hidden fixed bottom-0 inset-x-0 z-40 bg-white border-t border-line grid grid-cols-5">
        {nav.map((n) => (
          <NavLink key={n.to} to={n.to}
            className={({ isActive }) => `py-3 text-center text-[11px] font-semibold ${isActive ? "text-accent" : "text-ink-faint"}`}>
            {n.label.split(" ")[0]}
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
