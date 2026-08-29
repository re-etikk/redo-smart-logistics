// Customer onboarding after signup: quick business profile, then straight to booking.
import React, { useState } from 'react';
import { Alert, ScrollView, StyleSheet, Text, View } from 'react-native';
import { api } from '../lib/api';
import { supabase } from '../lib/supabase';
import { useI18n } from '../lib/i18n';
import { C } from '../lib/theme';
import { Button, Card, Input, Label, LogoRow } from '../components/ui';

export default function CustomerOnboarding({ onDone }: { onDone: () => void }) {
  const { t } = useI18n();
  const [form, setForm] = useState({ company_name: '', full_name: '', phone: '' });
  const [busy, setBusy] = useState(false);

  const finish = async () => {
    setBusy(true);
    try {
      const { data: sess } = await supabase.auth.getSession();
      const uid = sess.session?.user?.id;
      if (uid) {
        await supabase.from('profiles').upsert({
          id: uid,
          company_name: form.company_name,
          full_name: form.full_name || sess.session?.user?.email?.split('@')[0] || 'Shipper',
          phone: form.phone || null,
          role: 'sme',
          onboarding_complete: true,
        });
      }
      await api.patch('/auth/profile', {
        company_name: form.company_name,
        ...(form.full_name ? { full_name: form.full_name } : {}),
        ...(form.phone ? { phone: form.phone } : {}),
        role: 'sme',
        onboarding_complete: true,
      }).catch(() => null);
      onDone();
    } catch (e: any) {
      Alert.alert('Error', e.message || 'Could not save profile.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={{ padding: 20, paddingTop: 72 }}>
      <View style={{ alignItems: 'center', marginBottom: 18 }}><LogoRow /></View>
      <Card>
        <Text style={s.h1}>{t('business_title')}</Text>
        <Text style={s.sub}>{t('business_sub')}</Text>
        <Label>{t('business_name')}</Label>
        <Input value={form.company_name} onChangeText={(v) => setForm({ ...form, company_name: v })} />
        <Label>{t('contact_person')}</Label>
        <Input value={form.full_name} onChangeText={(v) => setForm({ ...form, full_name: v })} />
        <Label>{t('phone')}</Label>
        <Input keyboardType="phone-pad" value={form.phone} onChangeText={(v) => setForm({ ...form, phone: v })} />
        <View style={{ height: 18 }} />
        <Button title={busy ? '…' : t('finish')} loading={busy} disabled={!form.company_name} onPress={finish} />
      </Card>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  h1: { fontSize: 20, fontWeight: '900', color: C.ink },
  sub: { fontSize: 13, color: C.inkFaint, marginTop: 2, marginBottom: 4 },
});
