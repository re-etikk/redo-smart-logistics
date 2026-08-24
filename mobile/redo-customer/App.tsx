// Boot flow (Rapido-style): Language → Location permission → Auth → Onboarding → Main app.
import React, { useCallback, useEffect, useState } from 'react';
import { Text } from 'react-native';
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
import PermissionScreen from './src/screens/PermissionScreen';
import { LoginScreen, SignupScreen } from './src/screens/AuthScreens';
import CustomerOnboarding from './src/screens/CustomerOnboarding';
import HomeScreen from './src/screens/HomeScreen';
import MatchesScreen from './src/screens/MatchesScreen';
import ShipmentsScreen from './src/screens/ShipmentsScreen';
import ShipmentDetailScreen from './src/screens/ShipmentDetailScreen';
import TrackingScreen from './src/screens/TrackingScreen';
import InvoicesScreen from './src/screens/InvoicesScreen';
import NotificationsScreen from './src/screens/NotificationsScreen';
import SupportScreen from './src/screens/SupportScreen';
import RateCardScreen from './src/screens/RateCardScreen';
import AddressesScreen from './src/screens/AddressesScreen';
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
      tabBarActiveTintColor: C.accent,
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

type Phase = 'boot' | 'language' | 'permission' | 'auth' | 'onboarding' | 'main';

function Root() {
  const [phase, setPhase] = useState<Phase>('boot');
  const [authScreen, setAuthScreen] = useState<'login' | 'signup'>('login');

  const decideAfterAuth = useCallback(async () => {
    try {
      const profile: any = await api.get('/auth/profile');
      setPhase(profile?.onboarding_complete ? 'main' : 'onboarding');
    } catch { setPhase('onboarding'); } // no profile row yet → onboarding creates it
  }, []);

  useEffect(() => {
    (async () => {
      if (!(await hasChosenLanguage())) { setPhase('language'); return; }
      if (!(await AsyncStorage.getItem(PERM_KEY))) { setPhase('permission'); return; }
      const { data } = await supabase.auth.getSession();
      if (!data.session) { setPhase('auth'); return; }
      await decideAfterAuth();
    })();
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => {
      if (!s) setPhase((p) => (['main', 'onboarding'].includes(p) ? 'auth' : p));
    });
    return () => sub.subscription.unsubscribe();
  }, [decideAfterAuth]);
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
      const { data } = await supabase.auth.getSession();
      if (data.session) await decideAfterAuth(); else setPhase('auth');
    }} />;
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
        <Stack.Screen name="Matches" component={MatchesScreen} options={{ title: 'Truck Matches' }} />
        <Stack.Screen name="ShipmentDetail" component={ShipmentDetailScreen} options={{ title: 'Shipment' }} />
        <Stack.Screen name="Tracking" component={TrackingScreen} options={{ title: 'Live Tracking' }} />
        <Stack.Screen name="Notifications" component={NotificationsScreen} options={{ title: 'Notifications' }} />
        <Stack.Screen name="Support" component={SupportScreen} options={{ title: 'Support' }} />
        <Stack.Screen name="RateCard" component={RateCardScreen} options={{ title: 'Rate Card' }} />
        <Stack.Screen name="Addresses" component={AddressesScreen} options={{ title: 'Addresses' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return <I18nProvider><Root /></I18nProvider>;
}
