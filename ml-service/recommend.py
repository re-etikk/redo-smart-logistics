"""
Redo — recommendation layer.

Pipeline:  candidates -> hard filters -> ML ranking -> top-K with reasons.

Model loading is artifact-agnostic: accepts either the dict artifact
produced by train_model.py ({"model": ..., "features": [...]}) or a bare
estimator saved directly (e.g. an original XGBoost match_model.joblib).
"""

from __future__ import annotations

import os
from functools import lru_cache

import joblib
import pandas as pd

MODEL_PATH = os.environ.get("MATCH_MODEL_PATH", os.path.join(os.path.dirname(__file__), "model", "match_model.joblib"))

DEFAULT_FEATURES = [
    "distance_km",
    "available_capacity_tons",
    "cargo_weight_tons",
    "time_gap_hours",
    "route_similarity",
    "capacity_fit",
    "driver_rating",
    "on_time_rate",
    "cancel_rate",
    "route_deviation_rate",
    "price_per_km_ton",
]

# Optional features get neutral defaults when the caller omits them.
OPTIONAL_DEFAULTS = {
    "route_similarity": 1.0,
    "route_deviation_rate": 0.03,
    "price_per_km_ton": 1.0,
}


@lru_cache(maxsize=1)
def load_model():
    artifact = joblib.load(MODEL_PATH)
    if isinstance(artifact, dict) and "model" in artifact:
        return artifact["model"], artifact.get("features", DEFAULT_FEATURES), artifact.get("backend", "unknown")
    return artifact, DEFAULT_FEATURES, "bare-estimator"


def hard_filter(candidate: dict) -> tuple[bool, str | None]:
    """Business-rule gate before any ML scoring. Returns (eligible, reject_reason)."""
    if candidate.get("cargo_weight_tons", 0) > candidate.get("available_capacity_tons", 0):
        return False, "insufficient_capacity"
    if candidate.get("time_gap_hours", 0) > candidate.get("max_time_gap_hours", 12):
        return False, "timing_incompatible"
    if candidate.get("route_similarity", 1.0) < candidate.get("min_route_similarity", 0.5):
        return False, "route_mismatch"
    if candidate.get("truck_status", "available") not in ("available", "returning"):
        return False, "truck_unavailable"
    return True, None


def _reasons(row: dict, score: float) -> list[str]:
    """Human-readable reason chips (no model jargon)."""
    out = []
    if row.get("route_similarity", 1.0) >= 0.9:
        out.append("Route aligned")
    if row.get("time_gap_hours", 99) <= 2:
        out.append("Timing aligned")
    if row.get("available_capacity_tons", 0) >= row.get("cargo_weight_tons", 0):
        out.append("Capacity available")
    if row.get("driver_rating", 0) >= 4.4 and row.get("on_time_rate", 0) >= 0.9:
        out.append("Reliable driver")
    if not out:
        out.append("Meets basic requirements")
    return out


def score_candidates(candidates: list[dict], top_k: int = 5) -> dict:
    """
    candidates: list of feature dicts (one per truck-cargo pair).
    Returns eligible candidates ranked by match_score, plus rejects with reasons.
    """
    model, features, backend = load_model()

    eligible, rejected = [], []
    for c in candidates:
        ok, why = hard_filter(c)
        (eligible if ok else rejected).append(c if ok else {**c, "reject_reason": why})

    ranked = []
    if eligible:
        rows = []
        for c in eligible:
            row = {f: c.get(f, OPTIONAL_DEFAULTS.get(f)) for f in features}
            missing = [f for f, v in row.items() if v is None]
            if missing:
                raise ValueError(f"Missing required features {missing} for candidate {c.get('truck_id', '?')}")
            rows.append(row)
        X = pd.DataFrame(rows, columns=features)
        scores = model.predict_proba(X)[:, 1]
        for c, s in zip(eligible, scores):
            ranked.append(
                {
                    **{k: c[k] for k in ("truck_id", "cargo_id") if k in c},
                    "match_score": round(float(s), 4),
                    "reasons": _reasons(c, float(s)),
                }
            )
        ranked.sort(key=lambda r: r["match_score"], reverse=True)

    return {
        "model_backend": backend,
        "recommendations": ranked[:top_k],
        "eligible_count": len(eligible),
        "rejected_count": len(rejected),
        "rejected": [{"truck_id": r.get("truck_id"), "reason": r["reject_reason"]} for r in rejected],
    }


def score_one(features_dict: dict) -> float:
    """Score a single pair — powers POST /predict-match."""
    model, features, _ = load_model()
    row = {f: features_dict.get(f, OPTIONAL_DEFAULTS.get(f)) for f in features}
    missing = [f for f, v in row.items() if v is None]
    if missing:
        raise ValueError(f"Missing required features: {missing}")
    X = pd.DataFrame([row], columns=features)
    return round(float(model.predict_proba(X)[0, 1]), 4)
