# 🔐 Backend OTP Patch (secure handover, Rapido/Porter-style)

## What it adds
- 4-digit **pickup OTP + delivery OTP** auto-generated per booking.
- Only the **shipper** ever receives the OTPs in API responses (owner-side
  responses have them stripped) — driver must be TOLD them at the dock.
- New endpoint: `POST /bookings/:id/verify-otp` `{type: 'pickup'|'delivery', otp}`.
- `PATCH /bookings/:id/status` now REFUSES `picked_up` / `delivered` until the
  matching OTP is verified (`OTP_REQUIRED` / `OTP_INVALID` errors).
- Shipper gets a live notification the moment an OTP is verified.

## Apply (3 min)
1. Copy `backend/src/routes/bookings.js` into your repo (overwrite).
2. Run `supabase/migrations/0006_otp_handover.sql` in the Supabase SQL editor
   (also included at the end of REQUIRED_SUPABASE_SQL.sql in the apps zip).
3. `git add . && git commit -m "secure OTP handover" && git push`
   → Render auto-redeploys. Done.

Apps in the flutter zip are already wired to this: customer sees the OTPs on
the shipment card; the driver gets an OTP dialog before each e-POD photo.
Websites: same two calls — show `pickup_otp`/`delivery_otp` from GET /bookings
(shipper side) and call `/verify-otp` before the status PATCH (owner side).
