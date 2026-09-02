# 🌐 Website Live-Wiring Patch (drop into your GitHub repo)

Your deployed website is missing the realtime wiring + the "Post Return Trip"
feature — that's why it doesn't feel connected to the apps. This patch adds it.

## What each file does
| File | Adds |
|---|---|
| `frontend/src/lib/realtime.ts` | NEW - one hook: refetch on Supabase Realtime changes |
| `frontend/src/pages/owner/AvailableLoads.tsx` | Shipper posts cargo (app/web) → appears here INSTANTLY |
| `frontend/src/pages/Bookings.tsx` | Booking list updates live (both roles) |
| `frontend/src/pages/BookingDetail.tsx` | Status changes from the driver app reflect live |
| `frontend/src/components/Layout.tsx` | Header bell badge updates live on new notifications |
| `frontend/src/pages/owner/MyTrucks.tsx` | "+ Post Return Trip" per truck — keeps trucks matchable (same feature as the partner app) |
| `supabase/migrations/0005_realtime_wiring.sql` | Same SQL as the app package - run once if not already |

## How to apply (2 min)
1. Copy these files into your repo at the SAME paths (overwrite existing).
2. `git add . && git commit -m "live wiring: realtime + return trips" && git push`
3. Vercel auto-deploys. Done - website ↔ customer app ↔ partner app all live.

(SQL from `REQUIRED_SUPABASE_SQL.sql` chalana na bhoolna - wahi realtime ka switch hai.)
