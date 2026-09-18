import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { apiError } from '../middleware/error.js';
import { routeDistanceKm } from '../services/matching.js';
import { computePriceQuote } from '../services/pricing.js';

const r = Router();
r.use(requireAuth);

// GET /pricing/quote?origin=..&destination=..&weight_tons=..&cargo_type=..&distance_km=..
r.get('/quote', async (req, res, next) => {
  try {
    const { origin, destination, weight_tons, cargo_type, distance_km, volume_cft } = req.query;
    if (!origin || !destination || !weight_tons) {
      throw apiError(400, 'VALIDATION', 'origin, destination and weight_tons are required.');
    }
    const distanceKm = Number(distance_km) || routeDistanceKm(origin, destination) || 500;
    const quote = await computePriceQuote({
      origin, destination, distanceKm,
      weightTons: Number(weight_tons),
      cargoType: cargo_type,
      volumeCft: Number(volume_cft) || 0,
    });
    res.json(quote);
  } catch (e) { next(e); }
});

export default r;
