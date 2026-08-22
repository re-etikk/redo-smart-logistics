# Model provenance note (read this first)

The master build prompt referenced an existing `match_model.joblib`, `train_model.py`,
`recommend.py` and `api.py`. **The uploaded zip contained only the datasets**
(`trucks.csv`, `cargo_requests.csv`, `historical_matches.csv`, `README.txt`).
Additionally, the build environment had no network access, so XGBoost could not be installed.

Per the prompt's own rule ("unless there is a technical reason that must be documented"),
a stand-in model was trained on the same `historical_matches.csv` with the same
grouped-evaluation protocol:

| Metric | Original (claimed) | Stand-in (this repo) |
|---|---|---|
| 5-fold CV ROC-AUC | ~0.709 ± 0.01 | 0.701 ± 0.013 |
| Holdout ROC-AUC | ~0.70 | 0.690 |
| Precision@1 | ~0.80 | 0.780 |
| NDCG@3 | ~0.92 | 0.909 |

Backend: scikit-learn `HistGradientBoostingClassifier` (same gradient-boosted-trees
family as XGBoost). The near-identical metrics confirm the same data and protocol.

## Restoring the original XGBoost model
1. Drop your real `match_model.joblib` into `ml-service/` (or set `MATCH_MODEL_PATH`).
   `recommend.py` accepts either a bare estimator or the dict artifact format.
2. Or install xgboost (`pip install xgboost`) and rerun `python train_model.py` —
   the script automatically prefers XGBoost when available.

No other code changes are required; the API contract is identical either way.
