// Rapido-Captain-style onboarding after signup:
//   Step 1 Driver registration → Step 2 Truck registration → Step 3 Documents.
// Finishes by setting onboarding_complete on the shared profile (same flag the website uses).
import React, { useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { api } from '../lib/api';
import { supabase } from '../lib/supabase';
import { useI18n } from '../lib/i18n';
import { C, R } from '../lib/theme';
import { Badge, Button, Card, Input, Label, LogoRow } from '../components/ui';

const CITIES = ['Mumbai', 'Delhi', 'Pune', 'Jaipur', 'Surat'];
const TRUCK_TYPES = ['14FT', '17FT', '22FT', '32FT'];
const BODY_TYPES = ['Closed container', 'Open body', 'Refrigerated', 'Tipper'];
const DEPART = [{ label: 'Today 6 PM' }, { label: 'Tomorrow 10 AM' }, { label: 'Day after' }];
function departAt(idx: number): string {
  const d = new Date();
  if (idx === 0) { d.setHours(18, 0, 0, 0); if (d.getTime() < Date.now()) d.setDate(d.getDate() + 1); }
  if (idx === 1) { d.setDate(d.getDate() + 1); d.setHours(10, 0, 0, 0); }
  if (idx === 2) { d.setDate(d.getDate() + 2); d.setHours(10, 0, 0, 0); }
  return d.toISOString();
}

const DOCS: { type: string; label: string; required: boolean }[] = [
  { type: 'driving_licence', label: 'Driving Licence', required: true },
  { type: 'vehicle_rc', label: 'RC (Registration Certificate)', required: true },
  { type: 'identity', label: 'Owner ID Proof (Aadhaar)', required: true },
  { type: 'insurance', label: 'Insurance Certificate', required: false },
  { type: 'permit', label: 'Permit (National)', required: false },
  { type: 'fitness', label: 'Fitness Certificate', required: false },
];

function Chips({ options, value, onChange }: { options: string[]; value: string; onChange: (v: string) => void }) {
  return (
    <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 6 }}>
      {options.map((o) => (
        <Pressable key={o} onPress={() => onChange(o)}
          style={[s.chip, value === o && { backgroundColor: C.accent, borderColor: C.accent }]}>
          <Text style={[s.chipText, value === o && { color: C.accentFg }]}>{o}</Text>
        </Pressable>
      ))}
    </View>
  );
}

export default function PartnerOnboarding({ onDone }: { onDone: () => void }) {
  const { t } = useI18n();
  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [driver, setDriver] = useState({ full_name: '', phone: '', city: 'Delhi' });
  const [truck, setTruck] = useState({ registration_number: '', truck_type: '22FT', body_type: 'Closed container', capacity: '9' });
  const [tripFrom, setTripFrom] = useState('Mumbai');
  const [departIdx, setDepartIdx] = useState(1);
  const [uploaded, setUploaded] = useState<Record<string, boolean>>({});
  const [busyDoc, setBusyDoc] = useState<string | null>(null);

  const saveDriver = async () => {
    setBusy(true);
    try {
      await api.patch('/auth/profile', { full_name: driver.full_name, phone: driver.phone, company_name: driver.city });
      setStep(1);
    } catch (e: any) { Alert.alert('Error', e.message); }
    setBusy(false);
  };

  const saveTruck = async () => {
    if (tripFrom === driver.city) { Alert.alert('Route', 'Return trip From and To must be different cities.'); return; }
    setBusy(true);
    try {
      const created: any = await api.post('/trucks', {
        registration_number: truck.registration_number.toUpperCase(),
        truck_type: truck.truck_type, body_type: truck.body_type,
        home_origin: driver.city, default_capacity_tons: +truck.capacity,
      });
      // The wiring that makes matching work: post the empty RETURN TRIP.
      // Shippers are matched against trips, not bare trucks.
      await api.post(`/trucks/${created.truck_id}/trips`, {
        origin: tripFrom, destination: driver.city,
        departure_at: departAt(departIdx),
        available_capacity_tons: +truck.capacity,
      });
      setStep(2);
    } catch (e: any) { Alert.alert('Error', e.message); }
    setBusy(false);
  };

  const uploadDoc = async (type: string) => {
    const picked = await ImagePicker.launchImageLibraryAsync({ quality: 0.6 });
    if (picked.canceled) return;
    setBusyDoc(type);
    try {
      const { data: sess } = await supabase.auth.getSession();
      const uid = sess.session!.user.id;
      const path = `${uid}/${type}-${Date.now()}.jpg`;
      const file = await fetch(picked.assets[0].uri).then((r) => r.arrayBuffer());
      const { error } = await supabase.storage.from('kyc-documents').upload(path, file, { contentType: 'image/jpeg' });
      if (error) throw new Error(error.message);
      const { error: e2 } = await supabase.from('kyc_verifications').insert({
        user_id: uid, document_type: type, verification_status: 'pending',
        verification_source: 'manual_upload', document_reference_masked: `upload:…${path.slice(-10)}`,
      });
      if (e2) throw new Error(e2.message);
      setUploaded((u) => ({ ...u, [type]: true }));
    } catch (e: any) { Alert.alert('Upload failed', e.message); }
    setBusyDoc(null);
  };

  const allRequiredDone = DOCS.filter((d) => d.required).every((d) => uploaded[d.type]);

  const finish = async () => {
    setBusy(true);
    try {
      await api.patch('/auth/profile', { onboarding_complete: true });
      onDone();
    } catch (e: any) { Alert.alert('Error', e.message); setBusy(false); }
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.canvas }} contentContainerStyle={{ padding: 20, paddingTop: 56 }}>
      <View style={{ alignItems: 'center', marginBottom: 14 }}><LogoRow /></View>

      {/* Stepper */}
      <View style={{ flexDirection: 'row', justifyContent: 'center', gap: 8, marginBottom: 6 }}>
        {[0, 1, 2].map((i) => (
          <View key={i} style={[s.dot, i <= step && { backgroundColor: C.accent, width: 24 }]} />
        ))}
      </View>
      <Text style={{ textAlign: 'center', fontSize: 12, fontWeight: '700', color: C.inkFaint, marginBottom: 14 }}>
        {t('step')} {step + 1} {t('of')} 3
      </Text>

      {step === 0 && (
        <Card>
          <Text style={s.h1}>{t('driver_reg')}</Text>
          <Text style={s.sub}>{t('driver_sub')}</Text>
          <Label>{t('full_name')}</Label>
          <Input value={driver.full_name} onChangeText={(v) => setDriver({ ...driver, full_name: v })} />
          <Label>{t('phone')}</Label>
          <Input keyboardType="phone-pad" value={driver.phone} onChangeText={(v) => setDriver({ ...driver, phone: v })} />
          <Label>{t('city')}</Label>
          <Chips options={CITIES} value={driver.city} onChange={(v) => setDriver({ ...driver, city: v })} />
          <View style={{ height: 18 }} />
          <Button title={busy ? '…' : t('save_continue')} loading={busy}
            disabled={!driver.full_name || !driver.phone} onPress={saveDriver} />
        </Card>
      )}

      {step === 1 && (
        <Card>
          <Text style={s.h1}>{t('truck_reg')}</Text>
          <Text style={s.sub}>{t('truck_sub')}</Text>
          <Label>{t('reg_number')}</Label>
          <Input autoCapitalize="characters" placeholder="DL 01 AB 4321"
            value={truck.registration_number} onChangeText={(v) => setTruck({ ...truck, registration_number: v })} />
          <Label>{t('truck_type')}</Label>
          <Chips options={TRUCK_TYPES} value={truck.truck_type} onChange={(v) => setTruck({ ...truck, truck_type: v })} />
          <Label>{t('body_type')}</Label>
          <Chips options={BODY_TYPES} value={truck.body_type} onChange={(v) => setTruck({ ...truck, body_type: v })} />
          <Label>{t('capacity_t')}</Label>
          <Input keyboardType="decimal-pad" value={truck.capacity} onChangeText={(v) => setTruck({ ...truck, capacity: v })} />

          <View style={{ marginTop: 16, borderTopWidth: 1, borderTopColor: C.line, paddingTop: 12 }}>
            <Text style={{ fontWeight: '900', color: C.ink }}>Next empty return trip</Text>
            <Text style={{ fontSize: 12, color: C.inkFaint }}>Shippers get matched to this trip → {driver.city}</Text>
            <Label>Empty at (From)</Label>
            <Chips options={CITIES.filter((c) => c !== driver.city)} value={tripFrom} onChange={setTripFrom} />
            <Label>Departure</Label>
            <Chips options={DEPART.map((d) => d.label)} value={DEPART[departIdx].label}
              onChange={(v) => setDepartIdx(DEPART.findIndex((d) => d.label === v))} />
          </View>
          <View style={{ height: 18 }} />
          <Button title={busy ? '…' : t('save_continue')} loading={busy}
            disabled={!truck.registration_number} onPress={saveTruck} />
          <View style={{ height: 8 }} />
          <Button title={t('back')} variant="secondary" onPress={() => setStep(0)} />
        </Card>
      )}

      {step === 2 && (
        <View style={{ gap: 10 }}>
          <Card>
            <Text style={s.h1}>{t('docs_title')}</Text>
            <Text style={s.sub}>{t('docs_sub')}</Text>
          </Card>
          {DOCS.map((d) => (
            <Card key={d.type}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontWeight: '800', color: C.ink }}>{d.label}</Text>
                  <Badge tone={d.required ? 'warn' : 'neutral'} text={d.required ? t('doc_required') : t('doc_optional')} />
                </View>
                <View style={{ width: 130 }}>
                  <Button variant={uploaded[d.type] ? 'secondary' : 'primary'}
                    title={busyDoc === d.type ? t('uploading') : uploaded[d.type] ? t('uploaded') : t('upload')}
                    loading={busyDoc === d.type} onPress={() => uploadDoc(d.type)} />
                </View>
              </View>
            </Card>
          ))}
          <Text style={{ fontSize: 11, color: C.inkFaint }}>{t('docs_note')}</Text>
          <Button title={busy ? '…' : t('finish')} loading={busy} disabled={!allRequiredDone} onPress={finish} />
          {!allRequiredDone && (
            <Text style={{ fontSize: 11, color: C.warn, textAlign: 'center', fontWeight: '700' }}>
              {DOCS.filter((d) => d.required && !uploaded[d.type]).length} required document(s) left
            </Text>
          )}
          <Text style={{ fontSize: 11, color: C.inkFaint, textAlign: 'center' }}>{t('docs_pending_note')}</Text>
        </View>
      )}
    </ScrollView>
  );
}

const s = StyleSheet.create({
  h1: { fontSize: 20, fontWeight: '900', color: C.ink },
  sub: { fontSize: 13, color: C.inkFaint, marginTop: 2, marginBottom: 4 },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: C.line },
  chip: { borderWidth: 1, borderColor: C.line, backgroundColor: C.white, borderRadius: 999, paddingHorizontal: 12, paddingVertical: 8 },
  chipText: { fontSize: 13, fontWeight: '700', color: C.inkSoft },
});
