import { supabase } from "./supabase";

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
  assignedTruckId?: string;
  assignedTruckReg?: string;
  assignedDriverName?: string;
  assignedDriverPhone?: string;
}

const STORAGE_KEY = "redo_shared_cargo_v2";
const CLOUD_SYNC_ENDPOINT = "https://kvdb.io/4y9q8Pj7vYqF2WfB4hWq5q/redo_live_cargo_v3";

// Preset initial consignments so Find Loads always has rich freight even before custom postings
export const DEFAULT_CONSIGNMENTS: CargoItem[] = [
  {
    id: "CARGO-801",
    origin: "Delhi NCR (Okhla Industrial Area)",
    destination: "Mumbai (Bhiwandi Logistics Park)",
    cargoType: "Automotive Components & Spare Parts",
    weightTons: 6.5,
    truckRequired: "17-19 Feet Closed Container",
    distanceKm: 1420,
    pickupDate: "Today, 04:00 PM",
    offeredPriceInr: 24500,
    shipperName: "Hero Moto Logistics",
    shipperPhone: "+91 98765 43210",
    urgency: "Immediate Dispatch",
    cargoPhotoUrl: "/assets/redo_truck.jpg",
    status: "Open",
    createdAt: "Today, 10:30 AM",
  },
  {
    id: "CARGO-802",
    origin: "Delhi (Kundli Industrial Area)",
    destination: "Indore (Pithampur Industrial Hub)",
    cargoType: "FMCG Packaged Food & Beverages",
    weightTons: 4.8,
    truckRequired: "14-17 Feet Open/Closed",
    distanceKm: 830,
    pickupDate: "Tomorrow, 09:00 AM",
    offeredPriceInr: 16800,
    shipperName: "Dabur Distribution Pvt Ltd",
    shipperPhone: "+91 98112 55667",
    urgency: "Standard Delivery",
    status: "Open",
    createdAt: "Today, 11:15 AM",
  },
  {
    id: "CARGO-803",
    origin: "Bengaluru (Peenya Industrial Area)",
    destination: "Chennai (Sriperumbudur Auto Hub)",
    cargoType: "Industrial Machinery & Tooling",
    weightTons: 8.0,
    truckRequired: "19-22 Feet Heavy Truck",
    distanceKm: 340,
    pickupDate: "Tomorrow, 11:00 AM",
    offeredPriceInr: 14500,
    shipperName: "L&T Heavy Engineering",
    shipperPhone: "+91 98450 77889",
    urgency: "High Priority",
    status: "Open",
    createdAt: "Today, 12:00 PM",
  }
];

// Supabase Realtime Broadcast Channel across both domains
const channel = typeof window !== "undefined" ? supabase.channel("redo_cross_domain_freight") : null;
if (channel) {
  channel
    .on("broadcast", { event: "NEW_CARGO" }, (payload: { payload: CargoItem }) => {
      if (payload?.payload) {
        mergeRemoteCargo([payload.payload]);
      }
    })
    .on("broadcast", { event: "CARGO_UPDATED" }, (payload: { payload: CargoItem[] }) => {
      if (Array.isArray(payload?.payload)) {
        saveSharedCargoList(payload.payload, false);
      }
    })
    .subscribe();
}

export function getSharedCargoList(): CargoItem[] {
  if (typeof window === "undefined") return DEFAULT_CONSIGNMENTS;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      saveSharedCargoList(DEFAULT_CONSIGNMENTS, true);
      return DEFAULT_CONSIGNMENTS;
    }
    const parsed = JSON.parse(saved);
    if (!Array.isArray(parsed) || parsed.length === 0) {
      saveSharedCargoList(DEFAULT_CONSIGNMENTS, true);
      return DEFAULT_CONSIGNMENTS;
    }
    return parsed;
  } catch {
    return DEFAULT_CONSIGNMENTS;
  }
}

export function saveSharedCargoList(list: CargoItem[], syncToCloud = true): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
    window.dispatchEvent(new CustomEvent("redo_cargo_updated", { detail: list }));

    if (syncToCloud) {
      // 1. Sync to Cloud KV endpoint (cross-domain Vercel relay)
      fetch(CLOUD_SYNC_ENDPOINT, {
        method: "POST",
        body: JSON.stringify(list),
        headers: { "Content-Type": "application/json" },
      }).catch(() => {});

      // 2. Broadcast via Supabase Realtime Channel
      if (channel) {
        channel.send({
          type: "broadcast",
          event: "CARGO_UPDATED",
          payload: list,
        }).catch(() => {});
      }
    }
  } catch {}
}

export function mergeRemoteCargo(remoteList: CargoItem[]): void {
  if (!Array.isArray(remoteList) || remoteList.length === 0) return;
  const current = getSharedCargoList();
  const map = new Map<string, CargoItem>();
  // Put remote first so newer entries are indexed
  for (const item of remoteList) {
    if (item && item.id) map.set(item.id, item);
  }
  for (const item of current) {
    if (item && item.id && !map.has(item.id)) {
      map.set(item.id, item);
    }
  }
  const merged = Array.from(map.values());
  saveSharedCargoList(merged, false);
}

// Background poller from Cloud KV endpoint
export async function syncFromCloud(): Promise<CargoItem[]> {
  try {
    const res = await fetch(CLOUD_SYNC_ENDPOINT, { cache: "no-store" });
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && data.length > 0) {
        mergeRemoteCargo(data);
        return getSharedCargoList();
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

  // Broadcast single new cargo
  if (channel) {
    channel.send({
      type: "broadcast",
      event: "NEW_CARGO",
      payload: newCargo,
    }).catch(() => {});
  }

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
