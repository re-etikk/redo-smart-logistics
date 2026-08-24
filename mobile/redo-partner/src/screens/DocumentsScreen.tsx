// KYC uploads → private Supabase bucket; masked reference; admin verifies from web console.
import React, { useCallback, useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { useFocusEffect } from '@react-navigation/native';
import { supabase } from '../lib/supabase';
import { C } from '../lib/theme';
import { Badge, Button, Card } from '../components/ui';

const DOCS = [
  { type: 'driving_licence', label: 'Driving Licence' },
  { type: 'vehicle_rc', label: 'RC (Registration Certificate)' },
  { type: 'insurance', label: 'Insurance Certificate' },
  { type: 'identity', label: 'Owner ID Proof' },
  { type: 'permit', label: 'Permit (National)' },
  { type: 'fitness', label: 'Fitness Certificate' },
];

export default function DocumentsScreen() {
  const [rows, setRows] = useState<any[]>([]);
  const [busyType, setBusyType] = useState<string | null>(null);

  const load = useCallback(async () => {
    const { data } = await supabase.from('kyc_verifications').select('*').order('created_at');
    setRows(data ?? []);
  }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));

  const upload = async (type: string) => {
    const picked = await ImagePicker.launchImageLibraryAsync({ quality: 0.6 });
    if (picked.canceled) return;
    setBusyType(type);
    try {
      const { data: s } = await supabase.auth.getSession();
      const uid = s.session!.user.id;
      const path = `${uid}/${type}-${Date.now()}.jpg`;
      const file = await fetch(picked.assets[0].uri).then((r) => r.arrayBuffer());
      const { error } = await supabase.storage.from('kyc-documents').upload(path, file, { contentType: 'image/jpeg' });
      if (error) throw new Error(error.message);
      const { error: e2 } = await supabase.from('kyc_verifications').insert({
        user_id: uid, document_type: type, verification_status: 'pending',
        verification_source: 'manual_upload', document_reference_masked: `upload:…${path.slice(-10)}`,
      });
      if (e2) throw new Error(e2.message);
      Alert.alert('Uploaded', 'Pending admin review — you will get a notification on the decision.');
      load();
    } catch (e: any) { Alert.alert('Upload failed', e.message); }
    setBusyType(null);
  };

  const statusOf = (t: string) => rows.filter((r) => r.document_type === t).at(-1);

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={{ padding: 14, gap: 10 }}>
      <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>Documents</Text>
      <Text style={{ fontSize: 12, color: C.inkFaint, marginBottom: 4 }}>
        Files go to a private bucket; only masked references are stored.
      </Text>
      {DOCS.map((d) => {
        const row = statusOf(d.type);
        const st = row?.verification_status;
        return (
          <Card key={d.type}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={{ fontWeight: '800', color: C.ink }}>{d.label}</Text>
              {st === 'verified' && <Badge tone="ok" text="Verified" />}
              {st === 'pending' && <Badge tone="warn" text="Pending" />}
              {st === 'rejected' && <Badge tone="danger" text="Rejected" />}
              {!st && <Badge text="Not uploaded" />}
            </View>
            <View style={{ height: 10 }} />
            <Button title={busyType === d.type ? 'Uploading…' : st ? 'Replace document' : 'Upload document'}
              variant="secondary" loading={busyType === d.type} onPress={() => upload(d.type)} />
          </Card>
        );
      })}
    </ScrollView>
  );
}
