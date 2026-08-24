import { createClient } from "@supabase/supabase-js";
import "dotenv/config";

// Service-role client: server-side only. NEVER ship this key to the frontend.
export const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

// Per-request client bound to the caller JWT — RLS applies (defense in depth).
export const supabaseForUser = (accessToken) =>
  createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
    auth: { persistSession: false },
  });
