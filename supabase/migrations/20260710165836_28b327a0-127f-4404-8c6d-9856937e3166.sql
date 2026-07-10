
-- Auto-expiração de períodos aquisitivos de férias
CREATE OR REPLACE FUNCTION public.expire_vacation_periods()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  affected integer;
BEGIN
  UPDATE public.hr_vacation_periods
  SET status = 'expired', updated_at = now()
  WHERE status = 'open'
    AND concession_deadline IS NOT NULL
    AND concession_deadline < CURRENT_DATE;
  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$;

GRANT EXECUTE ON FUNCTION public.expire_vacation_periods() TO authenticated, service_role;

-- Agendar execução diária às 03:00 UTC
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'expire-vacation-periods-daily') THEN
    PERFORM cron.unschedule('expire-vacation-periods-daily');
  END IF;
  PERFORM cron.schedule(
    'expire-vacation-periods-daily',
    '0 3 * * *',
    $CRON$ SELECT public.expire_vacation_periods(); $CRON$
  );
END;
$$;

-- Executa imediatamente para marcar prazos já vencidos
SELECT public.expire_vacation_periods();
