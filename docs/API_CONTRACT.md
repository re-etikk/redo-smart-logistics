# API Contract — Redo backend (:8000)

Auth: all endpoints except `GET /health` require `Authorization: Bearer <supabase access token>`.
Errors always use `{ "error": "CODE", "message": "human readable" }`. Common codes:
`UNAUTHENTICATED`, `SESSION_INVALID`, `PROFILE_MISSING`, `FORBIDDEN_ROLE`, `VALIDATION`,
`NOT_FOUND`, `MATCHING_UNAVAILABLE`, `INVALID_TRANSITION`, `PROOF_REQUIRED`, `ALREADY_RATED`.

## Profile
| Method | Path | Body | Notes |
|---|---|---|---|
| POST | /auth/profile | `{full_name, phone, role, company_name?}` | upsert after signup; role ∈ truck_owner\|sme |
| PATCH | /auth/profile | any of `full_name, phone, company_name, avatar_url, onboarding_complete` | |

## Trucks & trips
| POST | /trucks | `{truck_type, registration_number, body_type?, home_origin?, default_capacity_tons}` | owner only |
| GET | /trucks | — | owner → own; sme → public fields |
| PATCH | /trucks/:id | subset | owner only |
| POST | /trucks/:id/trips | `{origin, destination, departure_at, available_capacity_tons, price_per_km_ton?, accepted_cargo_types?}` | capacity ≤ truck capacity |
| GET | /trucks/:id/trips | — | |

## Cargo
| POST | /cargo | `{origin, destination, cargo_type, cargo_weight_tons, pickup_at, urgency?, special_handling?}` | sme only |
| GET | /cargo | — | sme → own; owner → open |
| GET/PATCH | /cargo/:id | — / subset | |

## Recommendations (two-stage: hard filter → ML)
| GET | /recommendations/trucks/:cargo_id | → `{request_id, model_backend, recommendations:[{truck_id, match_score, reasons[], estimated_price_inr, eta_minutes, capacity_available_tons, reliability_score, driver_rating, on_time_rate, departure_at, trip_id, truck_type, registration_number, verified_documents}], rejected_count}` |
| GET | /recommendations/cargo/:truck_id | symmetric, cargo-shaped entries |
503 `MATCHING_UNAVAILABLE` when the ML service is down — clients must show Retry, never fabricate scores.

## Bookings (state machine — the only mutation path is /status)
| POST | /bookings | `{cargo_id, truck_id, trip_id?, match_score?, agreed_price_inr?}` | sme only; notifies owner |
| GET | /bookings | — | role-filtered |
| GET | /bookings/:id | — | includes `proofs[]`, `events[]` |
| PATCH | /bookings/:id/status | `{to}` | validated by role + proof gates; on `completed` → impact record + notifications |

Statuses: pending → accepted(owner) → confirmed(sme) → pickup_ready(owner) → picked_up(owner, needs pickup proof)
→ in_transit(owner) → delivered(owner, needs delivery proof) → completed(sme). `cancelled` from early states; `disputed` from delivered/completed (sme).

## Tracking / Proof / Ratings / Impact / Notifications
| GET | /tracking/:booking_id | latest 50 events (parties only) |
| POST | /tracking/:booking_id/events | `{lat, lng, progress_pct?, eta_minutes?, is_simulated?}` — defaults simulated:true |
| POST | /proof | `{booking_id, proof_type: pickup\|delivery, photo_url?, gps_lat?, gps_lng?}` (upsert per type) |
| GET | /proof/:booking_id | |
| POST | /ratings | `{booking_id, score 1–5, comment?}` — once per user per booking |
| GET | /impact | `{records, totals{…}, is_estimated:true}` role-scoped |
| GET | /notifications · PATCH /notifications/:id/read | |
| GET | /health · GET /diagnostics | diagnostics reports backend/supabase/ml status |

# ML service (:8001)
| GET | /health | `{status, model_backend}` |
| POST | /rank-candidates | `{candidates:[PairFeatures], top_k}` → `{model_backend, recommendations:[{truck_id?, cargo_id?, match_score, reasons[]}], rejected[]}` |
| POST | /predict-match | single pair → `{match_score}` |
| POST | /register/truck · /register/cargo | §28 registry contract |
| GET | /recommend/trucks/{cargo_id} · /recommend/cargo/{truck_id} | rank against registered entities |


## REDO Transport & Logistics additions (v3)

| Method | Path | Who | Notes |
|---|---|---|---|
| GET/POST | `/addresses`, PATCH `/addresses/:id` | any | Address book; soft delete via `{ deleted: true }` |
| GET/POST | `/support/tickets` | any | Ticket threads; POST `/support/tickets/:id/messages` to reply |
| GET | `/rates` | any | Published FTL lane rate cards (seeded by migration 0003) |
| GET | `/invoices` | sme | Auto-created on booking completion (base + 18% GST) |
| GET | `/earnings` | truck_owner | `{ totals, transactions }` — completed = paid, active = pending |
| GET | `/reviews` | any | Ratings received, with rater display name |
| GET | `/admin/stats` `/admin/users` `/admin/kyc` | admin | Ops console |
| PATCH | `/admin/kyc/:id` | admin | `{ status: "verified" | "rejected" }`, notifies the owner |
| POST | `/bookings` with `owner_initiated: true` | truck_owner | Accept an open load with your own truck → booking starts at `accepted`, shipper confirms |
