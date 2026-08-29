// Same REST contract as the website — one backend serves web + both apps.
import { API_URL, supabase } from './supabase';

export class ApiError extends Error {
  code: string;
  constructor(code: string, message: string) { super(message); this.code = code; }
}

async function call<T>(method: string, path: string, body?: unknown): Promise<T> {
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch {
    throw new ApiError('NETWORK',
      `Cannot reach the Redo server at ${API_URL}. ` +
      `Emulator → use http://10.0.2.2:8000 · Real phone → laptop LAN IP · and make sure the backend is running.`);
  }
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new ApiError(json.error ?? 'UNKNOWN', json.message ?? 'Something went wrong.');
  return json as T;
}

export const api = {
  get: <T>(p: string) => call<T>('GET', p),
  post: <T>(p: string, b?: unknown) => call<T>('POST', p, b),
  patch: <T>(p: string, b?: unknown) => call<T>('PATCH', p, b),
};
