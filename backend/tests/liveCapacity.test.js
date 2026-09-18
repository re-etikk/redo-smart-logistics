import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { calculateDynamicPrice, calculateVolumetricWeightTons, getBillableWeightTons } from '../src/services/dynamicPricing.js';
import { matchCorridorSubSegment } from '../src/services/corridorSegments.js';
import { checkTwoCargoCompatibility, checkTruckCoLoadSafety } from '../src/services/cargoCompatibility.js';
import { calculateReDoMatchScore } from '../src/services/matching.js';
import { consolidate } from '../src/services/consolidation.js';

describe('REDO Live Capacity Marketplace — Dynamic Pricing Engine', () => {
  it('calculates volumetric weight correctly (120 CFT = 1 Ton)', () => {
    assert.equal(calculateVolumetricWeightTons(240), 2.0);
    assert.equal(getBillableWeightTons(1.0, 360), 3.0); // 360 CFT is 3T, higher than 1T actual
  });

  it('computes transparent dynamic price with corridor base rate and savings', () => {
    const result = calculateDynamicPrice({
      weightTons: 2.5,
      distanceKm: 490,
      corridorId: 'delhi_patna',
      cargoType: 'fragile',
      truckOccupancyPct: 0.80, // Deep fill discount (0.88)
      detourKm: 6,
    });

    assert.ok(result.customerPrice > 0);
    assert.ok(result.driverFreight > 0);
    assert.ok(result.redoFee > 0);
    assert.equal(result.customerPrice, result.driverFreight + result.redoFee);
    assert.ok(result.savingsPct > 20); // Massive savings vs full truck
    assert.equal(result.breakdown.cargoMultiplier, 1.18);
  });
});

describe('REDO Corridor Sub-Segment Matching Engine', () => {
  it('matches sub-segments along Delhi-Agra-Kanpur-Lucknow-Patna corridor', () => {
    // Truck is going Delhi -> Patna, Customer wants Kanpur -> Lucknow
    const match = matchCorridorSubSegment('Delhi', 'Patna', 'Kanpur', 'Lucknow');
    assert.equal(match.isMatch, true);
    assert.equal(match.segmentType, 'sub_corridor');
    assert.equal(match.segmentDistanceKm, 60); // 550km - 490km
    assert.ok(match.overlapScore >= 0.90);
  });

  it('detects en-route pickup: Lucknow -> Patna on Delhi -> Patna trip', () => {
    const match = matchCorridorSubSegment('Delhi', 'Patna', 'Lucknow', 'Patna');
    assert.equal(match.isMatch, true);
    assert.equal(match.segmentType, 'enroute_pickup');
  });

  it('rejects inverted/wrong-way cargo along the corridor', () => {
    // Truck going Delhi -> Patna, but cargo wants Patna -> Delhi (reverse)
    const match = matchCorridorSubSegment('Delhi', 'Patna', 'Patna', 'Delhi');
    assert.equal(match.isMatch, false);
  });
});

describe('REDO Cargo Co-Load Safety Matrix', () => {
  it('strictly prohibits Food + Chemicals co-loading', () => {
    const check = checkTwoCargoCompatibility('packaged_food', 'chemicals');
    assert.equal(check.allowed, false);
    assert.equal(check.riskLevel, 'prohibited');
  });

  it('allows safe co-loading for General + FMCG', () => {
    const check = checkTwoCargoCompatibility('general', 'fmcg');
    assert.equal(check.allowed, true);
    assert.equal(check.riskLevel, 'safe');
  });

  it('evaluates truck multi-cargo safety before adding candidate', () => {
    const truckCargo = ['packaged_food', 'fmcg'];
    const safeCheck = checkTruckCoLoadSafety(truckCargo, 'general');
    assert.equal(safeCheck.allowed, true);

    const hazardCheck = checkTruckCoLoadSafety(truckCargo, 'chemicals');
    assert.equal(hazardCheck.allowed, false);
    assert.equal(hazardCheck.riskLevel, 'prohibited');
  });
});

describe('REDO ReDo Match Score', () => {
  it('produces an explainable score between 15% and 99%', () => {
    const score = calculateReDoMatchScore({
      routeOverlapScore: 0.95,
      availableCapacityTons: 8.0,
      cargoWeightTons: 4.0,
      timeGapHours: 1.5,
      cargoSafetyScore: 1.0,
      driverRating: 4.8,
      onTimeRate: 0.95,
      cancelRate: 0.02,
    });

    assert.ok(score.scorePct >= 80);
    assert.ok(score.breakdown.routeScore > 0);
    assert.ok(score.breakdown.capacityFit > 0);
  });
});

describe('REDO Smart Cargo Consolidation', () => {
  it('consolidates multiple partial loads within truck capacity and isolates hazardous items', () => {
    const candidateLoads = [
      { id: 'c1', weight_tons: 3.0, cargo_type: 'food' },
      { id: 'c2', weight_tons: 2.0, cargo_type: 'fmcg' },
      { id: 'c3', weight_tons: 1.5, cargo_type: 'general' },
      { id: 'c4', weight_tons: 1.0, cargo_type: 'chemicals' }, // capacity would allow (6.5 + 1.0 <= 8.0), but skipped for safety!
    ];

    const result = consolidate(8.0, candidateLoads);
    assert.equal(result.packed.length, 3); // c1 (3T), c2 (2T), c3 (1.5T) = 6.5T packed!
    assert.equal(result.used_tons, 6.5);
    assert.equal(result.remaining_capacity_tons, 1.5);
    assert.ok(result.skipped.some(s => s.id === 'c4' && s.skip_reason === 'cargo_incompatible'));
  });
});
