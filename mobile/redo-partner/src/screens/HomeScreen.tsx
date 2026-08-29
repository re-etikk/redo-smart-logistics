// Rapido-Captain-style home: duty toggle + your live location on the map +
// available loads on the network with one-tap Accept.
import React, { useCallback, useEffect, useState } from 'react';
import { Alert, FlatList, StyleSheet, Text, View } from 'react-native';
import MapView, { Marker, PROVIDER_GOOGLE } from 'react-native-maps';
import * as Location from 'expo-location';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C, R } from '../lib/theme';
import { CITY_COORDS } from '../lib/types';
import { Badge, Button, Card, Empty, LogoRow } from '../components/ui';
import { useI18n } from '../lib/i18n';
import { useLive } from '../lib/useLive';

const estimate = (km?: number | null, t?: number | null) =>
  Math.round(Number(km || 0) * Number(t || 0) * 1.05) || 0;

export default function HomeScreen({ navigation }: any) {
  const { t } = useI18n();
  const [profile, setProfile] = useState<any | null>(null);
  const [trucks, setTrucks] = useState<any[]>([]);
  const [loads, setLoads] = useState<any[] | null>(null);
  const [me, setMe] = useState<{ latitude: number; longitude: number } | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(() => {
    api.get('/auth/profile').then((p: any) => setProfile(p)).catch(() => {});
    api.get<any[]>('/trucks').then(setTrucks).catch(() => setTrucks([]));
    api.get<any[]>('/cargo').then(setLoads).catch(() => setLoads([]));
  }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));
  // LIVE WIRING: a shipper posting cargo anywhere (website or customer app)
  // shows up here instantly — the Rapido "new ride request" moment.
  useLive('cargo_requests', () => api.get<any[]>('/cargo').then(setLoads).catch(() => {}));

  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') return;
      const pos = await Location.getCurrentPositionAsync({});
      setMe({ latitude: pos.coords.latitude, longitude: pos.coords.longitude });
    })();
  }, []);

  const truck = trucks[0];

  const accept = async (c: any) => {
    if (!truck) { Alert.alert('Add a truck first', 'Go to Profile → My Trucks to add your truck.'); return; }
    setBusyId(c.cargo_id);
    try {
      const b = await api.post<{ id: string }>('/bookings', {
        cargo_id: c.cargo_id, truck_id: truck.truck_id,
        agreed_price_inr: estimate(c.distance_km, c.cargo_weight_tons),
        owner_initiated: true,
      });
      Alert.alert('Load accepted!', 'Waiting for the shipper to confirm.');
      navigation.navigate('BookingDetail', { bookingId: b.id });
    } catch (e: any) { Alert.alert('Could not accept', e.message); }
    setBusyId(null);
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas }}>
      <View style={{ height: 260 }}>
        <MapView provider={PROVIDER_GOOGLE} style={StyleSheet.absoluteFillObject}
          region={me ? { ...me, latitudeDelta: 0.08, longitudeDelta: 0.08 }
            : { ...CITY_COORDS.Delhi, latitudeDelta: 8, longitudeDelta: 8 }}
          showsUserLocation>
          {me && <Marker coordinate={me} title="You" />}
        </MapView>
        <View style={s.header}>
          <LogoRow />
          <View style={{ alignItems: 'flex-end' }}>
            <Text style={{ fontWeight: '900', color: C.ink }}>
              {t('hello')}, {profile?.full_name?.split(' ')[0] ?? 'Partner'} 👋
            </Text>
            {truck && <Text style={{ fontSize: 11, fontWeight: '700', color: C.inkFaint }}>{truck.registration_number}</Text>}
          </View>
        </View>
      </View>

      <View style={{ flex: 1, padding: 14 }}>
        <Text style={{ fontSize: 17, fontWeight: '900', color: C.ink, marginBottom: 10 }}>
          {t('loads_near')}
        </Text>
        {loads !== null && loads.length === 0 && (
          <Empty title={t('no_loads')} hint={t('no_loads_hint')} />
        )}
        <FlatList data={loads ?? []} keyExtractor={(c) => c.cargo_id} contentContainerStyle={{ gap: 10 }}
          renderItem={({ item: c }) => (
            <Card>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                <Text style={{ fontWeight: '900', color: C.ink }}>{c.origin} → {c.destination}</Text>
                {c.urgency !== 'normal' && <Badge tone="warn" text={c.urgency} />}
              </View>
              <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 3 }}>
                {c.cargo_type} · {c.cargo_weight_tons} T{c.distance_km ? ` · ${c.distance_km} km` : ''}
              </Text>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 10 }}>
                <View>
                  <Text style={{ fontSize: 10, color: C.inkFaint, fontWeight: '700' }}>{t('est_earning')}</Text>
                  <Text style={{ fontSize: 17, fontWeight: '900', color: C.ink }}>
                    ₹{estimate(c.distance_km, c.cargo_weight_tons).toLocaleString('en-IN')}
                  </Text>
                </View>
                <View style={{ width: 130 }}>
                  <Button title={busyId === c.cargo_id ? '…' : t('accept_load')}
                    loading={busyId === c.cargo_id} onPress={() => accept(c)} />
                </View>
              </View>
            </Card>
          )} />
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  header: {
    position: 'absolute', top: 44, left: 12, right: 12,
    backgroundColor: C.white, borderRadius: R.lg, borderWidth: 1, borderColor: C.line,
    paddingHorizontal: 14, paddingVertical: 8,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
  },
});
