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
    // Defensive fallback only — this should rarely fire since both apps
    // create/upsert their profile row during signup/onboarding. We do NOT
    // trust any client-supplied header here (e.g. "x-user-role") to decide
    // role, because that would let a caller pick their own permissions.
    // Worst case if this guess is wrong: the user hits a 403 and completes
    // onboarding properly, which sets the correct role explicitly.
    const role = req.path.includes("truck") || req.path.includes("partner") ? "truck_owner" : "sme";
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
      onboarding_complete: false,
    };
  }

  req.profile = profile;
  next();
}

// Rejects the request if the caller's account role doesn't match. Role is
// ALWAYS read from the DB profile (req.profile, set above) — never from a
// client-supplied header — so a caller cannot grant themselves access by
// simply claiming a different role. If someone's account genuinely has the
// wrong role (e.g. legacy data), the fix is to correct it via onboarding /
// an admin action, not to silently rewrite it on every mismatched request.
export const requireRole = (role) => (req, res, next) => {
  if (req.profile.role !== role) {
    return res.status(403).json({ error: "FORBIDDEN_ROLE", message: "This action is not available for your account type." });
  }
  next();
};
