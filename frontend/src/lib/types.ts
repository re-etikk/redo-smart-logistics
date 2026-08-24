export type Role = "truck_owner" | "sme";

export interface Profile {
  id: string; full_name: string; phone?: string; role: Role;
  company_name?: string; avatar_url?: string; onboarding_complete: boolean;
}

export interface Recommendation {
  truck_id: string; match_score: number; reasons: string[];
  estimated_price_inr: number; eta_minutes: number;
  capacity_available_tons: number; reliability_score: number | null;
  driver_rating: number | null; on_time_rate: number | null; departure_at: string;
  trip_id: string; truck_type?: string; registration_number?: string;
  verified_documents?: boolean;
}

export interface CargoRec {
  cargo_id: string; match_score: number; reasons: string[];
  origin: string; destination: string; cargo_type: string;
  cargo_weight_tons: number; pickup_at: string; urgency: string;
  estimated_price_inr: number; trip_id: string;
}

export interface Booking {
  id: string; cargo_id: string; truck_id: string; trip_id?: string;
  match_score?: number; agreed_price_inr?: number; status: string; created_at: string;
  cargo?: any; truck?: any; proofs?: Proof[]; events?: any[];
}

export interface Proof {
  proof_type: "pickup" | "delivery"; photo_url?: string;
  gps_lat?: number; gps_lng?: number; timestamp: string;
}

export const BOOKING_FLOW = [
  "pending", "accepted", "confirmed", "pickup_ready", "picked_up",
  "in_transit", "delivered", "completed",
];
