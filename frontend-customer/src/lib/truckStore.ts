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
  { label: "Eicher 17ft Closed Container", url: "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80" },
  { label: "BharatBenz 19ft Heavy Truck", url: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80" },
  { label: "Tata 14ft Open Body", url: "https://images.unsplash.com/photo-1592838064575-70ed626d3a0e?auto=format&fit=crop&w=600&q=80" },
  { label: "Mahindra Bolero Maxi Truck", url: "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=600&q=80" },
  { label: "32ft Multi-Axle Container", url: "https://images.unsplash.com/photo-1506015391300-4802dc74de2e?auto=format&fit=crop&w=600&q=80" },
  { label: "Ashok Leyland 22ft Tarpaulin", url: "https://images.unsplash.com/photo-1586191582056-a6b18974a44e?auto=format&fit=crop&w=600&q=80" },
];

const INITIAL_TRUCKS: TruckItem[] = [
  {
    id: "TRUCK-101",
    name: "Eicher Pro 2049",
    regNo: "HR 55 AB 1234",
    type: "17 Feet",
    body: "Enclosed Container",
    capacity: "7.0 Ton",
    capacityTons: 7.0,
    status: "Active",
    availability: "Available",
    location: "Delhi NCR, Delhi",
    photoUrl: "https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=600&q=80",
    driverName: "Sandeep Kumar",
    driverPhone: "+91 98765 11223",
    driverLicense: "DL-042018009876",
    insuranceValidTill: "20 Dec 2026",
    fitnessValidTill: "15 Jan 2027",
    pucValidTill: "10 Oct 2026",
    totalTrips: 34,
    totalEarnings: "₹2,45,600",
    rating: 4.9,
    verified: true,
    currentTrip: {
      id: "TRIP-881",
      origin: "Delhi, Delhi",
      dest: "Mumbai, Maharashtra",
      departureDate: "24 Aug 2026, 09:00 AM",
      expectedEarning: "₹24,500",
      distanceKm: 1450,
      status: "On the Way"
    }
  },
  {
    id: "TRUCK-102",
    name: "BharatBenz 1917R",
    regNo: "HR 55 CD 5678",
    type: "19 Feet",
    body: "Enclosed Container",
    capacity: "10.5 Ton",
    capacityTons: 10.5,
    status: "Active",
    availability: "On Trip",
    location: "Mumbai, Maharashtra",
    photoUrl: "https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=600&q=80",
    driverName: "Ramesh Yadav",
    driverPhone: "+91 98112 33445",
    driverLicense: "MH-022019004321",
    insuranceValidTill: "18 Nov 2026",
    fitnessValidTill: "05 Feb 2027",
    pucValidTill: "12 Sep 2026",
    totalTrips: 42,
    totalEarnings: "₹3,82,300",
    rating: 4.8,
    verified: true,
    currentTrip: {
      id: "TRIP-882",
      origin: "Mumbai, Maharashtra",
      dest: "Ahmedabad, Gujarat",
      departureDate: "23 Aug 2026, 08:30 PM",
      expectedEarning: "₹18,200",
      distanceKm: 525,
      status: "On the Way"
    }
  },
  {
    id: "TRUCK-103",
    name: "Tata 407 Gold SFC",
    regNo: "HR 55 EF 9012",
    type: "14 Feet",
    body: "Open Body",
    capacity: "4.5 Ton",
    capacityTons: 4.5,
    status: "Active",
    availability: "Available",
    location: "Indore, Madhya Pradesh",
    photoUrl: "https://images.unsplash.com/photo-1592838064575-70ed626d3a0e?auto=format&fit=crop&w=600&q=80",
    driverName: "Virendra Singh",
    driverPhone: "+91 97234 55667",
    driverLicense: "MP-092020005544",
    insuranceValidTill: "10 Oct 2026",
    fitnessValidTill: "22 Mar 2027",
    pucValidTill: "01 Nov 2026",
    totalTrips: 18,
    totalEarnings: "₹1,12,800",
    rating: 4.7,
    verified: true,
    currentTrip: {
      id: "TRIP-883",
      origin: "Delhi, Delhi",
      dest: "Indore, Madhya Pradesh",
      departureDate: "25 Aug 2026, 06:00 AM",
      expectedEarning: "₹16,200",
      distanceKm: 660,
      status: "Upcoming"
    }
  },
  {
    id: "TRUCK-104",
    name: "Mahindra Bolero Maxi Truck",
    regNo: "HR 55 GH 3456",
    type: "Pickup",
    body: "Open Body",
    capacity: "1.7 Ton",
    capacityTons: 1.7,
    status: "Active",
    availability: "Available",
    location: "Delhi NCR, Delhi",
    photoUrl: "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=600&q=80",
    driverName: "Amit Verma",
    driverPhone: "+91 98990 77889",
    driverLicense: "DL-102021008899",
    insuranceValidTill: "15 Dec 2026",
    fitnessValidTill: "30 Apr 2027",
    pucValidTill: "20 Dec 2026",
    totalTrips: 29,
    totalEarnings: "₹95,500",
    rating: 5.0,
    verified: true,
    currentTrip: {
      id: "TRIP-884",
      origin: "Delhi, Delhi",
      dest: "Lucknow, Uttar Pradesh",
      departureDate: "22 Aug 2026, 11:00 AM",
      expectedEarning: "₹12,500",
      distanceKm: 720,
      status: "Completed"
    }
  },
  {
    id: "TRUCK-105",
    name: "BharatBenz 2823R (32FT)",
    regNo: "HR 55 IJ 7890",
    type: "32 Feet",
    body: "Multi-Axle Container",
    capacity: "18.0 Ton",
    capacityTons: 18.0,
    status: "Active",
    availability: "Available",
    location: "Bengaluru, Karnataka",
    photoUrl: "https://images.unsplash.com/photo-1506015391300-4802dc74de2e?auto=format&fit=crop&w=600&q=80",
    driverName: "Manoj Singh",
    driverPhone: "+91 98450 66778",
    driverLicense: "KA-052017001122",
    insuranceValidTill: "25 Jan 2027",
    fitnessValidTill: "12 May 2027",
    pucValidTill: "15 Nov 2026",
    totalTrips: 56,
    totalEarnings: "₹5,88,000",
    rating: 4.9,
    verified: true,
    currentTrip: {
      id: "TRIP-885",
      origin: "Bengaluru, Karnataka",
      dest: "Chennai, Tamil Nadu",
      departureDate: "21 Aug 2026, 08:00 AM",
      expectedEarning: "₹28,800",
      distanceKm: 350,
      status: "Completed"
    }
  }
];

const STORAGE_KEY = "redo_user_fleet_v2";

export function getTrucks(): TruckItem[] {
  if (typeof window === "undefined") return INITIAL_TRUCKS;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(INITIAL_TRUCKS));
      return INITIAL_TRUCKS;
    }
    return JSON.parse(saved);
  } catch {
    return INITIAL_TRUCKS;
  }
}

export function saveTrucks(trucks: TruckItem[]): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(trucks));
    window.dispatchEvent(new Event("redo_fleet_updated"));
  } catch {}
}

export function addTruck(truck: Omit<TruckItem, "id" | "totalTrips" | "totalEarnings" | "rating" | "verified">): TruckItem {
  const current = getTrucks();
  const newTruck: TruckItem = {
    ...truck,
    id: `TRUCK-${Date.now().toString().slice(-4)}`,
    totalTrips: 0,
    totalEarnings: "₹0",
    rating: 5.0,
    verified: true,
  };
  const updated = [newTruck, ...current];
  saveTrucks(updated);
  return newTruck;
}

export function deleteTruck(id: string): void {
  const current = getTrucks();
  const updated = current.filter(t => t.id !== id);
  saveTrucks(updated);
}

export function updateTruck(id: string, updates: Partial<TruckItem>): void {
  const current = getTrucks();
  const updated = current.map(t => t.id === id ? { ...t, ...updates } : t);
  saveTrucks(updated);
}
