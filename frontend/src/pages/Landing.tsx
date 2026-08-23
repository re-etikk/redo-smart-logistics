import { useNavigate, Link } from "react-router-dom";
import { BadgeCheck, CalendarCheck, Clock, MapPin, ShieldCheck, Tag, Truck, Users } from "lucide-react";
import Logo from "../components/Logo";
import { Card } from "../components/ui";

export default function Landing() {
  const navigate = useNavigate();
  return (
    <div className="theme-owner min-h-screen bg-white">
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-16 flex items-center justify-between">
          <Logo />
          <nav className="hidden md:flex items-center gap-6 text-sm font-semibold text-ink-soft" aria-label="Landing">
            <a href="#book" className="hover:text-ink">Book a Truck</a>
            <a href="#how" className="hover:text-ink">How it Works</a>
            <a href="#owners" className="hover:text-ink">For Truck Owners</a>
            <Link to="/login" className="hover:text-ink">Sign in</Link>
          </nav>
          <button onClick={() => navigate("/signup")}
            className="rounded-xl bg-brand text-brand-ink px-4 py-2.5 text-sm font-bold hover:brightness-95">
            Login / Sign Up
          </button>
        </div>
      </header>

      <section className="mx-auto max-w-6xl px-4 pt-12 pb-16 grid gap-10 lg:grid-cols-[380px_1fr] items-start">
        {/* Search-style card */}
        <Card id="book" className="p-5 shadow-lift">
          <h2 className="font-extrabold text-ink text-lg">Book an Empty Truck</h2>
          <p className="text-xs text-ink-faint mt-0.5">Find and book the best backhaul truck for your cargo</p>
          <div className="mt-4 space-y-3">
            {[
              { icon: MapPin, label: "From", ph: "Enter pickup location" },
              { icon: MapPin, label: "To", ph: "Enter delivery location" },
              { icon: Truck, label: "Truck Type", ph: "Select truck type" },
              { icon: CalendarCheck, label: "When", ph: "Select date" },
            ].map(({ icon: Icon, label, ph }) => (
              <div key={label} className="flex items-center gap-3 rounded-xl border border-line px-3 py-2.5">
                <Icon size={16} className="text-brand-dark" />
                <span className="text-xs"><span className="block font-bold text-ink">{label}</span>
                  <span className="text-ink-faint">{ph}</span></span>
              </div>
            ))}
          </div>
          <button onClick={() => navigate("/signup?role=sme")}
            className="mt-4 w-full rounded-xl bg-brand text-brand-ink py-3 font-bold text-sm hover:brightness-95">
            Search Trucks
          </button>
        </Card>

        <div className="pt-4">
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-ink leading-tight">
            Bharosa Wahi,<br /><span className="text-brand-dark">Deal Sahi.</span>
          </h1>
          <p className="mt-4 text-lg text-ink-soft max-w-md">Book empty trucks easily for your cargo across India.</p>
          <div className="mt-6 grid grid-cols-3 gap-4 max-w-lg">
            {[
              { icon: ShieldCheck, t: "Verified & Trusted", d: "Document-checked truck owners" },
              { icon: Tag, t: "Best Prices", d: "Backhaul rates, compare and book" },
              { icon: Clock, t: "Quick & Easy", d: "Book in just a few clicks" },
            ].map(({ icon: Icon, t, d }) => (
              <div key={t}>
                <span className="h-10 w-10 rounded-full bg-brand-soft text-brand-dark grid place-items-center"><Icon size={18} /></span>
                <p className="mt-2 font-bold text-ink text-sm">{t}</p>
                <p className="text-xs text-ink-faint">{d}</p>
              </div>
            ))}
          </div>
          <p className="mt-6 text-xs text-ink-faint max-w-md">
            Studies attributed to NITI Aayog estimate a large share of truck kilometres in India run empty or underutilized
            (commonly cited at 28–43%). Redo matches SME cargo onto exactly those return legs.
          </p>
        </div>
      </section>

      {/* Stats strip — demo-network figures, labeled */}
      <section className="mx-auto max-w-5xl px-4">
        <Card className="p-5 grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { icon: Users, v: "Growing", l: "Shipper network" },
            { icon: Truck, v: "Verified", l: "Truck owners" },
            { icon: BadgeCheck, v: "ML-ranked", l: "Match scores" },
            { icon: MapPin, v: "Multi-city", l: "Corridors covered" },
          ].map(({ icon: Icon, v, l }) => (
            <div key={l} className="flex items-center gap-3">
              <span className="h-10 w-10 rounded-full bg-brand-soft text-brand-dark grid place-items-center"><Icon size={18} /></span>
              <span><span className="block font-extrabold text-ink">{v}</span>
                <span className="text-xs text-ink-faint">{l}</span></span>
            </div>
          ))}
        </Card>
      </section>

      <section id="how" className="mx-auto max-w-6xl px-4 py-16 text-center">
        <h2 className="text-2xl font-extrabold text-ink">How Redo Works?</h2>
        <div className="mt-8 grid gap-6 md:grid-cols-4">
          {[
            ["Enter Locations", "Add your pickup and delivery locations"],
            ["Choose Truck", "Pick from ML-ranked backhaul matches"],
            ["Confirm Booking", "Review details and confirm your booking"],
            ["Truck on the Way", "Track your shipment and get digital proof"],
          ].map(([t, d], i) => (
            <div key={t}>
              <span className="mx-auto h-14 w-14 rounded-full bg-brand-soft text-brand-dark grid place-items-center font-extrabold">{i + 1}</span>
              <p className="mt-3 font-bold text-ink">{t}</p>
              <p className="mt-1 text-sm text-ink-faint">{d}</p>
            </div>
          ))}
        </div>
      </section>

      <section id="owners" className="bg-canvas border-t border-line">
        <div className="mx-auto max-w-6xl px-4 py-14 grid gap-6 md:grid-cols-2">
          <Card className="p-6">
            <h3 className="text-lg font-extrabold text-ink">More Loads. <span className="text-brand-dark">More Earnings.</span></h3>
            <p className="mt-1 text-sm text-ink-soft">List your truck, fill your empty return trips and grow your business with Redo.</p>
            <button onClick={() => navigate("/signup?role=truck_owner")}
              className="mt-4 rounded-xl bg-brand text-brand-ink px-4 py-2.5 text-sm font-bold">Use my truck</button>
          </Card>
          <Card className="p-6">
            <h3 className="text-lg font-extrabold text-ink">Ship partial loads affordably.</h3>
            <p className="mt-1 text-sm text-ink-soft">1–3 T cargo? Pay only for the capacity you use on verified return trips.</p>
            <button onClick={() => navigate("/signup?role=sme")}
              className="mt-4 rounded-xl border-2 border-ink text-ink px-4 py-2.5 text-sm font-bold hover:bg-ink hover:text-white transition">Find transport</button>
          </Card>
        </div>
      </section>

      <footer className="border-t border-line">
        <div className="mx-auto max-w-6xl px-4 py-8 flex flex-wrap items-center justify-between gap-3 text-xs text-ink-faint">
          <span>© 2026 Redo Transport &amp; Logistics · Match. Consolidate. Trust. Track. Optimize.</span>
          <span>Built for Smart India Hackathon</span>
        </div>
      </footer>
    </div>
  );
}
