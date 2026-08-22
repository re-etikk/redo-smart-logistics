import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://npisbdoztiweaayqmqev.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5waXNiZG96dGl3ZWFheXFtcWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1NTkyMTMsImV4cCI6MjA1NDEzNTIxM30.EfFWxAoFLX01XD3Pf2L4CtUaJuyRAaS8HK7t-stzFIU";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Return type: caller ab pata laga sakta hai success hua ya nahi
export async function triggerDemoLogin(
  role: "sme" | "truck_owner" | "admin" = "sme"
): Promise<{ success: boolean; error?: string }> {
  // README ke seeded accounts se match karta email (demo.sme@ / demo.owner@)
  const emailMap: Record<string, string> = {
    sme: "demo.sme@redo.app",
    truck_owner: "demo.owner@redo.app",
    admin: "demo.admin@redo.app",
  };
  const demoEmail = emailMap[role];
  const demoPassword = import.meta.env.VITE_DEMO_PASSWORD || "password123";

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: demoEmail,
      password: demoPassword,
    });

    if (error || !data.session) {
      return { success: false, error: error?.message || "No session returned" };
    }
    return { success: true };
  } catch (e: any) {
    return { success: false, error: e?.message || "Unknown error" };
  }
}
