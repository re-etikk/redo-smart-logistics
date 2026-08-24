// Rapido-style first screen: pick your language (persisted on device).
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useI18n, type Lang } from '../lib/i18n';
import { C, R } from '../lib/theme';
import { LogoRow } from '../components/ui';

const LANGS: { code: Lang; native: string; sub: string }[] = [
  { code: 'hi', native: 'हिन्दी', sub: 'Hindi' },
  { code: 'en', native: 'English', sub: 'English' },
];

export default function LanguageScreen({ onDone }: { onDone: () => void }) {
  const { lang, setLang, t } = useI18n();
  return (
    <View style={s.wrap}>
      <View style={{ alignItems: 'center', marginBottom: 28 }}><LogoRow /></View>
      <Text style={s.title}>{t('choose_language')}</Text>
      <Text style={{ fontSize: 18, color: C.inkFaint, marginTop: 2 }}>अपनी भाषा चुनें</Text>
      <View style={{ marginTop: 24, gap: 12 }}>
        {LANGS.map((l) => (
          <Pressable key={l.code} onPress={() => setLang(l.code)}
            style={[s.card, lang === l.code && { borderColor: C.accent, backgroundColor: C.accentSoft }]}>
            <Text style={{ fontSize: 22, fontWeight: '900', color: C.ink }}>{l.native}</Text>
            <Text style={{ fontSize: 12, color: C.inkFaint }}>{l.sub}</Text>
          </Pressable>
        ))}
      </View>
      <View style={{ flex: 1 }} />
      <Pressable onPress={onDone} style={s.cta}>
        <Text style={{ color: C.accentFg, fontWeight: '900', fontSize: 16 }}>{t('continue')}</Text>
      </Pressable>
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.canvas, padding: 24, paddingTop: 80 },
  title: { fontSize: 24, fontWeight: '900', color: C.ink },
  card: { backgroundColor: C.white, borderWidth: 2, borderColor: C.line, borderRadius: R.lg, padding: 18 },
  cta: { backgroundColor: C.accent, borderRadius: R.md, paddingVertical: 15, alignItems: 'center', marginBottom: 16 },
});
