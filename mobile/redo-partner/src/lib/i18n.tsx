// Lightweight i18n — Rapido-style language selection persisted on device.
// Add a language = add a column here; every screen reads through t().
import React, { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

export type Lang = 'en' | 'hi';
const KEY = 'redo.lang';

const D: Record<string, { en: string; hi: string }> = {
  // Language / permission
  choose_language: { en: 'Choose your language', hi: 'अपनी भाषा चुनें' },
  continue: { en: 'Continue', hi: 'आगे बढ़ें' },
  loc_title: { en: 'Allow location access', hi: 'लोकेशन की अनुमति दें' },
  loc_why_c: { en: 'We use your location to show nearby routes and live truck tracking on the map.', hi: 'हम आपकी लोकेशन का उपयोग नज़दीकी रूट और मैप पर लाइव ट्रक ट्रैकिंग दिखाने के लिए करते हैं।' },
  loc_why_p: { en: 'Your location powers live trip tracking for shippers and nearby load matching.', hi: 'आपकी लोकेशन से शिपर को लाइव ट्रैकिंग मिलती है और नज़दीकी लोड मैच होते हैं।' },
  loc_allow: { en: 'Allow location', hi: 'लोकेशन दें' },
  loc_skip: { en: 'Not now', hi: 'अभी नहीं' },
  // Auth
  sign_in: { en: 'Sign in', hi: 'साइन इन करें' },
  create_account: { en: 'Create account', hi: 'खाता बनाएँ' },
  email: { en: 'Email', hi: 'ईमेल' },
  password: { en: 'Password', hi: 'पासवर्ड' },
  password_min: { en: 'Password (min 8)', hi: 'पासवर्ड (कम से कम 8)' },
  full_name: { en: 'Full name', hi: 'पूरा नाम' },
  phone: { en: 'Phone', hi: 'फ़ोन नंबर' },
  signing_in: { en: 'Signing in…', hi: 'साइन इन हो रहा है…' },
  creating: { en: 'Creating…', hi: 'बन रहा है…' },
  have_account: { en: 'I already have an account', hi: 'मेरा खाता पहले से है' },
  signin_failed: { en: 'Sign in failed', hi: 'साइन इन नहीं हुआ' },
  wrong_creds: { en: 'Incorrect email or password.', hi: 'ईमेल या पासवर्ड गलत है।' },
  confirm_email_first: { en: 'Email not confirmed yet. Check your inbox for the confirmation link.', hi: 'ईमेल अभी कन्फर्म नहीं हुआ है। अपने इनबॉक्स में कन्फर्मेशन लिंक देखें।' },
  confirm_email_title: { en: 'Confirm your email', hi: 'अपना ईमेल कन्फर्म करें' },
  confirm_email_body: { en: 'We sent a confirmation link to your email. Click it, then sign in here — your account will finish setting up automatically.', hi: 'हमने आपके ईमेल पर कन्फर्मेशन लिंक भेजा है। उस पर क्लिक करें, फिर यहाँ साइन इन करें — आपका खाता अपने आप पूरा सेट हो जाएगा।' },
  same_account: { en: 'Same account works on the website and the app.', hi: 'यही खाता वेबसाइट और ऐप दोनों पर चलता है।' },
  // Onboarding — common
  step: { en: 'Step', hi: 'चरण' },
  of: { en: 'of', hi: 'में से' },
  save_continue: { en: 'Save & continue', hi: 'सेव करें और आगे बढ़ें' },
  finish: { en: 'Finish setup', hi: 'सेटअप पूरा करें' },
  back: { en: 'Back', hi: 'वापस' },
  // Partner onboarding
  driver_reg: { en: 'Driver registration', hi: 'ड्राइवर रजिस्ट्रेशन' },
  driver_sub: { en: 'Tell us about yourself', hi: 'अपने बारे में बताएं' },
  city: { en: 'Home city', hi: 'शहर' },
  truck_reg: { en: 'Truck registration', hi: 'ट्रक रजिस्ट्रेशन' },
  truck_sub: { en: 'Add your vehicle details', hi: 'अपने वाहन की जानकारी डालें' },
  reg_number: { en: 'Registration number', hi: 'रजिस्ट्रेशन नंबर' },
  truck_type: { en: 'Truck type', hi: 'ट्रक का प्रकार' },
  capacity_t: { en: 'Capacity (tonnes)', hi: 'क्षमता (टन)' },
  body_type: { en: 'Body type', hi: 'बॉडी टाइप' },
  docs_title: { en: 'Upload documents', hi: 'दस्तावेज़ अपलोड करें' },
  docs_sub: { en: 'Required for verification before your first trip', hi: 'पहली ट्रिप से पहले वेरिफिकेशन के लिए ज़रूरी' },
  doc_required: { en: 'Required', hi: 'ज़रूरी' },
  doc_optional: { en: 'Optional', hi: 'वैकल्पिक' },
  upload: { en: 'Upload', hi: 'अपलोड करें' },
  uploaded: { en: 'Uploaded ✓', hi: 'अपलोड हो गया ✓' },
  uploading: { en: 'Uploading…', hi: 'अपलोड हो रहा है…' },
  docs_note: { en: 'Files go to a private bucket. Our team verifies them — you will get a notification.', hi: 'फ़ाइलें प्राइवेट बकेट में जाती हैं। हमारी टीम वेरिफाई करेगी — आपको नोटिफिकेशन मिलेगा।' },
  docs_pending_note: { en: 'You can start using the app; trips unlock as documents get verified.', hi: 'आप ऐप इस्तेमाल शुरू कर सकते हैं; दस्तावेज़ वेरिफाई होते ही ट्रिप्स चालू हो जाएँगी।' },
  // Customer onboarding
  business_title: { en: 'Business details', hi: 'बिज़नेस की जानकारी' },
  business_sub: { en: 'One quick step and you are ready to ship', hi: 'बस एक छोटा-सा चरण और आप शिपिंग के लिए तैयार' },
  business_name: { en: 'Business name', hi: 'बिज़नेस का नाम' },
  contact_person: { en: 'Contact person', hi: 'संपर्क व्यक्ति' },
  // Tabs & common UI
  tab_home: { en: 'Home', hi: 'होम' },
  tab_shipments: { en: 'Shipments', hi: 'शिपमेंट' },
  tab_bookings: { en: 'Bookings', hi: 'बुकिंग' },
  tab_invoices: { en: 'Invoices', hi: 'इनवॉइस' },
  tab_earnings: { en: 'Earnings', hi: 'कमाई' },
  tab_profile: { en: 'Profile', hi: 'प्रोफ़ाइल' },
  // Home (customer)
  book_truck: { en: 'Book a truck', hi: 'ट्रक बुक करें' },
  pickup_city: { en: 'Pickup city', hi: 'पिकअप शहर' },
  drop_city: { en: 'Drop city', hi: 'ड्रॉप शहर' },
  weight_t: { en: 'Weight (tonnes)', hi: 'वज़न (टन)' },
  cargo_type: { en: 'Cargo type', hi: 'कार्गो का प्रकार' },
  find_trucks: { en: 'Find trucks on this route', hi: 'इस रूट पर ट्रक खोजें' },
  finding: { en: 'Finding trucks…', hi: 'ट्रक खोजे जा रहे हैं…' },
  // Home (partner)
  hello: { en: 'Hello', hi: 'नमस्ते' },
  loads_near: { en: 'Available loads on the network', hi: 'नेटवर्क पर उपलब्ध लोड' },
  no_loads: { en: 'No open loads right now.', hi: 'अभी कोई खुला लोड नहीं है।' },
  no_loads_hint: { en: 'New shipper requests appear here instantly.', hi: 'नए शिपर रिक्वेस्ट यहाँ तुरंत दिखेंगे।' },
  est_earning: { en: 'ESTIMATED EARNING', hi: 'अनुमानित कमाई' },
  accept_load: { en: 'Accept load', hi: 'लोड स्वीकार करें' },
  sign_out: { en: 'Sign out', hi: 'साइन आउट' },
};

interface I18n { lang: Lang; setLang: (l: Lang) => void; ready: boolean; t: (k: string) => string }
const Ctx = createContext<I18n>({ lang: 'en', setLang: () => {}, ready: false, t: (k) => k });
export const useI18n = () => useContext(Ctx);

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>('en');
  const [ready, setReady] = useState(false);
  const [chosen, setChosen] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(KEY).then((v) => {
      if (v === 'en' || v === 'hi') { setLangState(v); setChosen(true); }
      setReady(true);
    });
  }, []);

  const setLang = (l: Lang) => {
    setLangState(l); setChosen(true);
    AsyncStorage.setItem(KEY, l).catch(() => {});
  };

  const t = (k: string) => D[k]?.[lang] ?? k;
  return <Ctx.Provider value={{ lang, setLang, ready, t }}>{children}</Ctx.Provider>;
}

// App.tsx needs to know whether the user has ever picked a language.
export async function hasChosenLanguage(): Promise<boolean> {
  const v = await AsyncStorage.getItem(KEY);
  return v === 'en' || v === 'hi';
}
