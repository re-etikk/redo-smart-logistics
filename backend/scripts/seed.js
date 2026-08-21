// Seed script (spec §11, §53, §71).
// Creates REAL Supabase Auth demo accounts and the SIH demo scenario.
// Run once after migrations:  node scripts/seed.js
// Requires backend/.env with SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY + DEMO_PASSWORD.

import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import { createClient } from '@supabase/supabase-js';

const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

const PASSWORD = process.env.DEMO_PASSWORD;
if (!PASSWORD) {
  console.error('Set DEMO_PASSWORD in backend/.env — demo accounts must not ship a hardcoded password.');
  process.exit(1);
}

async function ensureUser(email, meta) {
  const { data: list } = await admin.auth.admin.listUsers();
  const existing = list?.users?.find((u) => u.email === email);
  if (existing) return existing;
  const { data, error } = await admin.auth.admin.createUser({
    email, password: PASSWORD, email_confirm: true, user_metadata: meta,
  });
  if (error) throw error;
  return data.user;
}

async function main() {
  console.log('Creating demo auth accounts…');
  const owner = await ensureUser(process.env.DEMO_OWNER_EMAIL || 'demo.owner@redo.app', { demo: true });
  const sme = await ensureUser(process.env.DEMO_SME_EMAIL || 'demo.sme@redo.app', { demo: true });

  console.log('Creating profiles…');
  await admin.from('profiles').upsert([
    { id: owner.id, full_name: 'Rakesh Yadav (Demo)', phone: '+91-9800000001', role: 'truck_owner', onboarding_complete: true },
    { id: sme.id, full_name: 'Meera Sharma (Demo)', phone: '+91-9800000002', role: 'sme', company_name: 'Meera Traders', onboarding_complete: true },
  ]);

  console.log('Creating demo truck + open return trip (Mumbai → Delhi, 4 T free)…');
  await admin.from('trucks').upsert({
    truck_id: 'T-DEMO-1', owner_id: owner.id, truck_type: '22FT', registration_number: 'DL 01 AB 4321',
    body_type: 'Closed container', home_origin: 'Delhi', default_capacity_tons: 9,
    driver_rating: 4.7, on_time_rate: 0.94, cancel_rate: 0.03, verified_documents: true, status: 'available',
  });
  const tomorrow = new Date(Date.now() + 24 * 36e5); tomorrow.setUTCHours(6, 0, 0, 0);
  await admin.from('truck_trips').upsert({
    id: '11111111-1111-4111-8111-111111111111',
    truck_id: 'T-DEMO-1', origin: 'Mumbai', destination: 'Delhi', distance_km: 1400,
    departure_at: tomorrow.toISOString(), available_capacity_tons: 4.0,
    price_per_km_ton: 1.05, open_for_matching: true,
  });

  console.log('Demo KYC (labeled demo verification — never DigiLocker)…');
  await admin.from('kyc_verifications').upsert([
    { id: '22222222-2222-4222-8222-222222222221', user_id: owner.id, document_type: 'driving_licence',
      verification_status: 'verified', verification_source: 'demo', document_reference_masked: 'DL-XXXX-XXXX-1234' },
    { id: '22222222-2222-4222-8222-222222222222', user_id: owner.id, document_type: 'vehicle_rc',
      verification_status: 'verified', verification_source: 'demo', document_reference_masked: 'RC-XXXX-4321' },
  ]);

  // Optional bulk seed from CSVs (training snapshots -> initial marketplace records only; never runtime data)
  const csvPath = path.resolve('../ml-service/data/trucks.csv');
  if (fs.existsSync(csvPath)) {
    console.log('Bulk-seeding a sample of synthetic trucks from CSV (first 25 rows)…');
    const rows = fs.readFileSync(csvPath, 'utf8').trim().split('\n').slice(1, 26);
    const trucks = rows.map((line) => {
      const [truck_id, truck_type, home_origin, cap, rating, onTime, cancel, dev, verified, gps] = line.split(',');
      return {
        truck_id: 'SEED-' + truck_id, owner_id: owner.id, truck_type, home_origin,
        registration_number: 'SEED-' + truck_id, default_capacity_tons: +cap,
        driver_rating: +rating, on_time_rate: +onTime, cancel_rate: +cancel,
        route_deviation_rate: +dev, verified_documents: verified === '1', gps_enabled: gps === '1',
        status: 'available',
      };
    });
    await admin.from('trucks').upsert(trucks);
  }

  console.log('\nDone. Demo accounts:');
  console.log('  Truck owner:', owner.email);
  console.log('  SME:', sme.email);
  console.log('  Password: (the DEMO_PASSWORD you configured)');
}

main().catch((e) => { console.error(e); process.exit(1); });
