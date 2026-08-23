/** REDO Transport & Logistics — design tokens.
 *  Brand: yellow/black. Role accents via CSS vars: shipper=blue, owner=yellow, admin=slate. */
export default {
  darkMode: "class",
  content: ["./index.html", "./src/**/*.{ts,tsx}", "../shared/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: { DEFAULT: "#111417", soft: "#3D444D", faint: "#6B7280" },
        canvas: "#F7F8FA",
        line: "#E7E9EE",
        brand: { DEFAULT: "#F7B500", dark: "#E0A400", soft: "#FFF6DE", ink: "#111417" },
        blue: { DEFAULT: "#146BFF", soft: "#EAF1FF" },
        accent: "rgb(var(--accent) / <alpha-value>)",
        "accent-soft": "rgb(var(--accent-soft) / <alpha-value>)",
        "accent-fg": "rgb(var(--accent-fg) / <alpha-value>)",
        ok: { DEFAULT: "#15803D", soft: "#E9F7EF" },
        info: { DEFAULT: "#146BFF", soft: "#EAF1FF" },
        warn: { DEFAULT: "#C2620A", soft: "#FDF2E3" },
        danger: { DEFAULT: "#DC2626", soft: "#FDECEC" },
        purple: { DEFAULT: "#7C3AED", soft: "#F3EDFD" },
      },
      fontFamily: { sans: ["Inter", "system-ui", "sans-serif"] },
      boxShadow: {
        card: "0 1px 2px rgba(17,20,23,.05), 0 4px 14px rgba(17,20,23,.05)",
        lift: "0 2px 4px rgba(17,20,23,.07), 0 12px 28px rgba(17,20,23,.10)",
      },
      borderRadius: { xl: "14px" },
    },
  },
  plugins: [],
};
