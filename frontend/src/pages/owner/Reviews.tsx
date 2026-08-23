import { useEffect, useState } from "react";
import { Star, ThumbsUp, Users } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Card, CardSkeleton, EmptyState, SectionHead, StatCard } from "../../components/ui";

export default function Reviews() {
  const [reviews, setReviews] = useState<any[] | null>(null);
  useEffect(() => { api.get<any[]>("/reviews").then(setReviews).catch(() => setReviews([])); }, []);
  const list = reviews ?? [];
  const avg = list.length ? (list.reduce((a, r) => a + r.score, 0) / list.length).toFixed(1) : "—";
  const fiveStar = list.filter((r) => r.score === 5).length;

  return (
    <Layout>
      <SectionHead title="Reviews" sub="See what customers say about you and your service." />
      <div className="mt-5 grid gap-4 grid-cols-3">
        <StatCard icon={Star} label="Overall Rating" value={avg} sub={`${list.length} reviews`} tone="ok" />
        <StatCard icon={Users} label="Total Reviews" value={list.length} tone="info" />
        <StatCard icon={ThumbsUp} label="5 Star Reviews" value={fiveStar}
          sub={list.length ? `${Math.round((fiveStar / list.length) * 100)}% of total` : ""} tone="warn" />
      </div>
      <Card className="mt-5 p-5">
        {reviews === null ? <CardSkeleton /> : list.length === 0 ? (
          <EmptyState title="No reviews yet." hint="Ratings appear after shippers rate completed trips." />
        ) : (
          <div className="divide-y divide-line">
            {list.map((r) => (
              <div key={r.id} className="py-4 flex items-start gap-3">
                <span className="h-10 w-10 rounded-full bg-purple-soft text-purple grid place-items-center font-bold text-sm">
                  {(r.rater_name ?? "?")[0]}
                </span>
                <div className="flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="font-bold text-ink text-sm">{r.rater_name}</p>
                    <span className="text-warn text-sm" aria-label={`${r.score} out of 5`}>{"★".repeat(r.score)}{"☆".repeat(5 - r.score)}</span>
                    <span className="text-xs text-ink-faint ml-auto">{new Date(r.created_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}</span>
                  </div>
                  {r.comment && <p className="mt-1 text-sm text-ink-soft">{r.comment}</p>}
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>
    </Layout>
  );
}
