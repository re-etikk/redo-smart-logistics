import React, { useCallback, useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { api } from '../lib/api';
import { supabase } from '../lib/supabase';
import { C } from '../lib/theme';
import { Badge, Button, Card, Empty } from '../components/ui';

export default function ProfileScreen({ onSignOut }: { onSignOut: () => void }) {
  const [profile, setProfile] = useState<any | null>(null);
  const [reviews, setReviews] = useState<any[]>([]);
  const navigation = useNavigation<any>();

  useFocusEffect(useCallback(() => {
    api.get('/auth/profile').then((p: any) => setProfile(p)).catch(() => {});
    api.get<any[]>('/reviews').then(setReviews).catch(() => {});
  }, []));

  const avg = reviews.length ? (reviews.reduce((a, r) => a + r.score, 0) / reviews.length).toFixed(1) : null;

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={{ padding: 14, gap: 12 }}>
      <Card>
        <Text style={{ fontSize: 18, fontWeight: '900', color: C.ink }}>{profile?.full_name ?? '…'}</Text>
        <Text style={{ fontSize: 12, color: C.inkFaint }}>Truck Owner{avg ? ` · ★ ${avg} (${reviews.length} reviews)` : ' · New partner'}</Text>
        <View style={{ marginTop: 6 }}><Badge tone="ok" text="Partner account" /></View>
      </Card>

      <Card>
        {[
          ['🚚  My Trucks', 'Trucks'],
          ['📄  Documents (KYC)', 'Documents'],
          ['🔔  Notifications', 'Notifications'],
          ['🎧  Support', 'Support'],
        ].map(([label, screen]) => (
          <Text key={screen} onPress={() => navigation.navigate(screen)}
            style={{ paddingVertical: 12, fontSize: 15, fontWeight: '700', color: C.ink, borderBottomWidth: 1, borderBottomColor: C.line }}>
            {label}
          </Text>
        ))}
      </Card>

      <Card>
        <Text style={{ fontWeight: '800', color: C.ink, marginBottom: 8 }}>Latest reviews</Text>
        {reviews.length === 0 && <Empty title="No reviews yet." hint="Ratings appear after completed trips." />}
        {reviews.slice(0, 3).map((r) => (
          <View key={r.id} style={{ paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: C.line }}>
            <Text style={{ fontWeight: '800', color: C.ink }}>{r.rater_name} · {'★'.repeat(r.score)}</Text>
            {r.comment ? <Text style={{ fontSize: 12, color: C.inkSoft }}>{r.comment}</Text> : null}
          </View>
        ))}
      </Card>

      <Button title="Sign out" variant="danger" onPress={() => {
        Alert.alert('Sign out?', '', [
          { text: 'Cancel' },
          { text: 'Sign out', style: 'destructive', onPress: async () => { await supabase.auth.signOut(); onSignOut(); } },
        ]);
      }} />
    </ScrollView>
  );
}
