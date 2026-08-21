"""
Redo ML service — FastAPI (spec §28–30).

Endpoints:
  GET  /health
  POST /register/truck            in-memory registry (contract §28)
  POST /register/cargo
  GET  /recommend/trucks/{cargo_id}
  GET  /recommend/cargo/{truck_id}
  POST /rank-candidates           stateless ranking — the backend's primary path
  POST /predict-match             single-pair score

The backend orchestrates hard filtering against LIVE Supabase data and calls
/rank-candidates with feature payloads, so scoring always reflects current
application data — never CSV snapshots. The register/recommend endpoints
satisfy the §28 contract for direct use and for ML-team integration tests.

Run: uvicorn api:app --host 0.0.0.0 --port 8001
"""

from typing import Dict, List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

import recommend

app = FastAPI(title="Redo Match Service", version="2.0.0")

# ---------------- schemas ----------------

class PairFeatures(BaseModel):
    distance_km: float = Field(..., ge=0)
    available_capacity_tons: float = Field(..., ge=0)
    cargo_weight_tons: float = Field(..., ge=0)
    time_gap_hours: float = Field(..., ge=0)
    driver_rating: float = Field(..., ge=0, le=5)
    on_time_rate: float = Field(..., ge=0, le=1)
    cancel_rate: float = Field(..., ge=0, le=1)
    route_similarity: Optional[float] = Field(None, ge=0, le=1)
    capacity_fit: Optional[float] = None
    route_deviation_rate: Optional[float] = None
    price_per_km_ton: Optional[float] = None
    truck_id: Optional[str] = None
    cargo_id: Optional[str] = None
    truck_status: Optional[str] = "available"
    max_time_gap_hours: Optional[float] = 12
    min_route_similarity: Optional[float] = 0.5

    def to_dict(self) -> dict:
        d = self.model_dump(exclude_none=True)
        d.setdefault("capacity_fit", 1.0 if self.cargo_weight_tons <= self.available_capacity_tons else 0.0)
        return d


class RankRequest(BaseModel):
    candidates: List[PairFeatures]
    top_k: int = Field(5, ge=1, le=50)


class TruckReg(BaseModel):
    truck_id: str
    origin: str
    destination: str
    departure_iso: str
    available_capacity_tons: float
    driver_rating: float = 4.0
    on_time_rate: float = 0.85
    cancel_rate: float = 0.05
    route_deviation_rate: float = 0.03
    price_per_km_ton: float = 1.0
    status: str = "available"


class CargoReg(BaseModel):
    cargo_id: str
    origin: str
    destination: str
    distance_km: float
    cargo_weight_tons: float
    pickup_iso: str


# ---------------- in-memory registry (contract §28) ----------------
TRUCKS: Dict[str, TruckReg] = {}
CARGO: Dict[str, CargoReg] = {}


def _gap_hours(a_iso: str, b_iso: str) -> float:
    from datetime import datetime
    a = datetime.fromisoformat(a_iso.replace("Z", "+00:00"))
    b = datetime.fromisoformat(b_iso.replace("Z", "+00:00"))
    return abs((a - b).total_seconds()) / 3600


def _similarity(t: TruckReg, c: CargoReg) -> float:
    if t.origin == c.origin and t.destination == c.destination:
        return 1.0
    if t.destination == c.destination:
        return 0.75
    if t.origin == c.origin:
        return 0.7
    return 0.0


def _pair(t: TruckReg, c: CargoReg) -> dict:
    return {
        "truck_id": t.truck_id, "cargo_id": c.cargo_id,
        "distance_km": c.distance_km,
        "available_capacity_tons": t.available_capacity_tons,
        "cargo_weight_tons": c.cargo_weight_tons,
        "time_gap_hours": round(_gap_hours(t.departure_iso, c.pickup_iso), 2),
        "route_similarity": _similarity(t, c),
        "capacity_fit": 1.0 if c.cargo_weight_tons <= t.available_capacity_tons else 0.0,
        "driver_rating": t.driver_rating, "on_time_rate": t.on_time_rate,
        "cancel_rate": t.cancel_rate, "route_deviation_rate": t.route_deviation_rate,
        "price_per_km_ton": t.price_per_km_ton, "truck_status": t.status,
    }


# ---------------- endpoints ----------------

@app.get("/health")
def health():
    _, _, backend = recommend.load_model()
    return {"status": "ok", "model_backend": backend}


@app.post("/register/truck")
def register_truck(t: TruckReg):
    TRUCKS[t.truck_id] = t
    return {"registered": t.truck_id, "trucks": len(TRUCKS)}


@app.post("/register/cargo")
def register_cargo(c: CargoReg):
    CARGO[c.cargo_id] = c
    return {"registered": c.cargo_id, "cargo": len(CARGO)}


@app.get("/recommend/trucks/{cargo_id}")
def recommend_trucks(cargo_id: str, top_k: int = 5):
    c = CARGO.get(cargo_id)
    if not c:
        raise HTTPException(404, "cargo_id not registered")
    pairs = [_pair(t, c) for t in TRUCKS.values()]
    return {"request_id": cargo_id, **recommend.score_candidates(pairs, top_k=top_k)}


@app.get("/recommend/cargo/{truck_id}")
def recommend_cargo(truck_id: str, top_k: int = 5):
    t = TRUCKS.get(truck_id)
    if not t:
        raise HTTPException(404, "truck_id not registered")
    pairs = [_pair(t, c) for c in CARGO.values()]
    return {"request_id": truck_id, **recommend.score_candidates(pairs, top_k=top_k)}


@app.post("/predict-match")
def predict_match(pair: PairFeatures):
    try:
        return {"match_score": recommend.score_one(pair.to_dict())}
    except ValueError as e:
        raise HTTPException(422, str(e))


@app.post("/rank-candidates")
def rank_candidates(req: RankRequest):
    try:
        return recommend.score_candidates([p.to_dict() for p in req.candidates], top_k=req.top_k)
    except ValueError as e:
        raise HTTPException(422, str(e))
