import React, { useCallback, useState } from 'react';
import { Alert, FlatList, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Badge, Button, Card, Empty, Input, Label } from '../components/ui';

const CITIES = ['Mumbai', 'Delhi', 'Pune', 'Jaipur', 'Surat'];

export default function TrucksScreen() {
  const [trucks, setTrucks] = useState<any[] | null>(null);
  const [form, setForm] = useState({ registration_number: '', truck_type: '22FT', default_capacity_tons: '9' });
  const [busy, setBusy] = useState(false);
  const [tripFor, setTripFor] = useState<string | null>(null);
  const [tripFrom, setTripFrom] = useState('Mumbai');
  const [tripTo, setTripTo] = useState('Delhi');
  const load = useCallback(() => { api.get<any[]>('/trucks').then(setTrucks).catch(() => setTrucks([])); }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));

  const postTrip = async (truck: any) => {
    if (tripFrom === tripTo) { Alert.alert('Route', 'From and To must differ.'); return; }
    setBusy(true);
    try {
      const d = new Date(Date.now() + 864e5); d.setHours(10, 0, 0, 0);
      await api.post(`/trucks/${truck.truck_id}/trips`, {
        origin: tripFrom, destination: tripTo,
        departure_at: d.toISOString(),
        available_capacity_tons: Number(truck.default_capacity_tons),
      });
      setTripFor(null);
      Alert.alert('Trip posted!', 'You will now appear in shipper matches on this corridor.');
    } catch (e: any) { Alert.alert('Error', e.message); }
    setBusy(false);
  };

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
            <View style={{ height: 10 }} />
            <Button variant="secondary" title={tripFor === t.truck_id ? 'Close' : '+ Post return trip'}
              onPress={() => setTripFor(tripFor === t.truck_id ? null : t.truck_id)} />
            {tripFor === t.truck_id && (
              <View style={{ marginTop: 10 }}>
                <Label>Empty at (From)</Label>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 4 }}>
                  {CITIES.map((c) => (
                    <Text key={c} onPress={() => setTripFrom(c)}
                      style={{ paddingHorizontal: 12, paddingVertical: 8, borderRadius: 999, borderWidth: 1,
                        borderColor: tripFrom === c ? C.accent : C.line, backgroundColor: tripFrom === c ? C.accentSoft : C.white,
                        fontWeight: '700', fontSize: 13, color: C.ink }}>{c}</Text>
                  ))}
                </View>
                <Label>Returning to</Label>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 4 }}>
                  {CITIES.map((c) => (
                    <Text key={c} onPress={() => setTripTo(c)}
                      style={{ paddingHorizontal: 12, paddingVertical: 8, borderRadius: 999, borderWidth: 1,
                        borderColor: tripTo === c ? C.accent : C.line, backgroundColor: tripTo === c ? C.accentSoft : C.white,
                        fontWeight: '700', fontSize: 13, color: C.ink }}>{c}</Text>
                  ))}
                </View>
                <View style={{ height: 12 }} />
                <Button title={busy ? 'Posting…' : 'Post trip (tomorrow 10 AM)'} loading={busy} onPress={() => postTrip(t)} />
              </View>
            )}
          </Card>
        )} />
    </View>
  );
}
