import React, { useState } from 'react';
import { Alert, KeyboardAvoidingView, Platform, ScrollView, Text, View } from 'react-native';
import { supabase } from '../lib/supabase';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Button, Card, Input, Label, LogoRow } from '../components/ui';
import { useI18n } from '../lib/i18n';
import { signInWithGoogleNative } from '../lib/googleAuth';

export const APP_ROLE = 'sme'; // partner app uses 'truck_owner'

export function LoginScreen({ onDone, goSignup }: { onDone: () => void; goSignup: () => void }) {
  const { t } = useI18n();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) {
      const msg = error.message.toLowerCase().includes('confirm')
        ? t('confirm_email_first') : t('wrong_creds');
      Alert.alert(t('signin_failed'), msg);
      return;
    }
    onDone();
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1, backgroundColor: C.canvas }}>
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 20 }}>
        <View style={{ alignItems: 'center', marginBottom: 24 }}><LogoRow /></View>
        <Card>
          <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>{t('sign_in')}</Text>
          <Label>{t('email')}</Label>
          <Input autoCapitalize="none" keyboardType="email-address" value={email} onChangeText={setEmail} placeholder="you@business.com" />
          <Label>{t('password')}</Label>
          <Input secureTextEntry value={password} onChangeText={setPassword} placeholder="••••••••" />
          <View style={{ height: 16 }} />
          <Button title={busy ? t('signing_in') : t('sign_in')} loading={busy} onPress={submit} />
          <View style={{ height: 10 }} />
          <Button title="Continue with Google" variant="secondary" onPress={async () => {
            const r = await signInWithGoogleNative();
            if (r.ok) onDone(); else if (r.message) Alert.alert('Google sign-in', r.message);
          }} />
          <View style={{ height: 10 }} />
          <Button title={t('create_account')} variant="secondary" onPress={goSignup} />
        </Card>
        <Text style={{ marginTop: 14, fontSize: 11, color: C.inkFaint, textAlign: 'center' }}>
          {t('same_account')}
        </Text>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

export function SignupScreen({ onDone, goLogin }: { onDone: () => void; goLogin: () => void }) {
  const { t } = useI18n();
  const [form, setForm] = useState({ full_name: '', email: '', phone: '', password: '' });
  const [busy, setBusy] = useState(false);
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const submit = async () => {
    setBusy(true);
    const { data, error } = await supabase.auth.signUp({
      email: form.email, password: form.password,
      options: { data: { full_name: form.full_name } },
    });
    if (error) { setBusy(false); Alert.alert('Sign up failed', error.message); return; }
    if (!data.session) {
      setBusy(false);
      Alert.alert(t('confirm_email_title'), t('confirm_email_body'),
        [{ text: 'OK', onPress: goLogin }]);
      return;
    }
    try {
      await api.post('/auth/profile', { full_name: form.full_name, phone: form.phone, role: APP_ROLE });
      onDone();
    } catch (e: any) { Alert.alert('Error', e.message); }
    setBusy(false);
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1, backgroundColor: C.canvas }}>
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 20 }}>
        <View style={{ alignItems: 'center', marginBottom: 24 }}><LogoRow /></View>
        <Card>
          <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>{t('create_account')}</Text>
          <Label>{t('full_name')}</Label>
          <Input value={form.full_name} onChangeText={(v) => set('full_name', v)} />
          <Label>{t('email')}</Label>
          <Input autoCapitalize="none" keyboardType="email-address" value={form.email} onChangeText={(v) => set('email', v)} />
          <Label>{t('phone')}</Label>
          <Input keyboardType="phone-pad" value={form.phone} onChangeText={(v) => set('phone', v)} />
          <Label>{t('password_min')}</Label>
          <Input secureTextEntry value={form.password} onChangeText={(v) => set('password', v)} />
          <View style={{ height: 16 }} />
          <Button title={busy ? t('creating') : t('create_account')} loading={busy} onPress={submit} />
          <View style={{ height: 10 }} />
          <Button title="Sign up with Google" variant="secondary" onPress={async () => {
            const r = await signInWithGoogleNative();
            if (r.ok) onDone(); else if (r.message) Alert.alert('Google sign-in', r.message);
          }} />
          <View style={{ height: 10 }} />
          <Button title={t('have_account')} variant="secondary" onPress={goLogin} />
        </Card>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
