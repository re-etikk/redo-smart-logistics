import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://npisbdoztiweaayqmqev.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5waXNiZG96dGl3ZWFheXFtcWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1NTkyMTMsImV4cCI6MjA1NDEzNTIxM30.EfFWxAoFLX01XD3Pf2L4CtUaJuyRAaS8HK7t-stzFIU";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
