import { Linking } from 'react-native';
import { supabase } from './supabase';

export async function signInWithGoogleNative(): Promise<{ ok: boolean; message?: string }> {
  try {
    const redirectTo = 'redocustomer://auth/callback';

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo,
        skipBrowserRedirect: true,
      },
    });

    if (error || !data?.url) {
      return { ok: false, message: error?.message ?? 'Could not initiate Google Sign-In.' };
    }

    await Linking.openURL(data.url);
    return { ok: true };
  } catch (err: any) {
    return { ok: false, message: err.message || 'Google sign-in error' };
  }
}
