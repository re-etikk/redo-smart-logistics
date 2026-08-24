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
  negotiatedPriceInr?: number;
  negotiationStatus?: "None" | "Proposed" | "Accepted" | "Declined";
  negotiationNote?: string;
  status: "Awaiting Truck Assignment" | "Driver Assigned" | "In Transit" | "Delivered";
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
  rating?: number;
  reviewComment?: string;
}

const STORAGE_KEY = "redo_customer_shipments_v6";

export function getShipments(): ShipmentItem[] {
  if (typeof window === "undefined") return [];
  try {
    const postedCargo = getSharedCargoList();
    const list: ShipmentItem[] = [];

    for (const c of postedCargo) {
      let mappedStatus: ShipmentItem["status"] = "Awaiting Truck Assignment";
      let etaText = "Matching returning backhaul trucks in corridor...";
      let progress = c.trackingProgress || 10;
      let speed = c.currentSpeed || 0;

      if (c.status === "Assigned") {
        mappedStatus = "Driver Assigned";
        etaText = `Driver ${c.assignedDriverName || "Mukesh"} assigned • Heading to warehouse`;
        progress = 30;
        speed = 25;
      } else if (c.status === "In Transit") {
        mappedStatus = "In Transit";
        etaText = c.currentMilestone || "Live Highway Transit • NH-48 Corridor";
        progress = c.trackingProgress || 65;
        speed = c.currentSpeed || 48;
      } else if (c.status === "Delivered") {
        mappedStatus = "Delivered";
        etaText = "Delivered successfully • Signed e-POD Handover";
        progress = 100;
        speed = 0;
      }

      list.push({
        id: `SHP-${c.id.replace("CARGO-", "")}`,
        consignmentId: c.id,
        origin: c.origin,
        destination: c.destination,
        cargoType: c.cargoType,
        weightTons: c.weightTons,
        priceInr: c.offeredPriceInr || 23300,
        negotiatedPriceInr: c.negotiatedPriceInr,
        negotiationStatus: c.negotiationStatus,
        negotiationNote: c.negotiationNote,
        status: mappedStatus,
        truckModel: c.assignedTruckReg ? `Container Truck (${c.truckRequired})` : "Awaiting Truck Assignment",
        truckRegNo: c.assignedTruckReg || "Pending Assignment",
        truckPhoto: "/assets/redo_truck.jpg",
        driverName: c.assignedDriverName || (c.status === "Open" ? "Assigning Driver..." : "Mukesh Yadav"),
        driverPhone: c.assignedDriverPhone || "+91 98112 34567",
        driverRating: 4.8,
        etaText,
        progressPercent: progress,
        bookedAt: c.createdAt || "Just now",
        cargoPhotoUrl: c.cargoPhotoUrl,
        speedKmph: speed,
        rating: c.rating,
        reviewComment: c.reviewComment,
      });
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

export function getShipmentStats() {
  const list = getShipments();
  const inTransit = list.filter(s => s.status !== "Delivered");
  const delivered = list.filter(s => s.status === "Delivered");
  const spend = list.reduce((sum, s) => sum + (Number(s.priceInr) || 0), 0);
  return {
    total: list.length,
    inTransit: inTransit.length,
    delivered: delivered.length,
    spend,
  };
}
