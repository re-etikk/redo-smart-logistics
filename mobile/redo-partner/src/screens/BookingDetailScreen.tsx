// The Captain screen: walk the booking through the state machine.
// picked_up and delivered require a REAL proof photo (camera/gallery →
// Supabase Storage → /proof metadata). In-transit can share REAL GPS
// (expo-location → /tracking events with is_simulated: false).
import React, { useCallback, useRef, useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { supabase } from '../lib/supabase';
import { C } from '../lib/theme';
import { STATUS_LABEL } from '../lib/types';
import { Badge, Button, Card, statusTone } from '../components/ui';
import { useLive } from '../lib/useLive';

const NEXT: Record<string, { to: string; label: string; needsProof?: 'pickup' | 'delivery' }> = {
  confirmed: { to: 'pickup_ready', label: 'Reached pickup point' },
  pickup_ready: { to: 'picked_up', label: 'Upload pickup proof & start', needsProof: 'pickup' },
  picked_up: { to: 'in_transit', label: 'Start trip (in transit)' },
  in_transit: { to: 'delivered', label: 'Upload delivery proof & deliver', needsProof: 'delivery' },
};

export default function BookingDetailScreen({ route }: any) {
  const { bookingId } = route.params;
  const [data, setData] = useState<any | null>(null);
  const [busy, setBusy] = useState(false);
  const [sharing, setSharing] = useState(false);
  const watcher = useRef<Location.LocationSubscription | null>(null);

  const load = useCallback(async () => {
    try { setData(await api.get(`/bookings/${bookingId}`)); } catch { /* keep last */ }
  }, [bookingId]);
  useFocusEffect(useCallback(() => {
    load();
    return () => { watcher.current?.remove(); watcher.current = null; };
  }, [load]));

  useLive('bookings', load, `id=eq.${bookingId}`);

  if (!data) return <View style={{ flex: 1, backgroundColor: C.canvas }} />;
  const b = data.booking ?? data;
  const st: string = b.status;
  const action = NEXT[st];

  const uploadProof = async (type: 'pickup' | 'delivery') => {
    let picked = await ImagePicker.launchCameraAsync({ quality: 0.5 }).catch(() => null);
    if (!picked || picked.canceled) {
      picked = await ImagePicker.launchImageLibraryAsync({ quality: 0.5 });
    }
    if (!picked || picked.canceled) return false;
    const uri = picked.assets[0].uri;
    const { data: s } = await supabase.auth.getSession();
    const uid = s.session!.user.id;
    const path = `${uid}/${bookingId}-${type}-${Date.now()}.jpg`;
    const bucket = type === 'pickup' ? 'pickup-proofs' : 'delivery-proofs';
    const file = await fetch(uri).then((r) => r.arrayBuffer());
    const { error } = await supabase.storage.from(bucket).upload(path, file, { contentType: 'image/jpeg' });
    if (error) { Alert.alert('Upload failed', error.message); return false; }
    let gps: { gps_lat?: number; gps_lng?: number } = {};
    try {
      const pos = await Location.getCurrentPositionAsync({});
      gps = { gps_lat: pos.coords.latitude, gps_lng: pos.coords.longitude };
    } catch { /* proof still valid without GPS */ }
    await api.post('/proof', { booking_id: bookingId, proof_type: type, photo_url: `${bucket}/${path}`, ...gps });
    return true;
  };

  const advance = async () => {
    if (!action) return;
    setBusy(true);
    try {
      if (action.needsProof) {
        const ok = await uploadProof(action.needsProof);
        if (!ok) { setBusy(false); return; }
      }
      await api.patch(`/bookings/${bookingId}/status`, { to: action.to });
      await load();
    } catch (e: any) { Alert.alert('Not allowed', e.message); }
    setBusy(false);
  };

  const toggleLiveLocation = async () => {
    if (sharing) {
      watcher.current?.remove(); watcher.current = null; setSharing(false); return;
    }
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') { Alert.alert('Permission needed', 'Location permission is required to share live tracking.'); return; }
    watcher.current = await Location.watchPositionAsync(
      { accuracy: Location.Accuracy.Balanced, timeInterval: 15000, distanceInterval: 100 },
      (pos) => {
        // REAL GPS — explicitly opts out of the simulated flag.
        api.post(`/tracking/${bookingId}/events`, {
          lat: pos.coords.latitude, lng: pos.coords.longitude, is_simulated: false,
        }).catch(() => {});
      });
    setSharing(true);
    Alert.alert('Live tracking ON', 'Your real GPS position is now visible to the shipper every ~15 seconds.');
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={{ padding: 14, gap: 12 }}>
      <Card>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
          <Text style={{ fontWeight: '900', fontSize: 17, color: C.ink }}>
            {b.cargo.origin} → {b.cargo.destination}
          </Text>
          <Badge tone={statusTone(st)} text={STATUS_LABEL[st] ?? st} />
        </View>
        <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 4 }}>
          {b.cargo.cargo_type} · {b.cargo.cargo_weight_tons} T · {b.truck.registration_number}
        </Text>
        <View style={{ marginTop: 10 }}>
          <Text style={{ fontSize: 10, color: C.inkFaint, fontWeight: '700' }}>TRIP EARNING</Text>
          <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink }}>
            ₹{Number(b.agreed_price_inr || 0).toLocaleString('en-IN')}
          </Text>
        </View>
      </Card>

      {st === 'accepted' && (
        <Card>
          <Text style={{ color: C.inkSoft }}>
            You accepted this load. Waiting for the shipper to confirm — you will get a notification.
          </Text>
        </Card>
      )}

      {action && (
        <Button title={busy ? 'Working…' : action.label} loading={busy} onPress={advance} />
      )}

      {['picked_up', 'in_transit'].includes(st) && (
        <Button title={sharing ? 'Stop sharing live location' : 'Share live location (real GPS)'}
          variant={sharing ? 'danger' : 'secondary'} onPress={toggleLiveLocation} />
      )}

      {st === 'delivered' && (
        <Card>
          <Text style={{ color: C.inkSoft }}>
            Delivered with proof. The shipper will mark it completed — earnings settle then.
          </Text>
        </Card>
      )}
      {st === 'completed' && <Badge tone="ok" text="Trip completed — earning settled" />}

      <Text style={{ fontSize: 11, color: C.inkFaint }}>
        Pickup and delivery need a real photo proof; the backend blocks the status change without it.
      </Text>
    </ScrollView>
  );
}
