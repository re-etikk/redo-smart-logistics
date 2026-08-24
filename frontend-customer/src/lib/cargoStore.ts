import { supabase } from "./supabase";

export interface CargoItem {
  id: string;
  origin: string;
  originHub?: string;
  pickupAddress?: string;
  pickupContactPerson?: string;
  pickupContactPhone?: string;
  destination: string;
  destHub?: string;
  deliveryAddress?: string;
  deliveryContactPerson?: string;
  deliveryContactPhone?: string;
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
  assignedTruckId?: string;
  assignedTruckReg?: string;
  assignedDriverName?: string;
  assignedDriverPhone?: string;
}

const STORAGE_KEY = "redo_shared_cargo_v4";
const CLOUD_SYNC_ENDPOINT = "https://kvdb.io/4y9q8Pj7vYqF2WfB4hWq5q/redo_live_cargo_v4";

// ZERO PRE-POPULATED CARGO — user must book/post their own cargo
export const DEFAULT_CONSIGNMENTS: CargoItem[] = [];

export function getSharedCargoList(): CargoItem[] {
  if (typeof window === "undefined") return DEFAULT_CONSIGNMENTS;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return DEFAULT_CONSIGNMENTS;
    const parsed = JSON.parse(saved);
    if (!Array.isArray(parsed)) {
      return DEFAULT_CONSIGNMENTS;
    }
    return parsed;
  } catch {
    return DEFAULT_CONSIGNMENTS;
  }
}

const CARGO_CHANNEL = supabase.channel("redo_live_cargo_sync");

if (typeof window !== "undefined") {
  CARGO_CHANNEL.on("broadcast", { event: "cargo_updated" }, (payload: any) => {
    if (payload?.payload && Array.isArray(payload.payload)) {
      mergeRemoteCargo(payload.payload);
    }
  }).subscribe();
}

export function saveSharedCargoList(list: CargoItem[], syncToCloud = true): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
    window.dispatchEvent(new CustomEvent("redo_cargo_updated", { detail: list }));

    if (syncToCloud) {
      CARGO_CHANNEL.send({
        type: "broadcast",
        event: "cargo_updated",
        payload: list,
      }).catch(() => {});

      fetch(CLOUD_SYNC_ENDPOINT, {
        method: "POST",
        body: JSON.stringify(list),
        headers: { "Content-Type": "application/json" },
      }).catch(() => {});
    }
  } catch {}
}

export function mergeRemoteCargo(remoteList: CargoItem[]): CargoItem[] {
  if (!Array.isArray(remoteList) || remoteList.length === 0) return getSharedCargoList();
  const current = getSharedCargoList();
  const map = new Map<string, CargoItem>();
  for (const item of remoteList) {
    if (item && item.id) map.set(item.id, item);
  }
  for (const item of current) {
    if (item && item.id && !map.has(item.id)) {
      map.set(item.id, item);
    }
  }
  const merged = Array.from(map.values());
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(merged));
    window.dispatchEvent(new CustomEvent("redo_cargo_updated", { detail: merged }));
  } catch {}
  return merged;
}

export async function syncFromCloud(): Promise<CargoItem[]> {
  try {
    const res = await fetch(CLOUD_SYNC_ENDPOINT, { cache: "no-store" });
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && data.length > 0) {
        return mergeRemoteCargo(data);
      }
    }
  } catch {}
  return getSharedCargoList();
}

export function postNewCargo(cargo: Omit<CargoItem, "id" | "status" | "createdAt">): CargoItem {
  const list = getSharedCargoList();
  const newCargo: CargoItem = {
    ...cargo,
    id: `CARGO-${Date.now().toString().slice(-5)}`,
    status: "Open",
    createdAt: "Just now",
  };

  list.unshift(newCargo);
  saveSharedCargoList(list, true);
  return newCargo;
}

export function assignTruckToCargo(
  cargoId: string,
  truckDetails: { truckId: string; regNo: string; driverName: string; driverPhone?: string }
): boolean {
  const list = getSharedCargoList();
  const item = list.find(c => c.id === cargoId);
  if (!item) return false;

  item.status = "Assigned";
  item.assignedTruckId = truckDetails.truckId;
  item.assignedTruckReg = truckDetails.regNo;
  item.assignedDriverName = truckDetails.driverName;
  item.assignedDriverPhone = truckDetails.driverPhone || "+91 98112 34567";

  saveSharedCargoList(list, true);
  return true;
}
