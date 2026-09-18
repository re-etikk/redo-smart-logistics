// corridorSegments.js — Highway Corridor & Sub-Segment Matching Graph
// Enables matching partial cargo (e.g. Kanpur -> Lucknow) along moving truck trips (e.g. Delhi -> Patna).

import { normCity } from './matching.js';

export const CORRIDORS = {
  delhi_patna: {
    id: 'delhi_patna',
    name: 'Delhi - Agra - Kanpur - Lucknow - Patna',
    highway: 'NH19 / Purvanchal Expressway',
    waypoints: [
      { city: 'delhi', name: 'Delhi NCR', km: 0, lat: 28.6139, lng: 77.2090 },
      { city: 'mathura', name: 'Mathura', km: 160, lat: 27.4924, lng: 77.6737 },
      { city: 'agra', name: 'Agra', km: 215, lat: 27.1767, lng: 78.0081 },
      { city: 'kanpur', name: 'Kanpur', km: 490, lat: 26.4499, lng: 80.3319 },
      { city: 'lucknow', name: 'Lucknow', km: 550, lat: 26.8467, lng: 80.9462 },
      { city: 'prayagraj', name: 'Prayagraj', km: 670, lat: 25.4358, lng: 81.8463 },
      { city: 'varanasi', name: 'Varanasi', km: 790, lat: 25.3176, lng: 82.9739 },
      { city: 'patna', name: 'Patna', km: 1050, lat: 25.5941, lng: 85.1376 },
    ]
  },
  delhi_mumbai: {
    id: 'delhi_mumbai',
    name: 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai',
    highway: 'NE4 / NH48',
    waypoints: [
      { city: 'delhi', name: 'Delhi NCR', km: 0, lat: 28.6139, lng: 77.2090 },
      { city: 'jaipur', name: 'Jaipur', km: 280, lat: 26.9124, lng: 75.7873 },
      { city: 'ajmer', name: 'Ajmer', km: 415, lat: 26.4499, lng: 74.6399 },
      { city: 'ahmedabad', name: 'Ahmedabad', km: 930, lat: 23.0225, lng: 72.5714 },
      { city: 'vadodara', name: 'Vadodara', km: 1040, lat: 22.3072, lng: 73.1812 },
      { city: 'surat', name: 'Surat', km: 1160, lat: 21.1702, lng: 72.8311 },
      { city: 'vapi', name: 'Vapi', km: 1280, lat: 20.3712, lng: 72.9048 },
      { city: 'mumbai', name: 'Mumbai', km: 1400, lat: 19.0760, lng: 72.8777 },
    ]
  },
  mumbai_bengaluru: {
    id: 'mumbai_bengaluru',
    name: 'Mumbai - Pune - Kolhapur - Bengaluru',
    highway: 'NH48',
    waypoints: [
      { city: 'mumbai', name: 'Mumbai', km: 0, lat: 19.0760, lng: 72.8777 },
      { city: 'pune', name: 'Pune', km: 150, lat: 18.5204, lng: 73.8567 },
      { city: 'satara', name: 'Satara', km: 265, lat: 17.6805, lng: 74.0183 },
      { city: 'kolhapur', name: 'Kolhapur', km: 385, lat: 16.7050, lng: 74.2433 },
      { city: 'belagavi', name: 'Belagavi', km: 495, lat: 15.8497, lng: 74.4977 },
      { city: 'hubli', name: 'Hubli', km: 590, lat: 15.3647, lng: 75.1240 },
      { city: 'davanagere', name: 'Davanagere', km: 730, lat: 14.4644, lng: 75.9218 },
      { city: 'bengaluru', name: 'Bengaluru', km: 980, lat: 12.9716, lng: 77.5946 },
    ]
  }
};

/**
 * Finds index of a city in a corridor waypoint array.
 */
export function findWaypointIndex(corridorWaypoints, rawCity) {
  const norm = normCity(rawCity);
  if (!norm) return -1;
  return corridorWaypoints.findIndex(w => {
    const wc = w.city.toLowerCase();
    return norm.includes(wc) || wc.includes(norm);
  });
}

/**
 * Analyzes whether a cargo request (origin, destination) can be serviced by a truck trip
 * along any known highway corridor.
 */
export function matchCorridorSubSegment(tripOrigin, tripDest, cargoOrigin, cargoDest) {
  const normTO = normCity(tripOrigin);
  const normTD = normCity(tripDest);
  const normCO = normCity(cargoOrigin);
  const normCD = normCity(cargoDest);

  for (const [corrKey, corr] of Object.entries(CORRIDORS)) {
    const waypoints = corr.waypoints;
    const idxTO = findWaypointIndex(waypoints, normTO);
    const idxTD = findWaypointIndex(waypoints, normTD);

    // Forward trip check
    if (idxTO !== -1 && idxTD !== -1 && idxTO < idxTD) {
      const idxCO = findWaypointIndex(waypoints, normCO);
      const idxCD = findWaypointIndex(waypoints, normCD);

      // Does cargo lie within this corridor in the same direction?
      if (idxCO !== -1 && idxCD !== -1 && idxCO < idxCD) {
        // Must be a true sub-segment within or equal to the truck bounds
        if (idxCO >= idxTO && idxCD <= idxTD) {
          const segDist = Math.abs(waypoints[idxCD].km - waypoints[idxCO].km);
          const isDirectMatch = (idxCO === idxTO && idxCD === idxTD);
          const isPickupEnRoute = (idxCO > idxTO && idxCD === idxTD);
          const isDropoffEnRoute = (idxCO === idxTO && idxCD < idxTD);
          const isMidSegment = (idxCO > idxTO && idxCD < idxTD);

          let segmentType = 'direct';
          let overlapScore = 1.0;
          if (isDirectMatch) { segmentType = 'direct'; overlapScore = 1.0; }
          else if (isPickupEnRoute) { segmentType = 'enroute_pickup'; overlapScore = 0.94; }
          else if (isDropoffEnRoute) { segmentType = 'enroute_dropoff'; overlapScore = 0.96; }
          else if (isMidSegment) { segmentType = 'sub_corridor'; overlapScore = 0.91; }

          return {
            isMatch: true,
            corridorId: corr.id,
            corridorName: corr.name,
            direction: 'forward',
            segmentType,
            overlapScore,
            segmentDistanceKm: segDist,
            startWaypoint: waypoints[idxCO].name,
            endWaypoint: waypoints[idxCD].name,
            waypointCount: (idxCD - idxCO) + 1,
            enRouteStops: waypoints.slice(idxCO, idxCD + 1).map(w => w.name),
          };
        }
      }
    }

    // Reverse return / backhaul trip check (trip goes from high index to low index)
    if (idxTO !== -1 && idxTD !== -1 && idxTO > idxTD) {
      const idxCO = findWaypointIndex(waypoints, normCO);
      const idxCD = findWaypointIndex(waypoints, normCD);

      if (idxCO !== -1 && idxCD !== -1 && idxCO > idxCD) {
        if (idxCO <= idxTO && idxCD >= idxTD) {
          const segDist = Math.abs(waypoints[idxCO].km - waypoints[idxCD].km);
          return {
            isMatch: true,
            corridorId: corr.id,
            corridorName: corr.name,
            direction: 'reverse_backhaul',
            segmentType: 'return_load',
            overlapScore: 0.95,
            segmentDistanceKm: segDist,
            startWaypoint: waypoints[idxCO].name,
            endWaypoint: waypoints[idxCD].name,
            waypointCount: (idxCO - idxCD) + 1,
            enRouteStops: waypoints.slice(idxCD, idxCO + 1).reverse().map(w => w.name),
          };
        }
      }
    }
  }

  // Not on known defined corridor
  return {
    isMatch: false,
    overlapScore: 0.50,
  };
}
