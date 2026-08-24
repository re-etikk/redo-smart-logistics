// Rapido-style location permission ask, with an honest rationale.
import React, { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import * as Location from 'expo-location';
import { useI18n } from '../lib/i18n';
import { C } from '../lib/theme';
import { Button, LogoRow } from '../components/ui';

export default function PermissionScreen({ onDone, whyKey }: { onDone: () => void; whyKey: 'loc_why_c' | 'loc_why_p' }) {
  const { t } = useI18n();
  const [busy, setBusy] = useState(false);

  const ask = async () => {
    setBusy(true);
    try { await Location.requestForegroundPermissionsAsync(); } catch { /* user decides in OS dialog */ }
    setBusy(false);
    onDone(); // proceed either way — features degrade gracefully without it
  };

  return (
    <View style={s.wrap}>
      <View style={{ alignItems: 'center', marginBottom: 28 }}><LogoRow /></View>
      <Text style={{ fontSize: 64, textAlign: 'center' }}>📍</Text>
      <Text style={s.title}>{t('loc_title')}</Text>
      <Text style={s.body}>{t(whyKey)}</Text>
      <View style={{ flex: 1 }} />
      <Button title={busy ? '…' : t('loc_allow')} loading={busy} onPress={ask} />
      <View style={{ height: 10 }} />
      <Button title={t('loc_skip')} variant="secondary" onPress={onDone} />
      <View style={{ height: 16 }} />
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.canvas, padding: 24, paddingTop: 80 },
  title: { fontSize: 22, fontWeight: '900', color: C.ink, textAlign: 'center', marginTop: 12 },
  body: { fontSize: 14, color: C.inkSoft, textAlign: 'center', marginTop: 8, lineHeight: 21 },
});
