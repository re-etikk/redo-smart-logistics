import { useState } from "react";
import {
  Headset, Phone, Mail, MessageSquare, HelpCircle, ChevronDown, Send, CheckCircle2
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { useTranslation } from "../lib/i18n";

export default function Support() {
  const { t } = useTranslation();
  const [ticketSent, setTicketSent] = useState(false);
  const [ticketForm, setTicketForm] = useState({ subject: "", category: "Payment & Settlement", message: "" });
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const faqs = [
    { q: "How do instant wallet payouts work?", a: "Once a trip POD is digitally confirmed by the shipper, freight earnings reflect in your REDO wallet. You can withdraw to your IMPS verified bank account in under 60 seconds." },
    { q: "What documents are required to get 100% verified?", a: "You need to upload your commercial Vehicle RC, Active Insurance Policy, Commercial Driver Driving License (DL), and PAN card in the Documents KYC section." },
    { q: "How does REDO find return loads for my truck?", a: "Our AI matching engine pairs your scheduled corridor departure with verified SME cargo posts along your return route." },
    { q: "What happens if a trip is delayed due to highway breakdown?", a: "Contact 24/7 Fleet Dispatch Support via the hotline button. We notify the shipper and coordinate nearest emergency roadside assistance." },
  ];

  const handleTicketSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setTicketSent(true);
    setTimeout(() => {
      setTicketSent(false);
      setTicketForm({ subject: "", category: "Payment & Settlement", message: "" });
    }, 3000);
  };

  return (
    <OwnerLayout activeTab="support" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title */}
        <div>
          <h1 className="text-2xl font-black tracking-tight">{t("support")} &amp; 24/7 Dispatch Desk</h1>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Need assistance with active trips, load matching or wallet payouts? We are here to help.</p>
        </div>

        {/* 3 Contact Channel Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <a
            href="tel:18001237336"
            className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm hover:border-amber-400 transition flex items-center gap-4 cursor-pointer"
          >
            <div className="w-12 h-12 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-300 flex items-center justify-center font-black">
              <Phone size={22} />
            </div>
            <div>
              <span className="text-[10px] uppercase font-bold text-slate-400 block">Toll-Free Helpline</span>
              <h4 className="font-black text-sm text-slate-900 dark:text-white">1800-123-REDO (7336)</h4>
              <span className="text-[10px] text-emerald-600 font-bold">Available 24x7</span>
            </div>
          </a>

          <a
            href="https://wa.me/919876543210"
            target="_blank"
            rel="noreferrer"
            className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm hover:border-amber-400 transition flex items-center gap-4 cursor-pointer"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-100 dark:bg-emerald-950/60 text-emerald-900 dark:text-emerald-300 flex items-center justify-center font-black">
              <MessageSquare size={22} />
            </div>
            <div>
              <span className="text-[10px] uppercase font-bold text-slate-400 block">WhatsApp Dispatch</span>
              <h4 className="font-black text-sm text-slate-900 dark:text-white">+91 98765 43210</h4>
              <span className="text-[10px] text-emerald-600 font-bold">Instant Bot &amp; Agent</span>
            </div>
          </a>

          <a
            href="mailto:support@redo.app"
            className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm hover:border-amber-400 transition flex items-center gap-4 cursor-pointer"
          >
            <div className="w-12 h-12 rounded-2xl bg-blue-100 dark:bg-blue-950/60 text-blue-900 dark:text-blue-300 flex items-center justify-center font-black">
              <Mail size={22} />
            </div>
            <div>
              <span className="text-[10px] uppercase font-bold text-slate-400 block">Email Support</span>
              <h4 className="font-black text-sm text-slate-900 dark:text-white">support@redo.app</h4>
              <span className="text-[10px] text-slate-500 font-bold">Reply in &lt; 2 hours</span>
            </div>
          </a>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          {/* Raise Support Ticket */}
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
            <h3 className="font-black text-xs uppercase tracking-wider text-slate-900 dark:text-white flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
              <Headset size={16} className="text-amber-500" /> Raise Priority Support Ticket
            </h3>

            {ticketSent ? (
              <div className="p-6 text-center space-y-2 bg-emerald-50 dark:bg-emerald-950/40 rounded-2xl border border-emerald-300/40">
                <CheckCircle2 size={32} className="text-emerald-600 mx-auto" />
                <h4 className="font-black text-sm text-slate-900 dark:text-white">Ticket Submitted Successfully!</h4>
                <p className="text-xs text-slate-500">Our dispatch manager will contact you within 15 minutes.</p>
              </div>
            ) : (
              <form onSubmit={handleTicketSubmit} className="space-y-4 text-xs font-bold">
                <div>
                  <label className="text-slate-700 dark:text-slate-300 block mb-1">Issue Category</label>
                  <select
                    value={ticketForm.category}
                    onChange={(e) => setTicketForm({ ...ticketForm, category: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                  >
                    <option>Payment &amp; Settlement</option>
                    <option>Active Trip Milestone / GPS Issue</option>
                    <option>Document Verification &amp; KYC</option>
                    <option>Shipper Cancellation &amp; Detention Fee</option>
                    <option>Other Queries</option>
                  </select>
                </div>

                <div>
                  <label className="text-slate-700 dark:text-slate-300 block mb-1">Trip Reference / Subject</label>
                  <input
                    required
                    value={ticketForm.subject}
                    onChange={(e) => setTicketForm({ ...ticketForm, subject: e.target.value })}
                    placeholder="e.g. Delay at Bhiwandi Unloading Hub or RD124578"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                  />
                </div>

                <div>
                  <label className="text-slate-700 dark:text-slate-300 block mb-1">Detailed Description</label>
                  <textarea
                    required
                    rows={4}
                    value={ticketForm.message}
                    onChange={(e) => setTicketForm({ ...ticketForm, message: e.target.value })}
                    placeholder="Explain the issue with truck number, location and details..."
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                  />
                </div>

                <button
                  type="submit"
                  className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2 cursor-pointer"
                >
                  <Send size={15} /> Submit Support Request
                </button>
              </form>
            )}
          </div>

          {/* FAQs Accordion */}
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
            <h3 className="font-black text-xs uppercase tracking-wider text-slate-900 dark:text-white flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
              <HelpCircle size={16} className="text-amber-500" /> Frequently Asked Questions
            </h3>

            <div className="space-y-2 text-xs">
              {faqs.map((faq, i) => (
                <div key={i} className="border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden">
                  <button
                    onClick={() => setOpenFaq(openFaq === i ? null : i)}
                    className="w-full p-4 text-left font-black flex items-center justify-between bg-slate-50 dark:bg-slate-800/60 hover:bg-slate-100 transition cursor-pointer"
                  >
                    <span className="text-slate-900 dark:text-white">{faq.q}</span>
                    <ChevronDown size={16} className={`transition transform ${openFaq === i ? "rotate-180 text-amber-500" : "text-slate-400"}`} />
                  </button>
                  {openFaq === i && (
                    <div className="p-4 text-slate-600 dark:text-slate-300 bg-white dark:bg-slate-900 font-medium leading-relaxed border-t border-slate-200/60 dark:border-slate-800">
                      {faq.a}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </OwnerLayout>
  );
}
