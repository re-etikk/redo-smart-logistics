import { createClient } from "@supabase/supabase-js";

const DEFAULT_SUPABASE_URL = "https://npisbdoztiweaayqmqev.supabase.co";
const DEFAULT_SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5waXNiZG96dGl3ZWFheXFtcWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMTkyNjMsImV4cCI6MjEwMjg5NTI2M30.EFfWxAoFLXO1XD3Pf2L4CtUaJuyRAaS8HK7t-stzFIU";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || DEFAULT_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || DEFAULT_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
