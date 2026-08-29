import React, { useCallback, useState } from 'react';
import { FlatList, Pressable, RefreshControl, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { STATUS_LABEL, type Booking } from '../lib/types';
import { Badge, Card, Empty, Stat, statusTone } from '../components/ui';
import AppHeader from '../components/AppHeader';
import { useLive } from '../lib/useLive';

export default function BookingsScreen({ navigation }: any) {
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const load = useCallback(async () => {
    try { setBookings(await api.get<Booking[]>('/bookings')); } catch { setBookings([]); }
    setRefreshing(false);
  }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));
  useLive('bookings', load);

  const b = bookings ?? [];
  const active = b.filter((x) => ['confirmed', 'pickup_ready', 'picked_up', 'in_transit'].includes(x.status));

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas }}>
      <AppHeader />
      <View style={{ flex: 1, padding: 14 }}>
      <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink, marginBottom: 12 }}>My Bookings</Text>
      <View style={{ flexDirection: 'row', gap: 10, marginBottom: 12 }}>
        <Stat label="Total" value={b.length} />
        <Stat label="Active trips" value={active.length} />
        <Stat label="Completed" value={b.filter((x) => x.status === 'completed').length} />
      </View>
      {bookings !== null && b.length === 0 && (
        <Empty title="No bookings yet." hint="Accept a load from the Home tab to start earning." />
      )}
      <FlatList data={b} keyExtractor={(x) => x.id}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load(); }} />}
        contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: x }) => (
          <Pressable onPress={() => navigation.navigate('BookingDetail', { bookingId: x.id })}>
            <Card>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                <Text style={{ fontWeight: '900', color: C.ink }}>{x.cargo.origin} → {x.cargo.destination}</Text>
                <Badge tone={statusTone(x.status)} text={STATUS_LABEL[x.status] ?? x.status} />
              </View>
              <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 4 }}>
                {x.cargo.cargo_weight_tons} T · ₹{Number(x.agreed_price_inr || 0).toLocaleString('en-IN')}
              </Text>
            </Card>
          </Pressable>
        )} />
      </View>
    </View>
  );
}
