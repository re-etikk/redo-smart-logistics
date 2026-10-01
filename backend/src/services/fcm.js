import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { supabaseAdmin } from '../lib/supabase.js';

let fcmApp;

function getFcmApp() {
  if (fcmApp) return fcmApp;
  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!rawServiceAccount) return null;

  const serviceAccount = JSON.parse(rawServiceAccount);
  fcmApp = getApps().find((app) => app.name === 'redo-dispatch-fcm') ||
    initializeApp({ credential: cert(serviceAccount) }, 'redo-dispatch-fcm');
  return fcmApp;
}

export async function sendDispatchOfferPush(driverIds, cargo, offers) {
  const app = getFcmApp();
  if (!app || !driverIds.length) return { sent: 0, configured: Boolean(app) };

  const { data: devices, error } = await supabaseAdmin.from('user_devices')
    .select('user_id, fcm_token')
    .in('user_id', driverIds);
  if (error) throw error;

  const offerByDriver = new Map(offers.map((offer) => [offer.driver_id, offer]));
  const messaging = getMessaging(app);
  const results = await Promise.all((devices || []).map(async (device) => {
    const offer = offerByDriver.get(device.user_id);
    if (!offer) return false;
    try {
      await messaging.send({
        token: device.fcm_token,
        data: {
          type: 'dispatch_offer',
          offer_id: offer.id,
          cargo_id: cargo.cargo_id,
          origin: cargo.origin,
          destination: cargo.destination,
          cargo_type: cargo.cargo_type,
          weight_tons: String(cargo.cargo_weight_tons),
          payout_inr: String(cargo.offered_price_inr || 0),
          distance_from_driver_km: String(offer.distance_km),
          expires_at: offer.expires_at,
        },
        android: { priority: 'high', ttl: 45_000 },
      });
      return true;
    } catch (sendError) {
      if (sendError.code === 'messaging/registration-token-not-registered' ||
          sendError.code === 'messaging/invalid-registration-token') {
        await supabaseAdmin.from('user_devices').delete().eq('fcm_token', device.fcm_token);
      }
      console.error('FCM dispatch send failed:', sendError.code || sendError.message);
      return false;
    }
  }));

  return { sent: results.filter(Boolean).length, configured: true };
}