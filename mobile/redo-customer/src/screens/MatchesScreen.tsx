// ML-ranked truck matches for a posted cargo — honest 503 handling with Retry.
import React, { useCallback, useEffect, useState } from 'react';
import { Alert, FlatList, Text, View } from 'react-native';
import { api, ApiError } from '../lib/api';
import { C } from '../lib/theme';
import type { Rec } from '../lib/types';
import { Badge, Button, Card, Empty } from '../components/ui';

export default function MatchesScreen({ route, navigation }: any) {
  const { cargoId, origin, destination } = route.params;
  const [recs, setRecs] = useState<Rec[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [bookingId, setBookingId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null); setRecs(null);
    try {
      const out = await api.get<{ recommendations: Rec[] }>(`/recommendations/trucks/${cargoId}`);
      setRecs(out.recommendations);
    } catch (e) {
      setError(e instanceof ApiError && e.code === 'MATCHING_UNAVAILABLE'
        ? 'Smart matching is temporarily unavailable. We never show made-up scores — please retry.'
        : 'Could not load matches.');
    }
  }, [cargoId]);
  useEffect(() => { load(); }, [load]);

  const book = async (r: Rec) => {
    setBookingId(r.truck_id);
    try {
      const b = await api.post<{ id: string }>('/bookings', {
        cargo_id: cargoId, truck_id: r.truck_id,
        match_score: r.match_score, agreed_price_inr: r.estimated_price_inr,
      });
      Alert.alert('Booked!', 'The truck owner has been notified. Track it in My Shipments.');
      navigation.replace('ShipmentDetail', { bookingId: b.id });
    } catch (e: any) { Alert.alert('Booking failed', e.message); setBookingId(null); }
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Text style={{ fontSize: 18, fontWeight: '900', color: C.ink }}>{origin} → {destination}</Text>
      <Text style={{ fontSize: 12, color: C.inkFaint, marginBottom: 12 }}>
        Ranked by our ML model on live return-trip capacity.
      </Text>
      {error && (
        <Card>
          <Text style={{ color: C.danger, fontWeight: '600' }}>{error}</Text>
          <View style={{ height: 10 }} />
          <Button title="Retry" onPress={load} />
        </Card>
      )}
      {!error && recs === null && <Card><Text style={{ color: C.inkFaint }}>Scoring candidates…</Text></Card>}
      {recs !== null && recs.length === 0 && (
        <Empty title="No matching trucks right now." hint="Owners on this corridor will see your load in Available Loads." />
      )}
      <FlatList
        data={recs ?? []}
        keyExtractor={(r) => r.truck_id}
        contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: r }) => (
          <Card>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={{ fontWeight: '900', fontSize: 16, color: C.ink }}>{r.truck_type} truck</Text>
              <Badge tone="accent" text={`${Math.round(r.match_score * 100)}% match`} />
            </View>
            <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 4 }}>
              {r.capacity_available_tons} T free · {r.driver_rating != null ? `★ ${r.driver_rating.toFixed(1)}` : 'New driver'} · ETA ~{Math.round(r.eta_minutes / 60)} h
            </Text>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 8 }}>
              {r.reasons.slice(0, 3).map((x) => <Badge key={x} tone="ok" text={x} />)}
            </View>
            <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 12 }}>
              <Text style={{ fontSize: 18, fontWeight: '900', color: C.ink }}>
                ₹{r.estimated_price_inr.toLocaleString('en-IN')}
              </Text>
              <View style={{ width: 130 }}>
                <Button title={bookingId === r.truck_id ? 'Booking…' : 'Book'} loading={bookingId === r.truck_id} onPress={() => book(r)} />
              </View>
            </View>
          </Card>
        )}
      />
    </View>
  );
}
