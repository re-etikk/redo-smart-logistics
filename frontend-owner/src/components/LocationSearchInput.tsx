import { useState, useEffect, useRef } from "react";
import { MapPin, Building2, Search, X, Loader2, Navigation } from "lucide-react";
import { searchLocationsLive, type LocationHub } from "../lib/locationService";

interface Props {
  value: string;
  onChange: (value: string, hub?: LocationHub) => void;
  placeholder?: string;
  label?: string;
  iconType?: "pickup" | "drop" | "search";
  required?: boolean;
  className?: string;
}

export default function LocationSearchInput({
  value,
  onChange,
  placeholder = "Search city, warehouse area, locality or pincode...",
  label,
  iconType = "pickup",
  required = false,
  className = "",
}: Props) {
  const [query, setQuery] = useState(value || "");
  const [suggestions, setSuggestions] = useState<LocationHub[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setQuery(value || "");
  }, [value]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    if (!isOpen) return;

    const timer = setTimeout(async () => {
      setLoading(true);
      try {
        const results = await searchLocationsLive(query);
        setSuggestions(results);
      } catch {
        setSuggestions([]);
      } finally {
        setLoading(false);
      }
    }, 200);

    return () => clearTimeout(timer);
  }, [query, isOpen]);

  const handleSelect = (hub: LocationHub) => {
    setQuery(hub.name);
    onChange(hub.name, hub);
    setIsOpen(false);
  };

  const handleClear = () => {
    setQuery("");
    onChange("");
    setSuggestions([]);
  };

  const getIcon = () => {
    if (iconType === "pickup") return <MapPin size={15} className="text-emerald-500" />;
    if (iconType === "drop") return <Building2 size={15} className="text-rose-500" />;
    return <Search size={15} className="text-amber-500" />;
  };

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      {label && (
        <label className="text-[10px] uppercase font-black tracking-wider text-slate-500 dark:text-slate-400 block mb-1.5 flex items-center gap-1">
          {getIcon()}
          <span>{label}</span>
        </label>
      )}

      <div className="relative">
        <div className="absolute left-3.5 top-1/2 -translate-y-1/2 flex items-center pointer-events-none">
          {loading ? <Loader2 size={15} className="text-amber-500 animate-spin" /> : getIcon()}
        </div>

        <input
          type="text"
          required={required}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            onChange(e.target.value);
            setIsOpen(true);
          }}
          onFocus={() => setIsOpen(true)}
          placeholder={placeholder}
          className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl pl-10 pr-8 py-3 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-amber-400 shadow-sm"
        />

        {query && (
          <button
            type="button"
            onClick={handleClear}
            className="absolute right-2.5 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-slate-600 dark:hover:text-white rounded-full cursor-pointer"
          >
            <X size={14} />
          </button>
        )}
      </div>

      {/* Autocomplete Dropdown List */}
      {isOpen && (
        <div className="absolute left-0 right-0 top-full mt-2 z-50 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-2xl overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 animate-in fade-in zoom-in-95 duration-150">
          <div className="px-3.5 py-1.5 bg-slate-50 dark:bg-slate-800/80 flex items-center justify-between text-[10px] font-black uppercase tracking-wider text-slate-400">
            <span className="flex items-center gap-1">
              <Navigation size={11} className="text-amber-500" />
              <span>Live Location Suggestions</span>
            </span>
            <span>Google Maps / GPS Enabled</span>
          </div>

          <div className="max-h-60 overflow-y-auto">
            {suggestions.length === 0 ? (
              <div className="p-4 text-center text-xs text-slate-400 font-medium">
                {loading ? "Searching Google Maps & Indian logistics hubs..." : "Type city, area, pincode or landmark name"}
              </div>
            ) : (
              suggestions.map((s, idx) => (
                <div
                  key={`${s.name}-${idx}`}
                  onClick={() => handleSelect(s)}
                  className="px-4 py-3 hover:bg-amber-50 dark:hover:bg-slate-800/80 transition cursor-pointer flex items-center justify-between gap-3 text-xs"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-8 h-8 rounded-xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 flex items-center justify-center shrink-0 font-bold">
                      <MapPin size={15} />
                    </div>
                    <div className="min-w-0">
                      <p className="font-black text-slate-900 dark:text-white truncate">
                        {s.name}
                      </p>
                      <p className="text-[11px] text-slate-500 dark:text-slate-400 truncate font-medium">
                        {s.state} {s.fullAddress && s.fullAddress !== s.name ? `• ${s.fullAddress}` : ""}
                      </p>
                    </div>
                  </div>

                  <span className="text-[9px] font-black uppercase px-2 py-0.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 shrink-0">
                    {s.hub || "Verified Hub"}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
