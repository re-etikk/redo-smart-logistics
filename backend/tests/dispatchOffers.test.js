import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { distanceKmBetween, selectNearbyDispatchTrucks } from '../src/services/dispatchOffers.js';

describe('Nearby dispatch offer selection', () => {
  it('computes GPS distance in kilometres', () => {
    assert.ok(Math.abs(distanceKmBetween(19.076, 72.8777, 19.076, 72.8777)) < 0.001);
    assert.ok(distanceKmBetween(19.076, 72.8777, 19.176, 72.8777) > 10);
  });

  it('sends offers only to the five closest available trucks within 10km with capacity', () => {
    const cargo = { pickup_lat: 19.076, pickup_lng: 72.8777, cargo_weight_tons: 4 };
    const trucks = Array.from({ length: 8 }, (_, index) => ({
      truck_id: `T${index}`,
      owner_id: `D${index === 2 ? 0 : index}`,
      current_lat: 19.076 + index * 0.004,
      current_lng: 72.8777,
      default_capacity_tons: index === 1 ? 2 : 8,
      status: index === 6 ? 'offline' : 'available',
    }));

    const offers = selectNearbyDispatchTrucks(cargo, trucks);
    assert.equal(offers.length, 5);
    assert.equal(offers[0].truck.truck_id, 'T0');
    assert.ok(offers.every((offer) => offer.distanceKm <= 10));
    assert.ok(offers.every((offer) => offer.truck.truck_id !== 'T1' && offer.truck.truck_id !== 'T6'));
    assert.equal(new Set(offers.map((offer) => offer.truck.owner_id)).size, 5);
  });

  it('does not guess a radius match if pickup GPS is missing', () => {
    assert.deepEqual(selectNearbyDispatchTrucks({ cargo_weight_tons: 1 }, [{
      truck_id: 'T1', owner_id: 'D1', current_lat: 19, current_lng: 72,
      default_capacity_tons: 4, status: 'available',
    }]), []);
  });
});