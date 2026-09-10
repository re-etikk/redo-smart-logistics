-- Fix: permission denied for table cargo_requests
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;

GRANT ALL ON TABLE public.cargo_requests TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.trucks TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.bookings TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.profiles TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.truck_trips TO anon, authenticated, service_role;

ALTER TABLE public.cargo_requests ENABLE ROW LEVEL SECURITY;

DO \$\$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'cargo_requests' AND policyname = 'cargo_requests_insert_all'
  ) THEN
    CREATE POLICY cargo_requests_insert_all ON public.cargo_requests FOR INSERT WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'cargo_requests' AND policyname = 'cargo_requests_select_all'
  ) THEN
    CREATE POLICY cargo_requests_select_all ON public.cargo_requests FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'cargo_requests' AND policyname = 'cargo_requests_update_all'
  ) THEN
    CREATE POLICY cargo_requests_update_all ON public.cargo_requests FOR UPDATE USING (true);
  END IF;
END \$\$;
