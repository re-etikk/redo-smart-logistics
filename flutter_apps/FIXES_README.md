# 🔧 REDO Flutter Apps — What Was Broken & What I Fixed

## 🔴 The 3 root causes of "customer aur truck app connected nahi hain"

### 1. Partner "Accept Load" was FAKE (biggest bug)
`acceptLoad()` created a **local-only** ActiveTrip object — **no booking was ever
written anywhere**. The shipper could never see it. Same story in reverse:
customer `createBooking()` did a direct table insert that RLS rejected, then the
`catch` block **returned a fake "confirmed" booking** — looked booked on screen,
existed nowhere.
**Fixed:** both now call the Express backend (`POST /bookings`) — the same state
machine the website uses. Accept → shipper notified → visible on their app
instantly. Book → partner sees it. One database, one truth.

### 2. Fake data everywhere (violated the project's own "Honesty by design")
Hardcoded fallbacks removed from **7 places**: fake truck matches (96%, ★4.9),
fake loads (Tata AutoComp / Reliance), fake active trip, fake shipments, fake
wallet ₹48,600, fake settlement ledger, fake contact numbers. Now: real data or
an honest empty/error state — never invented numbers. Matches come from the
**real ML service** (`GET /recommendations`); backhaul discount is **computed**
vs a spot baseline, not hardcoded 35%.

### 3. No realtime anywhere + status updates silently dropped
No Supabase channel existed in either app, and `updateTripStatus()` was a direct
table UPDATE that RLS silently swallowed — driver pressed buttons, shipper saw
nothing, e-POD photo was captured and **thrown away** (never uploaded).
**Fixed:** live subscriptions (loads feed, trips, shipments, tracking) + status
via backend PATCH with **mandatory proof photos**:
`confirmed → pickup_ready → (pickup e-POD) picked_up → in_transit → (delivery
e-POD) delivered`. Completion (`delivered → completed`) is the **shipper's**
button (added on the customer Shipments card, with rating) — that's what settles
earnings + generates the GST invoice.

## ✅ Also fixed
- **Kotlin metadata hacks removed** (`-Xskip-metadata-version-check`,
  AarMetadata disable) — those were build-time band-aids that can crash at
  runtime. Proper fix: `google_maps_flutter: 2.9.0` pinned (no Kotlin 2.3.0
  transitives). Run `flutter clean && flutter pub get` after pulling this.
- **Live GPS**: driver's "Share Live GPS" now streams real positions to
  `POST /tracking/:id/events` (`is_simulated: false`) — customer tracking map
  moves in realtime with a trail; simulated demo points get labeled honestly.
- **Customer tracking screen** rebuilt on `tracking_events` + Realtime (was a
  static marker hardcoded near Indore).
- **Earnings screen** now backend-computed (`GET /earnings`): settled vs
  pending, real ledger; withdraw labeled Demo (Razorpay pending, as planned).
- **Render cold start** handled: `/health` warmup on app launch + 70s
  first-call timeout + friendly "server waking up" message.
- Truck+return-trip registration during onboarding now goes via the backend
  (validation + consistent IDs).

## ▶️ To run
1. **Supabase SQL Editor** → run `REQUIRED_SUPABASE_SQL.sql` (once). Without it
   the live feed doesn't push.
2. Supabase → Auth: "Confirm email" **OFF** (demo logins self-create users).
3. Each app: `flutter clean && flutter pub get && flutter run`
4. Demo: Partner app → Quick Demo Login → onboarding (truck + return trip +
   docs) → Customer app → Quick Demo Login → book Mumbai→Delhi → matches →
   Book → **Shipments → "Confirm this Truck"** → Partner: Arrived → Pickup
   e-POD → (Share Live GPS!) → Delivery e-POD → Customer: watch map move →
   "Mark Completed & Rate" → Partner Earnings updates. 🎉

## ⚠️ Notes
- `delivered → Completed` button is on the CUSTOMER app by design (shipper
  sign-off) — driver app correctly shows "awaiting shipper completion".
- Google login: add `redocustomer://auth` and `redopartner://auth` in Supabase
  → Auth → URL Configuration → Additional Redirect URLs.
- Maps key is in AndroidManifest + config — rotate it before making the repo
  public-public, it's already in git history.


---

# 🆕 Round 2 — Rapido/Uber-grade features added

## 🔐 Secure OTP Handover (pickup + delivery)
- Booking बनते ही backend 4-digit **pickup OTP + delivery OTP** generate karta hai.
- **Customer app/website**: shipment card pe OTP bade akshron me dikhta hai
  ("share with driver at loading"). Sirf shipper ko dikhta hai — owner-side
  responses se backend strip kar deta hai.
- **Driver app**: pickup/delivery se pehle OTP dialog → `POST /verify-otp` →
  galat OTP = aage nahi. Verify hote hi shipper ko live notification.
- Backend `picked_up`/`delivered` ko OTP-verify ke bina REFUSE karta hai —
  security server-side hai, UI-side nahi.
- ⚠️ Requires: backend_otp_patch.zip apply + SQL section 4 (REQUIRED_SUPABASE_SQL.sql).

## 🗺️ Live Network Maps (Rapido home-screen feel)
- **Customer home map**: network ke saare OPEN return trips yellow truck markers
  ke roop me — tap karo to "Return truck → Delhi · 9T free". Naya trip post ho
  (driver onboarding/My Trucks se) to marker LIVE aata hai (truck_trips realtime).
  REDO model ke hisaab se: idle taxis nahi, RETURN TRIPS dikh rahi hain.
- **Partner loads feed**: upar 170px live map — har open load ka pickup point
  yellow marker (liteMode = zero jank). Naya load aate hi map + list dono update.

## ⭐ Two-way Reviews (Uber-style trust)
- Customer pehle se rate karta tha; ab **driver bhi shipper ko rate karta hai**
  (completed trip pe "Rate this Shipper"). Same ratings ledger, ALREADY_RATED
  guard backend me.

## 📱 Real-phone crash
- Dekho `CRASH_FIX_REAL_PHONE.md` — 90% chance purani (hacked-gradle) APK hai;
  fresh build steps + adb logcat one-liner diya hai jisse exact crash line milegi.
