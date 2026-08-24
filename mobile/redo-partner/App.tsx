// Boot flow (Rapido-Captain-style):
// Language → Location permission → Auth → Driver reg → Truck reg → Documents → Main app.
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
import PartnerOnboarding from './src/screens/PartnerOnboarding';
import HomeScreen from './src/screens/HomeScreen';
import BookingsScreen from './src/screens/BookingsScreen';
import BookingDetailScreen from './src/screens/BookingDetailScreen';
import EarningsScreen from './src/screens/EarningsScreen';
import TrucksScreen from './src/screens/TrucksScreen';
import DocumentsScreen from './src/screens/DocumentsScreen';
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
      <TabsNav.Screen name="Home" component={HomeScreen} options={{ title: t('tab_home'), tabBarIcon: icon('🗺️') }} />
      <TabsNav.Screen name="Bookings" component={BookingsScreen} options={{ title: t('tab_bookings'), tabBarIcon: icon('📋') }} />
      <TabsNav.Screen name="Earnings" component={EarningsScreen} options={{ title: t('tab_earnings'), tabBarIcon: icon('💰') }} />
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
    } catch { setPhase('onboarding'); }
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
    return <PermissionScreen whyKey="loc_why_p" onDone={async () => {
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
  if (phase === 'onboarding') return <PartnerOnboarding onDone={() => setPhase('main')} />;

  return (
    <NavigationContainer>
      <StatusBar style="dark" />
      <Stack.Navigator screenOptions={{ headerTintColor: C.ink, headerTitleStyle: { fontWeight: '800' } }}>
        <Stack.Screen name="Main" component={MainTabs} options={{ headerShown: false }} />
        <Stack.Screen name="BookingDetail" component={BookingDetailScreen} options={{ title: 'Trip' }} />
        <Stack.Screen name="Trucks" component={TrucksScreen} options={{ title: 'My Trucks' }} />
        <Stack.Screen name="Documents" component={DocumentsScreen} options={{ title: 'Documents' }} />
        <Stack.Screen name="Notifications" component={NotificationsScreen} options={{ title: 'Notifications' }} />
        <Stack.Screen name="Support" component={SupportScreen} options={{ title: 'Support' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return <I18nProvider><Root /></I18nProvider>;
}
