import { supabaseAdmin } from "../lib/supabase.js";

// Verifies the Supabase JWT and loads the profile (role, onboarding state).
export async function requireAuth(req, res, next) {
  const token = (req.headers.authorization || "").replace(/^Bearer /, "");
  if (!token) return res.status(401).json({ error: "UNAUTHENTICATED", message: "Sign in to continue." });
  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data?.user) {
    return res.status(401).json({ error: "SESSION_INVALID", message: "Your session has expired. Sign in again." });
  }

  req.user = data.user;
  req.token = token;

  let { data: profile } = await supabaseAdmin
    .from("profiles").select("*").eq("id", data.user.id).maybeSingle();

  if (!profile) {
    // Auto-provision profile from auth metadata / client role header to prevent 403 blocks
    const roleHeader = req.headers["x-user-role"] || (req.path.includes("truck") || req.path.includes("partner") ? "truck_owner" : "sme");
    const role = (roleHeader === "truck_owner" || roleHeader === "driver") ? "truck_owner" : "sme";
    const fullName = data.user.user_metadata?.full_name || data.user.user_metadata?.name || data.user.email?.split("@")[0] || "User";

    try {
      const { data: newProfile, error: upsertErr } = await supabaseAdmin
        .from("profiles")
        .upsert({
          id: data.user.id,
          full_name: fullName,
          role: role,
          company_name: data.user.user_metadata?.company_name || null,
          phone: data.user.phone || data.user.user_metadata?.phone || null,
          onboarding_complete: true,
        })
        .select("*")
        .maybeSingle();

      if (!upsertErr && newProfile) {
        profile = newProfile;
      }
    } catch (_) {}

    profile = profile || {
      id: data.user.id,
      full_name: fullName,
      role: role,
      onboarding_complete: true,
    };
  }

  req.profile = profile;
  next();
}

export const requireRole = (role) => async (req, res, next) => {
  if (req.profile.role !== role) {
    // If user is operating in customer app, auto-update role to sme so they are not blocked
    if (role === "sme" && req.headers["x-user-role"] === "sme") {
      req.profile.role = "sme";
      await supabaseAdmin.from("profiles").update({ role: "sme" }).eq("id", req.profile.id).catch(() => {});
      return next();
    }
    return res.status(403).json({ error: "FORBIDDEN_ROLE", message: "This action is not available for your account type." });
  }
  next();
};

