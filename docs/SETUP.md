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


## v3.1 — Real-data & auth wiring notes

### Migrations to (re)run
Run `supabase/migrations/0004_real_reputation.sql` after 0003. For an **existing** database that
already has synthetic data, also run `supabase/cleanup_synthetic.sql` once — it deletes all
`SEED-…` trucks (and anything referencing them) and nulls fabricated reputation so new trucks
show **New** instead of an invented 4.0 rating.

### Seeding — real by default
`npm run seed` now creates ONLY the demo login accounts (owner / sme / admin) with the demo
truck + return trip. The 25 synthetic marketplace trucks are seeded **only** when you opt in:

    SEED_SYNTHETIC=1 npm run seed

### Email + password login
If "Confirm email" is ON in Supabase (Auth → Providers → Email) and SMTP is not configured,
signups never receive the link and can never log in — Google works, passwords don't.
Two correct setups:
1. Demo/judging: turn **Confirm email OFF**. Signup logs straight in.
2. Production-style: keep it ON and configure SMTP (Auth → SMTP settings). The app now shows a
   "Confirm your email" screen after signup, a **Resend confirmation** link on failed logins,
   and finishes profile setup automatically on `/auth/complete` after the first confirmed sign-in.

### Google sign-in
1. Supabase → Authentication → Providers → **Google** → enable, paste the OAuth Client ID/Secret
   from Google Cloud Console (OAuth consent screen + Web credentials).
2. In Google Cloud, add the redirect URI shown by Supabase (`https://<ref>.supabase.co/auth/v1/callback`).
3. Supabase → Authentication → **URL Configuration** → set Site URL to your deployed origin
   (e.g. `https://redo-smart-logistics.vercel.app`) and add `http://localhost:5173` plus the
   Vercel URL under Additional Redirect URLs.
Google users land on `/auth/complete`, pick Shipper/Truck Owner once, and continue to onboarding —
no fake pre-filled data anywhere.
