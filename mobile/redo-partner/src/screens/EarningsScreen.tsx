import React, { useCallback, useState } from 'react';
import { FlatList, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Badge, Card, Empty, Stat } from '../components/ui';

export default function EarningsScreen() {
  const [data, setData] = useState<any | null>(null);
  useFocusEffect(useCallback(() => {
    api.get('/earnings').then(setData).catch(() => setData({ totals: {}, transactions: [] }));
  }, []));
  const t = data?.totals ?? {};
  const txns: any[] = data?.transactions ?? [];

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink, marginBottom: 12 }}>Earnings</Text>
      <View style={{ flexDirection: 'row', gap: 10, marginBottom: 10 }}>
        <Stat label="Total earned" value={`₹${Number(t.completed_inr ?? 0).toLocaleString('en-IN')}`} />
        <Stat label="Pending" value={`₹${Number(t.pending_inr ?? 0).toLocaleString('en-IN')}`} />
      </View>
      <View style={{ flexDirection: 'row', gap: 10, marginBottom: 12 }}>
        <Stat label="Trips done" value={t.completed_trips ?? 0} />
        <Stat label="Avg / trip" value={`₹${Number(t.avg_per_trip_inr ?? 0).toLocaleString('en-IN')}`} />
      </View>
      {data !== null && txns.length === 0 && (
        <Empty title="No earnings yet." hint="Complete trips to see payouts. Amounts settle when the shipper confirms delivery." />
      )}
      <FlatList data={txns} keyExtractor={(x) => x.booking_id} contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: x }) => (
          <Card>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <Text style={{ fontWeight: '800', color: C.ink }}>{x.route}</Text>
              <Badge tone={x.settled ? 'ok' : 'warn'} text={x.settled ? 'Paid' : 'Pending'} />
            </View>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginTop: 6 }}>
              <Text style={{ fontSize: 11, color: C.inkFaint }}>
                {new Date(x.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}
              </Text>
              <Text style={{ fontWeight: '900', color: C.ink }}>₹{Number(x.amount_inr).toLocaleString('en-IN')}</Text>
            </View>
          </Card>
        )} />
    </View>
  );
}
