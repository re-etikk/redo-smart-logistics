# REDO — Transport & Logistics
## Complete Technical Documentation & Interview Preparation Guide

> **Bharosa Wahi, Deal Sahi.** A full-stack logistics marketplace that matches trucks running
> empty on their **return trips** with SMEs shipping partial (1–3 T) loads on the same corridor.
>
> **The one-liner for interviews:** *"We are not finding a truck for cargo. We are finding cargo
> for trucks that are already going there."* Studies attributed to NITI Aayog estimate a large
> share of truck-kilometres in India run empty or under-utilised (commonly cited at 28–43%).
> REDO monetises exactly those wasted kilometres.

---

## Table of Contents

1. [Problem & Solution](#1-problem--solution)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack — What, Why, and What We Rejected](#3-tech-stack)
4. [Machine Learning — Deep Dive](#4-machine-learning--deep-dive)
5. [Backend — Deep Dive](#5-backend--deep-dive)
6. [Database & Auth — Deep Dive](#6-database--auth--deep-dive)
7. [Frontend — Deep Dive](#7-frontend--deep-dive)
8. [Security & Honesty-by-Design](#8-security--honesty-by-design)
9. [Key Numbers Cheat Sheet](#9-key-numbers-cheat-sheet)
10. [Rapid-Fire Interview Q&A](#10-rapid-fire-interview-qa)
11. [2-Minute Demo Script](#11-2-minute-demo-script)

---

## 1. Problem & Solution

**Problem.** A truck delivers Mumbai → Delhi and returns empty because the owner has no way to
find a small load going back. Meanwhile an SME in Mumbai with 2 tonnes of textiles for Delhi
pays full-truck rates or waits days for an aggregator. Both sides lose: the owner burns diesel
for zero revenue; the SME overpays; the country burns fuel moving air.

**Solution.** A three-sided marketplace:

| Role | What they do | Console theme |
|---|---|---|
| **Truck Owner** | Lists trucks, posts return trips with spare capacity, accepts loads, uploads KYC docs, tracks earnings | Yellow |
| **Shipper (SME)** | Books shipments (FTL or part-load), gets ML-ranked truck matches, tracks delivery, receives GST invoices | Blue |
| **Admin (Ops)** | Platform stats, user management, KYC document review (verify/reject with owner notification) | Dark |

The core intelligence is a **two-stage matching engine**: deterministic hard filters (capacity,
timing, route, availability) followed by an **ML ranking model** that scores every eligible
truck–cargo pair and returns the top-K with human-readable reason chips.

---

## 2. System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│  FRONTEND — React 18 + TypeScript + Vite + Tailwind (SPA, Vercel)  │
│  Role-themed consoles · Leaflet maps · Supabase JS client          │
└──────────────┬────────────────────────────────┬────────────────────┘
               │ REST (JWT in Authorization)    │ Auth / Realtime / Storage
               ▼                                ▼
┌──────────────────────────────┐   ┌────────────────────────────────┐
│  BACKEND — Node/Express      │   │  SUPABASE                      │
│  · JWT verify middleware     │◄──┤  · Postgres + Row Level Sec.   │
│  · Booking state machine     │   │  · Auth (email + Google OAuth) │
│  · Hard match filters        │   │  · Private storage buckets     │
│  · Impact / invoice engines  │   │  · Realtime (tracking channel) │
│  · Admin / support / rates   │   └────────────────────────────────┘
└──────────────┬───────────────┘
               │ POST /rank-candidates (8s timeout)
               ▼
┌──────────────────────────────┐
│  ML SERVICE — Python FastAPI │
│  · hard_filter (rule gate)   │
│  · Gradient-boosted ranker   │
│  · Reason-chip generator     │
│  · match_model.joblib        │
└──────────────────────────────┘
```

**End-to-end booking flow (memorise this — interviewers love flow questions):**

1. Shipper completes the 4-step Book Shipment wizard → `POST /cargo` creates a `cargo_requests` row.
2. Frontend calls `GET /recommendations/trucks/:cargoId`. Backend pulls **live** trucks + open
   return trips from Postgres, computes pair features, applies **hard filters**, then POSTs the
   survivors to the ML service `/rank-candidates`.
3. ML returns `match_score` (0–1) + reason chips per candidate. Backend enriches with price
   estimate (`distance × tonnes × owner's per-km-per-tonne rate`) and ETA, returns top-K.
4. Shipper picks a truck → `POST /bookings` (status `pending`). Owner gets a notification.
5. Status walks the **state machine**: `pending → accepted (owner) → confirmed (shipper) →
   pickup_ready → picked_up (needs pickup proof) → in_transit → delivered (needs delivery
   proof) → completed (shipper)`. Every transition is validated server-side for role + proof.
6. On `completed`: impact record computed (fuel/CO₂ saved, SME saving), **GST invoice
   auto-generated** (base + 18%), owner earnings updated, both sides can rate each other.

---

## 3. Tech Stack

| Layer | Choice | Why | Alternatives considered & why rejected |
|---|---|---|---|
| Frontend | React 18 + TypeScript + Vite | Huge ecosystem, typed props catch bugs pre-runtime, Vite dev server is instant | Next.js — SSR adds complexity with zero benefit for a logged-in dashboard app; Angular — heavier learning curve, slower iteration for a hackathon |
| Styling | Tailwind CSS + CSS variables | Design tokens (`--accent`) let three role themes share one component library | Styled-components/MUI — runtime CSS-in-JS overhead; MUI look is hard to de-genericise |
| Maps | Leaflet + OpenStreetMap | Free, no API key, no billing surprises | Google Maps JS — needs billing account; Mapbox — token management for a demo |
| Backend | Node.js + Express | Minimal, explicit, same language as frontend; middleware model fits JWT-auth cleanly | NestJS — decorators/DI overkill at this size; Django — Python but we wanted JS for the API and Python isolated for ML; FastAPI for everything — we DID use it, but only where Python earns its place (ML) |
| DB/Auth | Supabase (managed Postgres) | Relational data (bookings join trucks join cargo) demands SQL; Auth + RLS + Storage + Realtime in one service saved days | Firebase — NoSQL makes relational queries (earnings joins, admin stats) painful; MongoDB — same relational objection; self-hosted Postgres + Passport.js — auth is exactly the thing you should not hand-roll in a weekend |
| ML serving | Python FastAPI | Python owns the ML ecosystem; FastAPI gives Pydantic validation + async + OpenAPI docs for free | Flask — no built-in validation; embedding the model in Node via ONNX — kills fast Python-side iteration on features |
| ML model | Gradient-boosted trees (XGBoost preferred, scikit-learn `HistGradientBoostingClassifier` fallback) | See §4 | See §4 — this question deserves its own section |

---

## 4. Machine Learning — Deep Dive

### 4.1 Problem framing (say this first in any ML interview)

We framed truck–cargo matching as **pointwise ranking via binary classification**:

- Each (truck, cargo) pair gets a feature vector.
- The model learns `P(successful_match = 1)` from historical pairs.
- For one cargo request, we score all eligible trucks and **sort by probability** — that IS the
  ranking, and the probability doubles as the "87% match" number the shipper sees.

**Why two stages (rules → ML) instead of pure ML?**

1. **Safety** — a model must never be able to recommend a physically impossible match
   (9 T cargo on a 4 T-free truck). Hard constraints belong in code, not in learned weights.
2. **Explainability** — a rejected truck gets an explicit reason (`insufficient_capacity`,
   `timing_incompatible`, `route_mismatch`, `truck_unavailable`), which ops and users can trust.
3. **Latency & cost** — filtering first means the model scores 10 candidates, not 10,000.

This mirrors real industrial recommender design (candidate generation → filtering → ranking).

### 4.2 The data — where it comes from (answer honestly)

> **Interview answer:** "There is **no public dataset** of Indian truck return-trip matching
> outcomes — this data is the moat of companies like BlackBuck. So for the prototype we
> **generated a synthetic dataset** with realistic structure, trained the pipeline on it, and
> designed the system so that **real outcome data replaces it with zero code changes**."

Details of the synthetic dataset (`ml-service/data/`):

- **12,000 candidate (truck, cargo) pairs** in `historical_matches.csv`, grouped by `cargo_id`
  (~each cargo has several candidate trucks — exactly the shape of real serving traffic).
- Feature values drawn from realistic distributions: truck capacities by body type (17FT/22FT/32FT),
  Indian corridor distances (Mumbai–Delhi 1,400 km etc.), pickup-hour patterns, driver ratings
  centred near 4.3 with variance, on-time rates 0.8–0.95.
- The **label** `successful_match` is generated as a *probabilistic* function of route similarity,
  time gap, capacity fit, price competitiveness and driver reliability **plus noise** — so the
  signal is learnable but not trivially separable (a model can't get AUC 0.99, just like reality).
- The file `data/DATA_README.txt` explicitly marks it as synthetic — no fake claims of real data.

**How real data flows in after launch (the feedback loop):**

Every booking outcome is a **free label**: `completed` → positive; `cancelled`/`disputed` after
match → negative; shown-but-not-booked → implicit negative. The backend already records all
features at recommendation time, so `train_model.py --data <real_export>.csv` retrains the same
pipeline. The saved artifact is a dict `{model, features, backend, metrics, trained_at}` — the
serving code reads the ordered `features` list from the artifact, so even a differently-trained
XGBoost model **drops in without touching serving code**.

### 4.3 The features (11, in fixed contract order)

| Feature | Why it matters |
|---|---|
| `distance_km` | Long lanes behave differently (pricing, tolerance for detour) |
| `available_capacity_tons` | Raw headroom on the return trip |
| `cargo_weight_tons` | Raw demand |
| `time_gap_hours` | Hours between truck departure and cargo pickup — the #1 practical dealbreaker |
| `route_similarity` | 0–1 corridor overlap between the truck's return leg and the cargo lane |
| `capacity_fit` | Ratio-style engineered feature: how snugly cargo fits free capacity (utilisation without overflow) |
| `driver_rating` | Reliability signal shippers care about |
| `on_time_rate` | Historical punctuality |
| `cancel_rate` | Historical flakiness (negative signal) |
| `route_deviation_rate` | Does the driver actually stay on route |
| `price_per_km_ton` | Owner's asking rate — price competitiveness of this specific match |

Engineered features (`capacity_fit`, `route_similarity`, `time_gap_hours`) are **pair features**
computed per candidate at serving time — a key design point: the model scores the *interaction*,
not the truck alone.

### 4.4 The model & why

**Chosen: gradient-boosted decision trees.** `train_model.py` prefers **XGBoost** when installed
and falls back to scikit-learn's **`HistGradientBoostingClassifier`** (same algorithm family) so
the pipeline runs in restricted environments. Typical settings: ~300 trees, learning rate 0.05,
limited depth, early-stopping-style regularisation.

**Why gradient boosting for this problem (the 4-point interview answer):**

1. **Tabular data is GBT territory.** On small/medium structured datasets, boosted trees beat
   neural networks consistently (this is well-documented empirically). Our data: 12k rows × 11
   numeric features — squarely in that zone.
2. **Non-linear interactions for free.** "High rating matters *more* when time-gap is small" is
   a tree split, no manual feature crosses needed. Logistic regression would need us to hand-craft
   every interaction.
3. **Well-calibrated-enough probabilities** out of `predict_proba` — we display the score as a
   match percentage, so calibration matters, and boosted trees + log-loss give sane probabilities.
4. **Fast, dependency-light inference.** Millisecond scoring per batch on CPU; the sklearn
   fallback needs nothing beyond scikit-learn (and it handles NaNs natively — useful for new
   trucks with null reputation).

**Alternatives and why we rejected them (know all of these):**

| Alternative | Why not (our reasoning) |
|---|---|
| **Logistic regression** | We use it mentally as the baseline. Linear — misses interactions (rating × time-gap, capacity × distance). Fine as a first benchmark; measurably worse ranking on held-out groups. |
| **Random forest** | Comparable family, but boosting typically edges it on accuracy and produces better-ordered probabilities on this size of data; also larger artifacts. |
| **XGBoost / LightGBM as hard dependency** | We actually *prefer* XGBoost — the trainer uses it when available. We made sklearn the fallback so the whole pipeline runs in constrained environments (no compiled wheels). The artifact contract makes them interchangeable. |
| **Neural network (MLP / deep ranking)** | 12k rows, 11 features — a NN adds tuning burden, GPU pressure, worse interpretability, and no accuracy win at this scale. Wrong tool. |
| **Collaborative filtering / matrix factorisation** | Fatal **cold-start** problem: new trucks and new shippers join daily with zero interaction history. Our content-based features (capacity, route, timing) work from the very first minute. CF becomes useful later as *additional* features, not as the core. |
| **Learning-to-rank (pairwise/listwise, e.g. LambdaMART)** | Legitimate upgrade path. We chose **pointwise** because (a) it's simpler to train and debug in hackathon time, (b) the calibrated probability doubles as the user-facing match %, which pairwise losses don't give directly. With real click/booking logs, moving to LambdaMART on the same features is the natural v2. |
| **Rules only, no ML** | Rules can filter but can't *weigh* trade-offs (slightly worse timing vs much better rating?). The learned ranker encodes those trade-offs from outcomes. |

### 4.5 Training & evaluation (this section wins interviews)

```
python train_model.py --data data/historical_matches.csv --out model/match_model.joblib
```

- **GroupKFold(5) cross-validation grouped by `cargo_id`.** This is the single most important
  methodological decision: candidates for the *same cargo* share cargo features, so a random
  row-level split would leak information from train to validation and **inflate AUC**. Grouped
  splits guarantee every cargo (with all its candidate trucks) lives entirely in one fold.
- **Holdout (GroupShuffleSplit, 20%)** for ranking metrics computed per cargo group:
  - **Precision@1 = 0.78** — for 78% of shipments, the top-ranked truck was the truck that
    would have actually worked. This is the money metric: the UI shows the top card first.
  - **NDCG@3 = 0.909** — the top-3 list is ordered nearly ideally.
  - **ROC-AUC ≈ 0.70 (CV mean, ±0.013 std)** — honest, deliberately noisy-realistic signal.
- **Why ranking metrics over accuracy?** Class imbalance makes accuracy meaningless (predicting
  "no match" for everything scores high). We care about *which truck is shown first*, so P@K and
  NDCG@K are the primary metrics; AUC is a sanity check on the underlying classifier.
- **Final model** is refit on all data after evaluation; metrics + timestamp are stored inside
  the artifact for auditability.

### 4.6 Challenges we faced (real answers for "what problems did you hit?")

1. **Label leakage via grouped structure.** First naive random split gave suspiciously high AUC;
   switching to GroupKFold by `cargo_id` dropped it to honest levels. Lesson: *how you split
   matters more than which model you pick.*
2. **Cold-start trucks.** A brand-new truck has no rating/on-time history. We refused to
   fabricate reputation (early schema had `default 4.0` — we removed it in migration 0004). Fix:
   columns are nullable; the **UI shows "New"**; the ML uses documented **neutral priors**
   (4.0 / 0.85 / 0.05) *only inside the scoring payload*, never shown to users.
3. **Class imbalance.** Most candidate pairs don't convert. Handled by evaluating with ranking
   metrics and monitoring per-group behaviour rather than chasing accuracy.
4. **Synthetic-to-real gap.** We can't claim real-world performance. Mitigation: the retraining
   pipeline is data-agnostic, the feature contract is stored in the artifact, and every booking
   generates labelled data from day one.
5. **Serving reliability.** If the ML service is down, the backend returns HTTP 503
   `MATCHING_UNAVAILABLE` and the UI shows a Retry state. We **never** fall back to fake or
   random scores — an explicit product decision (trust > appearing smart).
6. **Feature-order fragility.** Early bug: training and serving disagreed on column order. Fix:
   the ordered feature list ships *inside* the joblib artifact and serving reads it from there.

---

## 5. Backend — Deep Dive

### 5.1 Structure

```
backend/src/
├── index.js                # Express app, CORS, router mounting
├── middleware/
│   ├── auth.js             # Verifies Supabase JWT, loads profile, attaches req.user/req.profile
│   └── error.js            # apiError(status, CODE, message) + single error envelope {error, message}
├── services/
│   ├── bookingMachine.js   # canTransition(from, to, role, proofs) — the state machine
│   ├── matching.js         # hard filters, corridor distances, price & ETA estimates, ML payload
│   ├── impact.js           # fuel/CO₂/savings formulas (labeled estimates)
│   ├── consolidation.js    # best-fit-decreasing bin packing (deterministic, NOT ML)
│   ├── ml.js               # calls FastAPI /rank-candidates, 8s timeout, 503 on failure
│   └── notifications.js    # notification row inserts
├── routes/
│   ├── trucks.js  cargo.js  recommendations.js  bookings.js
│   ├── extras.js           # addresses, support tickets, rate cards, invoices, earnings, reviews
│   ├── admin.js            # role-gated ops console: stats, users, KYC verify/reject
│   └── misc.js             # health, profile, tracking, proofs, ratings, impact, notifications
└── scripts/seed.js         # real Supabase Auth demo users; synthetic trucks only if SEED_SYNTHETIC=1
```

### 5.2 The booking state machine (know this cold)

10 statuses: `pending, accepted, confirmed, pickup_ready, picked_up, in_transit, delivered,
completed, cancelled, disputed`.

Rules enforced in `canTransition` (pure function → unit-testable):

- **Role gates**: only the owner can `accept`; only the shipper can `confirm` and `complete`.
- **Proof gates**: `picked_up` requires an uploaded pickup proof; `delivered` requires delivery
  proof. Proof rows are unique per (booking, type) — idempotent uploads.
- **Single mutation path**: `PATCH /bookings/:id/status` is the *only* way status changes; every
  transition writes a `booking_events` audit row.
- **Owner-initiated flow**: when an owner accepts an open load (`POST /bookings` with
  `owner_initiated: true`), the booking is created directly at `accepted` (the owner's yes is
  implicit) with an audit event — same machine, no skipped validations, and the truck must belong
  to that owner.

**Why a state machine?** Booking lifecycles are exactly where race conditions and "status
teleporting" bugs live. Encoding legal transitions as data + one guard function means the
whole lifecycle is testable in milliseconds without a database.

**Side effects on `completed`** (all idempotent): impact record upsert, cargo marked delivered,
**invoice auto-created** (`INV-<id8>`, base + 18% GST, unique per booking), notification sent.

### 5.3 Matching (deterministic half)

- **Hard filters** (mirrored in Python): capacity, time-gap ≤ 12 h, route similarity ≥ 0.5,
  truck availability — each with a machine-readable reject reason.
- **Pricing**: `distance_km × cargo_tons × price_per_km_ton` (the owner's own rate) — transparent
  and explainable, deliberately *not* an ML black box for v1 (spec choice: deterministic +
  explainable first).
- **Impact**: fuel saved = 0.28 L/km × distance (shared vs separate trip), CO₂ = 2.68 kg/L,
  SME saving modeled at 35% vs dedicated FTL — all surfaced as *labeled estimates*.

### 5.4 Security model

- Every route behind `requireAuth`: verifies the Supabase JWT with the Supabase admin client,
  loads the caller's profile, rejects unknown tokens.
- The backend uses the **service-role key** (server-side only, never shipped to the browser) and
  therefore re-implements authorization explicitly: ownership checks on every truck/cargo/booking
  mutation, role checks (`requireRole('truck_owner')`, admin gate middleware).
- The browser's direct Supabase access (tracking subscribe, KYC upload) is constrained by **RLS
  policies** — defense in depth: even a leaked anon key can only touch the caller's own rows.
- Admin endpoints double-gate: JWT valid **and** `profile.role === 'admin'`.

### 5.5 Testing & challenges

- `node --test`: 8 tests — every illegal state transition, all six filter reject reasons,
  impact/consolidation math. Pure functions made this trivial; that was intentional design.
- **Challenges faced:** (a) an `/earnings` bug where we filtered on a non-existent
  `bookings.truck_owner_id` column — fixed by joining through `trucks.owner_id`; teaches: always
  derive ownership through relations, don't denormalise casually. (b) Making completion side
  effects idempotent (upserts with unique constraints) so a double-click can't double-invoice.
  (c) Designing the owner-initiated booking path without duplicating the state machine.

---

## 6. Database & Auth — Deep Dive

### 6.1 Schema (4 migrations, run in order)

| Migration | Adds |
|---|---|
| `0001_schema.sql` | Core: `profiles`, `trucks`, `cargo_requests`, `bookings`, `kyc_verifications`, `digital_proof`, `tracking_events`, `impact_records`, `ratings`, `notifications` |
| `0002_extensions_rls.sql` | `truck_trips` (return legs), `booking_events` (audit), RLS policies, private storage buckets (`kyc-documents`, `pickup-proofs`, `delivery-proofs`), realtime publication |
| `0003_transport_logistics.sql` | `admin` role, `addresses`, `support_tickets`/`support_messages`, `rate_cards` (seeded FTL lanes), `invoices` |
| `0004_real_reputation.sql` | Drops fake reputation defaults; nullable rating columns; nulls out never-rated trucks |

Plus `supabase/cleanup_synthetic.sql` — one-shot script that purges all `SEED-` synthetic
marketplace data from an existing DB so only real user-created records remain.

### 6.2 Auth flows (three, all real — no mock auth anywhere)

1. **Email + password (confirmation OFF)** — demo mode: signup → immediate session → profile
   created via API → onboarding.
2. **Email + password (confirmation ON)** — production mode: signup returns *no session*; the app
   shows a "Confirm your email" screen, stashes the intended role locally, and after the user
   clicks the link and signs in, **`/auth/complete`** creates the profile automatically. Login
   surfaces the *real* error ("Email not confirmed" ≠ "wrong password") with a **Resend
   confirmation** action — this distinction fixed a real bug where manual login silently failed
   while Google worked.
3. **Google OAuth** — `signInWithOAuth` redirects back to `/auth/complete`; OAuth users have no
   profile row yet, so they pick Shipper/Owner once and continue to onboarding. `Protected`
   routes send any profile-less session to `/auth/complete` (previously they bounced to the
   login page in a loop — the classic OAuth bootstrap bug, worth mentioning as a war story).

---

## 7. Frontend — Deep Dive

### 7.1 Architecture

```
frontend/src/
├── App.tsx                  # Router: public, onboarding, role-gated + shared routes, legacy redirects
├── hooks/useAuth.tsx        # AuthProvider (session+profile context) + <Protected role=...>
├── components/
│   ├── Layout.tsx           # AppShell: header (wallet, bell, avatar), role sidebar, mobile drawer
│   ├── Logo.tsx             # Yellow/black R mark
│   └── ui.tsx               # Design system: Button, Card, Badge, StatCard, Tabs, Rating, Toast…
├── lib/                     # supabase client, types, authHelpers (Google + pending profile), pricing
├── services/api.ts          # fetch wrapper: attaches JWT, parses {error,message}, throws ApiError
└── pages/
    ├── auth/                # Login, SignUp, Forgot, Complete (OAuth/confirm bootstrap)
    ├── onboarding/          # Owner (5-step: truck + return trip), Sme (business profile)
    ├── sme/                 # Dashboard, BookShipment (4-step wizard), Recommendations
    ├── owner/               # Dashboard, MyTrucks, AvailableLoads, Earnings, Trips, Reviews
    ├── admin/               # Dashboard, Users, Kyc
    └── shared               # Bookings, BookingDetail, Tracking (Leaflet), Impact, Invoices,
                             # Addresses, RateCard, Support, Verification(Documents), Profile, Notifications
```

### 7.2 Key design decisions

- **State management: React Context only, no Redux.** The only truly global state is
  session + profile. Everything else is server state fetched per page. Redux would be ceremony
  without benefit; if server-state caching grows, TanStack Query is the upgrade, not Redux.
- **Role theming with CSS variables.** One component library; the shell sets `.theme-shipper`
  (blue) / `.theme-owner` (yellow) / `.theme-admin` (dark), and every `bg-accent` resolves via
  `rgb(var(--accent))`. Three products for the price of one design system.
- **Route protection as a component.** `<Protected role="sme">` handles: loading spinner → no
  session → login (with return path) → no profile → `/auth/complete` → incomplete onboarding →
  onboarding → wrong role → own dashboard. All routing policy in one place.
- **Honest empty/error states everywhere.** New accounts see genuinely empty dashboards with
  CTAs — no fabricated shipment history. ML outage renders an error card with Retry, never fake
  scores. Unrated trucks render a "New" badge, never an invented 4.0.
- **Maps**: Leaflet + OSM on the Tracking page; positions arrive via Supabase Realtime and are
  explicitly labeled "Demo tracking · Simulated location" when `is_simulated` is true.

### 7.3 Challenges faced

1. **OAuth profile bootstrap** (described in §6.2) — solved with `/auth/complete` + pending-profile
   handoff through localStorage.
2. **Session restore on refresh** — Supabase persists the session; the AuthProvider hydrates
   asynchronously, so `Protected` must render a spinner during `loading` instead of prematurely
   redirecting (a common flash-of-login bug).
3. **Distinguishing auth failure modes** — mapping Supabase error strings to actionable UI
   ("Email not confirmed" → resend button) instead of one generic "wrong password" message.
4. **Type-safe null reputation** — after migration 0004, `driver_rating` became `number | null`;
   TypeScript forced every display site to handle "New" explicitly. Types caught what tests missed.

---

## 8. Security & Honesty-by-Design

- JWT verified server-side on every request; service-role key never leaves the server.
- RLS as second defense layer for direct browser→Supabase access.
- Private storage buckets with per-user folder policies; only **masked** document references in DB.
- Match scores only ever come from the ML service scoring live DB candidates; outage → explicit
  503 + Retry, never fabricated numbers.
- KYC is manual/demo-labeled — we did **not** fake a DigiLocker integration.
- Impact numbers labeled as estimates with stated formulas.
- Payments are sandbox-labeled; no fake gateway success screens.
- Synthetic marketplace seed data is opt-in (`SEED_SYNTHETIC=1`) and purgeable (`cleanup_synthetic.sql`).

**Why this matters in an interview:** every "honest failure" decision is a system-design answer
about *trust as a product feature* — judges and interviewers probe exactly here.

---

## 9. Key Numbers Cheat Sheet

| Number | Meaning |
|---|---|
| **12,000** | Synthetic training pairs (grouped under ~cargo requests) |
| **11** | Features in the model contract |
| **0.70 ± 0.013** | 5-fold GroupKFold ROC-AUC (honest, noisy-realistic signal) |
| **0.78** | Precision@1 — top-ranked truck is the right one 78% of the time |
| **0.909** | NDCG@3 — near-ideal ordering of the top 3 |
| **10** | Booking statuses in the state machine |
| **6** | Hard-filter reject reasons |
| **8 + 7** | Backend unit tests + ML unit tests (all passing) |
| **8 s** | ML call timeout before honest 503 |
| **0.28 L/km, 2.68 kg CO₂/L, 35%** | Impact-engine constants (labeled estimates) |
| **18%** | GST applied on auto-generated invoices |
| **28–43%** | Commonly cited empty/under-utilised share of Indian truck-km (attributed to NITI Aayog studies) |

---

## 10. Rapid-Fire Interview Q&A

**Q. Walk me through what happens when a shipper books.**
A. Wizard → `POST /cargo` → recommendations endpoint pulls live trucks/trips → hard filters →
ML `/rank-candidates` → top-K with scores + reasons → shipper books → state machine to completion
→ impact + invoice + ratings. (Expand using §2.)

**Q. Why gradient boosting and not deep learning?**
A. 12k rows of tabular data with 11 numeric features — boosted trees dominate this regime:
better accuracy, no GPU, native NaN handling, millisecond CPU inference, calibrated-enough
probabilities we can show as match %. A NN buys nothing here except tuning pain.

**Q. Where did training data come from?**
A. Honest answer: synthetic, because no public Indian backhaul-outcome dataset exists. We
generated 12k pairs with realistic distributions and a noisy probabilistic label. The system is
built so real booking outcomes become labels and the identical pipeline retrains — the artifact
even carries its own feature contract so retrained models drop in.

**Q. How do you prevent evaluation from lying to you?**
A. GroupKFold by `cargo_id` — candidates of the same cargo never straddle train/validation, so
no leakage through shared cargo features. And we lead with ranking metrics (P@1, NDCG@3), not
accuracy, because of class imbalance.

**Q. Cold start?**
A. Content-based features work from minute one (capacity, route, timing need no history). New
trucks have *null* reputation — UI shows "New", ML uses documented neutral priors internally.
We explicitly removed fake default ratings from the schema.

**Q. ML service dies mid-demo. What happens?**
A. Backend returns 503 `MATCHING_UNAVAILABLE`; frontend shows an error card with Retry. We never
fabricate scores — trust is the product.

**Q. Why Supabase over Firebase?**
A. The domain is relational (bookings ⋈ trucks ⋈ cargo ⋈ ratings; earnings aggregations; admin
stats). Postgres + RLS fits; Firebase's document model fights every join. And we got Auth,
Storage, and Realtime from the same service.

**Q. Why is status change a single PATCH endpoint?**
A. One mutation path → one guard (`canTransition`) → impossible to skip role/proof checks; every
change audited in `booking_events`. State machines kill whole bug classes.

**Q. What was your hardest bug?**
A. Pick one with a lesson: (1) OAuth users looping back to login because no profile row existed —
fixed with an `/auth/complete` bootstrap step; (2) manual login "failing" while Google worked —
root cause was email-confirmation ON without SMTP, masked by a generic error message; fix was
surfacing the real error + resend action; (3) AUC inflation from ungrouped CV splits.

**Q. How would you scale matching to 100k trucks?**
A. Candidate generation narrows first (corridor + date index in SQL, or geo-hash buckets), hard
filters cut further, ML ranks only the shortlist. Add caching per corridor-hour, batch scoring,
and eventually a two-tower retrieval model for candidate generation — the current two-stage
design is already the right skeleton.

**Q. What would v2 ML look like?**
A. Real outcome labels → retrain; add implicit negatives (shown-not-booked); move pointwise →
LambdaMART for ranking loss; add price-elasticity and ETA models; feature store for freshness;
online metrics (booking-through rate of rank-1) as the true north star.

---

## 11. 2-Minute Demo Script

1. **Landing** (yellow/black, "Bharosa Wahi, Deal Sahi") — state the empty-km problem, one line.
2. **Shipper**: login → Book Shipment wizard (LTL, Mumbai → Delhi, 2 T) → live match list with
   scores + reason chips → open top match → book.
3. **Owner** (second browser): notification → accept → walk statuses; upload pickup proof
   (gate demo!) → in transit → tracking map (labeled simulated) → delivered with proof.
4. **Shipper**: complete → Impact card (fuel/CO₂/saving) → auto-generated GST invoice → rate the owner.
5. **Owner**: Earnings updated; Reviews shows the rating.
6. **Admin**: stats, then verify a pending KYC document → owner receives the notification live.
7. Close: "Every number you saw was computed — filters, ML scores, impact, invoices. Nothing was
   hardcoded; when a service is down we say so."

---

*Built for Smart India Hackathon. Stack: React 18 + TypeScript · Node/Express · Supabase
(Postgres/Auth/RLS/Storage/Realtime) · Python FastAPI · Gradient-boosted trees (XGBoost /
sklearn HGB).*
