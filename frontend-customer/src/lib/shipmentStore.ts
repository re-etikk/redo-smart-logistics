import { getSharedCargoList, type CargoItem } from "./cargoStore";
import { getTrucks } from "./truckStore";

export interface ShipmentItem {
  id: string;
  consignmentId: string;
  origin: string;
  destination: string;
  cargoType: string;
  weightTons: number;
  priceInr: number;
  status: "In Transit" | "Driver En Route" | "Scheduled Loading" | "Delivered";
  truckModel: string;
  truckRegNo: string;
  truckPhoto: string;
  driverName: string;
  driverPhone: string;
  driverRating: number;
  etaText: string;
  progressPercent: number;
  bookedAt: string;
  currentLat?: number;
  currentLng?: number;
  originLat?: number;
  originLng?: number;
  destLat?: number;
  destLng?: number;
  speedKmph?: number;
  cargoPhotoUrl?: string;
}

const STORAGE_KEY = "redo_customer_shipments_v4";

// NEW ACCOUNTS START WITH ZERO SHIPMENTS — only user-booked shipments appear
export const DEFAULT_SHIPMENTS: ShipmentItem[] = [];

export function getShipments(): ShipmentItem[] {
  if (typeof window === "undefined") return [];
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    let list: ShipmentItem[] = [];
    if (saved) {
      list = JSON.parse(saved);
    }
    if (!Array.isArray(list)) {
      list = [];
      saveShipments(list);
    }

    // Synchronize any newly posted cargo from cargoStore (only real user-booked cargo)
    const postedCargo = getSharedCargoList();
    for (const c of postedCargo) {
      if (!list.some(s => s.consignmentId === c.id)) {
        const fleet = getTrucks();
        const trk = fleet[0];
        list.unshift({
          id: `SHP-${Date.now().toString().slice(-4)}`,
          consignmentId: c.id,
          origin: c.origin,
          destination: c.destination,
          cargoType: c.cargoType,
          weightTons: c.weightTons,
          priceInr: c.offeredPriceInr || 22000,
          status: "Driver En Route",
          truckModel: trk ? trk.name : "Awaiting Truck Assignment",
          truckRegNo: trk ? trk.regNo : "Pending",
          truckPhoto: trk ? trk.photoUrl : "/assets/redo_truck.jpg",
          driverName: trk ? trk.driverName : "Assigning Driver...",
          driverPhone: trk ? trk.driverPhone : "",
          driverRating: trk ? trk.rating : 0,
          etaText: "Driver assigned • Pickup scheduled in ~30 mins",
          progressPercent: 20,
          bookedAt: "Just now",
          cargoPhotoUrl: c.cargoPhotoUrl,
          currentLat: 28.528,
          currentLng: 77.279,
          speedKmph: 42,
        });
      }
    }

    return list;
  } catch {
    return [];
  }
}

export function saveShipments(list: ShipmentItem[]): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
    window.dispatchEvent(new CustomEvent("redo_shipment_updated", { detail: list }));
  } catch {}
}

export function createNewShipment(item: Omit<ShipmentItem, "id" | "bookedAt" | "progressPercent">): ShipmentItem {
  const list = getShipments();
  const newShipment: ShipmentItem = {
    ...item,
    id: `SHP-${Date.now().toString().slice(-4)}`,
    bookedAt: "Just now",
    progressPercent: 25,
  };
  list.unshift(newShipment);
  saveShipments(list);
  return newShipment;
}

export function getShipmentStats() {
  const list = getShipments();
  const inTransitShipments = list.filter(s => s.status !== "Delivered");
  const deliveredShipments = list.filter(s => s.status === "Delivered");
  const totalSpend = list.reduce((sum, s) => sum + (Number(s.priceInr) || 0), 0);

  return {
    totalCount: list.length,
    inTransitCount: inTransitShipments.length,
    deliveredCount: deliveredShipments.length,
    totalSpendInr: totalSpend,
    activeShipments: inTransitShipments,
    deliveredShipments: deliveredShipments,
    allShipments: list,
  };
}
