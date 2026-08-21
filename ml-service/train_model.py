"""
Redo — Smart Backhaul Network
Train the truck<->cargo match-ranking model.

Prefers XGBoost when installed. Falls back to scikit-learn's
HistGradientBoostingClassifier (same gradient-boosted-trees family) when
XGBoost is unavailable, so the pipeline runs in restricted environments.
The saved artifact is a dict:

    {
      "model":        fitted classifier with predict_proba,
      "features":     ordered feature list (the API contract),
      "backend":      "xgboost" | "sklearn-hgb",
      "metrics":      evaluation summary,
      "trained_at":   ISO timestamp,
    }

recommend.py / api.py only require `model` + `features`, so a real
XGBoost `match_model.joblib` saved with the same dict shape (or even a
bare estimator — recommend.py handles that too) drops in unchanged.

Usage:
    python train_model.py [--data data/historical_matches.csv] [--out match_model.joblib]
"""

import argparse
import json
from datetime import datetime, timezone

import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import ndcg_score, roc_auc_score
from sklearn.model_selection import GroupKFold, GroupShuffleSplit

# Ordered feature contract — keep in sync with recommend.py / api.py.
FEATURES = [
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
TARGET = "successful_match"
GROUP = "cargo_id"


def make_model():
    """Return (estimator, backend_name). XGBoost preferred, sklearn fallback."""
    try:
        from xgboost import XGBClassifier

        return (
            XGBClassifier(
                n_estimators=300,
                max_depth=5,
                learning_rate=0.06,
                subsample=0.9,
                colsample_bytree=0.9,
                eval_metric="auc",
                n_jobs=-1,
                random_state=42,
            ),
            "xgboost",
        )
    except ImportError:
        from sklearn.ensemble import HistGradientBoostingClassifier

        return (
            HistGradientBoostingClassifier(
                max_iter=300,
                max_depth=5,
                learning_rate=0.06,
                l2_regularization=0.1,
                random_state=42,
            ),
            "sklearn-hgb",
        )


def ranking_metrics(df: pd.DataFrame, scores: np.ndarray, k: int = 3):
    """Precision@1 and NDCG@k computed per cargo group, averaged."""
    tmp = df[[GROUP, TARGET]].copy()
    tmp["score"] = scores
    p1, ndcgs = [], []
    for _, g in tmp.groupby(GROUP):
        if g[TARGET].sum() == 0 or len(g) < 2:
            continue
        g = g.sort_values("score", ascending=False)
        p1.append(float(g[TARGET].iloc[0]))
        ndcgs.append(
            ndcg_score(
                g[TARGET].to_numpy().reshape(1, -1),
                g["score"].to_numpy().reshape(1, -1),
                k=min(k, len(g)),
            )
        )
    return float(np.mean(p1)), float(np.mean(ndcgs))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default="data/historical_matches.csv")
    ap.add_argument("--out", default="model/match_model.joblib")
    args = ap.parse_args()

    df = pd.read_csv(args.data)
    X, y, groups = df[FEATURES], df[TARGET], df[GROUP]

    # ----- 5-fold grouped CV (no cargo leaks across folds) -----
    cv_aucs = []
    for tr, va in GroupKFold(n_splits=5).split(X, y, groups):
        m, _ = make_model()
        m.fit(X.iloc[tr], y.iloc[tr])
        cv_aucs.append(roc_auc_score(y.iloc[va], m.predict_proba(X.iloc[va])[:, 1]))
    cv_mean, cv_std = float(np.mean(cv_aucs)), float(np.std(cv_aucs))

    # ----- Holdout for ranking metrics -----
    tr, te = next(GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42).split(X, y, groups))
    m_hold, _ = make_model()
    m_hold.fit(X.iloc[tr], y.iloc[tr])
    hold_scores = m_hold.predict_proba(X.iloc[te])[:, 1]
    hold_auc = float(roc_auc_score(y.iloc[te], hold_scores))
    p_at_1, ndcg_at_3 = ranking_metrics(df.iloc[te], hold_scores, k=3)

    # ----- Final model on all data -----
    model, backend = make_model()
    model.fit(X, y)

    metrics = {
        "backend": backend,
        "cv_roc_auc_mean": round(cv_mean, 4),
        "cv_roc_auc_std": round(cv_std, 4),
        "holdout_roc_auc": round(hold_auc, 4),
        "holdout_precision_at_1": round(p_at_1, 4),
        "holdout_ndcg_at_3": round(ndcg_at_3, 4),
        "n_rows": int(len(df)),
        "n_cargo_groups": int(groups.nunique()),
    }
    print(json.dumps(metrics, indent=2))

    joblib.dump(
        {
            "model": model,
            "features": FEATURES,
            "backend": backend,
            "metrics": metrics,
            "trained_at": datetime.now(timezone.utc).isoformat(),
        },
        args.out,
    )
    print(f"Saved -> {args.out}")


if __name__ == "__main__":
    main()
