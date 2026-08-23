import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://npisbdoztiweaayqmqev.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5waXNiZG96dGl3ZWFheXFtcWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMTkyNjMsImV4cCI6MjEwMjg5NTI2M30.EFfWxAoFLXO1XD3Pf2L4CtUaJuyRAaS8HK7t-stzFIU";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

// Purana/corrupt session hatane ke liye — kabhi bhi call karo jab auth 401/invalid token de
export function clearStaleSession() {
  try {
    Object.keys(localStorage)
      .filter((k) => k.startsWith("sb-") && k.includes("auth-token"))
      .forEach((k) => localStorage.removeItem(k));
  } catch {
    // localStorage access fail ho to ignore karo (SSR ya privacy mode)
  }
}

export async function triggerDemoLogin(
  role: "sme" | "truck_owner" | "admin" = "sme"
): Promise<{ success: boolean; error?: string }> {
  const emailMap: Record<string, string> = {
    sme: "demo.sme@redo.app",
    truck_owner: "demo.owner@redo.app",
    admin: "demo.admin@redo.app",
  };
  const demoEmail = emailMap[role];
  const demoPassword = import.meta.env.VITE_DEMO_PASSWORD || "password123";

  try {
    // Pehle stale session clear karo taaki purana corrupt token interfere na kare
    clearStaleSession();

    const { data, error } = await supabase.auth.signInWithPassword({
      email: demoEmail,
      password: demoPassword,
    });

    if (error || !data.session) {
      return { success: false, error: error?.message || "Demo account not found. Seed it on the backend first." };
    }
    return { success: true };
  } catch (e: any) {
    return { success: false, error: e?.message || "Unknown error during demo login" };
  }
}
