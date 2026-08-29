# REDO Mobile — Architecture & Implementation Guide

Two Android apps (Rapido-style), **one platform**: the same Supabase database, the same
Express backend, and the same ML service that already power the website.

| App | Folder | For | Accent | Rapido analogy |
|---|---|---|---|---|
| **Redo** | `mobile/redo-customer` | Shippers (SMEs) | Blue | Rapido |
| **Redo Partner** | `mobile/redo-partner` | Truck owners/drivers | Yellow | Rapido Captain |

Tech: **React Native + Expo (TypeScript)** — same language as the website, so the API client,
types and booking logic are shared with the web app, and you can test on a phone in minutes
with Expo Go and build APKs in the cloud with EAS (no Android Studio required).

---

## 1. Architecture — how everything connects

```
┌─────────────┐   ┌──────────────────┐   ┌─────────────┐
│  WEBSITE     │   │  REDO (customer) │   │ REDO PARTNER │
│  React (TS)  │   │  Expo RN app     │   │ Expo RN app  │
└──────┬───────┘   └──────┬───────────┘   └──────┬───────┘
       │  same REST API + same Supabase Auth/Realtime/Storage
       ▼                  ▼                      ▼
┌──────────────────────────────────────────────────────────┐
│                BACKEND — Node/Express (one)              │
│  JWT verify · state machine · matching · earnings ·      │
│  invoices · admin · support · rates                      │
└───────────────┬──────────────────────────┬───────────────┘
                ▼                          ▼
        ┌──────────────┐          ┌──────────────────┐
        │   SUPABASE   │          │  ML SERVICE       │
        │  Postgres+RLS│          │  FastAPI + GBT    │
        │  Auth/Storage│          │  /rank-candidates │
        │  Realtime    │          └──────────────────┘
        └──────────────┘
```

**Key point for interviews:** the apps added **zero** new backend code. One account works on
web *and* mobile because auth is a Supabase session (JWT) — the app attaches the same
`Authorization: Bearer <token>` header the website does. A booking made in the app shows up on
the website instantly and vice-versa, because there is exactly one database.

### App internals (both apps share this shape)

```
mobile/redo-*/
├── App.tsx                    # Auth gate → bottom tabs + stack navigation
├── app.json                   # App identity, permissions, Google Maps key, env (extra)
└── src/
    ├── lib/
    │   ├── supabase.ts        # Supabase client with AsyncStorage session persistence
    │   ├── api.ts             # REST wrapper — same contract as the website
    │   ├── theme.ts           # Redo palette (blue accent customer / yellow partner)
    │   └── types.ts           # Booking/Cargo/Truck types + city coordinates
    ├── components/ui.tsx      # Card, Button, Badge, Stat, Input… (mini design system)
    └── screens/               # One file per screen (listed below)
```

### Feature parity with the website

| Website feature | Customer app | Partner app |
|---|---|---|
| Login / Signup (Supabase, confirm-email aware) | ✔ AuthScreens | ✔ AuthScreens |
| Book shipment | ✔ Home (map-first, Rapido style) | — |
| ML truck matches + reason chips + honest 503/Retry | ✔ Matches | — |
| My shipments/bookings + status | ✔ Shipments | ✔ Bookings |
| Booking detail + state-machine actions | ✔ (confirm, complete, cancel, rate) | ✔ (pickup_ready → picked_up → in_transit → delivered) |
| Digital proof (photo, GPS-stamped) | views result | ✔ camera/gallery → private bucket → `/proof` |
| Live tracking map | ✔ realtime subscriber (labeled if simulated) | ✔ **real GPS publisher** (`is_simulated:false`, every ~15 s) |
| Available loads + accept | — | ✔ Home (duty toggle like Captain) |
| Earnings | — | ✔ Earnings |
| My trucks (add/status) | — | ✔ Trucks + duty toggle |
| KYC documents | — | ✔ Documents |
| Reviews received | — | ✔ in Profile |
| Invoices (GST 18%) | ✔ Invoices tab | — |
| Rate card | ✔ RateCard | — |
| Addresses | ✔ Addresses | — |
| Notifications (+mark read) | ✔ | ✔ |
| Support tickets | ✔ | ✔ |

The Rapido magic moment: **partner shares real GPS → customer's tracking map moves live** —
via Supabase Realtime on `tracking_events`, no polling.

---

## 1.5 First-run experience (Rapido-style, both apps)

```
App open
  → Language selection (English / हिन्दी — persisted on device, whole app translates)
  → Location permission (with honest rationale; skippable, features degrade gracefully)
  → Login / Register (in the chosen language; confirm-email flow handled)
  → Onboarding
       Customer:  Business details (1 step)
       Partner:   Driver registration → Truck registration → Document uploads
                  (DL, RC, ID required; insurance/permit/fitness optional →
                   files go to the private KYC bucket, admin verifies from the web console)
  → Main app
```

Onboarding completion is the SAME `profiles.onboarding_complete` flag the website uses, so a
partner who finished setup on the web goes straight to the main app on mobile (and vice-versa).
There is **no on/off duty toggle** — a registered truck is discoverable by default, exactly like
the website; availability is managed from My Trucks if ever needed.

Adding a language = adding one column in `src/lib/i18n.tsx`.

## 2. Step-by-step implementation (do this in order)

### Step 0 — What you need
Node 18+, a phone with **Expo Go** installed (Play Store), your Supabase project (already set up
for the website), backend + ML service running.

### Step 1 — Configure both apps
Open `mobile/redo-customer/app.json` and `mobile/redo-partner/app.json`, edit `expo.extra`:

```json
"extra": {
  "SUPABASE_URL": "https://YOUR-PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ…your anon key…",
  "API_URL": "http://192.168.1.10:8000"
}
```

⚠️ **`API_URL` cannot be `localhost`** — the phone is a different machine. Use:
- your laptop's LAN IP (`ipconfig` / `ifconfig`, e.g. `http://192.168.1.10:8000`) with phone +
  laptop on the same Wi-Fi, **or**
- your deployed backend URL (Render/Railway) — best for demos.

Also make sure backend `CORS_ORIGIN` allows the app (or set it permissive for demo).

### Step 2 — Install & run (each app)
```bash
cd mobile/redo-customer
npm install
npx expo start
```
Scan the QR with Expo Go → the app opens on your phone. Repeat for `redo-partner`
(run on a second phone, or switch apps on one phone).

> Maps note: in **Expo Go on Android**, Google Maps renders without your own key.
> A key is only needed for standalone APK builds (Step 5).

### Step 3 — End-to-end test (the Rapido demo)
1. **Partner app**: language → permission → sign up → driver reg → truck reg → upload DL/RC/ID → main app.
2. **Customer app**: language → permission → sign up as shipper → business details → Home → pick cities/weight → *Find trucks* → see ML
   matches with % score → **Book**.
3. Partner: Bookings → open trip → (after customer confirms) *Reached pickup* → *Upload pickup
   proof* (photo) → *Start trip* → **Share live location (real GPS)**.
4. Customer: Shipment → **Track live** → watch the truck marker move on the map in realtime.
5. Partner: *Upload delivery proof & deliver* → Customer: *Mark completed* → rate ★ → Partner
   sees Earnings update + review; Customer sees the GST invoice.

Everything you just did also appears on the **website** — same accounts, same data.

### Step 4 — Google Maps key (for APK builds only)
1. Google Cloud Console → enable **Maps SDK for Android** → create an API key.
2. Paste it in both `app.json` files: `android.config.googleMaps.apiKey`.

### Step 5 — Build installable APKs (cloud, free tier)
```bash
npm i -g eas-cli
eas login                 # free Expo account
cd mobile/redo-customer
eas build -p android --profile preview
```
EAS builds in the cloud and gives you an APK download link. Repeat for `redo-partner`.
(First run: `eas build:configure` creates `eas.json`; choose the `preview` profile for APK.)

### Step 6 — Production checklist (later)
- Deploy backend + ML (Render/Railway) and set `API_URL` to the public URL.
- Supabase Auth: keep "Confirm email" ON with SMTP configured (the apps already handle the
  confirm-your-email flow), URL config includes your domains.
- Push notifications: add `expo-notifications` and store Expo push tokens per profile — the
  backend `notify()` helper is the single place to also send a push.
- Background location: current live-sharing runs while the app is open (foreground). For
  Rapido-grade background tracking add `expo-task-manager` + background location permission.

---

## 3. Design decisions (interview-ready)

- **Why React Native/Expo over Flutter?** The platform is TypeScript end-to-end: the app reuses
  the website's API contract, types and Supabase client verbatim. Expo Go gives instant
  on-device testing and EAS gives APKs without local Android SDK. Flutter would work fine —
  the backend is client-agnostic — but would duplicate every model/type in Dart for no gain.
- **Two apps, not one app with role switch?** Same reason as Rapido/Rapido Captain: the two
  jobs-to-be-done are different (book vs earn), the home screens are different (booking sheet vs
  duty toggle + load feed), and separate apps keep each one small and focused. They still share
  ~40% of code (lib/, ui kit, auth screens) by copy-sync.
- **Where is the business logic?** Server-side, deliberately. The apps never decide what a legal
  status transition is — they call `PATCH /bookings/:id/status` and render the backend's answer.
  That is why web and mobile can never disagree about a booking.
- **Real vs simulated tracking:** the schema flags every point (`is_simulated`). The website's
  demo simulator stays labeled; the partner app publishes **real GPS with `is_simulated:false`**
  — the customer app shows the label only when points are simulated. Honesty is preserved
  end-to-end.
- **No fake data on mobile either:** new accounts see genuinely empty states with CTAs; unrated
  trucks show "New"; ML outage shows Retry, never invented scores.

## 4. Screen inventory

**Customer (15):** Language, Permission, Login, Signup, Onboarding (business details),
Home (map + booking sheet), Matches, Shipments, ShipmentDetail (timeline +
confirm/complete/cancel/rate), Tracking (realtime map), Invoices, Notifications, Support,
RateCard, Addresses, Profile.

**Partner (13):** Language, Permission, Login, Signup, Onboarding (driver reg → truck reg →
documents), Home (greeting + live map + available-loads feed with Accept), Bookings,
BookingDetail (state machine + proof photos + real-GPS sharing), Earnings, Trucks,
Documents (KYC), Notifications, Support, Profile (reviews inside).


---

## 5. FULL WIRING CHECKLIST (industry run-book — do these in order)

The customer side and truck side connect through TWO things: **return trips** (matching) and
**Supabase Realtime** (live updates). Miss either and the sides look "disconnected".

### 5.1 Database (Supabase SQL editor)
- Run migrations **0001 → 0005** in order. `0005_realtime_wiring.sql` is what makes a shipper's
  new cargo appear LIVE in the partner feed (adds `cargo_requests` + `truck_trips` to the
  realtime publication). Also run `cleanup_synthetic.sql` once if the DB has old SEED data.
- Supabase → Database → Replication: confirm `supabase_realtime` publication lists
  `tracking_events, bookings, notifications, cargo_requests, truck_trips`.

### 5.2 Why "customer posts cargo but truck owner sees nothing / shipper search finds no trucks"
Root cause found: **matching runs against return TRIPS, not bare trucks.** If an owner only adds
a truck (web MyTrucks or the app) and never posts a return trip, the shipper's Find Trucks is
correctly empty. Fixed in three places:
- **Partner app onboarding** now collects the next empty return trip (From → home city, departure)
  and posts it right after truck creation.
- **Partner app → My Trucks** has a "+ Post return trip" per truck.
- **Website → My Trucks** has the same "+ Post Return Trip" form per truck.
And the reverse feed (owner sees shipper cargo) is the `/cargo` open-loads endpoint + the new
realtime subscription — new cargo pops into the partner Home instantly, Rapido-style.

### 5.3 Backend + website
- `backend`: `npm run dev` (port 8000) with `.env` filled; `ml-service`: `uvicorn api:app --port 8001`.
- Website `.env`: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_API_URL`.
- Supabase Auth: "Confirm email" **OFF** for demo (or SMTP configured).

### 5.4 Apps
- Both `app.json → expo.extra`: real `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `API_URL`
  (**emulator → `http://10.0.2.2:8000`**, real phone → laptop LAN IP, deployed → https URL).
- On boot each app now runs a **connection self-check**: bad config or unreachable backend shows
  ONE clear screen listing exactly what to fix (no more random errors everywhere).
- `npm install` then `npx expo start -c` (the `-c` clears cache after config changes).

### 5.5 Google login in the apps (same method as the website)
The apps use native PKCE OAuth (`expo-auth-session` + `expo-web-browser`).
1. Supabase → Auth → Providers → Google enabled (already done for the website).
2. First time you tap "Continue with Google", if Supabase rejects the redirect the app shows the
   EXACT redirect URL to whitelist — copy it into Supabase → Auth → URL Configuration →
   Additional Redirect URLs (Expo Go uses an `exp://…` URL; APK builds use `redocustomer://` /
   `redopartner://`). Add both once; done forever.

### 5.6 Live-wiring map (what updates without refresh)
| Event | Who sees it live |
|---|---|
| Shipper posts cargo (web or app) | Partner app Home feed · website Available Loads |
| Owner accepts / any status change | Customer Shipments + ShipmentDetail · Partner Bookings + BookingDetail · website Bookings + BookingDetail |
| Any notification (booking request, KYC decision…) | Bell badge on website header AND both app headers |
| Partner shares real GPS | Customer Tracking map (website + app) |

### 5.7 GitHub reminder
The repo currently has **no `mobile/` folder and is missing the latest fixes** — push this
delivered folder as-is (`git add mobile supabase docs frontend backend && git commit && git push`)
so the deployed site and your local apps run the same wired code.

### 5.8 Troubleshooting matrix
| Symptom | Cause → Fix |
|---|---|
| App shows "Connection setup needed" | It tells you exactly what: fill extra config / start backend / fix API_URL |
| Login fails only with email+password | Supabase "Confirm email" ON without SMTP → turn OFF (or confirm the email) |
| Shipper search returns nothing | Owner has no OPEN return trip on that corridor → post one (see 5.2) |
| Partner feed empty | No open cargo yet, or cargo cities outside known corridors — post from customer side |
| Nothing updates live | Migration 0005 not run / publication missing tables (see 5.1) |
| Google button errors with a URL | Add that exact URL in Supabase Additional Redirect URLs |
