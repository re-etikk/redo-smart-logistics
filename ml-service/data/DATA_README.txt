BackhaulX ML starter dataset

IMPORTANT: This is SYNTHETIC data for prototyping/model development.
It is NOT real customer, truck, GPS, or transaction data.

Files:
- historical_matches.csv: 12,000 synthetic candidate truck-cargo pairs + successful_match label
- trucks.csv: synthetic truck/driver operational features
- cargo_requests.csv: synthetic SME shipment requests

Suggested target:
- successful_match for classification
- or rank trucks per cargo_id for recommendation

Suggested first metrics:
- Precision@K / Recall@K / NDCG@K
- Also ROC-AUC for the binary baseline
