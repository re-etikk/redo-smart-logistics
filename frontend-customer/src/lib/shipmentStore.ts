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

const STORAGE_KEY = "redo_customer_shipments_v3";

export const DEFAULT_SHIPMENTS: ShipmentItem[] = [
  {
    id: "SHP-901",
    consignmentId: "CARGO-101",
    origin: "Mumbai (Bhiwandi Logistics Park)",
    destination: "Delhi NCR (Okhla Industrial Area)",
    cargoType: "Automobile Components & Spare Parts",
    weightTons: 4.5,
    priceInr: 24500,
    status: "In Transit",
    truckModel: "REDO Express Container (19 Feet)",
    truckRegNo: "REDO 2024",
    truckPhoto: "/assets/redo_truck.jpg",
    driverName: "Mukesh Yadav",
    driverPhone: "+91 98112 34567",
    driverRating: 4.9,
    etaText: "Arriving in 3 hrs 20 mins (Passing Jaipur Tollway)",
    progressPercent: 72,
    bookedAt: "Today, 09:30 AM",
    currentLat: 26.9124,
    currentLng: 75.7873,
    originLat: 19.296,
    originLng: 73.063,
    destLat: 28.528,
    destLng: 77.279,
    speedKmph: 58,
    cargoPhotoUrl: "/assets/redo_truck.jpg",
  },
  {
    id: "SHP-902",
    consignmentId: "CARGO-102",
    origin: "Delhi (Kundli Industrial Area)",
    destination: "Indore (Pithampur Hub)",
    cargoType: "FMCG Packaged Food & Beverage",
    weightTons: 3.2,
    priceInr: 16800,
    status: "Driver En Route",
    truckModel: "BharatBenz 1917R (19 Feet)",
    truckRegNo: "HR 55 CD 5678",
    truckPhoto: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80",
    driverName: "Jaswinder Singh",
    driverPhone: "+91 98765 12345",
    driverRating: 4.8,
    etaText: "Driver arriving at Pickup Hub in 22 mins",
    progressPercent: 28,
    bookedAt: "Today, 11:15 AM",
    currentLat: 28.75,
    currentLng: 77.10,
    speedKmph: 35,
  },
  {
    id: "SHP-903",
    consignmentId: "CARGO-103",
    origin: "Bengaluru (Peenya Industrial Area)",
    destination: "Chennai (Sriperumbudur Auto Hub)",
    cargoType: "Textile Bales & Cotton Rolls",
    weightTons: 6.0,
    priceInr: 14500,
    status: "Delivered",
    truckModel: "Tata Ultra T.7 (14 Feet)",
    truckRegNo: "KA 01 EF 9012",
    truckPhoto: "https://images.unsplash.com/photo-1586191582150-a8d29837936a?auto=format&fit=crop&w=600&q=80",
    driverName: "Sanjay Verma",
    driverPhone: "+91 98450 99887",
    driverRating: 4.9,
    etaText: "Delivered successfully • Signed e-POD Handover",
    progressPercent: 100,
    bookedAt: "Yesterday, 04:00 PM",
    currentLat: 12.969,
    currentLng: 79.944,
    speedKmph: 0,
  },
];

export function getShipments(): ShipmentItem[] {
  if (typeof window === "undefined") return DEFAULT_SHIPMENTS;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    let list: ShipmentItem[] = [];
    if (saved) {
      list = JSON.parse(saved);
    }
    if (!Array.isArray(list) || list.length === 0) {
      list = [...DEFAULT_SHIPMENTS];
      saveShipments(list);
    }

    // Also synchronize any newly posted cargo from cargoStore
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
          truckModel: trk ? trk.name : "REDO Express Container (19 Feet)",
          truckRegNo: trk ? trk.regNo : "REDO 2024",
          truckPhoto: trk ? trk.photoUrl : "/assets/redo_truck.jpg",
          driverName: trk ? trk.driverName : "Mukesh Yadav",
          driverPhone: trk ? trk.driverPhone : "+91 98112 34567",
          driverRating: trk ? trk.rating : 4.9,
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
    return DEFAULT_SHIPMENTS;
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
