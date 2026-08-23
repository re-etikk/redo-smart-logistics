export interface LocationHub {
  name: string;
  state: string;
  hub: string;
  lat: number;
  lng: number;
}

export const INDIAN_LOGISTICS_HUBS: LocationHub[] = [
  { name: "Delhi NCR (Okhla Industrial Area)", state: "Delhi", hub: "North Central Hub", lat: 28.528, lng: 77.279 },
  { name: "Delhi (Kundli Industrial Area)", state: "Haryana", hub: "GT Karnal Corridor", lat: 28.874, lng: 77.128 },
  { name: "Delhi (Nangloi Transport Nagar)", state: "Delhi", hub: "Rohtak Road Hub", lat: 28.683, lng: 77.065 },
  { name: "Gurugram (Manesar Auto Hub)", state: "Haryana", hub: "NH-48 Western Corridor", lat: 28.358, lng: 76.936 },
  { name: "Noida (Sector 62 / Greater Noida Express)", state: "Uttar Pradesh", hub: "Yamuna Corridor", lat: 28.627, lng: 77.365 },
  { name: "Mumbai (Bhiwandi Logistics Park)", state: "Maharashtra", hub: "Western Mega Hub", lat: 19.296, lng: 73.063 },
  { name: "Mumbai (JNPT Port Hub, Navi Mumbai)", state: "Maharashtra", hub: "Port Gateway", lat: 18.949, lng: 72.951 },
  { name: "Pune (Chakan Auto & Engineering Hub)", state: "Maharashtra", hub: "Industrial Cluster", lat: 18.761, lng: 73.858 },
  { name: "Ahmedabad (Sanand GIDC)", state: "Gujarat", hub: "Auto Corridor", lat: 22.986, lng: 72.380 },
  { name: "Surat (Pandesara GIDC / Textile Hub)", state: "Gujarat", hub: "Textile Cluster", lat: 21.144, lng: 72.822 },
  { name: "Vadodara (Makarpura GIDC)", state: "Gujarat", hub: "Heavy Engineering", lat: 22.254, lng: 73.197 },
  { name: "Bengaluru (Peenya Industrial Area)", state: "Karnataka", hub: "South Apex Hub", lat: 13.033, lng: 77.514 },
  { name: "Bengaluru (Bommasandra / Hosur Corridor)", state: "Karnataka", hub: "NH-44 Southern Hub", lat: 12.815, lng: 77.685 },
  { name: "Chennai (Sriperumbudur Auto Corridor)", state: "Tamil Nadu", hub: "Southern Gateway", lat: 12.969, lng: 79.944 },
  { name: "Coimbatore (SIDCO Industrial Estate)", state: "Tamil Nadu", hub: "Textile & Pump Hub", lat: 10.963, lng: 76.967 },
  { name: "Hyderabad (Patancheru Industrial Area)", state: "Telangana", hub: "Pharma Corridor", lat: 17.528, lng: 78.267 },
  { name: "Hyderabad (Cherlapally Logistics Hub)", state: "Telangana", hub: "East Freight Hub", lat: 17.464, lng: 78.601 },
  { name: "Indore (Pithampur Industrial Corridor)", state: "Madhya Pradesh", hub: "Central Logistics", lat: 22.613, lng: 75.688 },
  { name: "Jaipur (VKI Industrial Area / Sitapura)", state: "Rajasthan", hub: "North Western Hub", lat: 26.985, lng: 75.772 },
  { name: "Lucknow (Transport Nagar, Amausi)", state: "Uttar Pradesh", hub: "East Central Hub", lat: 26.782, lng: 80.876 },
  { name: "Kanpur (Panki Industrial Estate)", state: "Uttar Pradesh", hub: "Leather & Heavy", lat: 26.471, lng: 80.245 },
  { name: "Kolkata (Dankuni Freight Hub)", state: "West Bengal", hub: "Eastern Gateway", lat: 22.684, lng: 88.293 },
  { name: "Ludhiana (Dhandari Kalan Freight Terminal)", state: "Punjab", hub: "Northern Heavy Hub", lat: 30.866, lng: 75.922 },
  { name: "Nagpur (MIHAN Cargo Hub)", state: "Maharashtra", hub: "Zero Mile Center", lat: 21.058, lng: 79.053 },
  { name: "Patna (Fatuha Logistics Hub)", state: "Bihar", hub: "East Corridor", lat: 25.508, lng: 85.313 },
  { name: "Chandigarh (Industrial Area Phase 1 & 2)", state: "Chandigarh", hub: "Tri-City Hub", lat: 30.706, lng: 76.797 },
];

export function searchLocations(query: string): LocationHub[] {
  if (!query || query.trim() === "") return INDIAN_LOGISTICS_HUBS.slice(0, 6);
  const q = query.toLowerCase().trim();
  return INDIAN_LOGISTICS_HUBS.filter(
    h => h.name.toLowerCase().includes(q) || h.state.toLowerCase().includes(q) || h.hub.toLowerCase().includes(q)
  );
}

export function estimateHighwayDistance(origin: string, dest: string): { distanceKm: number; transitHours: number } {
  // Simple haversine / lookup approximation
  const origHub = INDIAN_LOGISTICS_HUBS.find(h => origin.toLowerCase().includes(h.state.toLowerCase()) || origin.toLowerCase().includes(h.name.toLowerCase().split(" ")[0]));
  const destHub = INDIAN_LOGISTICS_HUBS.find(h => dest.toLowerCase().includes(h.state.toLowerCase()) || dest.toLowerCase().includes(h.name.toLowerCase().split(" ")[0]));

  if (origHub && destHub && origHub !== destHub) {
    const latDiff = Math.abs(origHub.lat - destHub.lat) * 111;
    const lngDiff = Math.abs(origHub.lng - destHub.lng) * 100;
    const directKm = Math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
    const highwayKm = Math.round(directKm * 1.35); // 1.35 road winding factor
    const transitHours = Math.round((highwayKm / 45) * 10) / 10; // 45 km/h truck avg
    return { distanceKm: Math.max(80, highwayKm), transitHours: Math.max(3, transitHours) };
  }

  return { distanceKm: 750, transitHours: 18 };
}

export function estimateFairPrice(distanceKm: number, weightTons: number): number {
  const baseRate = 1800; // Base dispatch & loading fee
  const perKmPerTon = 3.2; // Optimized backhaul freight rate (vs market 4.5)
  const total = baseRate + distanceKm * weightTons * perKmPerTon;
  return Math.round(total / 100) * 100;
}
