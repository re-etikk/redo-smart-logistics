import React, { useCallback, useState } from 'react';
import { Alert, FlatList, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Badge, Button, Card, Empty, Input, Label } from '../components/ui';

export default function SupportScreen() {
  const [tickets, setTickets] = useState<any[] | null>(null);
  const [subject, setSubject] = useState('');
  const [description, setDescription] = useState('');
  const [busy, setBusy] = useState(false);
  const load = useCallback(() => { api.get<any[]>('/support/tickets').then(setTickets).catch(() => setTickets([])); }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));

  const submit = async () => {
    if (!subject.trim()) return;
    setBusy(true);
    try {
      await api.post('/support/tickets', { subject, description, category: 'App' });
      setSubject(''); setDescription('');
      Alert.alert('Ticket raised', 'Our team will respond soon.');
      load();
    } catch (e: any) { Alert.alert('Error', e.message); }
    setBusy(false);
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>Support</Text>
      <Card style={{ marginTop: 12 }}>
        <Label>Subject</Label>
        <Input value={subject} onChangeText={setSubject} placeholder="What do you need help with?" />
        <Label>Details</Label>
        <Input value={description} onChangeText={setDescription} multiline numberOfLines={3} />
        <View style={{ height: 12 }} />
        <Button title={busy ? 'Submitting…' : 'Raise ticket'} loading={busy} onPress={submit} />
      </Card>
      <Text style={{ fontWeight: '800', color: C.ink, marginVertical: 12 }}>My tickets</Text>
      {tickets !== null && tickets.length === 0 && <Empty title="No tickets yet." />}
      <FlatList data={tickets ?? []} keyExtractor={(t) => t.id} contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: t }) => (
          <Card>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <Text style={{ fontWeight: '800', color: C.ink, flex: 1 }}>{t.subject}</Text>
              <Badge tone={['resolved', 'closed'].includes(t.status) ? 'ok' : 'warn'} text={t.status.replace('_', ' ')} />
            </View>
            {(t.messages ?? []).slice(-2).map((m: any, i: number) => (
              <Text key={i} style={{ fontSize: 12, color: C.inkSoft, marginTop: 4 }}>
                <Text style={{ fontWeight: '800' }}>{m.author_name}: </Text>{m.body}
              </Text>
            ))}
          </Card>
        )} />
    </View>
  );
}
