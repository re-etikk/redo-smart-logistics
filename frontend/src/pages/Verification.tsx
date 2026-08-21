import { useEffect, useRef, useState } from "react";
import Layout from "../components/Layout";
import { supabase } from "../lib/supabase";
import { Badge, Button, Card, useToast } from "../components/ui";

const DOCS = [
  { type: "driving_licence", label: "Driving licence" },
  { type: "vehicle_rc", label: "Vehicle RC" },
  { type: "identity", label: "Identity document" },
];

export default function Verification() {
  const [rows, setRows] = useState<any[]>([]);
  const [busyType, setBusyType] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const pendingType = useRef<string>("");
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
      // Store only a masked reference — never raw ID numbers (§34).
      const { error: e2 } = await supabase.from("kyc_verifications").insert({
        user_id: uid, document_type: type, verification_status: "pending",
        verification_source: "manual_upload", document_reference_masked: `upload:…${path.slice(-10)}`,
      });
      if (e2) throw new Error(e2.message);
      toast("Document uploaded — pending review");
      load();
    } catch (e: any) { toast(e.message, "danger"); } finally { setBusyType(null); }
  };

  const statusOf = (t: string) => rows.filter((r) => r.document_type === t).at(-1);

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Verification</h1>
      <p className="text-sm text-ink-faint mt-1">
        Documents are stored in a private bucket. This build uses manual + demo verification — DigiLocker integration
        requires official API access and is intentionally not simulated.
      </p>
      <input ref={fileRef} type="file" accept="image/*,.pdf" className="hidden"
        onChange={(e) => e.target.files?.[0] && upload(e.target.files[0])} />
      <div className="mt-6 grid gap-4 md:grid-cols-3">
        {DOCS.map((d) => {
          const row = statusOf(d.type);
          const st = row?.verification_status;
          return (
            <Card key={d.type} className="p-5">
              <div className="flex items-center justify-between">
                <p className="font-bold text-ink">{d.label}</p>
                {st === "verified" && <Badge tone="ok">{row.verification_source === "demo" ? "Demo verified" : "Verified"}</Badge>}
                {st === "pending" && <Badge tone="warn">Pending</Badge>}
                {st === "rejected" && <Badge tone="danger">Rejected</Badge>}
                {!st && <Badge>Not uploaded</Badge>}
              </div>
              {row?.document_reference_masked && <p className="mt-2 text-xs text-ink-faint">Ref: {row.document_reference_masked}</p>}
              <Button variant="secondary" className="mt-4 w-full" disabled={busyType === d.type}
                onClick={() => { pendingType.current = d.type; fileRef.current?.click(); }}>
                {busyType === d.type ? "Uploading…" : st ? "Replace document" : "Upload document"}
              </Button>
            </Card>
          );
        })}
      </div>
    </Layout>
  );
}
