export interface CargoItem {
  id: string;
  origin: string;
  originHub?: string;
  destination: string;
  destHub?: string;
  cargoType: string;
  weightTons: number;
  truckRequired: string;
  distanceKm: number;
  pickupDate: string;
  pickupTime?: string;
  offeredPriceInr: number;
  shipperName: string;
  shipperPhone: string;
  shipperEmail?: string;
  urgency: "Immediate Dispatch" | "High Priority" | "Standard Delivery";
  cargoPhotoUrl?: string;
  specialInstructions?: string;
  status: "Open" | "Assigned" | "In Transit" | "Delivered";
  createdAt: string;
}

const STORAGE_KEY = "redo_shared_cargo_v2";

export function getSharedCargoList(): CargoItem[] {
  if (typeof window === "undefined") return [];
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return [];
    return JSON.parse(saved);
  } catch {
    return [];
  }
}

export function saveSharedCargoList(list: CargoItem[]): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
    window.dispatchEvent(new CustomEvent("redo_cargo_updated", { detail: list }));
  } catch {}
}

export function postNewCargo(cargo: Omit<CargoItem, "id" | "status" | "createdAt">): CargoItem {
  const list = getSharedCargoList();
  const newCargo: CargoItem = {
    ...cargo,
    id: `CARGO-${Date.now().toString().slice(-6)}`,
    status: "Open",
    createdAt: new Date().toLocaleString("en-IN"),
  };
  list.unshift(newCargo);
  saveSharedCargoList(list);
  return newCargo;
}

export function assignTruckToCargo(cargoId: string, truckDetails: { truckId: string; regNo: string; driverName: string }): boolean {
  const list = getSharedCargoList();
  const item = list.find(c => c.id === cargoId);
  if (!item) return false;
  item.status = "Assigned";
  saveSharedCargoList(list);
  return true;
}
