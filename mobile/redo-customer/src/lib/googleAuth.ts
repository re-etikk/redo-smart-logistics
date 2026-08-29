import { Linking } from 'react-native';
import { supabase } from './supabase';

let WebBrowser: any = null;
let makeRedirectUri: any = null;

try {
  WebBrowser = require('expo-web-browser');
  WebBrowser.maybeCompleteAuthSession();
} catch {}

try {
  const authSession = require('expo-auth-session');
  makeRedirectUri = authSession.makeRedirectUri;
} catch {}

export async function signInWithGoogleNative(): Promise<{ ok: boolean; message?: string }> {
  try {
    const redirectTo = makeRedirectUri
      ? makeRedirectUri({ scheme: 'redologistics' })
      : 'https://npisbdoztiweaayqmqev.supabase.co/auth/v1/callback';

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo, skipBrowserRedirect: true },
    });

    if (error || !data?.url) {
      return { ok: false, message: error?.message ?? 'Could not initiate Google Sign-In.' };
    }

    if (WebBrowser && WebBrowser.openAuthSessionAsync) {
      const result = await WebBrowser.openAuthSessionAsync(data.url, redirectTo);
      if (result.type === 'success' && result.url) {
        const url = new URL(result.url);
        const code = url.searchParams.get('code');
        if (code) {
          const { error: exErr } = await supabase.auth.exchangeCodeForSession(code);
          if (exErr) return { ok: false, message: exErr.message };
          return { ok: true };
        }
      }
    } else {
      await Linking.openURL(data.url);
      return { ok: true };
    }

    return { ok: true };
  } catch (err: any) {
    return { ok: false, message: err.message || 'Google sign-in error' };
  }
}
