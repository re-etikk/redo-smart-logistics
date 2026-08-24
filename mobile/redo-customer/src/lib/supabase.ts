import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';

export const GOOGLE_MAPS_API_KEY = "AIzaSyDnD2JUGtjeZvTETWi4bz7nBvu364T11ds";
export const SUPABASE_URL = "https://npisbdoztiweaayqmqev.supabase.co";
export const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5waXNiZG96dGl3ZWFheXFtcWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMTkyNjMsImV4cCI6MjEwMjg5NTI2M30.EFfWxAoFLXO1XD3Pf2L4CtUaJuyRAaS8HK7t-stzFIU";
export const BACKEND_URL = "https://redo-backend.onrender.com";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false, // no browser URL on native
  },
});

export const API_URL: string = BACKEND_URL;
