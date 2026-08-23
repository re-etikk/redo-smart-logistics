import { useState } from "react";
import {
  Headset, MessageSquare, CheckCircle2, Clock, Phone, Mail, FileText, ChevronRight
} from "lucide-react";
import Layout from "../components/Layout";
import { Badge, Button, Card, SectionHead } from "../components/ui";

export default function CustomerSupport() {
  const [activeTab, setActiveTab] = useState<"tickets" | "new">("tickets");
  const [submitted, setSubmitted] = useState(false);

  const ticketList = [
    { id: "S1", title: "Shipment delay tracking query for #RD124567", desc: "Delivery estimated time was yesterday 6 PM, currently shows in transit.", ticketNo: "#SUP-C8821", date: "22 Aug 2026, 11:30 AM", status: "Open", tone: "warn" as const },
    { id: "S2", title: "Invoice GST calculation clarification", desc: "Need updated GST invoice with business PAN included.", ticketNo: "#SUP-C8810", date: "20 Aug 2026, 04:15 PM", status: "Resolved", tone: "ok" as const },
    { id: "S3", title: "POD copy request for Mumbai shipment", desc: "Consignee signature verification required for accounting.", ticketNo: "#SUP-C8792", date: "15 Aug 2026, 02:00 PM", status: "Resolved", tone: "ok" as const },
  ];

  return (
    <Layout>
      <SectionHead
        title="Help &amp; Support"
        sub="Get assistance with your shipments, billing, tracking, and account."
      />

      <div className="mt-5 grid gap-6 lg:grid-cols-[1fr_340px]">
        <div className="space-y-5">
          {/* Tabs */}
          <div className="flex items-center gap-2 border-b border-slate-200 pb-3">
            <button
              onClick={() => setActiveTab("tickets")}
              className={`px-4 py-2 rounded-xl text-xs font-black transition ${
                activeTab === "tickets" ? "bg-[#FFC800] text-slate-950 shadow-sm" : "bg-white text-slate-600 hover:bg-slate-50 border border-slate-200"
              }`}
            >
              My Support Tickets ({ticketList.length})
            </button>
            <button
              onClick={() => setActiveTab("new")}
              className={`px-4 py-2 rounded-xl text-xs font-black transition ${
                activeTab === "new" ? "bg-[#FFC800] text-slate-950 shadow-sm" : "bg-white text-slate-600 hover:bg-slate-50 border border-slate-200"
              }`}
            >
              + Raise New Ticket
            </button>
          </div>

          {activeTab === "tickets" ? (
            <div className="space-y-3">
              {ticketList.map((t) => (
                <Card key={t.id} className="p-5 hover:border-amber-400 transition">
                  <div className="flex items-start justify-between gap-4">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-mono font-bold text-slate-400">{t.ticketNo}</span>
                        <Badge tone={t.tone}>{t.status}</Badge>
                      </div>
                      <h4 className="text-sm font-black text-slate-900">{t.title}</h4>
                      <p className="text-xs text-slate-600 leading-relaxed">{t.desc}</p>
                      <span className="text-[10px] text-slate-400 font-medium block pt-1">{t.date}</span>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          ) : (
            <Card className="p-6">
              <h3 className="text-sm font-black text-slate-900 mb-4">Create New Support Ticket</h3>
              {submitted ? (
                <div className="p-6 text-center space-y-2">
                  <CheckCircle2 size={36} className="text-emerald-500 mx-auto" />
                  <h4 className="text-sm font-black text-slate-900">Ticket Submitted!</h4>
                  <p className="text-xs text-slate-500">Our customer success team will respond within 15 minutes.</p>
                  <Button variant="secondary" onClick={() => { setSubmitted(false); setActiveTab("tickets"); }}>
                    Back to Tickets
                  </Button>
                </div>
              ) : (
                <form
                  onSubmit={(e) => {
                    e.preventDefault();
                    setSubmitted(true);
                  }}
                  className="space-y-4 text-xs font-bold"
                >
                  <div>
                    <label className="text-slate-700 block mb-1">Issue Category</label>
                    <select className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900">
                      <option>Shipment Tracking &amp; Delays</option>
                      <option>Billing &amp; GST Invoices</option>
                      <option>Driver / Transporter Issue</option>
                      <option>Claims &amp; Damages</option>
                      <option>Other Queries</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Related Shipment ID (Optional)</label>
                    <input placeholder="e.g. RD124567" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900" />
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Subject</label>
                    <input required placeholder="Brief summary of the issue" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-slate-900" />
                  </div>
                  <div>
                    <label className="text-slate-700 block mb-1">Detailed Description</label>
                    <textarea required rows={4} placeholder="Please provide all details so we can resolve this quickly..." className="w-full bg-slate-50 border border-slate-200 rounded-xl p-3 text-slate-900" />
                  </div>
                  <Button type="submit" className="w-full">
                    Submit Ticket
                  </Button>
                </form>
              )}
            </Card>
          )}
        </div>

        {/* Right Help Sidebar */}
        <div className="space-y-4">
          <Card className="p-5 bg-white space-y-3">
            <h4 className="text-xs font-black text-slate-900 flex items-center gap-2">
              <Headset size={16} className="text-amber-500" /> 24/7 Shipper Helpline
            </h4>
            <p className="text-xs text-slate-600">
              For emergency freight escalations, reach our priority operations desk:
            </p>
            <div className="space-y-2 pt-1 text-xs font-bold text-slate-800">
              <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <Phone size={14} className="text-amber-600" /> +91 1800-REDO-SHIP
              </div>
              <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <Mail size={14} className="text-amber-600" /> support@redo.in
              </div>
            </div>
            <span className="block text-[10px] font-extrabold text-emerald-700 bg-emerald-100 px-2 py-1 rounded-md text-center">
              Avg Callback: Under 5 Minutes
            </span>
          </Card>

          <Card className="p-5 bg-amber-50 border border-amber-200">
            <h4 className="text-xs font-black text-slate-900">Transit Insurance Support</h4>
            <p className="text-[11px] text-slate-600 mt-1">
              All bookings placed on REDO carry complimentary goods in-transit protection up to ₹50 Lakhs.
            </p>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
