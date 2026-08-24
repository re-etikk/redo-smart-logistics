// Small RN design system shared by both apps (Badge tones, Button, Card, Stat).
import React, { type ReactNode } from 'react';
import {
  ActivityIndicator, Pressable, StyleSheet, Text, TextInput, View,
  type StyleProp, type TextInputProps, type ViewStyle,
} from 'react-native';
import { C, R } from '../lib/theme';

export function Card({ children, style }: { children: ReactNode; style?: StyleProp<ViewStyle> }) {
  return <View style={[s.card, style]}>{children}</View>;
}

export function Button({ title, onPress, variant = 'primary', disabled, loading }: {
  title: string; onPress: () => void; variant?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean; loading?: boolean;
}) {
  const bg = variant === 'primary' ? C.accent : variant === 'danger' ? C.danger : C.white;
  const fg = variant === 'primary' ? C.accentFg : variant === 'danger' ? C.white : C.ink;
  return (
    <Pressable onPress={onPress} disabled={disabled || loading}
      style={({ pressed }) => [s.btn, { backgroundColor: bg, opacity: disabled ? 0.5 : pressed ? 0.85 : 1 },
        variant === 'secondary' && { borderWidth: 1, borderColor: C.line }]}>
      {loading ? <ActivityIndicator color={fg} /> : <Text style={[s.btnText, { color: fg }]}>{title}</Text>}
    </Pressable>
  );
}

export function Badge({ text, tone = 'neutral' }: { text: string; tone?: 'neutral' | 'ok' | 'warn' | 'danger' | 'accent' }) {
  const map = {
    neutral: { bg: C.canvas, fg: C.inkSoft }, ok: { bg: C.okSoft, fg: C.ok },
    warn: { bg: C.warnSoft, fg: C.warn }, danger: { bg: C.dangerSoft, fg: C.danger },
    accent: { bg: C.accentSoft, fg: C.ink },
  }[tone];
  return (
    <View style={[s.badge, { backgroundColor: map.bg }]}>
      <Text style={[s.badgeText, { color: map.fg }]}>{text}</Text>
    </View>
  );
}

export const statusTone = (st: string): 'neutral' | 'ok' | 'warn' | 'danger' | 'accent' =>
  ['delivered', 'completed'].includes(st) ? 'ok'
  : ['cancelled', 'disputed'].includes(st) ? 'danger'
  : ['pending', 'accepted'].includes(st) ? 'warn' : 'accent';

export function Input(props: TextInputProps) {
  return <TextInput placeholderTextColor={C.inkFaint} {...props} style={[s.input, props.style]} />;
}

export function Label({ children }: { children: ReactNode }) {
  return <Text style={s.label}>{children}</Text>;
}

export function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <Card style={s.stat}>
      <Text style={s.statValue}>{value}</Text>
      <Text style={s.statLabel}>{label}</Text>
    </Card>
  );
}

export function Empty({ title, hint }: { title: string; hint?: string }) {
  return (
    <View style={{ padding: 32, alignItems: 'center' }}>
      <Text style={{ fontWeight: '700', color: C.ink }}>{title}</Text>
      {hint ? <Text style={{ marginTop: 4, fontSize: 12, color: C.inkFaint, textAlign: 'center' }}>{hint}</Text> : null}
    </View>
  );
}

export function LogoRow() {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
      <View style={{ width: 26, height: 26, borderRadius: 6, backgroundColor: C.ink, alignItems: 'center', justifyContent: 'center' }}>
        <Text style={{ color: C.brand, fontWeight: '900', fontSize: 15 }}>R</Text>
      </View>
      <View>
        <Text style={{ fontSize: 18, fontWeight: '900', color: C.ink, lineHeight: 20 }}>redo</Text>
        <Text style={{ fontSize: 9, fontWeight: '600', color: C.inkFaint }}>Transport &amp; Logistics</Text>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  card: { backgroundColor: C.white, borderRadius: R.lg, borderWidth: 1, borderColor: C.line, padding: 14 },
  btn: { borderRadius: R.md, paddingVertical: 13, alignItems: 'center', justifyContent: 'center' },
  btnText: { fontWeight: '800', fontSize: 15 },
  badge: { borderRadius: 999, paddingHorizontal: 9, paddingVertical: 3, alignSelf: 'flex-start' },
  badgeText: { fontSize: 11, fontWeight: '700' },
  input: {
    borderWidth: 1, borderColor: C.line, borderRadius: R.md, backgroundColor: C.white,
    paddingHorizontal: 12, paddingVertical: 11, fontSize: 15, color: C.ink,
  },
  label: { fontSize: 13, fontWeight: '700', color: C.inkSoft, marginBottom: 6, marginTop: 12 },
  stat: { flex: 1, alignItems: 'center', paddingVertical: 12 },
  statValue: { fontSize: 18, fontWeight: '900', color: C.ink },
  statLabel: { fontSize: 11, fontWeight: '600', color: C.inkFaint, marginTop: 2 },
});
