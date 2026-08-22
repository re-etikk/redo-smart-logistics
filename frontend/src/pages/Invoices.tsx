import { useEffect, useState } from 'react';
import { Download, FileText, IndianRupee } from 'lucide-react';
import Layout from '../components/Layout';
import { api } from '../services/api';
import { Badge, Card, CardSkeleton, EmptyState, SectionHead, StatCard } from '../components/ui';

interface Inv { id: string; invoice_no: string; booking_id: string; route: string;
  base_inr: number; gst_inr: number; total_inr: number; status: string; created_at: string; }

export default function Invoices() {
  const [invoices, setInvoices] = useState<Inv[] | null>(null);
  useEffect(() => { api.get<Inv[]>('/invoices').then(setInvoices).catch(() => setInvoices([])); }, []);
  const list = invoices ?? [];
  const paid = list.filter((i) => i.status === 'paid');

  return (
    <Layout>
      <SectionHead title="Invoices & Payments" sub="View, download and manage all your invoices and payments." />
      <div className="mt-5 grid gap-4 grid-cols-3">
        <StatCard icon={FileText} label="Total Invoices" value={list.length}
          sub={`₹${list.reduce((a, i) => a + i.total_inr, 0).toLocaleString('en-IN')} total`} tone="info" />
        <StatCard icon={IndianRupee} label="Paid Invoices" value={paid.length}
          sub={`₹${paid.reduce((a, i) => a + i.total_inr, 0).toLocaleString('en-IN')} paid`} tone="ok" />
        <StatCard icon={FileText} label="Pending" value={list.length - paid.length} tone="warn" />
      </div>
      <Card className="mt-5 p-5">
        {invoices === null ? <CardSkeleton /> : list.length === 0 ? (
          <EmptyState title="No invoices yet." hint="Invoices are generated automatically when a shipment completes." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm min-w-[680px]">
              <thead><tr className="text-left text-xs font-semibold text-ink-faint border-b border-line">
                <th className="py-2.5 pr-3">Invoice No.</th><th className="py-2.5 pr-3">Shipment</th>
                <th className="py-2.5 pr-3">Date</th><th className="py-2.5 pr-3">Base</th>
                <th className="py-2.5 pr-3">GST (18%)</th><th className="py-2.5 pr-3">Total</th>
                <th className="py-2.5 pr-3">Status</th><th className="py-2.5">Action</th>
              </tr></thead>
              <tbody>
                {list.map((i) => (
                  <tr key={i.id} className="border-b border-line last:border-0">
                    <td className="py-3.5 pr-3 font-bold text-accent">{i.invoice_no}</td>
                    <td className="py-3.5 pr-3 font-semibold">{i.route}</td>
                    <td className="py-3.5 pr-3 text-ink-soft">{new Date(i.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}</td>
                    <td className="py-3.5 pr-3 tabular-nums">₹{i.base_inr.toLocaleString('en-IN')}</td>
                    <td className="py-3.5 pr-3 tabular-nums">₹{i.gst_inr.toLocaleString('en-IN')}</td>
                    <td className="py-3.5 pr-3 font-bold tabular-nums">₹{i.total_inr.toLocaleString('en-IN')}</td>
                    <td className="py-3.5 pr-3"><Badge tone={i.status === 'paid' ? 'ok' : 'warn'}>{i.status === 'paid' ? 'Paid' : 'To be Paid'}</Badge></td>
                    <td className="py-3.5">
                      <button className="inline-flex items-center gap-1 text-sm font-semibold text-accent" onClick={() => window.print()}>
                        <Download size={14} /> PDF
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="mt-3 text-xs text-ink-faint">
              Payment collection is in sandbox mode for this build — no real gateway is charged. Razorpay/Stripe keys plug in via backend env.
            </p>
          </div>
        )}
      </Card>
    </Layout>
  );
}
