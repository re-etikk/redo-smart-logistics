import React from 'react';
import { ScrollView, StyleSheet, Text } from 'react-native';
import { C } from '../lib/theme';
import { Button, Card, LogoRow } from '../components/ui';
import { SUPABASE_URL, SUPABASE_ANON_KEY, API_URL } from '../lib/supabase';

export async function runStartupChecks(): Promise<string[]> {
  const problems: string[] = [];
  if (!SUPABASE_URL || SUPABASE_URL.includes('YOUR-PROJECT')) {
    problems.push('SUPABASE_URL is not configured properly.');
  }
  if (!SUPABASE_ANON_KEY || SUPABASE_ANON_KEY.startsWith('YOUR')) {
    problems.push('SUPABASE_ANON_KEY is not configured properly.');
  }
  if (problems.length) return problems;

  // Background health ping (non-blocking)
  try {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 3000);
    await fetch(`${API_URL}/health`, { signal: ctrl.signal }).catch(() => null);
    clearTimeout(timer);
  } catch {
    // Graceful fallback — Supabase direct queries handle core freight
  }
  return [];
}

export function StartupErrorScreen({ problems, onRetry }: { problems: string[]; onRetry: () => void }) {
  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={s.wrap}>
      <LogoRow />
      <Text style={s.title}>Connection Setup Needed</Text>
      <Card style={{ marginTop: 14, gap: 10 }}>
        {problems.map((p, i) => (
          <Text key={i} style={{ color: C.danger, fontWeight: '600', lineHeight: 20 }}>• {p}</Text>
        ))}
      </Card>
      <Text style={s.hint}>
        Please verify network connection and try again.
      </Text>
      <Button title="Retry Connection" onPress={onRetry} />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  wrap: { padding: 20, paddingTop: 80, gap: 8 },
  title: { fontSize: 22, fontWeight: '900', color: C.ink, marginTop: 12 },
  hint: { fontSize: 12, color: C.inkFaint, marginVertical: 12 },
});
