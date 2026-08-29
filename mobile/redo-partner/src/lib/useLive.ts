// Refetch on realtime Postgres changes (tables must be in the publication; RLS scopes rows).
import { useEffect } from 'react';
import { supabase } from './supabase';

export function useLive(table: string, onChange: () => void, filter?: string) {
  useEffect(() => {
    const ch = supabase.channel(`live-${table}-${filter ?? 'all'}-${Math.random().toString(36).slice(2)}`)
      .on('postgres_changes',
        { event: '*', schema: 'public', table, ...(filter ? { filter } : {}) },
        () => onChange())
      .subscribe();
    return () => { supabase.removeChannel(ch); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [table, filter]);
}
