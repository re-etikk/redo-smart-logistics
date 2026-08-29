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

  const { data: profile } = await supabaseAdmin
    .from("profiles").select("*").eq("id", data.user.id).single();

  if (!profile && req.path !== "/auth/profile") {
    return res.status(403).json({ error: "PROFILE_MISSING", message: "Complete your profile first." });
  }

  req.profile = profile || { id: data.user.id, role: 'truck_owner' };
  next();
}

export const requireRole = (role) => (req, res, next) => {
  if (req.profile.role !== role) {
    return res.status(403).json({ error: "FORBIDDEN_ROLE", message: "This action is not available for your account type." });
  }
  next();
};
