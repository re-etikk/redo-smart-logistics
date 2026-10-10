import { useState } from "react";
import { Link } from "react-router-dom";
import {
  ShieldCheck, Lock, MapPin, Eye, FileText, Phone, Mail, ChevronRight,
  ArrowLeft, CheckCircle2, AlertTriangle, Smartphone, Server, CreditCard,
  Camera, Mic, HelpCircle, Download, ExternalLink
} from "lucide-react";
import Logo from "../components/Logo";

export default function PrivacyPolicy() {
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
              to="/"
              className="flex items-center gap-1.5 text-xs font-black text-slate-700 hover:text-slate-950 bg-slate-100 hover:bg-slate-200 px-3 py-2 rounded-xl transition cursor-pointer"
            >
              <ArrowLeft size={15} />
              <span>Back to Home</span>
            </Link>
            <Link to="/">
              <Logo />
            </Link>
          </div>

          <div className="flex items-center gap-3">
            <a
              href="mailto:ritik45chaurasia@gmail.com?subject=REDO%20Privacy%20Inquiry"
              className="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-slate-700 hover:text-slate-950 px-3.5 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 transition"
            >
              <Mail size={14} className="text-amber-500" />
              <span>Contact Privacy Team</span>
            </a>
            <Link
              to="/login"
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-4 py-2 rounded-xl shadow-xs transition"
            >
              Sign In
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Banner */}
      <section className="bg-gradient-to-b from-amber-50/80 via-white to-[#FAF9F6] border-b border-slate-200/60 py-12 px-4 sm:px-8">
        <div className="max-w-5xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-100 border border-amber-300 text-amber-900 text-xs font-black shadow-xs">
            <ShieldCheck size={14} className="text-amber-600" />
            <span>Digital Personal Data Protection (DPDP) Act 2023 Compliant</span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-black text-slate-950 tracking-tight">
            Privacy Policy &amp; Data Safeguards
          </h1>

          <p className="text-sm sm:text-base text-slate-600 max-w-2xl mx-auto font-medium leading-relaxed">
            REDO Smart Logistics (&ldquo;REDO&rdquo;, &ldquo;we&rdquo;, &ldquo;our&rdquo;, or &ldquo;platform&rdquo;) is committed to protecting the privacy, confidentiality, and security of our shippers, freight partners, vehicle owners, and platform users.
          </p>

          <div className="pt-2 flex flex-wrap items-center justify-center gap-4 text-xs font-bold text-slate-500">
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              <FileText size={14} className="text-amber-500" /> Version: 2.4 (Production)
            </span>
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              <Lock size={14} className="text-emerald-500" /> End-to-End Encryption
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
                Comprehensive Policy
              </button>
              <button
                onClick={() => setActiveTab("customer")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "customer" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                For Customers / Shippers
              </button>
              <button
                onClick={() => setActiveTab("partner")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "partner" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                For Truck Partners &amp; Drivers
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
              <span>Table of Contents</span>
            </div>

            <nav className="space-y-1 text-xs font-bold text-slate-600">
              {[
                { id: "overview", label: "1. Overview & Platform Scope" },
                { id: "data-collection", label: "2. Information We Collect" },
                { id: "location-data", label: "3. Location Data & Background GPS" },
                { id: "camera-audio", label: "4. Camera, Storage & Audio" },
                { id: "data-usage", label: "5. How We Use Your Information" },
                { id: "payments", label: "6. Payments & Financial Data" },
                { id: "data-sharing", label: "7. Third-Party Sharing & Processors" },
                { id: "security-retention", label: "8. Data Security & Retention" },
                { id: "user-rights", label: "9. Your Rights (DPDP Act 2023)" },
                { id: "account-deletion", label: "10. Account & Data Deletion" },
                { id: "grievance", label: "11. Grievance Officer & Contact" },
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
              <p className="font-bold text-slate-700">Need immediate help?</p>
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
                <h2 className="text-xl font-black text-slate-950">Overview &amp; Platform Scope</h2>
                <p className="text-xs text-slate-500 font-medium">Identity of platform, entities covered, and governing framework</p>
              </div>
            </div>

            <p>
              This Privacy Policy applies to the services offered through <strong>REDO Smart Logistics</strong>, including:
            </p>
            <ul className="list-disc pl-5 space-y-1.5 text-xs sm:text-sm font-medium">
              <li><strong>REDO Customer Mobile Application &amp; Web Portal:</strong> For SME shippers, factories, e-commerce vendors, and cargo consignors.</li>
              <li><strong>REDO Partner Mobile Application &amp; Web Portal:</strong> For commercial truck drivers, fleet operators, and transport contractors.</li>
              <li><strong>REDO Operations &amp; Admin Panel:</strong> For KYC compliance, route overseer, and dispute arbitration.</li>
            </ul>

            <div className="bg-amber-50/70 border border-amber-200/80 rounded-2xl p-4 text-xs space-y-2 text-slate-800">
              <div className="flex items-center gap-2 font-black text-amber-900">
                <ShieldCheck size={16} className="text-amber-600" />
                <span>Statutory Compliance Notice</span>
              </div>
              <p>
                REDO complies with the Indian <strong>Information Technology Act, 2000</strong>, the <strong>Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011</strong>, and the <strong>Digital Personal Data Protection Act (DPDP Act), 2023</strong>.
              </p>
            </div>
          </section>

          {/* Section 2: Information We Collect */}
          <section id="data-collection" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                2
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Information We Collect</h2>
                <p className="text-xs text-slate-500 font-medium">Categorized by Shipper vs Partner roles</p>
              </div>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              {/* Customer Box */}
              {(activeTab === "all" || activeTab === "customer") && (
                <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/50 space-y-3">
                  <div className="flex items-center gap-2 text-xs font-black text-slate-900 uppercase">
                    <Smartphone size={16} className="text-amber-500" />
                    <span>Customer &amp; Shipper Data</span>
                  </div>
                  <ul className="text-xs space-y-2 text-slate-600">
                    <li><strong>Account Credentials:</strong> Full Name, Email, Mobile Phone Number, Profile Photo.</li>
                    <li><strong>Business Information:</strong> Enterprise/Company Name, Registered GSTIN, Corporate Address, State &amp; Pincode.</li>
                    <li><strong>Shipment Details:</strong> Pickup and delivery addresses, cargo category, weight, dimensions, declared cargo value.</li>
                    <li><strong>Commercial Documents:</strong> Invoice copies, Delivery Challans, E-Way Bill numbers (for interstate freight &gt; ₹50,000).</li>
                  </ul>
                </div>
              )}

              {/* Partner Box */}
              {(activeTab === "all" || activeTab === "partner") && (
                <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/50 space-y-3">
                  <div className="flex items-center gap-2 text-xs font-black text-slate-900 uppercase">
                    <CheckCircle2 size={16} className="text-emerald-500" />
                    <span>Truck Partner &amp; Driver Data</span>
                  </div>
                  <ul className="text-xs space-y-2 text-slate-600">
                    <li><strong>Driver Identity &amp; KYC:</strong> Full Name, Mobile Phone, Driving License (DL) number, Aadhaar / Voter ID (masked), Permanent Account Number (PAN).</li>
                    <li><strong>Vehicle Verification:</strong> Registration Certificate (RC), Commercial Vehicle Permit, Fitness Certificate, PUC, Commercial Insurance policy copy.</li>
                    <li><strong>Fleet Telematics:</strong> Vehicle registration number, truck capacity (tons), body type, fuel type, FASTag ID.</li>
                    <li><strong>Payout Information:</strong> Bank Account Number, Account Holder Name, and Bank IFSC Code for direct trip earnings settlement.</li>
                  </ul>
                </div>
              )}
            </div>
          </section>

          {/* Section 3: Location Data & Background GPS Disclosure */}
          <section id="location-data" className="bg-white border-2 border-amber-400/80 rounded-3xl p-6 sm:p-8 shadow-sm space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#FFC800] text-slate-950 flex items-center justify-center font-black">
                <MapPin size={22} />
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Location Data &amp; Background GPS Disclosure</h2>
                <span className="text-[11px] font-black uppercase text-amber-700 bg-amber-100 px-2 py-0.5 rounded-md">
                  Mandatory Google Play &amp; Indus Appstore Policy Disclosure
                </span>
              </div>
            </div>

            <div className="space-y-3 text-sm">
              <p className="font-semibold text-slate-900">
                REDO collects and processes precise and approximate location information under the following strict conditions:
              </p>

              <div className="space-y-3">
                <div className="border border-slate-200 rounded-2xl p-4 bg-amber-50/40">
                  <h4 className="font-black text-xs text-slate-950 uppercase tracking-wide flex items-center gap-1.5 mb-1">
                    <MapPin size={14} className="text-amber-600" />
                    A. Foreground Location Access (Customer &amp; Partner Apps)
                  </h4>
                  <p className="text-xs text-slate-600 leading-relaxed">
                    When actively using the app, your location is used to pinpoint your pickup address, suggest nearby logistics hubs and industrial corridors, and verify proximity to freight warehouses.
                  </p>
                </div>

                <div className="border-2 border-amber-300 rounded-2xl p-4 bg-amber-100/50">
                  <h4 className="font-black text-xs text-amber-950 uppercase tracking-wide flex items-center gap-1.5 mb-1">
                    <ShieldCheck size={16} className="text-amber-700" />
                    B. Background Location Access (REDO Partner App Only)
                  </h4>
                  <p className="text-xs text-slate-800 font-medium leading-relaxed">
                    <strong>The REDO Partner application collects real-time location data in the background even when the application is closed or not in active foreground use.</strong> This background location tracking begins ONLY when a driver accepts a freight trip and continues until the shipment has been delivered and the electronic Proof of Delivery (e-POD) is submitted.
                  </p>
                  <p className="text-xs text-slate-700 pt-2 leading-relaxed">
                    <strong>Why this is necessary:</strong>
                  </p>
                  <ul className="list-disc pl-5 text-xs text-slate-700 space-y-1 pt-1">
                    <li>To transmit continuous, real-time GPS telemetry to the cargo owner and consignee during intercity transit.</li>
                    <li>To calculate accurate, real-time dynamic Estimated Time of Arrival (ETA) updates and route deviation alerts.</li>
                    <li>To calculate and trigger automated corridor load recommendations and backhaul cargo matching along the truck&apos;s return route.</li>
                    <li>To trigger automated geofenced arrival alerts at loading docks and unloading hubs.</li>
                  </ul>
                  <p className="text-[11px] text-slate-500 pt-2 font-mono">
                    * Background location tracking is automatically deactivated whenever the partner is offline, not engaged in an active trip, or toggles off the &ldquo;Online&rdquo; status.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Section 4: Camera, Storage & Audio Permissions */}
          <section id="camera-audio" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                4
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Camera, Device Media &amp; Voice Permissions</h2>
                <p className="text-xs text-slate-500 font-medium">Strict operational purpose limitations</p>
              </div>
            </div>

            <div className="grid sm:grid-cols-3 gap-4 pt-2">
              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50">
                <div className="w-8 h-8 rounded-xl bg-purple-100 text-purple-700 flex items-center justify-center font-black mb-2">
                  <Camera size={16} />
                </div>
                <h4 className="font-black text-xs text-slate-900 mb-1">Camera Permission</h4>
                <p className="text-xs text-slate-500 leading-relaxed">
                  Used solely to capture KYC documents (RC, Driving License), physical Proof of Delivery (e-POD), and cargo condition at loading.
                </p>
              </div>

              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50">
                <div className="w-8 h-8 rounded-xl bg-blue-100 text-blue-700 flex items-center justify-center font-black mb-2">
                  <FileText size={16} />
                </div>
                <h4 className="font-black text-xs text-slate-900 mb-1">Storage &amp; Files</h4>
                <p className="text-xs text-slate-500 leading-relaxed">
                  Used to read and upload GST invoices, E-way bill PDFs, and save booking tax receipts or proof of delivery reports to device storage.
                </p>
              </div>

              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50">
                <div className="w-8 h-8 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center font-black mb-2">
                  <Mic size={16} />
                </div>
                <h4 className="font-black text-xs text-slate-900 mb-1">Microphone Access</h4>
                <p className="text-xs text-slate-500 leading-relaxed">
                  Used solely when you engage the interactive in-app Voice Assistant to search routes, or make in-app transit VoIP calls. Audio is not saved or monetized.
                </p>
              </div>
            </div>
          </section>

          {/* Section 5: How We Use Information */}
          <section id="data-usage" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                5
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">How We Use Your Information</h2>
                <p className="text-xs text-slate-500 font-medium">Core logistics operations and matching algorithms</p>
              </div>
            </div>

            <ul className="space-y-3 text-xs sm:text-sm">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 size={16} className="text-emerald-500 shrink-0 mt-0.5" />
                <span><strong>AI-Powered Cargo Matching:</strong> Matching available truck capacity with active cargo consignments based on route, tonnage, and scheduled pickup windows.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 size={16} className="text-emerald-500 shrink-0 mt-0.5" />
                <span><strong>Trip Execution &amp; Live Tracking:</strong> Transmitting continuous location, speed, and milestone telemetry to shippers and consignees.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 size={16} className="text-emerald-500 shrink-0 mt-0.5" />
                <span><strong>Safety &amp; Identity Verification:</strong> Verifying vehicle RC, fitness certificates, and driver credentials via our Operations Command Center.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 size={16} className="text-emerald-500 shrink-0 mt-0.5" />
                <span><strong>Invoicing &amp; Tax Compliance:</strong> Generating GST-compliant transport consignment notes, tax invoices, and accounting ledgers.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 size={16} className="text-emerald-500 shrink-0 mt-0.5" />
                <span><strong>No Commercial Sale of Data:</strong> REDO never sells, rents, or monetizes your personal information, telematics, or phone numbers to third-party ad networks or brokers.</span>
              </li>
            </ul>
          </section>

          {/* Section 6: Payments & Financial Data */}
          <section id="payments" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                6
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Payments &amp; Financial Security</h2>
                <p className="text-xs text-slate-500 font-medium">PCI-DSS compliance and escrow payout safeguards</p>
              </div>
            </div>

            <div className="space-y-3 text-xs sm:text-sm">
              <p>
                All freight advance payments, customer checkout charges, and balance settlements are processed via <strong>Razorpay</strong>, an RBI-licensed and PCI-DSS Level 1 compliant payment gateway.
              </p>
              <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 space-y-2">
                <div className="flex items-center gap-2 font-black text-slate-900">
                  <CreditCard size={16} className="text-amber-500" />
                  <span>Card &amp; Bank Details Protection</span>
                </div>
                <p className="text-xs text-slate-600">
                  REDO servers <strong>never store or record</strong> raw credit/debit card numbers, CVVs, UPI PINs, or netbanking passwords. Partner bank accounts (Account Number &amp; IFSC) provided for trip payouts are encrypted with AES-256 and used exclusively for direct NEFT/IMPS payout settlements.
                </p>
              </div>
            </div>
          </section>

          {/* Section 7: Third-Party Service Processors */}
          <section id="data-sharing" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                7
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Third-Party Service Providers</h2>
                <p className="text-xs text-slate-500 font-medium">Infrastructure and sub-processors utilized</p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-slate-200 bg-slate-50 text-slate-700 font-black">
                    <th className="p-3">Processor</th>
                    <th className="p-3">Purpose</th>
                    <th className="p-3">Data Shared</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-600 font-medium">
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Supabase (PostgreSQL)</td>
                    <td className="p-3">Encrypted database &amp; authentication</td>
                    <td className="p-3">User profiles, shipments, fleet records</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Razorpay Software Ltd</td>
                    <td className="p-3">Payment processing &amp; driver payouts</td>
                    <td className="p-3">Transaction amount, masked account, order ID</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Google Maps Platform</td>
                    <td className="p-3">Routing, Geocoding, Places Autocomplete</td>
                    <td className="p-3">Latitude/longitude coordinates, address text</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Firebase Cloud Messaging</td>
                    <td className="p-3">Push notifications for load dispatches</td>
                    <td className="p-3">Device push token, alert payload</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          {/* Section 8: Data Security & Retention */}
          <section id="security-retention" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                8
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Data Security &amp; Retention</h2>
                <p className="text-xs text-slate-500 font-medium">Cryptographic safeguards and archival schedules</p>
              </div>
            </div>

            <div className="space-y-3 text-xs sm:text-sm">
              <p>
                We implement industry-standard organizational and technological security safeguards:
              </p>
              <ul className="list-disc pl-5 space-y-1.5 text-xs text-slate-600">
                <li><strong>Encryption in Transit:</strong> All HTTP communications are enforced over TLS 1.3 with 256-bit encryption.</li>
                <li><strong>Encryption at Rest:</strong> Database tables and digital document vaults are encrypted with AES-256.</li>
                <li><strong>Access Control:</strong> Granular Row Level Security (RLS) rules prevent unauthorized horizontal access across tenant accounts.</li>
                <li><strong>Statutory Retention:</strong> Transport consignment notes and GST billing records are retained for 7 years as mandated under the Indian Central Goods and Services Tax (CGST) Act, after which they are securely purged.</li>
              </ul>
            </div>
          </section>

          {/* Section 9: Your Rights under DPDP Act 2023 */}
          <section id="user-rights" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                9
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Your Rights Under DPDP Act 2023</h2>
                <p className="text-xs text-slate-500 font-medium">Empowering users over their digital personal data</p>
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-4 pt-2">
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1.5">
                <h4 className="font-black text-xs text-slate-900">Right to Access</h4>
                <p className="text-xs text-slate-500">You may request a copy of all personal data processed by REDO in a structured, readable format.</p>
              </div>
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1.5">
                <h4 className="font-black text-xs text-slate-900">Right to Correction</h4>
                <p className="text-xs text-slate-500">You may update or rectify inaccurate profile, company, contact, or vehicle information at any time.</p>
              </div>
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1.5">
                <h4 className="font-black text-xs text-slate-900">Right to Consent Withdrawal</h4>
                <p className="text-xs text-slate-500">You may withdraw consent for optional marketing communications and notification broadcasts.</p>
              </div>
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1.5">
                <h4 className="font-black text-xs text-slate-900">Right of Grievance Redressal</h4>
                <p className="text-xs text-slate-500">You have the statutory right to escalate unresolved grievances directly to our designated officer.</p>
              </div>
            </div>
          </section>

          {/* Section 10: Account & Data Deletion */}
          <section id="account-deletion" className="bg-white border-2 border-rose-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-rose-100 text-rose-700 flex items-center justify-center font-black">
                10
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Account &amp; Data Deletion Policy</h2>
                <p className="text-xs text-slate-500 font-medium">How to exercise your right to erasure</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm">
              Users may request permanent deletion of their REDO account and associated personal data at any time through either of the following mechanisms:
            </p>

            <div className="grid sm:grid-cols-2 gap-4">
              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-2">
                <h4 className="font-black text-xs text-slate-900">Option A: In-App Self-Service</h4>
                <p className="text-xs text-slate-600">
                  Navigate to <strong>Profile &gt; Settings &gt; Security &gt; Request Account Deletion</strong>. Confirm your request with OTP verification.
                </p>
              </div>

              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-2">
                <h4 className="font-black text-xs text-slate-900">Option B: Written Email Request</h4>
                <p className="text-xs text-slate-600">
                  Send an email from your registered email address to <a href="mailto:ritik45chaurasia@gmail.com" className="text-amber-600 underline font-mono">ritik45chaurasia@gmail.com</a> with subject &ldquo;Data Deletion Request - [Registered Mobile Number]&rdquo;.
                </p>
              </div>
            </div>

            <p className="text-xs text-slate-500 font-medium pt-2">
              * Note: In accordance with statutory transport and commercial taxation regulations, non-personal financial invoices and completed trip transit records may be maintained in an archived, anonymized state for the mandatory statutory period.
            </p>
          </section>

          {/* Section 11: Grievance Officer & Contact */}
          <section id="grievance" className="bg-gradient-to-br from-slate-900 via-slate-900 to-slate-950 text-white rounded-3xl p-6 sm:p-8 shadow-lg space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#FFC800] text-slate-950 flex items-center justify-center font-black">
                11
              </div>
              <div>
                <h2 className="text-xl font-black">Grievance Redressal &amp; Data Protection Officer</h2>
                <p className="text-xs text-slate-400 font-medium">Designated under IT Act 2000 &amp; DPDP Act 2023</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm text-slate-300">
              For any concerns, complaints, data deletion requests, or questions regarding this Privacy Policy, please contact our designated Grievance Officer:
            </p>

            <div className="grid sm:grid-cols-2 gap-4 pt-1">
              <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 space-y-3">
                <div className="space-y-1">
                  <span className="text-[10px] font-mono uppercase tracking-wider text-amber-400 font-bold block">Officer Name</span>
                  <p className="text-base font-black text-white">Ritik Chaurasia</p>
                  <p className="text-xs text-slate-400">Chief Logistics Technology &amp; Privacy Officer</p>
                </div>

                <div className="space-y-1 pt-2 border-t border-slate-700/60 text-xs">
                  <span className="text-[10px] text-slate-400 uppercase font-mono block">Platform</span>
                  <p className="font-bold text-slate-200">REDO Smart Logistics Platform</p>
                  <p className="text-[11px] text-slate-400">Patna, Bihar, India — 800001</p>
                </div>
              </div>

              <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 space-y-3">
                <div className="space-y-1">
                  <span className="text-[10px] font-mono uppercase tracking-wider text-amber-400 font-bold block">Official Direct Contact</span>
                  <div className="space-y-2 pt-1 text-xs">
                    <div className="flex items-center gap-2">
                      <Mail size={15} className="text-amber-400 shrink-0" />
                      <a href="mailto:ritik45chaurasia@gmail.com" className="font-mono text-amber-300 hover:underline">
                        ritik45chaurasia@gmail.com
                      </a>
                    </div>
                    <div className="flex items-center gap-2">
                      <Phone size={15} className="text-amber-400 shrink-0" />
                      <a href="tel:+917250171036" className="font-mono text-amber-300 hover:underline">
                        +91 7250171036
                      </a>
                    </div>
                  </div>
                </div>

                <div className="space-y-1 pt-2 border-t border-slate-700/60 text-xs text-slate-300">
                  <span className="text-[10px] text-slate-400 uppercase font-mono block">Grievance Turnaround SLA</span>
                  <p className="font-medium text-[11px]">
                    Acknowledgement within <strong>24 hours</strong>; statutory resolution within <strong>15 working days</strong>.
                  </p>
                </div>
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
            <span>&copy; {new Date().getFullYear()} REDO Smart Logistics. All rights reserved.</span>
          </div>

          <div className="flex items-center gap-6">
            <Link to="/privacy" className="text-amber-600 hover:underline">Privacy Policy</Link>
            <Link to="/support" className="hover:text-slate-900 transition">Help &amp; Support</Link>
            <Link to="/login" className="hover:text-slate-900 transition">Shipper Portal</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
