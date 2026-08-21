import { supabaseAdmin } from "../lib/supabase.js";

export async function notify(userId, type, title, message) {
  await supabaseAdmin.from("notifications").insert({ user_id: userId, type, title, message });
}
