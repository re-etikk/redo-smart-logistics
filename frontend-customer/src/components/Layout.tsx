import { useEffect, useState, type ReactNode } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  Bell, BookOpen, Box, FileText, HelpCircle,
  LayoutDashboard, LogOut, MapPin, Menu, Package, PlusCircle, Settings, X,
  Moon, Sun, Globe, Check, Phone
} from "lucide-react";
import { useAuth } from "../hooks/useAuth";
import { api } from "../lib/api";
import Logo from "../components/Logo";
export { default as Logo } from "../components/Logo";
import { Badge } from "../components/ui";
import {
  getInitialTheme, applyTheme, getInitialLanguage, setLanguage,
  SUPPORTED_LANGUAGES, type ThemeMode, type LanguageCode
} from "../lib/themeStore";

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
  const { session, profile, signOut } = useAuth();
  const navigate = useNavigate();
  const [drawer, setDrawer] = useState(false);
  const [unread, setUnread] = useState(0);

  const [theme, setTheme] = useState<ThemeMode>(() => getInitialTheme());
  const [currentLang, setCurrentLang] = useState<LanguageCode>(() => getInitialLanguage());
  const [langMenuOpen, setLangMenuOpen] = useState(false);

  useEffect(() => {
    applyTheme(theme);
  }, [theme]);

  useEffect(() => {
    api.get<any[]>("/notifications").then((n) => setUnread(n.filter((x) => !x.read).length)).catch(() => {});
  }, []);

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

  const googleName = session?.user?.user_metadata?.full_name || session?.user?.user_metadata?.name || (session?.user?.email ? session.user.email.split('@')[0] : "");
  const displayName = session?.user ? (googleName || profile?.full_name) : (profile?.full_name || "Customer");
  const displayEmail = session?.user?.email || profile?.email || "customer@redo.app";

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
              isActive
                ? "bg-amber-100/80 dark:bg-amber-950/60 text-slate-950 dark:text-amber-300 border-l-4 border-amber-500 font-bold shadow-sm"
                : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
            }`
          }
        >
          {({ isActive }) => (
            <>
              <Icon size={18} className={isActive ? "text-amber-600 dark:text-amber-400" : "text-slate-400"} strokeWidth={2.2} />
              <span>{label}</span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  );

  return (
    <div className={`min-h-screen font-sans transition-colors duration-200 ${
      theme === "dark" ? "bg-slate-950 text-slate-100 dark" : "bg-[#FAF9F6] text-slate-900"
    }`}>
      {/* Header */}
      <header className={`sticky top-0 z-40 border-b transition-colors ${
        theme === "dark" ? "bg-slate-900 border-slate-800 text-white" : "bg-white border-slate-200 text-slate-900"
      }`}>
        <div className="h-16 px-4 flex items-center justify-between max-w-[1400px] mx-auto w-full">
          <div className="flex items-center gap-3">
            <button
              className="p-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-800 dark:text-white transition cursor-pointer"
              aria-label="Menu"
              onClick={() => setDrawer(true)}
              title="Open Navigation Drawer"
            >
              <Menu size={20} />
            </button>
            <button onClick={() => navigate("/dashboard")} className="shrink-0">
              <Logo />
            </button>
          </div>

          <div className="flex items-center gap-2.5 sm:gap-3">
            {/* Language Selector Dropdown */}
            <div className="relative">
              <button
                onClick={() => setLangMenuOpen(!langMenuOpen)}
                className={`p-2 rounded-xl border flex items-center gap-1 text-xs font-bold transition ${
                  theme === "dark" ? "bg-slate-800 border-slate-700 hover:bg-slate-700" : "bg-slate-50 border-slate-200 hover:bg-slate-100"
                }`}
                title="Select Language"
              >
                <Globe size={15} className="text-amber-500" />
                <span className="uppercase text-[10px] font-mono">{currentLang}</span>
              </button>

              {langMenuOpen && (
                <div className={`absolute right-0 mt-2 w-44 rounded-2xl shadow-xl z-50 py-1 font-bold text-xs border ${
                  theme === "dark" ? "bg-slate-900 border-slate-800 text-slate-200" : "bg-white border-slate-200 text-slate-800"
                }`}>
                  <div className="px-3 py-1.5 text-[10px] uppercase font-mono text-slate-400 border-b border-slate-200/40">
                    Select Language
                  </div>
                  {SUPPORTED_LANGUAGES.map((l) => (
                    <button
                      key={l.code}
                      onClick={() => handleSelectLanguage(l.code)}
                      className={`w-full text-left px-3.5 py-2 flex items-center justify-between hover:bg-amber-400/20 transition ${
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
              className={`p-2 rounded-xl border transition ${
                theme === "dark" ? "bg-slate-800 border-slate-700 text-amber-400 hover:bg-slate-700" : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100"
              }`}
              title={theme === "dark" ? "Switch to Day Mode" : "Switch to Dark Mode"}
            >
              {theme === "dark" ? <Sun size={17} /> : <Moon size={17} />}
            </button>

            <button
              onClick={() => navigate("/book")}
              className="hidden sm:inline-flex items-center gap-1.5 bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-4 py-2 rounded-xl text-xs shadow-sm transition"
            >
              <Box size={16} />
              <span>Book a Truck</span>
            </button>

            <NavLink to="/notifications" aria-label="Notifications" className="relative p-2 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800">
              <Bell size={18} className="text-slate-600 dark:text-slate-300" />
              {unread > 0 && (
                <span className="absolute top-1 right-1 h-3.5 min-w-3.5 px-1 rounded-full bg-amber-500 text-slate-950 text-[9px] font-black grid place-items-center">
                  {unread}
                </span>
              )}
            </NavLink>

            <div className="flex items-center gap-2 border-l border-slate-200 dark:border-slate-800 pl-3">
              <span className="h-8 w-8 rounded-full bg-amber-400 text-slate-950 font-black text-xs flex items-center justify-center shadow-sm">
                {displayName.charAt(0)}
              </span>
              <div className="hidden md:block text-left leading-tight">
                <span className={`block text-xs font-black truncate max-w-[120px] ${theme === "dark" ? "text-white" : "text-slate-900"}`}>{displayName}</span>
                <span className="block text-[10px] font-semibold text-slate-400 truncate max-w-[120px]">{displayEmail}</span>
              </div>
              <button
                onClick={async () => { await signOut(); navigate("/login"); }}
                className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition"
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
        <aside className={`hidden lg:flex w-64 shrink-0 flex-col border-r min-h-[calc(100vh-4rem)] sticky top-16 self-start ${
          theme === "dark" ? "bg-slate-900 border-slate-800" : "bg-white border-slate-200"
        }`}>
          <div className="p-4 flex items-center gap-3 border-b border-slate-100 dark:border-slate-800">
            <span className="h-10 w-10 rounded-2xl bg-amber-100 text-amber-900 border border-amber-300 grid place-items-center font-bold text-sm">
              {displayName.charAt(0)}
            </span>
            <div className="min-w-0">
              <p className="text-xs font-black truncate">{displayName}</p>
              <p className="text-[10px] font-medium text-slate-400">Shipper / Customer</p>
              <span className="mt-0.5 inline-flex"><Badge tone="ok">Verified Account</Badge></span>
            </div>
          </div>

          {SideNav}

          <div className={`m-3 rounded-2xl p-4 border ${
            theme === "dark" ? "bg-slate-800/60 border-amber-500/30" : "bg-amber-50 border-amber-200"
          }`}>
            <p className="text-xs font-black">Need Immediate Dispatch?</p>
            <p className="mt-1 text-[11px] text-slate-500 dark:text-slate-400">
              Post an urgent load and get matched with empty return trucks.
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
            <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" onClick={() => setDrawer(false)} />
            <div className={`absolute inset-y-0 left-0 w-72 flex flex-col shadow-2xl ${
              theme === "dark" ? "bg-slate-900 text-white" : "bg-white text-slate-900"
            }`}>
              <div className="h-16 px-4 flex items-center justify-between border-b border-slate-200 dark:border-slate-800">
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
