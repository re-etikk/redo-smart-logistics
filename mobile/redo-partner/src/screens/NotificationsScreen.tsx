import React, { useCallback, useState } from 'react';
import { FlatList, Pressable, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Card, Empty } from '../components/ui';

export default function NotificationsScreen() {
  const [items, setItems] = useState<any[] | null>(null);
  const load = useCallback(() => { api.get<any[]>('/notifications').then(setItems).catch(() => setItems([])); }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));

  const markRead = async (n: any) => {
    if (n.read) return;
    try { await api.patch(`/notifications/${n.id}/read`); load(); } catch { /* noop */ }
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink, marginBottom: 12 }}>Notifications</Text>
      {items !== null && items.length === 0 && <Empty title="Nothing here yet." />}
      <FlatList data={items ?? []} keyExtractor={(n) => n.id} contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: n }) => (
          <Pressable onPress={() => markRead(n)}>
            <Card style={!n.read ? { borderColor: C.accent } : undefined}>
              <Text style={{ fontWeight: n.read ? '600' : '900', color: C.ink }}>{n.title}</Text>
              <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 2 }}>{n.body}</Text>
              <Text style={{ fontSize: 10, color: C.inkFaint, marginTop: 4 }}>
                {new Date(n.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}
              </Text>
            </Card>
          </Pressable>
        )} />
    </View>
  );
}
