export interface DocumentItem {
  id: string;
  title: string;
  desc: string;
  expiry: string;
  status: "Valid" | "Expiring Soon" | "Expired" | "Pending Verification" | "Missing";
  statusTone: string;
  type: "pdf" | "jpg" | "png";
  category: "vehicle" | "insurance" | "owner" | "permits";
  fileUrl?: string;
  uploadedAt: string;
  isRequired: boolean;
}

const DEFAULT_DOCUMENTS: DocumentItem[] = [
  {
    id: "DOC-RC",
    title: "RC (Registration Certificate)",
    desc: "Commercial Vehicle RC",
    expiry: "Valid till 18 Aug 2028",
    status: "Pending Verification",
    statusTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300",
    type: "pdf",
    category: "vehicle",
    uploadedAt: "Pending Upload",
    isRequired: true,
  },
  {
    id: "DOC-INS",
    title: "Comprehensive Insurance",
    desc: "Goods Freight Transit Cover",
    expiry: "Valid till 20 Sep 2027",
    status: "Pending Verification",
    statusTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300",
    type: "pdf",
    category: "insurance",
    uploadedAt: "Pending Upload",
    isRequired: true,
  },
  {
    id: "DOC-DL",
    title: "Commercial Driving License (DL)",
    desc: "Heavy Commercial Vehicle (HCV)",
    expiry: "Valid till 28 Jan 2030",
    status: "Pending Verification",
    statusTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300",
    type: "jpg",
    category: "owner",
    uploadedAt: "Pending Upload",
    isRequired: true,
  },
  {
    id: "DOC-PAN",
    title: "Owner PAN / Aadhaar Card",
    desc: "Identity & GST Tax Verification",
    expiry: "Permanent Government ID",
    status: "Pending Verification",
    statusTone: "bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300",
    type: "jpg",
    category: "owner",
    uploadedAt: "Pending Upload",
    isRequired: true,
  },
  {
    id: "DOC-PERMIT",
    title: "National Goods Permit",
    desc: "All India Commercial Carriage",
    expiry: "Valid till 05 Oct 2027",
    status: "Valid",
    statusTone: "bg-emerald-100 text-emerald-800",
    type: "pdf",
    category: "permits",
    uploadedAt: "16 Aug 2026",
    isRequired: false,
  },
  {
    id: "DOC-FIT",
    title: "Vehicle Fitness Certificate",
    desc: "RTO Fitness Clearance",
    expiry: "Valid till 12 Sep 2027",
    status: "Valid",
    statusTone: "bg-emerald-100 text-emerald-800",
    type: "pdf",
    category: "vehicle",
    uploadedAt: "16 Aug 2026",
    isRequired: false,
  },
];

const STORAGE_KEY = "redo_owner_documents_v2";

export function getDocuments(): DocumentItem[] {
  if (typeof window === "undefined") return DEFAULT_DOCUMENTS;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(DEFAULT_DOCUMENTS));
      return DEFAULT_DOCUMENTS;
    }
    return JSON.parse(saved);
  } catch {
    return DEFAULT_DOCUMENTS;
  }
}

export function saveDocuments(docs: DocumentItem[]): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(docs));
    window.dispatchEvent(new Event("redo_docs_updated"));
  } catch {}
}

export function uploadDocument(id: string, fileData: { title: string; fileUrl: string; desc: string }): void {
  const docs = getDocuments();
  const existing = docs.find(d => d.id === id);
  if (existing) {
    existing.status = "Valid";
    existing.fileUrl = fileData.fileUrl;
    existing.uploadedAt = new Date().toLocaleDateString("en-IN");
  } else {
    docs.push({
      id,
      title: fileData.title,
      desc: fileData.desc,
      expiry: "Valid (Recently Uploaded)",
      status: "Valid",
      statusTone: "bg-emerald-100 text-emerald-800",
      type: "pdf",
      category: "vehicle",
      fileUrl: fileData.fileUrl,
      uploadedAt: new Date().toLocaleDateString("en-IN"),
      isRequired: true,
    });
  }
  saveDocuments(docs);
}

export interface KycStatus {
  isFullyVerified: boolean;
  verifiedCount: number;
  totalRequired: number;
  label: string;
  badgeTone: "verified" | "pending" | "required";
}

export function getKycStatus(): KycStatus {
  const docs = getDocuments();
  const requiredDocs = docs.filter(d => d.isRequired);
  const validRequired = requiredDocs.filter(d => d.status === "Valid");

  const isFullyVerified = validRequired.length === requiredDocs.length;

  if (isFullyVerified) {
    return {
      isFullyVerified: true,
      verifiedCount: validRequired.length,
      totalRequired: requiredDocs.length,
      label: "Account Verified",
      badgeTone: "verified",
    };
  }

  if (validRequired.length > 0) {
    return {
      isFullyVerified: false,
      verifiedCount: validRequired.length,
      totalRequired: requiredDocs.length,
      label: `KYC Pending (${validRequired.length}/${requiredDocs.length})`,
      badgeTone: "pending",
    };
  }

  return {
    isFullyVerified: false,
    verifiedCount: 0,
    totalRequired: requiredDocs.length,
    label: "Documents Required",
    badgeTone: "required",
  };
}
