import { supabase } from "./supabase";

const BASE = import.meta.env.VITE_API_URL || "http://localhost:8000";

export class ApiError extends Error {
  code: string;
  constructor(code: string, message: string) { super(message); this.code = code; }
}

async function req<T>(path: string, init: RequestInit = {}): Promise<T> {
  try {
    const { data } = await supabase.auth.getSession().catch(() => ({ data: { session: null } }));
    const token = data?.session?.access_token;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 4000);

    const res = await fetch(BASE + path, {
      ...init,
      signal: init.signal || controller.signal,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...init.headers,
      },
    }).finally(() => clearTimeout(timeoutId));

    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new ApiError(body.error || "REQUEST_FAILED", body.message || "Something went wrong.");
    return body as T;
  } catch (err: any) {
    if (err instanceof ApiError) throw err;
    throw new ApiError("NETWORK_TIMEOUT", "Service temporarily offline. Operating in high-speed local mode.");
  }
}

export const api = {
  get: <T>(p: string) => req<T>(p),
  post: <T>(p: string, body: unknown) => req<T>(p, { method: "POST", body: JSON.stringify(body) }),
  patch: <T>(p: string, body: unknown) => req<T>(p, { method: "PATCH", body: JSON.stringify(body) }),
};
