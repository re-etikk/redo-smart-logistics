# Architecture

```text
        React + TS + Tailwind (5173)
                  │  fetch + Supabase JWT
                  ▼
        Node/Express backend (8000)
        auth check · validation · hard filters
        booking state machine · impact · notifications
          │                    │
          │ service-role       │ POST /rank-candidates
          ▼                    ▼
     Supabase Postgres    FastAPI ML service (8001)
     (RLS + Storage +     HistGradientBoosting /
      Realtime)           XGBoost match model
          │
          ▼
     Realtime → tracking & notification UI
```

**Division of responsibility**
- Frontend never computes match scores and never sees the service-role key. It talks to Supabase directly only for: auth, its own RLS-protected reads, storage uploads (own folder), realtime subscriptions.
- Backend is the sole writer for bookings/status/proof metadata/impact — the state machine in `backend/src/services/bookingMachine.js` is the single source of truth and every transition is audited in `booking_events`.
- Matching is two-stage: deterministic hard filters (backend, live DB data) → ML ranking (`/rank-candidates`). If ML is down the API returns `MATCHING_UNAVAILABLE` and the UI shows Retry — no fallback scores.
- ML service is stateless for the primary path; the §28 register/recommend endpoints exist for the ML-team contract and integration tests.
- Consolidation is deterministic best-fit-decreasing (`consolidation.js`) and is never presented as ML.

**Honesty boundaries (enforced in code)**
- Tracking events default `is_simulated = true`; UI labels "Demo tracking / Simulated location".
- KYC: manual upload + `verification_source` (`manual_upload` / `demo`). No DigiLocker claims. Only masked references stored.
- Impact figures carry `is_estimated: true` and are labeled estimates in the UI.
