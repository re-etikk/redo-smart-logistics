// Website-style header for list screens: logo left, live notification bell right.
import React, { useCallback, useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { api } from '../lib/api';
import { supabase } from '../lib/supabase';
import { C } from '../lib/theme';
import { LogoRow } from './ui';

export default function AppHeader() {
  const [unread, setUnread] = useState(0);
  const navigation = useNavigation<any>();

  const refresh = useCallback(() => {
    api.get<any[]>('/notifications')
      .then((n) => setUnread(n.filter((x) => !x.read).length))
      .catch(() => {});
  }, []);

  useEffect(() => {
    refresh();
    // Live bell — new notifications land without any refresh (RLS scopes to own rows).
    const ch = supabase.channel(`bell-${Math.random().toString(36).slice(2)}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, refresh)
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [refresh]);

  return (
    <View style={s.wrap}>
      <LogoRow />
      <Pressable onPress={() => navigation.navigate('Notifications')} style={s.bell} accessibilityLabel="Notifications">
        <Text style={{ fontSize: 20 }}>🔔</Text>
        {unread > 0 && (
          <View style={s.badge}><Text style={s.badgeText}>{unread}</Text></View>
        )}
      </Pressable>
    </View>
  );
}

const s = StyleSheet.create({
  wrap: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    backgroundColor: C.white, borderBottomWidth: 1, borderBottomColor: C.line,
    paddingHorizontal: 14, paddingTop: 46, paddingBottom: 10,
  },
  bell: { padding: 6 },
  badge: {
    position: 'absolute', top: 0, right: 0, backgroundColor: C.brand,
    borderRadius: 999, minWidth: 16, height: 16, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 3,
  },
  badgeText: { fontSize: 10, fontWeight: '900', color: C.ink },
});
