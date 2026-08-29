// Live wiring: refetch when relevant Postgres rows change (Supabase Realtime).
// RLS scopes what each user actually receives; tables must be in the
// supabase_realtime publication (migrations 0002 + 0005).
import { useEffect } from 'react';
import { supabase } from './supabase';

export function useRealtimeRefresh(tables: string[], onChange: () => void, filter?: string) {
  useEffect(() => {
    const ch = supabase.channel(`live-${tables.join('-')}-${filter ?? 'all'}-${Math.random().toString(36).slice(2)}`);
    for (const table of tables) {
      ch.on('postgres_changes',
        { event: '*', schema: 'public', table, ...(filter ? { filter } : {}) },
        () => onChange());
    }
    ch.subscribe();
    return () => { supabase.removeChannel(ch); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tables.join(','), filter]);
}
