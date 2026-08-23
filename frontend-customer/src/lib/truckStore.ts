export interface TruckItem {
  id: string;
  name: string;
  regNo: string;
  type: string;
  body: string;
  capacity: string;
  capacityTons: number;
  status: "Active" | "Inactive" | "Maintenance";
  availability: "Available" | "On Trip" | "Not Available";
  location: string;
  photoUrl: string;
  driverName: string;
  driverPhone: string;
  driverLicense: string;
  insuranceValidTill: string;
  fitnessValidTill: string;
  pucValidTill: string;
  totalTrips: number;
  totalEarnings: string;
  rating: number;
  verified: boolean;
  currentTrip?: {
    id?: string;
    origin: string;
    dest: string;
    departureDate: string;
    expectedEarning: string;
    distanceKm: number;
    status: "Upcoming" | "On the Way" | "Completed" | "Cancelled";
  };
}

export const PRESET_TRUCK_PHOTOS = [
  { label: "REDO Official 19ft Container Truck (REDO 2024)", url: "/assets/redo_truck.jpg" },
  { label: "Eicher 17ft Closed Container", url: "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80" },
  { label: "BharatBenz 19ft Heavy Truck", url: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80" },
  { label: "Tata 14ft Open Body", url: "https://images.unsplash.com/photo-1592838064575-70ed626d3a0e?auto=format&fit=crop&w=600&q=80" },
  { label: "Mahindra Bolero Maxi Truck", url: "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=600&q=80" },
  { label: "32ft Multi-Axle Container", url: "https://images.unsplash.com/photo-1506015391300-4802dc74de2e?auto=format&fit=crop&w=600&q=80" },
];

// NEW ACCOUNTS START WITH ZERO TRUCKS — only see trucks registered by truck owners via cross-domain
const INITIAL_TRUCKS: TruckItem[] = [];

const STORAGE_KEY = "redo_user_fleet_v5";

export function getTrucks(): TruckItem[] {
  if (typeof window === "undefined") return INITIAL_TRUCKS;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(INITIAL_TRUCKS));
      return INITIAL_TRUCKS;
    }
    const parsed = JSON.parse(saved);
    if (!Array.isArray(parsed)) return INITIAL_TRUCKS;
    return parsed;
  } catch {
    return INITIAL_TRUCKS;
  }
}

export function saveTrucks(trucks: TruckItem[]): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(trucks));
    window.dispatchEvent(new CustomEvent("redo_fleet_updated", { detail: trucks }));
  } catch {}
}

export function addTruck(truck: Omit<TruckItem, "id" | "totalTrips" | "totalEarnings" | "rating" | "verified">): TruckItem {
  const list = getTrucks();
  const newTruck: TruckItem = {
    ...truck,
    id: `TRUCK-${Date.now().toString().slice(-4)}`,
    totalTrips: 0,
    totalEarnings: "₹0",
    rating: 5.0,
    verified: true,
  };
  list.unshift(newTruck);
  saveTrucks(list);
  return newTruck;
}

export function deleteTruck(id: string): void {
  const list = getTrucks().filter(t => t.id !== id);
  saveTrucks(list);
}

export function updateTruck(id: string, patch: Partial<TruckItem>): TruckItem | null {
  const list = getTrucks();
  const idx = list.findIndex(t => t.id === id);
  if (idx === -1) return null;
  list[idx] = { ...list[idx], ...patch };
  saveTrucks(list);
  return list[idx];
}
