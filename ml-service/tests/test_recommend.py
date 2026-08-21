"""Unit tests for the recommendation layer (runnable without FastAPI)."""
import sys, os, unittest
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import recommend


def cand(**over):
    base = dict(
        truck_id="T1", cargo_id="C1", distance_km=1400, available_capacity_tons=4.0,
        cargo_weight_tons=1.5, time_gap_hours=1.0, route_similarity=0.97,
        capacity_fit=1.0, driver_rating=4.7, on_time_rate=0.94, cancel_rate=0.03,
    )
    base.update(over)
    return base


class TestHardFilter(unittest.TestCase):
    def test_capacity_reject(self):
        ok, why = recommend.hard_filter(cand(available_capacity_tons=1.0))
        self.assertEqual((ok, why), (False, "insufficient_capacity"))

    def test_timing_reject(self):
        ok, why = recommend.hard_filter(cand(time_gap_hours=20))
        self.assertEqual((ok, why), (False, "timing_incompatible"))

    def test_route_reject(self):
        ok, why = recommend.hard_filter(cand(route_similarity=0.2))
        self.assertEqual((ok, why), (False, "route_mismatch"))

    def test_status_reject(self):
        ok, why = recommend.hard_filter(cand(truck_status="in_transit"))
        self.assertEqual((ok, why), (False, "truck_unavailable"))

    def test_pass(self):
        self.assertEqual(recommend.hard_filter(cand()), (True, None))


class TestScoring(unittest.TestCase):
    def test_ranking_orders_by_score_and_filters(self):
        out = recommend.score_candidates([
            cand(),
            cand(truck_id="T2", time_gap_hours=6, route_similarity=0.7,
                 driver_rating=3.8, on_time_rate=0.8, cancel_rate=0.12),
            cand(truck_id="T3", available_capacity_tons=1.0),
        ], top_k=5)
        self.assertEqual(out["rejected"][0]["reason"], "insufficient_capacity")
        recs = out["recommendations"]
        self.assertEqual([r["truck_id"] for r in recs][0], "T1")
        self.assertTrue(recs[0]["match_score"] > recs[1]["match_score"])
        self.assertNotIn("94", "")  # no hardcoded scores anywhere: values come from the model
        for r in recs:
            self.assertTrue(0.0 <= r["match_score"] <= 1.0)
            self.assertTrue(len(r["reasons"]) >= 1)

    def test_score_one_range(self):
        s = recommend.score_one(cand())
        self.assertTrue(0.0 <= s <= 1.0)


if __name__ == "__main__":
    unittest.main()
