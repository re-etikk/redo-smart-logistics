import { useState, useEffect, useRef } from "react";
import {
  FileText, CheckCircle2, Clock, AlertTriangle, Upload, Search, Filter, Eye,
  Download, HardDrive, Plus, ShieldCheck, X, Check, ArrowRight
} from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import {
  getDocuments, uploadDocument, getKycStatus,
  type DocumentItem, type KycStatus
} from "../lib/documentStore";

export default function OwnerDocuments() {
  const [documents, setDocuments] = useState<DocumentItem[]>(getDocuments());
  const [kycStatus, setKycStatus] = useState<KycStatus>(getKycStatus());
  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState("all");

  // Modals
  const [isUploadOpen, setIsUploadOpen] = useState(false);
  const [selectedDoc, setSelectedDoc] = useState<DocumentItem | null>(null);

  // Upload Form
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploadForm, setUploadForm] = useState({
    title: "Commercial Driving License (DL)",
    desc: "DL Number / State RTO",
    category: "owner" as const,
    fileUrl: "",
    fileName: "",
  });

  const refresh = () => {
    setDocuments(getDocuments());
    setKycStatus(getKycStatus());
  };

  useEffect(() => {
    refresh();
    window.addEventListener("redo_docs_updated", refresh);
    return () => window.removeEventListener("redo_docs_updated", refresh);
  }, []);

  const handleFilePick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      if (event.target?.result) {
        setUploadForm(prev => ({
          ...prev,
          fileUrl: event.target!.result as string,
          fileName: file.name
        }));
      }
    };
    reader.readAsDataURL(file);
  };

  const handleUploadSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const docId = `DOC-${uploadForm.title.split(" ")[0].toUpperCase()}`;
    uploadDocument(docId, {
      title: uploadForm.title,
      desc: uploadForm.desc || "Verified Commercial Document",
      fileUrl: uploadForm.fileUrl || "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=600&q=80",
    });

    setIsUploadOpen(false);
    refresh();
  };

  const filteredDocs = documents.filter((doc) => {
    const matchesSearch =
      doc.title.toLowerCase().includes(search.toLowerCase()) ||
      doc.desc.toLowerCase().includes(search.toLowerCase()) ||
      doc.category.toLowerCase().includes(search.toLowerCase());

    const matchesTab =
      activeTab === "all" ||
      (activeTab === "vehicle" && doc.category === "vehicle") ||
      (activeTab === "insurance" && doc.category === "insurance") ||
      (activeTab === "owner" && doc.category === "owner") ||
      (activeTab === "permits" && doc.category === "permits");

    return matchesSearch && matchesTab;
  });

  const validCount = documents.filter(d => d.status === "Valid").length;
  const expiringSoonCount = documents.filter(d => d.status === "Expiring Soon").length;
  const expiredCount = documents.filter(d => d.status === "Expired" || d.status === "Missing").length;

  return (
    <OwnerLayout activeTab="documents" promoCardType="refer">
      <div className="space-y-6">
        {/* Header Title */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black tracking-tight">Compliance &amp; KYC Documents</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Upload your RC, Insurance, Driving License &amp; National Permits to get verified.
            </p>
          </div>

          <button
            onClick={() => setIsUploadOpen(true)}
            className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-5 py-2.5 rounded-xl shadow-md transition text-xs flex items-center gap-2 cursor-pointer"
          >
            <Upload size={15} /> Upload New Document
          </button>
        </div>

        {/* KYC Verification Banner Card */}
        <div className={`p-6 rounded-3xl border shadow-sm flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 ${
          kycStatus.isFullyVerified
            ? "bg-emerald-50 dark:bg-emerald-950/40 border-emerald-300 dark:border-emerald-800 text-emerald-950 dark:text-emerald-300"
            : "bg-amber-50 dark:bg-amber-950/40 border-amber-300 dark:border-amber-800 text-amber-950 dark:text-amber-300"
        }`}>
          <div className="flex items-center gap-4">
            <div className={`w-12 h-12 rounded-2xl flex items-center justify-center font-black text-2xl shrink-0 shadow-sm ${
              kycStatus.isFullyVerified ? "bg-emerald-500 text-white" : "bg-amber-400 text-slate-950"
            }`}>
              {kycStatus.isFullyVerified ? <ShieldCheck size={26} /> : <AlertTriangle size={24} />}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-black">
                  {kycStatus.isFullyVerified ? "KYC Verification Complete (100%)" : "KYC Documents Verification in Progress"}
                </h3>
                <span className="text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full bg-white/80 dark:bg-slate-900 border border-current shadow-xs">
                  {kycStatus.verifiedCount} of {kycStatus.totalRequired} Mandatory Verified
                </span>
              </div>
              <p className="text-xs opacity-85 mt-0.5">
                {kycStatus.isFullyVerified
                  ? "Your fleet is 100% compliant and receives high priority on all spot backhaul matches."
                  : "Upload all required documents (RC, DL, Insurance, PAN) to activate full verified account badge."}
              </p>
            </div>
          </div>

          {!kycStatus.isFullyVerified && (
            <button
              onClick={() => setIsUploadOpen(true)}
              className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-4 py-2 rounded-xl text-xs shadow-sm transition whitespace-nowrap cursor-pointer"
            >
              Complete Verification
            </button>
          )}
        </div>

        {/* 4 Stat Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Total Tracked</span>
            <span className="text-2xl font-black text-slate-900 dark:text-white block">{documents.length}</span>
            <span className="text-[10px] font-bold text-slate-500 block">Fleet &amp; Owner Records</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Valid Documents</span>
            <span className="text-2xl font-black text-emerald-600 block">{validCount}</span>
            <span className="text-[10px] font-bold text-emerald-600 block">100% Active</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Expiring Soon</span>
            <span className="text-2xl font-black text-amber-600 block">{expiringSoonCount}</span>
            <span className="text-[10px] font-bold text-amber-600 block">Next 30 Days</span>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-sm space-y-1">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Action Needed</span>
            <span className="text-2xl font-black text-rose-600 block">{expiredCount}</span>
            <span className="text-[10px] font-bold text-rose-600 block">Upload Renewal</span>
          </div>
        </div>

        {/* Filter Bar */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-3 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-1.5 overflow-x-auto w-full md:w-auto text-xs font-bold">
            {["all", "vehicle", "insurance", "owner", "permits"].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-3.5 py-1.5 rounded-xl capitalize transition cursor-pointer ${
                  activeTab === tab
                    ? "bg-[#FFC800] text-slate-950 font-black shadow-sm"
                    : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                }`}
              >
                {tab}
              </button>
            ))}
          </div>

          <div className="relative w-full md:w-64">
            <Search size={14} className="text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search documents..."
              className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl pl-8 pr-3 py-1.5 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>
        </div>

        {/* Documents Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredDocs.map((doc) => (
            <div
              key={doc.id}
              className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm hover:shadow-md transition flex flex-col justify-between space-y-4"
            >
              <div className="space-y-3">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-400 flex items-center justify-center">
                      <FileText size={20} />
                    </div>
                    <div>
                      <h4 className="font-black text-xs sm:text-sm">{doc.title}</h4>
                      <p className="text-[11px] text-slate-500 font-medium">{doc.desc}</p>
                    </div>
                  </div>

                  <span className={`text-[10px] font-black px-2.5 py-0.5 rounded-full shadow-xs ${
                    doc.status === "Valid"
                      ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400"
                      : doc.status === "Expiring Soon"
                      ? "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400"
                      : "bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-400"
                  }`}>
                    {doc.status}
                  </span>
                </div>

                <div className="text-xs font-bold text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/60 p-3 rounded-2xl border border-slate-100 dark:border-slate-800 space-y-1">
                  <div className="flex justify-between">
                    <span className="text-slate-400 text-[10px] uppercase font-semibold">Validity / Expiry</span>
                    <span className="text-slate-900 dark:text-white">{doc.expiry}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400 text-[10px] uppercase font-semibold">Last Updated</span>
                    <span className="text-slate-900 dark:text-white">{doc.uploadedAt}</span>
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
                <button
                  onClick={() => setSelectedDoc(doc)}
                  className="flex-1 bg-slate-900 dark:bg-slate-800 hover:bg-slate-800 text-white font-bold py-2 rounded-xl text-xs flex items-center justify-center gap-1.5 transition cursor-pointer"
                >
                  <Eye size={14} /> View Document
                </button>
                <button
                  onClick={() => {
                    setUploadForm({
                      title: doc.title,
                      desc: doc.desc,
                      category: doc.category,
                      fileUrl: "",
                      fileName: "",
                    });
                    setIsUploadOpen(true);
                  }}
                  className="p-2 text-slate-500 hover:text-amber-600 bg-slate-50 dark:bg-slate-800 hover:bg-amber-50 rounded-xl transition cursor-pointer"
                  title="Re-upload / Update"
                >
                  <Upload size={16} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* UPLOAD DOCUMENT MODAL */}
      {/* ========================================================================= */}
      {isUploadOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-md w-full shadow-2xl p-6 space-y-5">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <h3 className="text-lg font-black">Upload KYC / Vehicle Document</h3>
                <p className="text-xs text-slate-500">Government approved RTO and identity proofs</p>
              </div>
              <button onClick={() => setIsUploadOpen(false)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleUploadSubmit} className="space-y-4 text-xs font-bold">
              <div>
                <label className="text-slate-700 dark:text-slate-300 block mb-1">Document Type *</label>
                <select
                  value={uploadForm.title}
                  onChange={(e) => setUploadForm({ ...uploadForm, title: e.target.value })}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                >
                  <option>RC (Registration Certificate)</option>
                  <option>Comprehensive Insurance</option>
                  <option>Commercial Driving License (DL)</option>
                  <option>Owner PAN / Aadhaar Card</option>
                  <option>National Goods Permit</option>
                  <option>Vehicle Fitness Certificate</option>
                  <option>PUC Certificate</option>
                </select>
              </div>

              <div>
                <label className="text-slate-700 dark:text-slate-300 block mb-1">Document Reference / ID Number</label>
                <input
                  required
                  value={uploadForm.desc}
                  onChange={(e) => setUploadForm({ ...uploadForm, desc: e.target.value })}
                  placeholder="e.g. DL-042018009876 or Vehicle RC"
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 font-mono"
                />
              </div>

              <div>
                <label className="text-slate-700 dark:text-slate-300 block mb-1">Select File (PDF, JPG, PNG)</label>
                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={handleFilePick}
                  accept="image/*,.pdf"
                  className="hidden"
                />
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full p-4 border-2 border-dashed border-slate-200 dark:border-slate-700 hover:border-amber-400 rounded-2xl flex flex-col items-center justify-center gap-1.5 bg-slate-50 dark:bg-slate-800/50 cursor-pointer transition"
                >
                  <Upload size={20} className="text-amber-500" />
                  <span className="text-slate-900 dark:text-white font-black text-xs">
                    {uploadForm.fileName ? uploadForm.fileName : "Click to Browse File"}
                  </span>
                  <span className="text-[10px] text-slate-400">Max size 5MB (Secure Cloud Storage)</span>
                </button>
              </div>

              <button
                type="submit"
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-xs flex items-center justify-center gap-2 cursor-pointer mt-2"
              >
                <span>Upload &amp; Submit for Verification</span>
                <Check size={16} />
              </button>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* VIEW DOCUMENT MODAL */}
      {/* ========================================================================= */}
      {selectedDoc && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl max-w-lg w-full shadow-2xl p-6 space-y-5">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
              <div>
                <h3 className="text-base font-black">{selectedDoc.title}</h3>
                <p className="text-xs text-slate-500">{selectedDoc.desc}</p>
              </div>
              <button onClick={() => setSelectedDoc(null)} className="p-1.5 text-slate-400 hover:text-slate-600">
                <X size={18} />
              </button>
            </div>

            <div className="space-y-3 text-xs font-bold bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-200 dark:border-slate-700">
              <div className="flex justify-between">
                <span className="text-slate-400">Document Status:</span>
                <span className="text-emerald-600 font-black">✓ {selectedDoc.status}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Validity:</span>
                <span className="text-slate-900 dark:text-white">{selectedDoc.expiry}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Verified By:</span>
                <span className="text-slate-900 dark:text-white">REDO Automated Compliance Check</span>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => setSelectedDoc(null)}
                className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </OwnerLayout>
  );
}
