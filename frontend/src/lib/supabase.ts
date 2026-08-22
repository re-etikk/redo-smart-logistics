import { createClient } from "@supabase/supabase-js";

const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const isSupabaseConfigured = Boolean(url && key && url.startsWith("http"));

export const MOCK_PROFILES: Record<string, any> = {
  "demo-sme-id": {
    id: "demo-sme-id",
    full_name: "Anita Sharma (Demo SME)",
    phone: "+91 98765 43210",
    role: "sme",
    company_name: "Apex Goods & Logistics",
    avatar_url: "",
    onboarding_complete: true,
  },
  "demo-owner-id": {
    id: "demo-owner-id",
    full_name: "Rajesh Kumar (Demo Owner)",
    phone: "+91 98123 45678",
    role: "truck_owner",
    company_name: "Kumar Backhaul Express",
    avatar_url: "",
    onboarding_complete: true,
  },
};

const LOCAL_SESSION_KEY = "redo_mock_session";
const LOCAL_PROFILES_KEY = "redo_mock_profiles";

function getStoredMockProfiles() {
  try {
    const raw = localStorage.getItem(LOCAL_PROFILES_KEY);
    return raw ? { ...MOCK_PROFILES, ...JSON.parse(raw) } : { ...MOCK_PROFILES };
  } catch {
    return { ...MOCK_PROFILES };
  }
}

function setStoredMockProfiles(profiles: Record<string, any>) {
  try {
    localStorage.setItem(LOCAL_PROFILES_KEY, JSON.stringify(profiles));
  } catch {}
}

function getStoredSession() {
  try {
    const raw = localStorage.getItem(LOCAL_SESSION_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function setStoredSession(session: any) {
  try {
    if (session) localStorage.setItem(LOCAL_SESSION_KEY, JSON.stringify(session));
    else localStorage.removeItem(LOCAL_SESSION_KEY);
  } catch {}
}

const authListeners: Array<(event: string, session: any) => void> = [];

export const mockSupabase = {
  auth: {
    async getSession() {
      const session = getStoredSession();
      return { data: { session }, error: null };
    },
    async signInWithPassword({ email }: { email?: string; password?: string }) {
      const lowerEmail = (email || "").toLowerCase().trim();
      let role: "sme" | "truck_owner" = "sme";
      let id = "demo-sme-id";
      let name = "Anita Sharma (Demo SME)";

      if (lowerEmail.includes("owner") || lowerEmail.includes("driver") || lowerEmail.includes("truck")) {
        role = "truck_owner";
        id = "demo-owner-id";
        name = "Rajesh Kumar (Demo Owner)";
      } else if (lowerEmail.includes("sme") || lowerEmail.includes("shipper")) {
        role = "sme";
        id = "demo-sme-id";
        name = "Anita Sharma (Demo SME)";
      } else {
        id = `user-${Date.now()}`;
        name = lowerEmail.split("@")[0] || "User";
      }

      const profiles = getStoredMockProfiles();
      if (!profiles[id]) {
        profiles[id] = {
          id,
          full_name: name,
          role,
          company_name: "Redo Logistics Partner",
          onboarding_complete: true,
        };
        setStoredMockProfiles(profiles);
      }

      const session = {
        access_token: `mock-token-${id}`,
        token_type: "bearer",
        user: { id, email: lowerEmail },
      };
      setStoredSession(session);
      authListeners.forEach((cb) => cb("SIGNED_IN", session));
      return { data: { user: session.user, session }, error: null };
    },
    async signUp({ email, options }: any) {
      const id = `user-${Date.now()}`;
      const lowerEmail = (email || "").toLowerCase().trim();
      const role = options?.data?.role || "sme";
      const name = options?.data?.full_name || lowerEmail.split("@")[0];

      const profiles = getStoredMockProfiles();
      profiles[id] = {
        id,
        full_name: name,
        role,
        company_name: options?.data?.company_name || "",
        onboarding_complete: false,
      };
      setStoredMockProfiles(profiles);

      const session = {
        access_token: `mock-token-${id}`,
        token_type: "bearer",
        user: { id, email: lowerEmail },
      };
      setStoredSession(session);
      authListeners.forEach((cb) => cb("SIGNED_IN", session));
      return { data: { user: session.user, session }, error: null };
    },
    async signOut() {
      setStoredSession(null);
      authListeners.forEach((cb) => cb("SIGNED_OUT", null));
      return { error: null };
    },
    onAuthStateChange(callback: (event: string, session: any) => void) {
      authListeners.push(callback);
      return {
        data: {
          subscription: {
            unsubscribe() {
              const idx = authListeners.indexOf(callback);
              if (idx >= 0) authListeners.splice(idx, 1);
            },
          },
        },
      };
    },
  },
  from(table: string) {
    return {
      select() {
        return {
          eq(_field: string, val: any) {
            return {
              async single() {
                if (table === "profiles") {
                  const profiles = getStoredMockProfiles();
                  const profile = profiles[val] || null;
                  return { data: profile, error: profile ? null : { message: "Profile not found" } };
                }
                return { data: null, error: null };
              },
              async select() {
                return { data: [], error: null };
              },
            };
          },
        };
      },
      update(fields: any) {
        return {
          eq(_field: string, val: any) {
            return {
              async select() {
                if (table === "profiles") {
                  const profiles = getStoredMockProfiles();
                  if (profiles[val]) {
                    profiles[val] = { ...profiles[val], ...fields };
                    setStoredMockProfiles(profiles);
                  }
                  return { data: [profiles[val]], error: null };
                }
                return { data: [], error: null };
              },
            };
          },
        };
      },
      insert(rows: any) {
        return {
          async select() {
            return { data: Array.isArray(rows) ? rows : [rows], error: null };
          },
        };
      },
    };
  },
};

const realClient = isSupabaseConfigured ? createClient(url!, key!) : null;

export const supabase: any = isSupabaseConfigured ? realClient : mockSupabase;
export const triggerDemoLogin = (role: "sme" | "truck_owner") => {
  const email = role === "sme" ? "demo.sme@redo.app" : "demo.owner@redo.app";
  return mockSupabase.auth.signInWithPassword({ email });
};

