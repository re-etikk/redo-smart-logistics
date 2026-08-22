import { useState } from "react";
import {
  FileText, CheckCircle2, Clock, AlertTriangle, Upload, Search, Filter, Eye, Download, ShieldCheck, HardDrive
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import Layout from "../components/Layout";
import { useAuth } from "../hooks/useAuth";

export default function Documents() {
  const { profile } = useAuth();
  const isOwner = profile?.role === "truck_owner";

  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState("all");

  const docList = [
    { id: "D1", title: "RC (Registration Certificate)", desc: "HR55 AB 1234", expiry: "Expiry: 18 Aug 2026", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "pdf", category: "vehicle" },
    { id: "D2", title: "Insurance Certificate", desc: "Bajaj Allianz", expiry: "Expiry: 20 Sep 2026", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "pdf", category: "insurance" },
    { id: "D3", title: "PUC Certificate", desc: "HR55 AB 1234", expiry: "Expiry: 10 Jul 2026", status: "Expiring Soon", statusTone: "bg-amber-100 text-amber-800", type: "pdf", category: "vehicle" },
    { id: "D4", title: "Driving License", desc: "Owner: Rohit Sharma", expiry: "Expiry: 28 Jan 2028", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "jpg", category: "owner" },
    { id: "D5", title: "Permit (National)", desc: "All India Permit", expiry: "Expiry: 05 Oct 2026", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "pdf", category: "permits" },
    { id: "D6", title: "Fitness Certificate", desc: "HR55 AB 1234", expiry: "Expiry: 12 Sep 2026", status: "Expiring Soon", statusTone: "bg-amber-100 text-amber-800", type: "pdf", category: "vehicle" },
    { id: "D7", title: "Tax Token", desc: "HR55 AB 1234", expiry: "Expiry: 31 Mar 2026", status: "Expired", statusTone: "bg-rose-100 text-rose-800", type: "pdf", category: "vehicle" },
    { id: "D8", title: "Owner ID Proof", desc: "Aadhar Card", expiry: "Expiry: — (Permanent)", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "jpg", category: "owner" },
    { id: "D9", title: "Bank Details", desc: "Account Linked", expiry: "Updated: 10 May 2024", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "pdf", category: "owner" },
    { id: "D10", title: "Vehicle Photo", desc: "Updated: 15 May 2024", expiry: "Valid", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "jpg", category: "vehicle" },
    { id: "D11", title: "Pollution Norms", desc: "BS6 Compliance", expiry: "Expiry: 10 Jul 2026", status: "Valid", statusTone: "bg-emerald-100 text-emerald-800", type: "pdf", category: "vehicle" },
  ];

  if (isOwner) {
    return (
      <OwnerLayout activeTab="documents" promoCardType="refer">
        <div className="space-y-6">
          {/* Header Title matching Mockup 7 */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <h1 className="text-2xl font-black text-slate-900 tracking-tight">Documents</h1>
              <p className="text-xs text-slate-500 mt-0.5">Manage all your truck and owner documents in one place.</p>
            </div>

            <div className="flex items-center gap-2 w-full sm:w-auto">
              <div className="relative flex-1 sm:w-64">
                <Search size={14} className="text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search documents..."
                  className="w-full bg-white border border-slate-200 rounded-xl pl-9 pr-3 py-2 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                />
              </div>
              <button className="p-2 bg-white border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-50">
                <Filter size={16} />
              </button>
            </div>
          </div>

          {/* 5 Stat Cards matching Mockup 7 */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
              <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <FileText size={16} />
              </div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Total Documents</span>
              <span className="text-lg font-black text-slate-900 block">16</span>
              <span className="text-[10px] font-bold text-slate-500 block">All Documents</span>
            </div>

            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
              <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
                <CheckCircle2 size={16} />
              </div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Valid Documents</span>
              <span className="text-lg font-black text-slate-900 block">12</span>
              <span className="text-[10px] font-bold text-emerald-600 block">Up to date</span>
            </div>

            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
              <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
                <Clock size={16} />
              </div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Expiring Soon</span>
              <span className="text-lg font-black text-slate-900 block">3</span>
              <span className="text-[10px] font-bold text-amber-600 block">Within 30 days</span>
            </div>

            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1">
              <div className="w-8 h-8 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center">
                <AlertTriangle size={16} />
              </div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Expired</span>
              <span className="text-lg font-black text-slate-900 block">1</span>
              <span className="text-[10px] font-bold text-rose-600 block">Action Required</span>
            </div>

            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm space-y-1 col-span-2 md:col-span-1">
              <div className="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
                <Upload size={16} />
              </div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block pt-1">Uploaded This Month</span>
              <span className="text-lg font-black text-slate-900 block">4</span>
              <span className="text-[10px] font-bold text-purple-600 block">New Uploads</span>
            </div>
          </div>

          {/* Filter Tabs */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-sm flex items-center gap-2 overflow-x-auto text-xs font-extrabold">
            <button onClick={() => setActiveTab("all")} className={`px-4 py-2 rounded-xl transition ${activeTab === "all" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>All Documents</button>
            <button onClick={() => setActiveTab("vehicle")} className={`px-4 py-2 rounded-xl transition ${activeTab === "vehicle" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Vehicle Documents</button>
            <button onClick={() => setActiveTab("owner")} className={`px-4 py-2 rounded-xl transition ${activeTab === "owner" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Owner Documents</button>
            <button onClick={() => setActiveTab("insurance")} className={`px-4 py-2 rounded-xl transition ${activeTab === "insurance" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Insurance</button>
            <button onClick={() => setActiveTab("permits")} className={`px-4 py-2 rounded-xl transition ${activeTab === "permits" ? "bg-[#FFC800] text-slate-950 font-black" : "text-slate-600 hover:bg-slate-50"}`}>Permits &amp; Licenses</button>
          </div>

          {/* Main Grid: Document Cards + Right Expiries Sidebar matching Mockup 7 */}
          <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
            {/* Document Cards Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {docList.map((doc) => (
                <div key={doc.id} className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm hover:shadow-md transition space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-amber-50 border border-amber-200 text-amber-600 flex items-center justify-center font-bold">
                        <FileText size={20} />
                      </div>
                      <div>
                        <h4 className="font-black text-slate-900 text-xs">{doc.title}</h4>
                        <span className="text-[10px] text-slate-500 font-medium block">{doc.desc}</span>
                      </div>
                    </div>
                    <span className={`px-2 py-0.5 rounded text-[9px] font-extrabold ${doc.statusTone}`}>
                      {doc.status}
                    </span>
                  </div>

                  <div className="text-[10px] text-slate-400 font-semibold pt-1 border-t border-slate-100 flex items-center justify-between">
                    <span>{doc.expiry}</span>
                    <div className="flex items-center gap-2">
                      <button className="px-2.5 py-1 bg-slate-50 border border-slate-200 rounded-lg text-slate-700 font-bold hover:bg-slate-100 flex items-center gap-1">
                        <Download size={12} /> {doc.type.toUpperCase()}
                      </button>
                      <button className="px-2.5 py-1 bg-slate-50 border border-slate-200 rounded-lg text-slate-700 font-bold hover:bg-slate-100 flex items-center gap-1">
                        <Eye size={12} /> View
                      </button>
                    </div>
                  </div>
                </div>
              ))}

              {/* Upload New Document Box */}
              <div className="border-2 border-dashed border-slate-200 hover:border-amber-400 rounded-2xl p-6 text-center flex flex-col items-center justify-center gap-2 bg-slate-50/50 cursor-pointer transition">
                <div className="w-12 h-12 rounded-full bg-white shadow-sm border border-slate-200 flex items-center justify-center text-slate-600">
                  <Upload size={20} />
                </div>
                <span className="font-black text-slate-900 text-xs">Upload Document</span>
                <span className="text-[10px] text-slate-400">Drag &amp; drop or click to upload PDF, JPG (Max 10MB)</span>
              </div>
            </div>

            {/* Right Expiries & Storage Sidebar */}
            <div className="space-y-6">
              {/* Upcoming Expiries Box */}
              <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
                <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                  <h4 className="font-black text-xs text-slate-900">Upcoming Expiries</h4>
                  <span className="text-[10px] font-bold text-amber-600 cursor-pointer">View All</span>
                </div>

                <div className="space-y-3 text-xs">
                  <div className="flex items-center justify-between bg-amber-50/60 p-2.5 rounded-xl border border-amber-200/60">
                    <div>
                      <span className="font-black text-slate-900 text-xs block">PUC Certificate</span>
                      <span className="text-[10px] text-slate-500 font-medium">HR55 AB 1234</span>
                    </div>
                    <span className="text-[10px] font-extrabold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                      10 Jul 2026 (20 days left)
                    </span>
                  </div>

                  <div className="flex items-center justify-between bg-amber-50/60 p-2.5 rounded-xl border border-amber-200/60">
                    <div>
                      <span className="font-black text-slate-900 text-xs block">Fitness Certificate</span>
                      <span className="text-[10px] text-slate-500 font-medium">HR55 AB 1234</span>
                    </div>
                    <span className="text-[10px] font-extrabold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                      12 Sep 2026 (53 days left)
                    </span>
                  </div>

                  <div className="flex items-center justify-between bg-amber-50/60 p-2.5 rounded-xl border border-amber-200/60">
                    <div>
                      <span className="font-black text-slate-900 text-xs block">Insurance Certificate</span>
                      <span className="text-[10px] text-slate-500 font-medium">HR55 AB 1234</span>
                    </div>
                    <span className="text-[10px] font-extrabold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                      20 Sep 2026 (61 days left)
                    </span>
                  </div>
                </div>
              </div>

              {/* Document Storage Usage */}
              <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-3">
                <div className="flex items-center justify-between">
                  <span className="font-black text-xs text-slate-900 flex items-center gap-1.5">
                    <HardDrive size={14} className="text-amber-500" /> Document Storage
                  </span>
                  <span className="text-[10px] font-bold text-slate-400">48%</span>
                </div>

                <div>
                  <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-[#FFC800] h-full w-[48%] rounded-full"></div>
                  </div>
                  <span className="text-[10px] text-slate-500 font-medium block pt-1.5">2.4 GB used of 5 GB</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </OwnerLayout>
    );
  }

  // Shipper Verification View
  return (
    <Layout>
      <div className="max-w-2xl mx-auto py-8">
        <h1 className="text-2xl font-black text-slate-900">KYC Verification</h1>
        <p className="text-xs text-slate-500 mt-1">Upload your identity proof and business license to complete account verification.</p>

        <div className="mt-6 bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
          <div>
            <label className="text-xs font-bold text-slate-700 block mb-1">GST / Business Registration</label>
            <input placeholder="Enter GSTIN" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold" />
          </div>

          <div>
            <label className="text-xs font-bold text-slate-700 block mb-1">Aadhar / PAN Card Upload</label>
            <input type="file" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs" />
          </div>

          <button className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-2.5 rounded-xl shadow-sm text-xs">
            Submit Documents
          </button>
        </div>
      </div>
    </Layout>
  );
}
