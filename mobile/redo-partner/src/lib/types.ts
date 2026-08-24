export interface Cargo {
  cargo_id: string; origin: string; destination: string; cargo_type: string;
  cargo_weight_tons: number; distance_km: number | null; pickup_at: string | null;
  urgency: string; status: string;
}
export interface Truck {
  truck_id: string; truck_type: string; registration_number: string;
  default_capacity_tons: number; driver_rating: number | null;
  on_time_rate: number | null; status: string;
}
export interface Booking {
  id: string; cargo_id: string; truck_id: string; status: string;
  agreed_price_inr: number | null; created_at: string;
  cargo: Cargo; truck: Truck;
}
export interface Rec {
  truck_id: string; truck_type: string; match_score: number; reasons: string[];
  estimated_price_inr: number; eta_minutes: number; capacity_available_tons: number;
  driver_rating: number | null; is_new?: boolean;
}
export const STATUS_LABEL: Record<string, string> = {
  pending: 'Pending', accepted: 'Accepted', confirmed: 'Confirmed',
  pickup_ready: 'Pickup Ready', picked_up: 'Picked Up', in_transit: 'In Transit',
  delivered: 'Delivered', completed: 'Completed', cancelled: 'Cancelled', disputed: 'Disputed',
};
export const CITY_COORDS: Record<string, { latitude: number; longitude: number }> = {
  Mumbai: { latitude: 19.076, longitude: 72.8777 },
  Delhi: { latitude: 28.6139, longitude: 77.209 },
  Pune: { latitude: 18.5204, longitude: 73.8567 },
  Jaipur: { latitude: 26.9124, longitude: 75.7873 },
  Surat: { latitude: 21.1702, longitude: 72.8311 },
};
