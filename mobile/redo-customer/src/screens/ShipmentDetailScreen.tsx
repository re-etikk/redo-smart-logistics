// Booking detail: status timeline + role actions (confirm / complete / rate) + Track button.
import React, { useCallback, useState } from 'react';
import { Alert, Pressable, ScrollView, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { STATUS_LABEL } from '../lib/types';
import { Badge, Button, Card, statusTone } from '../components/ui';

const FLOW = ['pending', 'accepted', 'confirmed', 'pickup_ready', 'picked_up', 'in_transit', 'delivered', 'completed'];

export default function ShipmentDetailScreen({ route, navigation }: any) {
  const { bookingId } = route.params;
  const [data, setData] = useState<any | null>(null);
  const [busy, setBusy] = useState(false);
  const [stars, setStars] = useState(5);

  const load = useCallback(async () => {
    try { setData(await api.get(`/bookings/${bookingId}`)); } catch { /* keep last */ }
  }, [bookingId]);
  useFocusEffect(useCallback(() => { load(); }, [load]));

  if (!data) return <View style={{ flex: 1, backgroundColor: C.canvas }} />;
  const b = data.booking ?? data;
  const st: string = b.status;

  const setStatus = async (to: string) => {
    setBusy(true);
    try { await api.patch(`/bookings/${bookingId}/status`, { to }); await load(); }
    catch (e: any) { Alert.alert('Not allowed', e.message); }
    setBusy(false);
  };

  const rate = async () => {
    setBusy(true);
    try {
      await api.post('/ratings', { booking_id: bookingId, score: stars });
      Alert.alert('Thanks!', 'Your rating helps other shippers.');
      await load();
    } catch (e: any) { Alert.alert('Rating', e.message); }
    setBusy(false);
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={{ padding: 14, gap: 12 }}>
      <Card>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
          <Text style={{ fontWeight: '900', fontSize: 17, color: C.ink }}>
            {b.cargo.origin} → {b.cargo.destination}
          </Text>
          <Badge tone={statusTone(st)} text={STATUS_LABEL[st] ?? st} />
        </View>
        <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 4 }}>
          {b.cargo.cargo_type} · {b.cargo.cargo_weight_tons} T · {b.truck.truck_type} ({b.truck.registration_number})
        </Text>
        <Text style={{ fontSize: 16, fontWeight: '900', color: C.ink, marginTop: 8 }}>
          ₹{Number(b.agreed_price_inr || 0).toLocaleString('en-IN')}
        </Text>
      </Card>

      <Card>
        <Text style={{ fontWeight: '800', color: C.ink, marginBottom: 10 }}>Status timeline</Text>
        {FLOW.map((step, i) => {
          const reached = FLOW.indexOf(st) >= i;
          return (
            <View key={step} style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 8 }}>
              <View style={{
                width: 12, height: 12, borderRadius: 6, marginRight: 10,
                backgroundColor: reached ? C.ok : C.line,
              }} />
              <Text style={{ fontWeight: reached ? '800' : '500', color: reached ? C.ink : C.inkFaint }}>
                {STATUS_LABEL[step]}
              </Text>
            </View>
          );
        })}
        {['cancelled', 'disputed'].includes(st) && <Badge tone="danger" text={STATUS_LABEL[st]} />}
      </Card>

      {st === 'accepted' && (
        <Button title={busy ? '…' : 'Confirm this truck'} loading={busy} onPress={() => setStatus('confirmed')} />
      )}
      {st === 'delivered' && (
        <Button title={busy ? '…' : 'Mark completed'} loading={busy} onPress={() => setStatus('completed')} />
      )}
      {['confirmed', 'pickup_ready', 'picked_up', 'in_transit'].includes(st) && (
        <Button title="Track live" onPress={() => navigation.navigate('Tracking', { bookingId, booking: b })} />
      )}
      {st === 'completed' && !data.my_rating && (
        <Card>
          <Text style={{ fontWeight: '800', color: C.ink }}>Rate the truck owner</Text>
          <View style={{ flexDirection: 'row', gap: 6, marginVertical: 10 }}>
            {[1, 2, 3, 4, 5].map((n) => (
              <Pressable key={n} onPress={() => setStars(n)}>
                <Text style={{ fontSize: 28, color: n <= stars ? C.brand : C.line }}>★</Text>
              </Pressable>
            ))}
          </View>
          <Button title="Submit rating" loading={busy} onPress={rate} />
        </Card>
      )}
      {['pending', 'accepted', 'confirmed'].includes(st) && (
        <Button title="Cancel booking" variant="danger" onPress={() => setStatus('cancelled')} />
      )}
    </ScrollView>
  );
}
