import { useEffect, useRef, useState } from "react";
import { FileCheck2, FileClock, FileText, FileWarning, Upload } from "lucide-react";
import Layout from "../components/Layout";
import { supabase } from "../lib/supabase";
import { Badge, Button, Card, SectionHead, StatCard, useToast } from "../components/ui";

const DOCS = [
  { type: "driving_licence", label: "Driving Licence" },
  { type: "vehicle_rc", label: "RC (Registration Certificate)" },
  { type: "insurance", label: "Insurance Certificate" },
  { type: "identity", label: "Owner ID Proof" },
  { type: "permit", label: "Permit (National)" },
  { type: "fitness", label: "Fitness Certificate" },
];

export default function Documents() {
  const [rows, setRows] = useState<any[]>([]);
  const [busyType, setBusyType] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const pendingType = useRef("");
  const toast = useToast();

  const load = async () => {
    const { data } = await supabase.from("kyc_verifications").select("*").order("created_at");
    setRows(data ?? []);
  };
  useEffect(() => { load(); }, []);

  const upload = async (file: File) => {
    const type = pendingType.current;
    setBusyType(type);
    try {
      const { data: s } = await supabase.auth.getSession();
      const uid = s.session!.user.id;
      const path = `${uid}/${type}-${Date.now()}.${file.name.split(".").pop()}`;
      const { error } = await supabase.storage.from("kyc-documents").upload(path, file);
      if (error) throw new Error(error.message);
      const { error: e2 } = await supabase.from("kyc_verifications").insert({
        user_id: uid, document_type: type, verification_status: "pending",
        verification_source: "manual_upload", document_reference_masked: `upload:…${path.slice(-10)}`,
      });
      if (e2) throw new Error(e2.message);
      toast("Document uploaded — pending admin review");
      load();
    } catch (e: any) { toast(e.message, "danger"); } finally { setBusyType(null); }
  };

  const statusOf = (t: string) => rows.filter((r) => r.document_type === t).at(-1);
  const counts = {
    total: rows.length,
    valid: rows.filter((r) => r.verification_status === "verified").length,
    pending: rows.filter((r) => r.verification_status === "pending").length,
    rejected: rows.filter((r) => r.verification_status === "rejected").length,
  };

  return (
    <Layout>
      <SectionHead title="Documents" sub="Manage all your truck and owner documents in one place." />
      <div className="mt-5 grid gap-4 grid-cols-2 xl:grid-cols-4">
        <StatCard icon={FileText} label="Total Documents" value={counts.total} tone="ok" />
        <StatCard icon={FileCheck2} label="Verified" value={counts.valid} sub="Up to date" tone="info" />
        <StatCard icon={FileClock} label="Pending Review" value={counts.pending} tone="warn" />
        <StatCard icon={FileWarning} label="Rejected" value={counts.rejected} sub={counts.rejected ? "Action required" : ""} tone="danger" />
      </div>

      <input ref={fileRef} type="file" accept="image/*,.pdf" className="hidden"
        onChange={(e) => e.target.files?.[0] && upload(e.target.files[0])} />

      <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {DOCS.map((d) => {
          const row = statusOf(d.type);
          const st = row?.verification_status;
          return (
            <Card key={d.type} className="p-4">
              <div className="flex items-start justify-between gap-2">
                <span className="h-10 w-10 rounded-xl bg-accent-soft text-accent grid place-items-center"><FileText size={18} /></span>
                {st === "verified" && <Badge tone="ok">{row.verification_source === "demo" ? "Demo Verified" : "Valid"}</Badge>}
                {st === "pending" && <Badge tone="warn">Pending</Badge>}
                {st === "rejected" && <Badge tone="danger">Rejected</Badge>}
                {!st && <Badge>Not Uploaded</Badge>}
              </div>
              <p className="mt-3 font-bold text-ink text-sm">{d.label}</p>
              {row?.document_reference_masked && <p className="mt-0.5 text-xs text-ink-faint">Ref: {row.document_reference_masked}</p>}
              <Button variant="secondary" className="mt-3 w-full !py-2 text-xs" disabled={busyType === d.type}
                onClick={() => { pendingType.current = d.type; fileRef.current?.click(); }}>
                <Upload size={13} /> {busyType === d.type ? "Uploading…" : st ? "Replace Document" : "Upload Document"}
              </Button>
            </Card>
          );
        })}
      </div>
      <p className="mt-4 text-xs text-ink-faint max-w-lg">
        Files go to a private storage bucket; only masked references are stored. Verification here is manual/demo — real
        DigiLocker integration needs official API access and is intentionally not simulated.
      </p>
    </Layout>
  );
}
