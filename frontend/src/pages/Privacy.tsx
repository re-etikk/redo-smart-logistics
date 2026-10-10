import { useState } from "react";
import { Link } from "react-router-dom";
import {
  ShieldCheck, Lock, MapPin, FileText, Phone, Mail, ChevronRight,
  ArrowLeft, CheckCircle2, Truck, Smartphone, Server, CreditCard,
  Camera, Mic, Navigation
} from "lucide-react";
import Logo from "../components/Logo";

export default function AdminPrivacyPolicy() {
  const [activeTab, setActiveTab] = useState<"all" | "customer" | "partner">("all");
  const lastUpdated = "October 10, 2026";

  const scrollToSection = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 font-sans selection:bg-amber-400">
      {/* Top Sticky Header */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200/80 shadow-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-8 h-20 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              to="/login"
              className="flex items-center gap-1.5 text-xs font-black text-slate-700 hover:text-slate-950 bg-slate-100 hover:bg-slate-200 px-3 py-2 rounded-xl transition cursor-pointer"
            >
              <ArrowLeft size={15} />
              <span>Back to Login</span>
            </Link>
            <div className="flex items-center gap-2">
              <Link to="/">
                <Logo />
              </Link>
              <span className="text-amber-600 font-black text-xs uppercase tracking-widest bg-amber-50 px-2 py-0.5 rounded-md border border-amber-300">
                ECOSYSTEM PRIVACY
              </span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <a
              href="mailto:ritik45chaurasia@gmail.com?subject=REDO%20Ecosystem%20Privacy"
              className="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-slate-700 hover:text-slate-950 px-3.5 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 transition"
            >
              <Mail size={14} className="text-amber-500" />
              <span>Grievance Desk</span>
            </a>
            <Link
              to="/login"
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-4 py-2 rounded-xl shadow-xs transition"
            >
              Admin Portal
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Banner */}
      <section className="bg-gradient-to-b from-amber-50/80 via-white to-[#FAF9F6] border-b border-slate-200/60 py-12 px-4 sm:px-8">
        <div className="max-w-5xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-100 border border-amber-300 text-amber-900 text-xs font-black shadow-xs">
            <ShieldCheck size={14} className="text-amber-600" />
            <span>DPDP Act 2023 Compliant &bull; Platform Wide Telematics &amp; Data Safeguards</span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-black text-slate-950 tracking-tight">
            REDO Smart Logistics Privacy Policy
          </h1>

          <p className="text-sm sm:text-base text-slate-600 max-w-2xl mx-auto font-medium leading-relaxed">
            Comprehensive Privacy &amp; Data Protection Policy governing the REDO Ecosystem: Customer Shipper Application, Partner Truck Fleet Network, and Operations Center.
          </p>

          <div className="pt-2 flex flex-wrap items-center justify-center gap-4 text-xs font-bold text-slate-500">
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              <FileText size={14} className="text-amber-500" /> Policy Version: 2.4 (Production)
            </span>
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              <Lock size={14} className="text-emerald-500" /> AES-256 &amp; TLS 1.3 Encryption
            </span>
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              Last Updated: {lastUpdated}
            </span>
          </div>

          {/* Quick Filter Tabs */}
          <div className="pt-6 flex justify-center">
            <div className="bg-slate-200/70 p-1 rounded-2xl flex items-center gap-1 text-xs font-black">
              <button
                onClick={() => setActiveTab("all")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "all" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Entire Ecosystem Policy
              </button>
              <button
                onClick={() => setActiveTab("customer")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "customer" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Customer / Shipper
              </button>
              <button
                onClick={() => setActiveTab("partner")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "partner" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Partner / Truck Fleet
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Main Content Layout */}
      <div className="max-w-7xl mx-auto px-4 sm:px-8 py-10 grid lg:grid-cols-[280px_1fr] gap-10">
        
        {/* Left Sticky Table of Contents */}
        <aside className="hidden lg:block">
          <div className="sticky top-28 bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-4">
            <div className="flex items-center gap-2 pb-2 border-b border-slate-100 text-xs font-black text-slate-900 uppercase tracking-wider">
              <FileText size={16} className="text-amber-500" />
              <span>Policy Sections</span>
            </div>

            <nav className="space-y-1 text-xs font-bold text-slate-600">
              {[
                { id: "overview", label: "1. Ecosystem & Legal Scope" },
                { id: "data-collection", label: "2. Information Collected" },
                { id: "background-gps", label: "3. Background GPS Disclosure" },
                { id: "permissions", label: "4. Camera & Device Permissions" },
                { id: "payments", label: "5. Financial Data & Escrow" },
                { id: "processors", label: "6. Sub-processors (Supabase/Razorpay)" },
                { id: "rights", label: "7. User Rights (DPDP Act 2023)" },
                { id: "deletion", label: "8. Data Erasure & Retention" },
                { id: "grievance", label: "9. Grievance Officer Contact" },
              ].map((item) => (
                <button
                  key={item.id}
                  onClick={() => scrollToSection(item.id)}
                  className="w-full text-left py-1.5 px-2 rounded-lg hover:bg-amber-50 hover:text-amber-900 transition flex items-center justify-between group"
                >
                  <span className="truncate">{item.label}</span>
                  <ChevronRight size={12} className="opacity-0 group-hover:opacity-100 text-amber-500 shrink-0" />
                </button>
              ))}
            </nav>

            <div className="pt-3 border-t border-slate-100 text-[11px] text-slate-500 space-y-2">
              <p className="font-bold text-slate-700">Official Privacy Desk</p>
              <p>Email: <a href="mailto:ritik45chaurasia@gmail.com" className="text-amber-600 underline font-mono">ritik45chaurasia@gmail.com</a></p>
              <p>Phone: <a href="tel:+917250171036" className="text-amber-600 underline font-mono">+91 7250171036</a></p>
            </div>
          </div>
        </aside>

        {/* Right Policy Body */}
        <main className="space-y-10 text-slate-700 text-sm leading-relaxed">
          
          {/* Section 1: Overview */}
          <section id="overview" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                1
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Ecosystem &amp; Legal Framework</h2>
                <p className="text-xs text-slate-500 font-medium">REDO Logistics Technology &bull; India Operations</p>
              </div>
            </div>

            <p>
              REDO Smart Logistics operates an intercity freight technology marketplace under the laws of the Republic of India. This Privacy Policy governs all end-user interactions, mobile apps, web applications, and backend API interactions for both Shippers (Customers) and Transporters (Partners/Fleet).
            </p>

            <div className="bg-amber-50/70 border border-amber-200/80 rounded-2xl p-4 text-xs space-y-2 text-slate-800">
              <div className="flex items-center gap-2 font-black text-amber-900">
                <ShieldCheck size={16} className="text-amber-600" />
                <span>Statutory Compliance Notice</span>
              </div>
              <p>
                Governed by the <strong>Information Technology Act, 2000</strong>, the <strong>IT (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011</strong>, and the <strong>Digital Personal Data Protection (DPDP) Act, 2023</strong>.
              </p>
            </div>
          </section>

          {/* Section 2: Data Collection */}
          <section id="data-collection" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                2
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Information Collected Across Roles</h2>
                <p className="text-xs text-slate-500 font-medium">Shipper Commercial Data vs Partner Fleet KYC</p>
              </div>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/60 space-y-2">
                <div className="flex items-center gap-2 text-xs font-black text-slate-900 uppercase">
                  <Smartphone size={16} className="text-amber-500" />
                  <span>Shipper / Customer Data</span>
                </div>
                <p className="text-xs text-slate-600">
                  Full Name, Phone Number, Email, Business Name, GSTIN, Pickup/Delivery Addresses, Commercial Invoices, E-Way Bill numbers.
                </p>
              </div>

              <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/60 space-y-2">
                <div className="flex items-center gap-2 text-xs font-black text-slate-900 uppercase">
                  <Truck size={16} className="text-emerald-500" />
                  <span>Truck Partner &amp; Fleet Data</span>
                </div>
                <p className="text-xs text-slate-600">
                  Driver Name, Mobile Phone, Driving License (DL), Masked Aadhaar/PAN, Vehicle RC, Fitness Certificate, Commercial Permits, Bank Account &amp; IFSC for direct payouts.
                </p>
              </div>
            </div>
          </section>

          {/* Section 3: Background GPS Disclosures */}
          <section id="background-gps" className="bg-white border-2 border-amber-400 rounded-3xl p-6 sm:p-8 shadow-sm space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#FFC800] text-slate-950 flex items-center justify-center font-black">
                <Navigation size={22} />
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Background Location GPS Telematics Disclosure</h2>
                <span className="text-[11px] font-black uppercase text-amber-800 bg-amber-100 px-2 py-0.5 rounded-md">
                  Mandatory Google Play Store &amp; Indus Appstore Policy Disclosure
                </span>
              </div>
            </div>

            <div className="border-2 border-amber-200 bg-amber-50/60 rounded-2xl p-5 space-y-3 text-xs leading-relaxed text-slate-800">
              <p className="font-bold">
                The REDO Partner mobile application collects real-time location data in the background (even when the application is closed or not in active foreground use) strictly while a driver is assigned to an active freight trip.
              </p>
              <ul className="list-disc pl-5 space-y-1 text-slate-700">
                <li>To transmit live consignment GPS tracking to shippers and consignees.</li>
                <li>To calculate dynamic corridor ETAs and traffic delay alerts.</li>
                <li>To calculate and recommend return cargo (backhauls) along the active transit corridor.</li>
                <li>To trigger geofenced arrival notifications at delivery terminals.</li>
              </ul>
              <p className="font-mono text-slate-500 pt-1">
                Background tracking immediately ceases when the trip is marked delivered or when the driver goes offline.
              </p>
            </div>
          </section>

          {/* Section 4: Permissions */}
          <section id="permissions" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                4
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Camera, Storage &amp; Voice Permissions</h2>
                <p className="text-xs text-slate-500 font-medium">Limited strictly to necessary functional requirements</p>
              </div>
            </div>

            <div className="grid sm:grid-cols-3 gap-4 text-xs">
              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-1">
                <h4 className="font-black text-slate-900 flex items-center gap-1.5"><Camera size={14} /> Camera</h4>
                <p className="text-slate-600">Uploading vehicle RC, DL, physical Proof of Delivery (e-POD), and consignment loading photos.</p>
              </div>
              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-1">
                <h4 className="font-black text-slate-900 flex items-center gap-1.5"><FileText size={14} /> Storage / Files</h4>
                <p className="text-slate-600">Uploading GST invoices, E-way bill PDFs, and saving settlement receipts.</p>
              </div>
              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-1">
                <h4 className="font-black text-slate-900 flex items-center gap-1.5"><Mic size={14} /> Microphone</h4>
                <p className="text-slate-600">Optional AI Voice Assistant route search and in-app driver-shipper transit calls.</p>
              </div>
            </div>
          </section>

          {/* Section 5: Financial Data */}
          <section id="payments" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                5
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Financial Data, Escrow &amp; Bank Protection</h2>
                <p className="text-xs text-slate-500 font-medium">PCI-DSS Level 1 &amp; RBI compliance</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm">
              All payment transactions are conducted through <strong>Razorpay</strong>. REDO does not store debit/credit card numbers or banking passwords. Partner bank accounts provided for settlements are encrypted with AES-256.
            </p>
          </section>

          {/* Section 6: Sub-processors */}
          <section id="processors" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                6
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Third-Party Service Providers</h2>
                <p className="text-xs text-slate-500 font-medium">Sub-processors strictly bound by data privacy agreements</p>
              </div>
            </div>

            <ul className="list-disc pl-5 text-xs text-slate-600 space-y-1.5">
              <li><strong>Supabase Inc:</strong> Managed PostgreSQL database with Row Level Security (RLS).</li>
              <li><strong>Razorpay Software Ltd:</strong> RBI-authorized payment gateway and IMPS/NEFT payout engine.</li>
              <li><strong>Google Maps Platform:</strong> Route navigation, geocoding, and corridor telemetry.</li>
              <li><strong>Firebase (Google LLC):</strong> Real-time push notifications for dispatch alerts.</li>
            </ul>
          </section>

          {/* Section 7: User Rights */}
          <section id="rights" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                7
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">User Rights Under DPDP Act 2023</h2>
                <p className="text-xs text-slate-500 font-medium">Rights of data principals under Indian statute</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm">
              Every registered user possesses the right to access a summary of their personal data, correct inaccurate records, withdraw consent for optional processing, and request account erasure.
            </p>
          </section>

          {/* Section 8: Deletion */}
          <section id="deletion" className="bg-white border-2 border-rose-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-rose-100 text-rose-700 flex items-center justify-center font-black">
                8
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Account &amp; Data Erasure</h2>
                <p className="text-xs text-slate-500 font-medium">Simple self-service or email-based deletion</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm">
              You can request permanent account deletion via in-app settings or by sending an email to <a href="mailto:ritik45chaurasia@gmail.com" className="text-amber-600 underline font-mono">ritik45chaurasia@gmail.com</a>. Personal identifiers will be erased within 7 business days, while statutory tax and transport consignment notes will be archived according to CGST Act mandates.
            </p>
          </section>

          {/* Section 9: Grievance Officer */}
          <section id="grievance" className="bg-gradient-to-br from-slate-900 via-slate-900 to-slate-950 text-white rounded-3xl p-6 sm:p-8 shadow-lg space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#FFC800] text-slate-950 flex items-center justify-center font-black">
                9
              </div>
              <div>
                <h2 className="text-xl font-black">Statutory Grievance Redressal Officer</h2>
                <p className="text-xs text-slate-400 font-medium">Designated under IT Act 2000 &amp; DPDP Act 2023</p>
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-4">
              <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 space-y-2 text-xs">
                <span className="text-[10px] font-mono uppercase text-amber-400 font-bold block">Officer Name</span>
                <p className="text-base font-black text-white">Ritik Chaurasia</p>
                <p className="text-slate-400">Chief Logistics Technology &amp; Privacy Officer</p>
                <p className="pt-2 text-slate-300">REDO Smart Logistics Platform &bull; Patna, Bihar, India</p>
              </div>

              <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 space-y-2 text-xs">
                <span className="text-[10px] font-mono uppercase text-amber-400 font-bold block">Direct Channels</span>
                <p className="text-slate-200">
                  Email: <a href="mailto:ritik45chaurasia@gmail.com" className="text-amber-300 underline font-mono">ritik45chaurasia@gmail.com</a>
                </p>
                <p className="text-slate-200">
                  Helpline: <a href="tel:+917250171036" className="text-amber-300 underline font-mono">+91 7250171036</a>
                </p>
                <p className="text-[11px] text-slate-400 pt-1">
                  SLA: Acknowledged within 24 hours &bull; Resolution within 15 working days
                </p>
              </div>
            </div>
          </section>

        </main>
      </div>

      {/* Footer */}
      <footer className="border-t border-slate-200/80 bg-white py-8 px-4 sm:px-8 mt-12">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs font-bold text-slate-500">
          <div className="flex items-center gap-3">
            <Logo compact />
            <span>&copy; {new Date().getFullYear()} REDO Smart Logistics. Control Center &amp; Operations.</span>
          </div>

          <div className="flex items-center gap-6">
            <Link to="/privacy" className="text-amber-600 hover:underline">Privacy Policy</Link>
            <Link to="/login" className="hover:text-slate-900 transition">Admin Portal</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
