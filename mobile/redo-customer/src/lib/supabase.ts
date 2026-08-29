import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import Constants from 'expo-constants';

const extra: any = Constants.expoConfig?.extra ?? {};

const DEFAULT_SUPABASE_URL = "https://npisbdoztiweaayqmqev.supabase.co";
const DEFAULT_SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5waXNiZG96dGl3ZWFheXFtcWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMTkyNjMsImV4cCI6MjEwMjg5NTI2M30.EFfWxAoFLXO1XD3Pf2L4CtUaJuyRAaS8HK7t-stzFIU";
const DEFAULT_API_URL = "https://redo-backend.onrender.com";

export const GOOGLE_MAPS_API_KEY = "AIzaSyDnD2JUGtjeZvTETWi4bz7nBvu364T11ds";
export const SUPABASE_URL: string = extra.SUPABASE_URL && !extra.SUPABASE_URL.includes('YOUR-PROJECT') ? extra.SUPABASE_URL : DEFAULT_SUPABASE_URL;
export const SUPABASE_ANON_KEY: string = extra.SUPABASE_ANON_KEY && !extra.SUPABASE_ANON_KEY.startsWith('YOUR') ? extra.SUPABASE_ANON_KEY : DEFAULT_SUPABASE_ANON_KEY;
export const API_URL: string = extra.API_URL && !extra.API_URL.includes('192.168') && !extra.API_URL.includes('localhost') ? extra.API_URL : DEFAULT_API_URL;

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false, // no browser URL on native
    flowType: 'pkce', // required for native Google OAuth code exchange
  },
});
