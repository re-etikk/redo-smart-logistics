export interface UserProfileData {
  full_name: string;
  email: string;
  phone: string;
  company_name: string;
  business_type: string;
  gstin: string;
  pan_number: string;
  city: string;
  fleet_size: string;
  avatar_url?: string;
  notifications: {
    sms: boolean;
    whatsapp: boolean;
    email: boolean;
    newLoads: boolean;
  };
  two_factor_auth: boolean;
}

const DEFAULT_PROFILE: UserProfileData = {
  full_name: "Ritik Chaurasia",
  email: "ritik.chaurasia@redo.app",
  phone: "+91 98765 43210",
  company_name: "Chaurasia Freight Logistics",
  business_type: "Fleet Owner & Operator",
  gstin: "07AAAAA0000A1Z5",
  pan_number: "ABCDE1234F",
  city: "Delhi NCR, Delhi",
  fleet_size: "5-20 Trucks",
  notifications: {
    sms: true,
    whatsapp: true,
    email: true,
    newLoads: true,
  },
  two_factor_auth: false,
};

const STORAGE_KEY = "redo_user_profile_v2";

export function getUserProfile(): UserProfileData {
  if (typeof window === "undefined") return DEFAULT_PROFILE;
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      // Check if logged in user has email in supabase
      localStorage.setItem(STORAGE_KEY, JSON.stringify(DEFAULT_PROFILE));
      return DEFAULT_PROFILE;
    }
    const parsed = JSON.parse(saved);
    return { ...DEFAULT_PROFILE, ...parsed };
  } catch {
    return DEFAULT_PROFILE;
  }
}

export function saveUserProfile(data: Partial<UserProfileData>): UserProfileData {
  const current = getUserProfile();
  const updated = { ...current, ...data };
  if (typeof window !== "undefined") {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    window.dispatchEvent(new CustomEvent("redo_profile_updated", { detail: updated }));
  }
  return updated;
}
