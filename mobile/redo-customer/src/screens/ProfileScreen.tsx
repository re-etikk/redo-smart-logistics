import React, { useCallback, useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { api } from '../lib/api';
import { supabase } from '../lib/supabase';
import { C } from '../lib/theme';
import { Badge, Button, Card, Empty } from '../components/ui';

export default function ProfileScreen({ onSignOut }: { onSignOut: () => void }) {
  const [profile, setProfile] = useState<any | null>(null);
  const [invoices, setInvoices] = useState<any[]>([]);
  const navigation = useNavigation<any>();

  useFocusEffect(useCallback(() => {
    api.get('/auth/profile').then((p: any) => setProfile(p)).catch(() => {});
    api.get<any[]>('/invoices').then(setInvoices).catch(() => {});
  }, []));

  const signOut = async () => {
    await supabase.auth.signOut();
    onSignOut();
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={{ padding: 14, gap: 12 }}>
      <Card>
        <Text style={{ fontSize: 18, fontWeight: '900', color: C.ink }}>{profile?.full_name ?? '…'}</Text>
        <Text style={{ fontSize: 12, color: C.inkFaint }}>{profile?.company_name || 'Shipper'}</Text>
        <View style={{ marginTop: 6 }}><Badge tone="ok" text="Shipper account" /></View>
      </Card>


      <Card>
        {[
          ['🔔  Notifications', 'Notifications'],
          ['🎧  Support', 'Support'],
          ['🏷️  Rate Card', 'RateCard'],
          ['📍  Saved Addresses', 'Addresses'],
        ].map(([label, screen]) => (
          <Text key={screen} onPress={() => navigation.navigate(screen)}
            style={{ paddingVertical: 12, fontSize: 15, fontWeight: '700', color: C.ink, borderBottomWidth: 1, borderBottomColor: C.line }}>
            {label}
          </Text>
        ))}
      </Card>
      <Card>
        <Text style={{ fontWeight: '800', color: C.ink, marginBottom: 8 }}>Recent invoices (GST 18%)</Text>
        {invoices.length === 0 && <Empty title="No invoices yet." hint="Generated automatically when a shipment completes." />}
        {invoices.slice(0, 5).map((i) => (
          <View key={i.id} style={{ flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: C.line }}>
            <View>
              <Text style={{ fontWeight: '800', color: C.accent }}>{i.invoice_no}</Text>
              <Text style={{ fontSize: 11, color: C.inkFaint }}>{i.route}</Text>
            </View>
            <Text style={{ fontWeight: '900', color: C.ink }}>₹{Number(i.total_inr).toLocaleString('en-IN')}</Text>
          </View>
        ))}
      </Card>

      <Button title="Sign out" variant="danger" onPress={() => {
        Alert.alert('Sign out?', '', [
          { text: 'Cancel' }, { text: 'Sign out', style: 'destructive', onPress: signOut },
        ]);
      }} />
      <Text style={{ fontSize: 11, color: C.inkFaint, textAlign: 'center' }}>
        Redo Transport &amp; Logistics · Same account as the website
      </Text>
    </ScrollView>
  );
}
