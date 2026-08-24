import React, { useEffect, useState } from 'react';
import { FlatList, Text, View } from 'react-native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Card, Empty } from '../components/ui';

export default function RateCardScreen() {
  const [rates, setRates] = useState<any[] | null>(null);
  useEffect(() => { api.get<any[]>('/rates').then(setRates).catch(() => setRates([])); }, []);

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>Rate Card (FTL)</Text>
      <Text style={{ fontSize: 12, color: C.inkFaint, marginBottom: 12 }}>
        Indicative lane rates, excl. GST. Part-load prices are live per matched truck.
      </Text>
      {rates !== null && rates.length === 0 && <Empty title="No published rates." />}
      <FlatList data={rates ?? []} keyExtractor={(r) => r.origin + r.destination} contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: r }) => (
          <Card>
            <Text style={{ fontWeight: '900', color: C.ink }}>{r.origin} → {r.destination}</Text>
            <Text style={{ fontSize: 11, color: C.inkFaint }}>{Number(r.distance_km).toLocaleString('en-IN')} km · {r.transit_days}</Text>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginTop: 8 }}>
              {(['ft20', 'ft24', 'ft32', 'ft40'] as const).map((k) => (
                <View key={k} style={{ alignItems: 'center' }}>
                  <Text style={{ fontSize: 10, fontWeight: '700', color: C.inkFaint }}>{k.slice(2)} FT</Text>
                  <Text style={{ fontWeight: '800', color: C.ink }}>₹{(Number(r[k]) / 1000).toFixed(0)}k</Text>
                </View>
              ))}
            </View>
          </Card>
        )} />
    </View>
  );
}
