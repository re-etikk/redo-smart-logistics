export const DISPATCH_RADIUS_KM = 10;
export const MAX_DISPATCH_DRIVERS = 5;
export const DISPATCH_WINDOW_SECONDS = 45;

export function distanceKmBetween(latA, lngA, latB, lngB) {
  const toRadians = (degrees) => (degrees * Math.PI) / 180;
  const dLat = toRadians(latB - latA);
  const dLng = toRadians(lngB - lngA);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(latA)) * Math.cos(toRadians(latB)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function selectNearbyDispatchTrucks(cargo, trucks, options = {}) {
  const radiusKm = options.radiusKm ?? DISPATCH_RADIUS_KM;
  const limit = options.limit ?? MAX_DISPATCH_DRIVERS;
  if (!Number.isFinite(Number(cargo.pickup_lat)) || !Number.isFinite(Number(cargo.pickup_lng))) {
    return [];
  }

  const closestTruckByDriver = new Map();
  for (const truck of trucks) {
    if (truck.status !== 'available' ||
        Number(truck.default_capacity_tons) < Number(cargo.cargo_weight_tons) ||
        !Number.isFinite(Number(truck.current_lat)) ||
        !Number.isFinite(Number(truck.current_lng))) continue;

    const distanceKm = distanceKmBetween(
      Number(cargo.pickup_lat),
      Number(cargo.pickup_lng),
      Number(truck.current_lat),
      Number(truck.current_lng),
    );
    if (distanceKm > radiusKm) continue;

    const existing = closestTruckByDriver.get(truck.owner_id);
    if (!existing || distanceKm < existing.distanceKm) {
      closestTruckByDriver.set(truck.owner_id, { truck, distanceKm });
    }
  }

  return Array.from(closestTruckByDriver.values())
    .sort((left, right) => left.distanceKm - right.distanceKm)
    .slice(0, limit);
}