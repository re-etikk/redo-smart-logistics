import { useState } from "react";
import { Link } from "react-router-dom";
import {
  ShieldCheck, Lock, MapPin, Eye, FileText, Phone, Mail, ChevronRight,
  ArrowLeft, CheckCircle2, AlertTriangle, Truck, Server, CreditCard,
  Camera, Mic, HelpCircle, Navigation, ExternalLink, Users
} from "lucide-react";
import Logo from "../components/Logo";

export default function PartnerPrivacyPolicy() {
  const [activeTab, setActiveTab] = useState<"partner" | "all" | "customer">("partner");
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
            <div className="flex items-center gap-2">
              <Link to="/">
                <Logo />
              </Link>
              <span className="text-amber-500 font-black text-xs uppercase tracking-widest bg-amber-50 px-2 py-0.5 rounded-md border border-amber-300">
                PARTNER
              </span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <a
              href="mailto:ritik45chaurasia@gmail.com?subject=REDO%20Partner%20Privacy%20Inquiry"
              className="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-slate-700 hover:text-slate-950 px-3.5 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 transition"
            >
              <Mail size={14} className="text-amber-500" />
              <span>Contact Privacy Officer</span>
            </a>
            <Link
              to="/login"
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-4 py-2 rounded-xl shadow-xs transition"
            >
              Partner Login
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Banner */}
      <section className="bg-gradient-to-b from-amber-50/80 via-white to-[#FAF9F6] border-b border-slate-200/60 py-12 px-4 sm:px-8">
        <div className="max-w-5xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-100 border border-amber-300 text-amber-900 text-xs font-black shadow-xs">
            <ShieldCheck size={14} className="text-amber-600" />
            <span>Digital Personal Data Protection (DPDP) Act 2023 &bull; Partner &amp; Fleet Guidelines</span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-black text-slate-950 tracking-tight">
            Partner &amp; Fleet Privacy Policy
          </h1>

          <p className="text-sm sm:text-base text-slate-600 max-w-2xl mx-auto font-medium leading-relaxed">
            REDO Freight &amp; Logistics (&ldquo;REDO Partner&rdquo;, &ldquo;we&rdquo;, &ldquo;our&rdquo;) safeguards the personal, vehicle, banking, and telematics data of all registered truck drivers, vehicle owners, and logistics fleet operators across India.
          </p>

          <div className="pt-2 flex flex-wrap items-center justify-center gap-4 text-xs font-bold text-slate-500">
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              <FileText size={14} className="text-amber-500" /> Policy Version: 2.4 (Production)
            </span>
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              <Lock size={14} className="text-emerald-500" /> 256-bit AES Bank Safeguards
            </span>
            <span className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-lg border border-slate-200">
              Last Updated: {lastUpdated}
            </span>
          </div>

          {/* Quick Filter Tabs */}
          <div className="pt-6 flex justify-center">
            <div className="bg-slate-200/70 p-1 rounded-2xl flex items-center gap-1 text-xs font-black">
              <button
                onClick={() => setActiveTab("partner")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "partner" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                For Truck Partners &amp; Drivers
              </button>
              <button
                onClick={() => setActiveTab("all")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "all" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Comprehensive Platform Policy
              </button>
              <button
                onClick={() => setActiveTab("customer")}
                className={`px-4 py-2 rounded-xl transition ${
                  activeTab === "customer" ? "bg-white text-slate-950 shadow-sm" : "text-slate-600 hover:text-slate-900"
                }`}
              >
                For Shippers / Customers
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
              <span>Partner Policy Index</span>
            </div>

            <nav className="space-y-1 text-xs font-bold text-slate-600">
              {[
                { id: "partner-overview", label: "1. Scope for Truck Owners & Drivers" },
                { id: "partner-data", label: "2. Partner Data Collected" },
                { id: "background-gps", label: "3. Background GPS Telematics Disclosure" },
                { id: "documents-kyc", label: "4. Vehicle & Driver KYC Documents" },
                { id: "bank-payouts", label: "5. Payouts & Bank Account Security" },
                { id: "matching-ai", label: "6. ML Matching & Corridor Optimization" },
                { id: "subprocessors", label: "7. Third-Party Service Providers" },
                { id: "data-rights", label: "8. Rights Under DPDP Act 2023" },
                { id: "deletion", label: "9. Account & Telematics Deletion" },
                { id: "grievance", label: "10. Grievance Officer & Contact" },
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
              <p className="font-bold text-slate-700">Partner Support Helpline</p>
              <p>Email: <a href="mailto:ritik45chaurasia@gmail.com" className="text-amber-600 underline font-mono">ritik45chaurasia@gmail.com</a></p>
              <p>Phone: <a href="tel:+917250171036" className="text-amber-600 underline font-mono">+91 7250171036</a></p>
            </div>
          </div>
        </aside>

        {/* Right Policy Body */}
        <main className="space-y-10 text-slate-700 text-sm leading-relaxed">
          
          {/* Section 1: Scope */}
          <section id="partner-overview" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                1
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Scope for Truck Owners &amp; Drivers</h2>
                <p className="text-xs text-slate-500 font-medium">Framework for commercial vehicle partners on the REDO ecosystem</p>
              </div>
            </div>

            <p>
              This section sets forth how <strong>REDO Smart Logistics</strong> processes and protects the sensitive personal and commercial data of individual truck drivers, fleet owners, logistics contractors, and vehicle operators using the <strong>REDO Partner Mobile Application</strong> and <strong>REDO Partner Web Portal</strong>.
            </p>

            <div className="bg-amber-50/70 border border-amber-200/80 rounded-2xl p-4 text-xs space-y-2 text-slate-800">
              <div className="flex items-center gap-2 font-black text-amber-900">
                <Truck size={16} className="text-amber-600" />
                <span>Commercial Driver Safeguard Commitment</span>
              </div>
              <p>
                We recognize that commercial drivers and fleet owners trust REDO with essential livelihood data. We ensure complete transparency regarding how your location is shared, how your documents are verified, and how your payments are disbursed.
              </p>
            </div>
          </section>

          {/* Section 2: Partner Data Collected */}
          <section id="partner-data" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                2
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Partner Data We Collect</h2>
                <p className="text-xs text-slate-500 font-medium">Identity, vehicle documentation, and telematics</p>
              </div>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/60 space-y-2.5">
                <div className="flex items-center gap-2 text-xs font-black text-slate-900 uppercase">
                  <ShieldCheck size={16} className="text-amber-500" />
                  <span>Driver &amp; Owner KYC</span>
                </div>
                <ul className="text-xs space-y-1.5 text-slate-600">
                  <li>&bull; <strong>Driver Name &amp; Contact:</strong> Full legal name, mobile phone number, profile photo.</li>
                  <li>&bull; <strong>Driving License (DL):</strong> Valid commercial transport vehicle driving license with category endorsements.</li>
                  <li>&bull; <strong>Identity Proof:</strong> Aadhaar (with UID number masked), Voter ID, or PAN for tax compliance (TDS deductions).</li>
                  <li>&bull; <strong>Emergency Contacts:</strong> Family or fleet manager contact for transit emergency support.</li>
                </ul>
              </div>

              <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/60 space-y-2.5">
                <div className="flex items-center gap-2 text-xs font-black text-slate-900 uppercase">
                  <Truck size={16} className="text-emerald-500" />
                  <span>Truck &amp; Commercial Fleet Data</span>
                </div>
                <ul className="text-xs space-y-1.5 text-slate-600">
                  <li>&bull; <strong>Vehicle Registration Certificate (RC):</strong> Registration number, chassis number, engine number.</li>
                  <li>&bull; <strong>Statutory Permits:</strong> All India Tourist/Goods Permit, State Carriage Permits.</li>
                  <li>&bull; <strong>Safety &amp; Compliance:</strong> Fitness Certificate, Pollution Under Control (PUC), Commercial Vehicle Insurance.</li>
                  <li>&bull; <strong>Capacity Specifications:</strong> Gross Vehicle Weight (GVW), unladen weight, payload tonnage, container length, and body type.</li>
                </ul>
              </div>
            </div>
          </section>

          {/* Section 3: Background Location GPS Disclosure */}
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

            <div className="space-y-3">
              <p className="font-semibold text-slate-950">
                Notice on Background Location Access for REDO Partner App Users:
              </p>

              <div className="border-2 border-amber-200 bg-amber-50/60 rounded-2xl p-5 space-y-3">
                <p className="text-xs text-slate-800 font-semibold leading-relaxed">
                  <strong>The REDO Partner mobile application collects real-time location data in the background (even when the application is closed or not in active foreground use)</strong> exclusively while a driver is carrying an active shipment.
                </p>

                <h4 className="font-black text-xs text-slate-900 uppercase tracking-wide">
                  Specific Purposes of Background Location Telematics:
                </h4>
                <ul className="list-disc pl-5 text-xs text-slate-700 space-y-1.5">
                  <li>
                    <strong>Continuous Consignment Telematics:</strong> To transmit live vehicle positions to the shipper and consignee during intercity haulage, eliminating constant phone calls while driving.
                  </li>
                  <li>
                    <strong>Dynamic Corridor ETA Updates:</strong> To recalculate accurate estimated arrival times considering real-time traffic congestion, highway toll bottlenecks, and weather delays.
                  </li>
                  <li>
                    <strong>Automated Backhaul Load Matching:</strong> To match your truck with return freight along your active corridor while you are in transit, ensuring you do not travel empty on return journeys.
                  </li>
                  <li>
                    <strong>Geofenced Waypoint Alerts:</strong> To automatically notify the destination warehouse dock when your truck is within 5 kilometers of the delivery terminal.
                  </li>
                  <li>
                    <strong>Driver Safety &amp; Breakdown Dispatch:</strong> To dispatch roadside assistance or emergency fleet mechanics in the event of highway breakdowns or route deviations.
                  </li>
                </ul>

                <div className="pt-2 border-t border-amber-200/80 text-[11px] text-slate-600 font-medium">
                  <strong>Control &amp; Deactivation:</strong> Background location tracking automatically ceases as soon as the delivery is completed (e-POD signed) or whenever the driver toggles the app to &ldquo;Offline&rdquo;. Drivers can revoke background location permissions at any time via Android Device Settings &gt; Apps &gt; REDO Partner &gt; Permissions &gt; Location.
                </div>
              </div>
            </div>
          </section>

          {/* Section 4: Document Verification & Security */}
          <section id="documents-kyc" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                4
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Vehicle &amp; Driver KYC Document Handling</h2>
                <p className="text-xs text-slate-500 font-medium">Encrypted document vaults and reviewer access control</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm">
              All vehicle certificates (RC, Fitness, Insurance, Permits) and driver identity documents uploaded during onboarding are stored in an encrypted digital document vault:
            </p>

            <div className="grid sm:grid-cols-2 gap-4 text-xs">
              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-1.5">
                <h4 className="font-black text-slate-900">Masked Identity View</h4>
                <p className="text-slate-600">Aadhaar and PAN numbers are automatically masked in operations views so that only authorized compliance admins can review credentials.</p>
              </div>
              <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-1.5">
                <h4 className="font-black text-slate-900">Zero Public Exposure</h4>
                <p className="text-slate-600">Your personal documents are never made public to shippers or outside third parties. Shippers only see verified badges and vehicle registration plate numbers.</p>
              </div>
            </div>
          </section>

          {/* Section 5: Payouts & Bank Account Security */}
          <section id="bank-payouts" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                5
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Payouts &amp; Bank Account Protection</h2>
                <p className="text-xs text-slate-500 font-medium">Direct NEFT/IMPS payout settlements and escrow releases</p>
              </div>
            </div>

            <div className="space-y-3 text-xs sm:text-sm">
              <p>
                To disburse freight trip advances, diesel subsidies, and final balance settlements, we collect:
              </p>
              <ul className="list-disc pl-5 space-y-1 text-slate-600 text-xs">
                <li>Bank Account Holder Name (must match driver/fleet owner KYC name)</li>
                <li>Bank Account Number</li>
                <li>Bank IFSC Code</li>
              </ul>
              <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4 text-xs space-y-1 text-emerald-950">
                <p className="font-black flex items-center gap-1.5">
                  <Lock size={14} className="text-emerald-600" />
                  <span>Bank Data Encryption Guarantee</span>
                </p>
                <p className="text-emerald-900">
                  Your bank account credentials are encrypted with AES-256 and stored strictly for processing NEFT/IMPS direct payouts through our RBI-authorized banking gateway (Razorpay). REDO will never ask you for ATM PINs, UPI PINs, or online banking passwords.
                </p>
              </div>
            </div>
          </section>

          {/* Section 6: ML Matching */}
          <section id="matching-ai" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                6
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">ML Matching &amp; Corridor Optimization</h2>
                <p className="text-xs text-slate-500 font-medium">Algorithmic load allocation without arbitrary bias</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm">
              REDO uses automated machine learning models to analyze freight consignments and recommend them to truck partners based on:
            </p>
            <ul className="list-disc pl-5 space-y-1 text-xs text-slate-600">
              <li>Truck payload capacity vs cargo weight and volume (CFT).</li>
              <li>Truck location and preferred interstate corridor (e.g., Delhi &rarr; Mumbai, Lucknow &rarr; Kanpur).</li>
              <li>Empty return availability to eliminate deadhead kilometers.</li>
              <li>Compliance and verification rating of the partner.</li>
            </ul>
          </section>

          {/* Section 7: Sub-processors */}
          <section id="subprocessors" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                7
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Third-Party Infrastructure &amp; Processors</h2>
                <p className="text-xs text-slate-500 font-medium">Trusted services powering the REDO platform</p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-slate-200 bg-slate-50 text-slate-700 font-black">
                    <th className="p-3">Partner Processor</th>
                    <th className="p-3">Function</th>
                    <th className="p-3">Data Handled</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-600 font-medium">
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Supabase (PostgreSQL)</td>
                    <td className="p-3">Encrypted database storage &amp; auth</td>
                    <td className="p-3">Driver records, KYC proofs, trip milestones</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Razorpay Software Ltd</td>
                    <td className="p-3">RBI-licensed direct bank payout settlements</td>
                    <td className="p-3">Account number, IFSC, payout transaction ID</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Google Maps Platform</td>
                    <td className="p-3">Turn-by-turn routing and corridor tracking</td>
                    <td className="p-3">Trip route coordinates, pickup/drop pins</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-bold text-slate-900">Firebase Cloud Messaging</td>
                    <td className="p-3">Instant load dispatch push notifications</td>
                    <td className="p-3">FCM device token, load announcement message</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          {/* Section 8: Rights Under DPDP Act 2023 */}
          <section id="data-rights" className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-900 flex items-center justify-center font-black">
                8
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Partner Rights Under DPDP Act 2023</h2>
                <p className="text-xs text-slate-500 font-medium">Statutory rights granted to every registered transport partner</p>
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-4 text-xs">
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1">
                <h4 className="font-black text-slate-900">Right to View Telematics History</h4>
                <p className="text-slate-500">Access your historical trip logs, routes travelled, and recorded payouts anytime in the app.</p>
              </div>
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1">
                <h4 className="font-black text-slate-900">Right to Rectify Documents</h4>
                <p className="text-slate-500">Submit renewed insurance, fresh fitness certificates, or updated bank account details directly.</p>
              </div>
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1">
                <h4 className="font-black text-slate-900">Right to Revoke Permissions</h4>
                <p className="text-slate-500">Toggle offline status to immediately suspend background location transmissions.</p>
              </div>
              <div className="p-4 rounded-2xl border border-slate-200 bg-slate-50 space-y-1">
                <h4 className="font-black text-slate-900">Right to Nominate</h4>
                <p className="text-slate-500">Nominate a next-of-kin or successor for pending wallet balances in case of emergency.</p>
              </div>
            </div>
          </section>

          {/* Section 9: Deletion */}
          <section id="deletion" className="bg-white border-2 border-rose-200 rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-rose-100 text-rose-700 flex items-center justify-center font-black">
                9
              </div>
              <div>
                <h2 className="text-xl font-black text-slate-950">Account Deletion &amp; Unlinking</h2>
                <p className="text-xs text-slate-500 font-medium">How to retire your truck or remove your partner account</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm">
              Truck partners may retire registered trucks or request complete removal of their personal profile by emailing <a href="mailto:ritik45chaurasia@gmail.com" className="text-amber-600 underline font-mono">ritik45chaurasia@gmail.com</a> with subject &ldquo;Partner Account Deletion - [Vehicle Number / Registered Phone]&rdquo;.
            </p>
            <p className="text-xs text-slate-500">
              Upon account closure, personal phone numbers, bank details, and identity scans will be permanently wiped within 7 business days, provided there are no active transit disputes or pending payout balances.
            </p>
          </section>

          {/* Section 10: Grievance Officer */}
          <section id="grievance" className="bg-gradient-to-br from-slate-900 via-slate-900 to-slate-950 text-white rounded-3xl p-6 sm:p-8 shadow-lg space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#FFC800] text-slate-950 flex items-center justify-center font-black">
                10
              </div>
              <div>
                <h2 className="text-xl font-black">Designated Grievance &amp; Data Protection Officer</h2>
                <p className="text-xs text-slate-400 font-medium">Statutory point of contact under IT Act 2000 &amp; DPDP Act 2023</p>
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-4">
              <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 space-y-2 text-xs">
                <span className="text-[10px] font-mono uppercase text-amber-400 font-bold block">Officer Name</span>
                <p className="text-base font-black text-white">Ritik Chaurasia</p>
                <p className="text-slate-400">Head of Logistics Operations &amp; Data Privacy</p>
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
                  SLA: Acknowledged within 24 hours &bull; 100% resolution within 15 days
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
            <span>&copy; {new Date().getFullYear()} REDO Smart Logistics. Partner &amp; Fleet Operations.</span>
          </div>

          <div className="flex items-center gap-6">
            <Link to="/privacy" className="text-amber-600 hover:underline">Privacy Policy</Link>
            <Link to="/support" className="hover:text-slate-900 transition">Partner Support</Link>
            <Link to="/login" className="hover:text-slate-900 transition">Owner Portal</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
