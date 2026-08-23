export type ThemeMode = "light" | "dark";

export type LanguageCode = "en" | "hi" | "mr" | "pa" | "gu" | "ta" | "bn";

export interface LanguageOption {
  code: LanguageCode;
  name: string;
  nativeName: string;
}

export const SUPPORTED_LANGUAGES: LanguageOption[] = [
  { code: "en", name: "English", nativeName: "English" },
  { code: "hi", name: "Hindi", nativeName: "हिन्दी" },
  { code: "mr", name: "Marathi", nativeName: "मराठी" },
  { code: "pa", name: "Punjabi", nativeName: "ਪੰਜਾਬੀ" },
  { code: "gu", name: "Gujarati", nativeName: "ગુજરાતી" },
  { code: "ta", name: "Tamil", nativeName: "தமிழ்" },
  { code: "bn", name: "Bengali", nativeName: "বাংলা" },
];

export function getInitialTheme(): ThemeMode {
  if (typeof window === "undefined") return "light";
  const saved = localStorage.getItem("redo_theme") as ThemeMode;
  if (saved === "dark" || saved === "light") return saved;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

export function applyTheme(mode: ThemeMode): void {
  if (typeof window === "undefined") return;
  const root = document.documentElement;
  if (mode === "dark") {
    root.classList.add("dark");
  } else {
    root.classList.remove("dark");
  }
  localStorage.setItem("redo_theme", mode);
  window.dispatchEvent(new CustomEvent("redo_theme_changed", { detail: mode }));
}

export function getInitialLanguage(): LanguageCode {
  if (typeof window === "undefined") return "en";
  return (localStorage.getItem("redo_lang") as LanguageCode) || "en";
}

export function setLanguage(code: LanguageCode): void {
  if (typeof window === "undefined") return;
  localStorage.setItem("redo_lang", code);
  window.dispatchEvent(new CustomEvent("redo_lang_changed", { detail: code }));
}
