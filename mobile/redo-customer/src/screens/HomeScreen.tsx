// Rapido-style home: full-screen map with a booking card docked at the bottom.
import React, { useMemo, useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import MapView, { Marker, Polyline, PROVIDER_GOOGLE } from 'react-native-maps';
import { api } from '../lib/api';
import { C, R } from '../lib/theme';
import { CITY_COORDS } from '../lib/types';
import { Button, Card, Input, Label, LogoRow } from '../components/ui';
import { useI18n } from '../lib/i18n';

const CITIES = Object.keys(CITY_COORDS);
const TYPES = ['Textiles', 'FMCG', 'Electronics', 'Auto parts', 'Pharma', 'Furniture'];

function CityPicker({ value, onChange, exclude }: { value: string; onChange: (c: string) => void; exclude?: string }) {
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 4 }}>
      {CITIES.filter((c) => c !== exclude).map((c) => (
        <Pressable key={c} onPress={() => onChange(c)}
          style={[s.chip, value === c && { backgroundColor: C.accent, borderColor: C.accent }]}>
          <Text style={[s.chipText, value === c && { color: C.accentFg }]}>{c}</Text>
        </Pressable>
      ))}
    </ScrollView>
  );
}

export default function HomeScreen({ navigation }: any) {
  const { t } = useI18n();
  const [origin, setOrigin] = useState('Mumbai');
  const [destination, setDestination] = useState('Delhi');
  const [weight, setWeight] = useState('1.5');
  const [cargoType, setCargoType] = useState('Textiles');
  const [busy, setBusy] = useState(false);

  const region = useMemo(() => {
    const a = CITY_COORDS[origin]; const b = CITY_COORDS[destination];
    return {
      latitude: (a.latitude + b.latitude) / 2,
      longitude: (a.longitude + b.longitude) / 2,
      latitudeDelta: Math.abs(a.latitude - b.latitude) * 1.9 + 1.5,
      longitudeDelta: Math.abs(a.longitude - b.longitude) * 1.9 + 1.5,
    };
  }, [origin, destination]);

  const findTrucks = async () => {
    setBusy(true);
    try {
      // Pickup defaults to tomorrow 10:00 — editable later from the shipment detail.
      const pickup = new Date(Date.now() + 24 * 3600 * 1000); pickup.setHours(10, 0, 0, 0);
      const cargo = await api.post<{ cargo_id: string }>('/cargo', {
        origin, destination, cargo_type: cargoType,
        cargo_weight_tons: parseFloat(weight) || 1,
        pickup_at: pickup.toISOString(), urgency: 'normal',
      });
      navigation.navigate('Matches', { cargoId: cargo.cargo_id, origin, destination });
    } catch (e: any) { Alert.alert('Could not post shipment', e.message); }
    setBusy(false);
  };

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas }}>
      <MapView provider={PROVIDER_GOOGLE} style={StyleSheet.absoluteFillObject} region={region}>
        <Marker coordinate={CITY_COORDS[origin]} title={origin} pinColor={C.ok} />
        <Marker coordinate={CITY_COORDS[destination]} title={destination} pinColor={C.danger} />
        <Polyline coordinates={[CITY_COORDS[origin], CITY_COORDS[destination]]}
          strokeColor={C.accent} strokeWidth={3} lineDashPattern={[8, 6]} />
      </MapView>

      <View style={s.header}><LogoRow /></View>

      <View style={s.sheet}>
        <Card>
          <Text style={{ fontSize: 17, fontWeight: '900', color: C.ink }}>{t('book_truck')}</Text>
          <Label>{t('pickup_city')}</Label>
          <CityPicker value={origin} onChange={setOrigin} exclude={destination} />
          <Label>{t('drop_city')}</Label>
          <CityPicker value={destination} onChange={setDestination} exclude={origin} />
          <View style={{ flexDirection: 'row', gap: 12 }}>
            <View style={{ flex: 1 }}>
              <Label>{t('weight_t')}</Label>
              <Input keyboardType="decimal-pad" value={weight} onChangeText={setWeight} />
            </View>
            <View style={{ flex: 1.4 }}>
              <Label>{t('cargo_type')}</Label>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 4 }}>
                {TYPES.map((t) => (
                  <Pressable key={t} onPress={() => setCargoType(t)}
                    style={[s.chip, cargoType === t && { backgroundColor: C.accent, borderColor: C.accent }]}>
                    <Text style={[s.chipText, cargoType === t && { color: C.accentFg }]}>{t}</Text>
                  </Pressable>
                ))}
              </ScrollView>
            </View>
          </View>
          <View style={{ height: 14 }} />
          <Button title={busy ? t('finding') : t('find_trucks')} loading={busy} onPress={findTrucks} />
        </Card>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  header: {
    position: 'absolute', top: 48, left: 16, right: 16,
    backgroundColor: C.white, borderRadius: R.lg, borderWidth: 1, borderColor: C.line,
    paddingHorizontal: 14, paddingVertical: 10,
  },
  sheet: { position: 'absolute', left: 12, right: 12, bottom: 16 },
  chip: {
    borderWidth: 1, borderColor: C.line, backgroundColor: C.white,
    borderRadius: 999, paddingHorizontal: 12, paddingVertical: 7, marginRight: 8, marginTop: 4,
  },
  chipText: { fontSize: 13, fontWeight: '700', color: C.inkSoft },
});
