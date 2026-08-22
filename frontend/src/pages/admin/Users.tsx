import { useEffect, useState } from "react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Card, CardSkeleton, SearchInput, SectionHead } from "../../components/ui";

export default function AdminUsers() {
  const [users, setUsers] = useState<any[] | null>(null);
  const [q, setQ] = useState("");
  useEffect(() => { api.get<any[]>("/admin/users").then(setUsers).catch(() => setUsers([])); }, []);
  const list = (users ?? []).filter((u) => !q || `${u.full_name} ${u.company_name} ${u.role}`.toLowerCase().includes(q.toLowerCase()));

  return (
    <Layout>
      <SectionHead title="Users" sub="All registered accounts on the platform." />
      <Card className="mt-5 p-5">
        <SearchInput value={q} onChange={setQ} placeholder="Search by name, company or role…" />
        {users === null ? <div className="mt-4"><CardSkeleton /></div> : (
          <div className="mt-4 overflow-x-auto">
            <table className="w-full text-sm min-w-[560px]">
              <thead><tr className="text-left text-xs font-semibold text-ink-faint border-b border-line">
                <th className="py-2.5 pr-3">Name</th><th className="py-2.5 pr-3">Company</th>
                <th className="py-2.5 pr-3">Role</th><th className="py-2.5 pr-3">Phone</th><th className="py-2.5">Joined</th>
              </tr></thead>
              <tbody>
                {list.map((u) => (
                  <tr key={u.id} className="border-b border-line last:border-0">
                    <td className="py-3 pr-3 font-bold">{u.full_name}</td>
                    <td className="py-3 pr-3 text-ink-soft">{u.company_name || "—"}</td>
                    <td className="py-3 pr-3"><Badge tone={u.role === "sme" ? "accent" : u.role === "admin" ? "neutral" : "warn"}>
                      {u.role === "sme" ? "Shipper" : u.role === "admin" ? "Admin" : "Truck Owner"}</Badge></td>
                    <td className="py-3 pr-3 text-ink-soft">{u.phone || "—"}</td>
                    <td className="py-3 text-ink-soft">{new Date(u.created_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </Layout>
  );
}
