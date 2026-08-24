import React, { useState } from 'react';
import { Alert, KeyboardAvoidingView, Platform, ScrollView, Text, View, TouchableOpacity } from 'react-native';
import * as WebBrowser from 'expo-web-browser';
import { makeRedirectUri } from 'expo-auth-session';
import { supabase } from '../lib/supabase';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Button, Card, Input, Label, LogoRow } from '../components/ui';
import { useI18n } from '../lib/i18n';

WebBrowser.maybeCompleteAuthSession();

export const APP_ROLE = 'truck_owner'; // Partner / Driver role

export function LoginScreen({ onDone, goSignup }: { onDone: () => void; goSignup: () => void }) {
  const { t } = useI18n();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    if (!email || !password) {
      Alert.alert(t('signin_failed'), 'Please enter both email and password.');
      return;
    }
    setBusy(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) {
      const msg = error.message.toLowerCase().includes('confirm')
        ? t('confirm_email_first') : error.message;
      Alert.alert(t('signin_failed'), msg);
      return;
    }
    onDone();
  };

  const handleGoogleSignIn = async () => {
    try {
      setBusy(true);
      const redirectUrl = makeRedirectUri({ scheme: 'redologistics' });
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: redirectUrl,
          skipBrowserRedirect: true,
        },
      });
      if (error) throw error;
      if (data?.url) {
        const res = await WebBrowser.openAuthSessionAsync(data.url, redirectUrl);
        if (res.type === 'success' && res.url) {
          const params = new URLSearchParams(res.url.split('#')[1] || res.url.split('?')[1]);
          const accessToken = params.get('access_token');
          const refreshToken = params.get('refresh_token');
          if (accessToken && refreshToken) {
            await supabase.auth.setSession({
              access_token: accessToken,
              refresh_token: refreshToken,
            });
            onDone();
          }
        }
      }
    } catch (e: any) {
      Alert.alert('Google Sign-In', e.message || 'Could not sign in with Google');
    } finally {
      setBusy(false);
    }
  };

  const handleQuickDemoDriverLogin = async () => {
    setEmail('driver@redo.app');
    setPassword('Driver@12345');
    setBusy(true);
    const { error } = await supabase.auth.signInWithPassword({
      email: 'driver@redo.app',
      password: 'Driver@12345',
    });
    setBusy(false);
    if (error) {
      const { data: upData } = await supabase.auth.signUp({
        email: 'driver@redo.app',
        password: 'Driver@12345',
        options: { data: { full_name: 'Mukesh Yadav (Fleet Owner)', role: 'truck_owner' } }
      });
      if (upData.session) {
        onDone();
        return;
      }
    }
    onDone();
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1, backgroundColor: C.canvas }}>
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 20 }}>
        <View style={{ alignItems: 'center', marginBottom: 24 }}><LogoRow /></View>
        <Card>
          <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>{t('sign_in')} • Partner</Text>
          <Label>{t('email')}</Label>
          <Input autoCapitalize="none" keyboardType="email-address" value={email} onChangeText={setEmail} placeholder="driver@transporter.com" />
          <Label>{t('password')}</Label>
          <Input secureTextEntry value={password} onChangeText={setPassword} placeholder="••••••••" />
          
          <View style={{ height: 16 }} />
          <Button title={busy ? t('signing_in') : t('sign_in')} loading={busy} onPress={submit} />
          
          <View style={{ flexDirection: 'row', alignItems: 'center', marginVertical: 14 }}>
            <View style={{ flex: 1, height: 1, backgroundColor: C.line }} />
            <Text style={{ marginHorizontal: 10, fontSize: 10, fontWeight: '800', color: C.inkFaint }}>OR</Text>
            <View style={{ flex: 1, height: 1, backgroundColor: C.line }} />
          </View>

          {/* Google Sign In */}
          <Button title="🚀 Continue with Google" variant="secondary" onPress={handleGoogleSignIn} />

          <View style={{ height: 10 }} />
          <Button title={t('create_account')} variant="secondary" onPress={goSignup} />

          {/* One-Tap Demo Driver Access */}
          <TouchableOpacity onPress={handleQuickDemoDriverLogin} style={{ marginTop: 12, paddingVertical: 6, alignItems: 'center' }}>
            <Text style={{ fontSize: 11, fontWeight: '800', color: C.brand }}>⚡ Quick Demo Truck Partner Access</Text>
          </TouchableOpacity>
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
    if (!form.email || !form.password || !form.full_name) {
      Alert.alert('Incomplete Form', 'Please enter your name, email and password.');
      return;
    }
    setBusy(true);
    const { data, error } = await supabase.auth.signUp({
      email: form.email, password: form.password,
      options: { data: { full_name: form.full_name, role: APP_ROLE } },
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
    } catch {
      onDone();
    }
    setBusy(false);
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1, backgroundColor: C.canvas }}>
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 20 }}>
        <View style={{ alignItems: 'center', marginBottom: 24 }}><LogoRow /></View>
        <Card>
          <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>{t('create_account')} • Partner</Text>
          <Label>{t('full_name')}</Label>
          <Input value={form.full_name} onChangeText={(v) => set('full_name', v)} placeholder="Truck Owner / Transporter Name" />
          <Label>{t('email')}</Label>
          <Input autoCapitalize="none" keyboardType="email-address" value={form.email} onChangeText={(v) => set('email', v)} placeholder="you@transporter.com" />
          <Label>{t('phone')}</Label>
          <Input keyboardType="phone-pad" value={form.phone} onChangeText={(v) => set('phone', v)} placeholder="+91 98765 43210" />
          <Label>{t('password_min')}</Label>
          <Input secureTextEntry value={form.password} onChangeText={(v) => set('password', v)} placeholder="••••••••" />
          <View style={{ height: 16 }} />
          <Button title={busy ? t('creating') : t('create_account')} loading={busy} onPress={submit} />
          <View style={{ height: 10 }} />
          <Button title={t('have_account')} variant="secondary" onPress={goLogin} />
        </Card>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
