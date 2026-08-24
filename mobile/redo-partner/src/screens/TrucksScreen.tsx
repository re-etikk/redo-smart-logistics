import React, { useCallback, useState } from 'react';
import { Alert, FlatList, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Badge, Button, Card, Empty, Input, Label } from '../components/ui';

export default function TrucksScreen() {
  const [trucks, setTrucks] = useState<any[] | null>(null);
  const [form, setForm] = useState({ registration_number: '', truck_type: '22FT', default_capacity_tons: '9' });
  const [busy, setBusy] = useState(false);
  const load = useCallback(() => { api.get<any[]>('/trucks').then(setTrucks).catch(() => setTrucks([])); }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));

  const save = async () => {
    if (!form.registration_number) return;
    setBusy(true);
    try {
      await api.post('/trucks', { ...form, default_capacity_tons: +form.default_capacity_tons, body_type: 'Closed container' });
      setForm({ registration_number: '', truck_type: '22FT', default_capacity_tons: '9' });
      load();
    } catch (e: any) { Alert.alert('Error', e.message); }
    setBusy(false);
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Card>
        <Text style={{ fontWeight: '900', color: C.ink }}>Add truck</Text>
        <Label>Registration number</Label>
        <Input autoCapitalize="characters" value={form.registration_number}
          onChangeText={(v) => setForm({ ...form, registration_number: v })} placeholder="DL 01 AB 4321" />
        <View style={{ flexDirection: 'row', gap: 12 }}>
          <View style={{ flex: 1 }}>
            <Label>Type (14/17/22/32FT)</Label>
            <Input autoCapitalize="characters" value={form.truck_type} onChangeText={(v) => setForm({ ...form, truck_type: v })} />
          </View>
          <View style={{ flex: 1 }}>
            <Label>Capacity (T)</Label>
            <Input keyboardType="decimal-pad" value={form.default_capacity_tons}
              onChangeText={(v) => setForm({ ...form, default_capacity_tons: v })} />
          </View>
        </View>
        <View style={{ height: 12 }} />
        <Button title={busy ? 'Saving…' : 'Save truck'} loading={busy} onPress={save} />
      </Card>
      <Text style={{ fontWeight: '800', color: C.ink, marginVertical: 12 }}>My trucks</Text>
      {trucks !== null && trucks.length === 0 && <Empty title="No trucks yet." hint="Your first truck unlocks load matching." />}
      <FlatList data={trucks ?? []} keyExtractor={(t) => t.truck_id} contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: t }) => (
          <Card>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <Text style={{ fontWeight: '900', color: C.ink }}>{t.truck_type} · {t.registration_number}</Text>
              <Badge tone={t.status === 'available' ? 'ok' : 'neutral'} text={t.status} />
            </View>
            <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 3 }}>
              {t.default_capacity_tons} T · {t.driver_rating != null ? `★ ${Number(t.driver_rating).toFixed(1)}` : 'New — no ratings yet'}
            </Text>
          </Card>
        )} />
    </View>
  );
}
