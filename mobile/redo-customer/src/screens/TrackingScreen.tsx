// Live map tracking — realtime positions from Supabase; simulated points are labeled.
import React, { useEffect, useRef, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import MapView, { Marker, Polyline, PROVIDER_GOOGLE } from 'react-native-maps';
import { api } from '../lib/api';
import { supabase } from '../lib/supabase';
import { C, R } from '../lib/theme';
import { CITY_COORDS } from '../lib/types';

interface Pt { lat: number; lng: number; is_simulated: boolean; created_at: string }

export default function TrackingScreen({ route }: any) {
  const { bookingId, booking } = route.params;
  const [points, setPoints] = useState<Pt[]>([]);
  const mapRef = useRef<MapView>(null);

  useEffect(() => {
    api.get<Pt[]>(`/tracking/${bookingId}`).then(setPoints).catch(() => {});
    const ch = supabase
      .channel(`tracking-${bookingId}`)
      .on('postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'tracking_events', filter: `booking_id=eq.${bookingId}` },
        (payload: any) => {
          const p = payload.new;
          setPoints((prev) => [...prev, { lat: p.lat, lng: p.lng, is_simulated: p.is_simulated, created_at: p.created_at }]);
        })
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [bookingId]);

  const last = points[points.length - 1];
  const origin = CITY_COORDS[booking?.cargo?.origin] ?? CITY_COORDS.Mumbai;
  const dest = CITY_COORDS[booking?.cargo?.destination] ?? CITY_COORDS.Delhi;

  useEffect(() => {
    if (last && mapRef.current) {
      mapRef.current.animateToRegion({
        latitude: last.lat, longitude: last.lng, latitudeDelta: 2.5, longitudeDelta: 2.5,
      }, 600);
    }
  }, [last]);

  return (
    <View style={{ flex: 1 }}>
      <MapView ref={mapRef} provider={PROVIDER_GOOGLE} style={StyleSheet.absoluteFillObject}
        initialRegion={{
          latitude: (origin.latitude + dest.latitude) / 2,
          longitude: (origin.longitude + dest.longitude) / 2,
          latitudeDelta: Math.abs(origin.latitude - dest.latitude) * 1.9 + 1.5,
          longitudeDelta: Math.abs(origin.longitude - dest.longitude) * 1.9 + 1.5,
        }}>
        <Marker coordinate={origin} title="Pickup" pinColor={C.ok} />
        <Marker coordinate={dest} title="Drop" pinColor={C.danger} />
        {points.length > 1 && (
          <Polyline coordinates={points.map((p) => ({ latitude: p.lat, longitude: p.lng }))}
            strokeColor={C.accent} strokeWidth={4} />
        )}
        {last && (
          <Marker coordinate={{ latitude: last.lat, longitude: last.lng }} title="Truck">
            <View style={s.truckDot}><Text style={{ fontSize: 16 }}>🚚</Text></View>
          </Marker>
        )}
      </MapView>
      <View style={s.banner}>
        <Text style={{ fontWeight: '800', color: C.ink }}>
          {last ? `Last update: ${new Date(last.created_at).toLocaleTimeString('en-IN')}` : 'Waiting for the driver to share location…'}
        </Text>
        {last?.is_simulated && (
          <Text style={{ fontSize: 11, color: C.warn, fontWeight: '700', marginTop: 2 }}>
            Demo tracking · Simulated location
          </Text>
        )}
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  banner: {
    position: 'absolute', top: 48, left: 16, right: 16, backgroundColor: C.white,
    borderRadius: R.lg, borderWidth: 1, borderColor: C.line, padding: 12,
  },
  truckDot: {
    backgroundColor: C.white, borderRadius: 999, padding: 6,
    borderWidth: 2, borderColor: C.accent,
  },
});
