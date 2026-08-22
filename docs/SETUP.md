# Redo — Setup Guide

Three services + Supabase. Order matters the first time.

## 0. Prerequisites
- Node 20+ · Python 3.11+ · a free [Supabase](https://supabase.com) project

## 1. Supabase
1. Create a project. Note **Project URL**, **anon key**, **service_role key** (Settings → API).
2. SQL Editor → run `supabase/migrations/0001_schema.sql`, then `0002_extensions_rls.sql`, then `supabase/migrations/0003_transport_logistics.sql`.
   (0002 creates the trips table, RLS policies, the four storage buckets and realtime publication.)
3. Auth → Providers → Email: for local demos, disable "Confirm email" so signups get a session immediately
   (or keep it on and confirm via the emails Supabase sends).

## 2. Backend
```bash
cd backend
cp .env.example .env        # fill SUPABASE_URL, SERVICE_ROLE_KEY, ANON_KEY, DEMO_PASSWORD
npm install
npm run seed                # creates REAL demo auth users + demo truck/trip + sample fleet
npm run dev                 # http://localhost:8000/health
```

## 3. ML service
```bash
cd ml-service
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn api:app --port 8001                          # http://localhost:8001/health
```
`model/match_model.joblib` ships in the repo (see MODEL_NOTE.md for provenance).
To retrain: `python train_model.py` (auto-uses XGBoost if installed).

## 4. Frontend
```bash
cd frontend
cp .env.example .env        # VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY, VITE_API_URL
npm install
npm run dev                 # http://localhost:5173
```

## 5. Demo accounts (real Supabase Auth users, created by the seed)
| Role | Email | Password |
|---|---|---|
| Truck owner | demo.owner@redo.app | the `DEMO_PASSWORD` you set |
| SME | demo.sme@redo.app` and admin `admin@redo.app | the `DEMO_PASSWORD` you set |

## 6. End-to-end acceptance run (spec §70)
1. Fresh browser → sign up as SME → onboarding → **Post cargo** (Mumbai → Delhi, 1.5 T, pickup near the demo trip departure).
2. Recommendations load from backend + ML (the demo truck should rank on top). Open the match → **Request booking**.
3. Second browser/incognito → sign in as `demo.owner@redo.app` → Bookings → **Accept**.
4. SME confirms → owner marks ready → uploads **pickup proof** → picked up → in transit.
5. Open **Tracking** → *Simulate movement* (events are stored flagged `is_simulated` and labeled in the UI).
6. Owner uploads **delivery proof** → delivered. SME confirms receipt → booking **completed**.
7. Impact record is generated automatically; both sides can now **rate**. Check the Impact page.

## 7. Tests
```bash
cd backend && npm test                       # state machine, filters, impact (no network needed)
cd ml-service && python -m unittest discover -s tests
```

## Troubleshooting
- **Matching service is temporarily unavailable** → the ML service isn't running on `ML_SERVICE_URL`. This is intentional honesty: the app never invents scores.
- **PROFILE_MISSING** after signup → the `POST /auth/profile` call failed; re-submit from the signup screen.
- Diagnostics (dev builds only): `http://localhost:5173/dev/diagnostics`.
