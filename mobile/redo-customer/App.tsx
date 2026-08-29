// Customer app boot flow:
// Language → Location permission → Auth → Business onboarding → Main app (map-first booking).
import React, { useCallback, useEffect, useState } from 'react';
import { Linking, Text } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { StatusBar } from 'expo-status-bar';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { supabase } from './src/lib/supabase';
import { api } from './src/lib/api';
import { C } from './src/lib/theme';
import { I18nProvider, hasChosenLanguage, useI18n } from './src/lib/i18n';
import LanguageScreen from './src/screens/LanguageScreen';
import { StartupErrorScreen, runStartupChecks } from './src/screens/StartupCheck';
import PermissionScreen from './src/screens/PermissionScreen';
import { LoginScreen, SignupScreen } from './src/screens/AuthScreens';
import CustomerOnboarding from './src/screens/CustomerOnboarding';
import HomeScreen from './src/screens/HomeScreen';
import MatchesScreen from './src/screens/MatchesScreen';
import ShipmentsScreen from './src/screens/ShipmentsScreen';
import ShipmentDetailScreen from './src/screens/ShipmentDetailScreen';
import TrackingScreen from './src/screens/TrackingScreen';
import InvoicesScreen from './src/screens/InvoicesScreen';
import RateCardScreen from './src/screens/RateCardScreen';
import AddressesScreen from './src/screens/AddressesScreen';
import NotificationsScreen from './src/screens/NotificationsScreen';
import SupportScreen from './src/screens/SupportScreen';
import ProfileScreen from './src/screens/ProfileScreen';

const Stack = createNativeStackNavigator();
const TabsNav = createBottomTabNavigator();
const PERM_KEY = 'redo.permAsked';

const icon = (glyph: string) => ({ color }: { color: string }) => (
  <Text style={{ fontSize: 20, color }}>{glyph}</Text>
);

let signOutCb: () => void = () => {};
function ProfileHost() { return <ProfileScreen onSignOut={() => signOutCb()} />; }

function MainTabs() {
  const { t } = useI18n();
  return (
    <TabsNav.Navigator screenOptions={{
      headerShown: false,
      tabBarActiveTintColor: C.brandDark,
      tabBarInactiveTintColor: C.inkFaint,
      tabBarLabelStyle: { fontWeight: '700', fontSize: 11 },
    }}>
      <TabsNav.Screen name="Home" component={HomeScreen} options={{ title: t('tab_home'), tabBarIcon: icon('🏠') }} />
      <TabsNav.Screen name="Shipments" component={ShipmentsScreen} options={{ title: t('tab_shipments'), tabBarIcon: icon('📦') }} />
      <TabsNav.Screen name="Invoices" component={InvoicesScreen} options={{ title: t('tab_invoices'), tabBarIcon: icon('🧾') }} />
      <TabsNav.Screen name="Profile" component={ProfileHost} options={{ title: t('tab_profile'), tabBarIcon: icon('👤') }} />
    </TabsNav.Navigator>
  );
}

type Phase = 'boot' | 'language' | 'permission' | 'health' | 'auth' | 'onboarding' | 'main';

function Root() {
  const [phase, setPhase] = useState<Phase>('boot');
  const [authScreen, setAuthScreen] = useState<'login' | 'signup'>('login');
  const [problems, setProblems] = useState<string[]>([]);

  const decideAfterAuth = useCallback(async () => {
    try {
      const { data: sess } = await supabase.auth.getSession();
      if (!sess.session?.user) {
        setPhase('auth');
        return;
      }
      const uid = sess.session.user.id;
      const { data: profile } = await supabase.from('profiles').select('*').eq('id', uid).single();
      if (profile && profile.onboarding_complete) {
        setPhase('main');
        return;
      }
      const apiProfile: any = await api.get('/auth/profile').catch(() => null);
      if (apiProfile?.onboarding_complete) {
        setPhase('main');
        return;
      }
      setPhase('onboarding');
    } catch {
      setPhase('onboarding');
    }
  }, []);

  const healthThenAuth = useCallback(async () => {
    const found = await runStartupChecks();
    if (found.length) { setProblems(found); setPhase('health'); return; }
    const { data } = await supabase.auth.getSession();
    if (!data.session) { setPhase('auth'); return; }
    await decideAfterAuth();
  }, [decideAfterAuth]);

  useEffect(() => {
    const handleDeepLink = async (url: string | null) => {
      if (!url) return;
      try {
        if (url.includes('access_token') || url.includes('refresh_token')) {
          const hash = url.split('#')[1] || url.split('?')[1] || '';
          const params = new URLSearchParams(hash);
          const access_token = params.get('access_token');
          const refresh_token = params.get('refresh_token');
          if (access_token && refresh_token) {
            await supabase.auth.setSession({ access_token, refresh_token });
            await decideAfterAuth();
          }
        } else if (url.includes('code=')) {
          const code = new URL(url).searchParams.get('code');
          if (code) {
            await supabase.auth.exchangeCodeForSession(code);
            await decideAfterAuth();
          }
        }
      } catch {}
    };

    Linking.getInitialURL().then(handleDeepLink);
    const subUrl = Linking.addEventListener('url', (e) => handleDeepLink(e.url));

    (async () => {
      if (!(await hasChosenLanguage())) { setPhase('language'); return; }
      if (!(await AsyncStorage.getItem(PERM_KEY))) { setPhase('permission'); return; }
      await healthThenAuth();
    })();

    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => {
      if (!s) setPhase((p) => (['main', 'onboarding'].includes(p) ? 'auth' : p));
      else decideAfterAuth();
    });

    return () => {
      sub.subscription.unsubscribe();
      subUrl.remove();
    };
  }, [decideAfterAuth, healthThenAuth]);

  signOutCb = () => setPhase('auth');

  if (phase === 'boot') return null;
  if (phase === 'language') {
    return <LanguageScreen onDone={async () => {
      setPhase((await AsyncStorage.getItem(PERM_KEY)) ? 'auth' : 'permission');
    }} />;
  }
  if (phase === 'permission') {
    return <PermissionScreen whyKey="loc_why_c" onDone={async () => {
      await AsyncStorage.setItem(PERM_KEY, '1');
      await healthThenAuth();
    }} />;
  }
  if (phase === 'health') {
    return <StartupErrorScreen problems={problems} onRetry={healthThenAuth} />;
  }
  if (phase === 'auth') {
    return authScreen === 'login'
      ? <LoginScreen onDone={decideAfterAuth} goSignup={() => setAuthScreen('signup')} />
      : <SignupScreen onDone={() => setPhase('onboarding')} goLogin={() => setAuthScreen('login')} />;
  }
  if (phase === 'onboarding') return <CustomerOnboarding onDone={() => setPhase('main')} />;

  return (
    <NavigationContainer>
      <StatusBar style="dark" />
      <Stack.Navigator screenOptions={{ headerTintColor: C.ink, headerTitleStyle: { fontWeight: '800' } }}>
        <Stack.Screen name="Main" component={MainTabs} options={{ headerShown: false }} />
        <Stack.Screen name="Matches" component={MatchesScreen} options={{ title: 'Matching Trucks' }} />
        <Stack.Screen name="ShipmentDetail" component={ShipmentDetailScreen} options={{ title: 'Shipment' }} />
        <Stack.Screen name="Tracking" component={TrackingScreen} options={{ title: 'Live GPS' }} />
        <Stack.Screen name="RateCard" component={RateCardScreen} options={{ title: 'Dynamic Rates' }} />
        <Stack.Screen name="Addresses" component={AddressesScreen} options={{ title: 'Saved Places' }} />
        <Stack.Screen name="Notifications" component={NotificationsScreen} options={{ title: 'Notifications' }} />
        <Stack.Screen name="Support" component={SupportScreen} options={{ title: 'Support' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return <I18nProvider><Root /></I18nProvider>;
}
