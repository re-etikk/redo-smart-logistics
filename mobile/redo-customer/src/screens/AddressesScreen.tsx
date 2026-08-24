import React, { useCallback, useState } from 'react';
import { Alert, FlatList, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Badge, Button, Card, Empty, Input, Label } from '../components/ui';

export default function AddressesScreen() {
  const [items, setItems] = useState<any[] | null>(null);
  const [form, setForm] = useState({ label: '', city: '', contact_name: '', contact_phone: '' });
  const [busy, setBusy] = useState(false);
  const load = useCallback(() => { api.get<any[]>('/addresses').then(setItems).catch(() => setItems([])); }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));

  const save = async () => {
    if (!form.label || !form.city) return;
    setBusy(true);
    try {
      await api.post('/addresses', { ...form, type: 'pickup' });
      setForm({ label: '', city: '', contact_name: '', contact_phone: '' });
      load();
    } catch (e: any) { Alert.alert('Error', e.message); }
    setBusy(false);
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Card>
        <Text style={{ fontWeight: '900', color: C.ink }}>Add address</Text>
        <Label>Label</Label>
        <Input value={form.label} onChangeText={(v) => setForm({ ...form, label: v })} placeholder="Warehouse, Bhiwandi" />
        <Label>City</Label>
        <Input value={form.city} onChangeText={(v) => setForm({ ...form, city: v })} />
        <Label>Contact name</Label>
        <Input value={form.contact_name} onChangeText={(v) => setForm({ ...form, contact_name: v })} />
        <Label>Contact phone</Label>
        <Input keyboardType="phone-pad" value={form.contact_phone} onChangeText={(v) => setForm({ ...form, contact_phone: v })} />
        <View style={{ height: 12 }} />
        <Button title={busy ? 'Saving…' : 'Save address'} loading={busy} onPress={save} />
      </Card>
      <Text style={{ fontWeight: '800', color: C.ink, marginVertical: 12 }}>Saved addresses</Text>
      {items !== null && items.length === 0 && <Empty title="No saved addresses." />}
      <FlatList data={items ?? []} keyExtractor={(a) => a.id} contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: a }) => (
          <Card>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <Text style={{ fontWeight: '800', color: C.ink }}>{a.label}</Text>
              <Badge tone="accent" text={a.type} />
            </View>
            <Text style={{ fontSize: 12, color: C.inkSoft }}>{a.city}{a.contact_name ? ` · ${a.contact_name}` : ''}</Text>
          </Card>
        )} />
    </View>
  );
}
