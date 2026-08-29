import React, { useCallback, useState } from 'react';
import { FlatList, Pressable, RefreshControl, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { STATUS_LABEL, type Booking } from '../lib/types';
import { Badge, Card, Empty, Stat, statusTone } from '../components/ui';
import AppHeader from '../components/AppHeader';
import { useLive } from '../lib/useLive';

export default function ShipmentsScreen({ navigation }: any) {
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    try { setBookings(await api.get<Booking[]>('/bookings')); }
    catch { setBookings([]); }
    setRefreshing(false);
  }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));
  // Owner accepts / status moves anywhere → this list updates live.
  useLive('bookings', load);

  const b = bookings ?? [];
  const active = b.filter((x) => ['confirmed', 'pickup_ready', 'picked_up', 'in_transit'].includes(x.status)).length;

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas }}>
      <AppHeader />
      <View style={{ flex: 1, padding: 14 }}>
        <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink, marginBottom: 12 }}>My Shipments</Text>
        <View style={{ flexDirection: 'row', gap: 10, marginBottom: 12 }}>
          <Stat label="Total" value={b.length} />
          <Stat label="Active" value={active} />
          <Stat label="Delivered" value={b.filter((x) => ['delivered', 'completed'].includes(x.status)).length} />
        </View>
        {bookings !== null && b.length === 0 && (
          <Empty title="No shipments yet." hint="Book your first truck from the Home tab." />
        )}
        <FlatList
          data={b}
          keyExtractor={(x) => x.id}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load(); }} />}
          contentContainerStyle={{ gap: 10 }}
          renderItem={({ item: x }) => (
            <Pressable onPress={() => navigation.navigate('ShipmentDetail', { bookingId: x.id })}>
              <Card>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                  <Text style={{ fontWeight: '900', color: C.ink }}>{x.cargo.origin} → {x.cargo.destination}</Text>
                  <Badge tone={statusTone(x.status)} text={STATUS_LABEL[x.status] ?? x.status} />
                </View>
                <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 4 }}>
                  {x.cargo.cargo_type} · {x.cargo.cargo_weight_tons} T · ₹{Number(x.agreed_price_inr || 0).toLocaleString('en-IN')}
                </Text>
                <Text style={{ fontSize: 11, color: C.inkFaint, marginTop: 2 }}>
                  {new Date(x.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                </Text>
              </Card>
            </Pressable>
          )}
        />
      </View>
    </View>
  );
}
