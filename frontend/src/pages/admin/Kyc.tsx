import { useEffect, useState } from "react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, EmptyState, SectionHead, useToast } from "../../components/ui";

export default function AdminKyc() {
  const [rows, setRows] = useState<any[] | null>(null);
  const toast = useToast();
  const load = () => api.get<any[]>("/admin/kyc").then(setRows).catch(() => setRows([]));
  useEffect(() => { load(); }, []);

  const decide = async (id: string, status: "verified" | "rejected") => {
    try { await api.patch(`/admin/kyc/${id}`, { status }); toast(`Document ${status}`); load(); }
    catch (e: any) { toast(e.message, "danger"); }
  };

  const list = rows ?? [];
  return (
    <Layout>
      <SectionHead title="KYC Verification" sub="Review pending documents. Owners are notified on decision." />
      <Card className="mt-5 p-5">
        {rows === null ? <CardSkeleton /> : list.length === 0 ? (
          <EmptyState title="No pending documents." hint="New uploads will appear here for review." />
        ) : (
          <div className="divide-y divide-line">
            {list.map((r) => (
              <div key={r.id} className="py-4 flex flex-wrap items-center gap-4">
                <div className="flex-1 min-w-[220px]">
                  <p className="font-bold text-ink text-sm">{r.document_type.replaceAll("_", " ")} <Badge tone="warn">pending</Badge></p>
                  <p className="text-xs text-ink-soft">{r.owner_name} · {r.document_reference_masked} · uploaded {new Date(r.created_at).toLocaleDateString("en-IN")}</p>
                </div>
                <Button className="!py-2 text-xs" onClick={() => decide(r.id, "verified")}>Verify</Button>
                <Button variant="danger" className="!py-2 text-xs" onClick={() => decide(r.id, "rejected")}>Reject</Button>
              </div>
            ))}
          </div>
        )}
      </Card>
    </Layout>
  );
}
