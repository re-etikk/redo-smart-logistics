# REDO — Smart Backhaul Network

> **Bharosa Wahi, Deal Sahi.** Shipper (blue), Truck Owner (yellow) and Admin (ops) consoles on one Supabase-backed platform.

**Make every return trip earn.**

A full-stack logistics marketplace matching trucks with unused *return-trip* capacity to SMEs
shipping partial (1–3 T) loads on the same corridor. Built for Smart India Hackathon.

> We are not finding a truck for cargo. We are finding cargo for trucks that are already going there.

## Stack
| Layer | Tech |
|---|---|
| Frontend | React 18 + TypeScript + Tailwind + React Router + Leaflet/OSM |
| Auth / DB / Storage / Realtime | Supabase (real auth sessions, Postgres + RLS, private buckets, realtime tracking) |
| Backend | Node/Express — validation, authorization, hard match filters, booking state machine, impact engine, notifications, ML orchestration |
| ML | Python FastAPI + gradient-boosted match model (`ml-service/model/match_model.joblib`) |

## Repository
```text
redo/
├── frontend/     # TS React app (all screens, protected role routes)
├── backend/      # Express API + unit tests + seed script (demo auth users)
├── ml-service/   # FastAPI, recommend.py, train_model.py, model/, tests/, data/ (seed/training CSVs)
├── supabase/     # migrations/0001_schema.sql (spec §51) + 0002_extensions_rls.sql (trips, RLS, buckets, realtime)
└── docs/         # SETUP.md · ARCHITECTURE.md · API_CONTRACT.md · MODEL_NOTE.md
```

## Quick start
Follow **docs/SETUP.md** (Supabase project → migrations → backend `.env` + `npm run seed` → start backend, ML, frontend).
Demo accounts `demo.owner@redo.app` / `demo.sme@redo.app` are **real seeded Supabase Auth users**; the password is whatever
`DEMO_PASSWORD` you configure — nothing is hardcoded.

## Honesty by design
- Match scores come only from the ML service scoring **live database candidates**. ML down → `MATCHING_UNAVAILABLE` + Retry; never fabricated percentages.
- Tracking is simulated for demos and is stored (`is_simulated`) and labeled ("Demo tracking · Simulated location").
- KYC uses manual/demo verification, clearly labeled; no fake DigiLocker; only masked document references are stored.
- Impact figures are computed per completed booking and labeled as estimates.
- Consolidation is deterministic bin-packing, not ML.

## Tests
```bash
cd backend && npm test                                  # 8 tests: state machine, filters, impact/consolidation
cd ml-service && python -m unittest discover -s tests   # 7 tests: reject reasons, ranking, score bounds
```
See docs/SETUP.md §6 for the end-to-end acceptance run (spec §70).
