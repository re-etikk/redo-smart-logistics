"""Smoke test for recommend.py — no FastAPI needed. Run: python smoke_test.py"""
import recommend

single = recommend.score_one({
    "distance_km": 1400, "available_capacity_tons": 4.0, "cargo_weight_tons": 1.5,
    "time_gap_hours": 1.2, "driver_rating": 4.7, "on_time_rate": 0.94,
    "cancel_rate": 0.03, "capacity_fit": 1.0,
})
print("single pair score:", single)

result = recommend.score_candidates([
    {"truck_id": "T1", "cargo_id": "C1", "distance_km": 1400, "available_capacity_tons": 4.0,
     "cargo_weight_tons": 1.5, "time_gap_hours": 1.2, "route_similarity": 0.96, "capacity_fit": 1.0,
     "driver_rating": 4.7, "on_time_rate": 0.94, "cancel_rate": 0.03},
    {"truck_id": "T2", "cargo_id": "C1", "distance_km": 1400, "available_capacity_tons": 2.0,
     "cargo_weight_tons": 1.5, "time_gap_hours": 5.5, "route_similarity": 0.7, "capacity_fit": 1.0,
     "driver_rating": 3.9, "on_time_rate": 0.78, "cancel_rate": 0.12},
    {"truck_id": "T3", "cargo_id": "C1", "distance_km": 1400, "available_capacity_tons": 1.0,
     "cargo_weight_tons": 1.5, "time_gap_hours": 1.0, "route_similarity": 0.95, "capacity_fit": 0.0,
     "driver_rating": 4.9, "on_time_rate": 0.97, "cancel_rate": 0.01},  # over capacity -> filtered
], top_k=3)
import json; print(json.dumps(result, indent=2))
assert result["rejected"][0]["reason"] == "insufficient_capacity"
assert result["recommendations"][0]["truck_id"] == "T1"
print("SMOKE TEST PASSED")
