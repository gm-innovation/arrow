-- R2: settings columns
ALTER TABLE public.quality_settings
  ADD COLUMN IF NOT EXISTS master_delegate_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS master_delegate_until timestamptz,
  ADD COLUMN IF NOT EXISTS central_approval_sla_hours integer NOT NULL DEFAULT 48;

-- R2: events table
CREATE TABLE IF NOT EXISTS public.quality_central_approval_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  approval_id uuid NOT NULL REFERENCES public.quality_central_approvals(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  event_type text NOT NULL CHECK (event_type IN ('requested','approved','rejected','commented','reassigned')),
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  comment text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_qcae_approval ON public.quality_central_approval_events(approval_id, created_at);
CREATE INDEX IF NOT EXISTS idx_qcae_company ON public.quality_central_approval_events(company_id);

GRANT SELECT, INSERT ON public.quality_central_approval_events TO authenticated;
GRANT ALL ON public.quality_central_approval_events TO service_role;

ALTER TABLE public.quality_central_approval_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qcae_select_company"
  ON public.quality_central_approval_events FOR SELECT TO authenticated
  USING (company_id = (SELECT p.company_id FROM public.profiles p WHERE p.id = auth.uid()));

CREATE POLICY "qcae_insert_self_company"
  ON public.quality_central_approval_events FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (SELECT p.company_id FROM public.profiles p WHERE p.id = auth.uid())
    AND (actor_user_id IS NULL OR actor_user_id = auth.uid())
  );

-- R5: policy versions
CREATE TABLE IF NOT EXISTS public.quality_policy_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  version integer NOT NULL,
  text text NOT NULL,
  published_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  published_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, version)
);
CREATE INDEX IF NOT EXISTS idx_qpv_company ON public.quality_policy_versions(company_id, version DESC);

GRANT SELECT, INSERT ON public.quality_policy_versions TO authenticated;
GRANT ALL ON public.quality_policy_versions TO service_role;

ALTER TABLE public.quality_policy_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qpv_select_company"
  ON public.quality_policy_versions FOR SELECT TO authenticated
  USING (company_id = (SELECT p.company_id FROM public.profiles p WHERE p.id = auth.uid()));

CREATE POLICY "qpv_insert_master"
  ON public.quality_policy_versions FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (SELECT p.company_id FROM public.profiles p WHERE p.id = auth.uid())
  );

-- R5: trigger to snapshot the OLD policy when a new one is published
CREATE OR REPLACE FUNCTION public.quality_snapshot_policy_on_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND COALESCE(OLD.quality_policy_text, '') <> ''
     AND COALESCE(NEW.quality_policy_version, 1) > COALESCE(OLD.quality_policy_version, 1) THEN
    INSERT INTO public.quality_policy_versions (company_id, version, text, published_by, published_at)
    VALUES (
      OLD.company_id,
      OLD.quality_policy_version,
      OLD.quality_policy_text,
      OLD.quality_master_user_id,
      COALESCE(OLD.quality_policy_published_at, now())
    )
    ON CONFLICT (company_id, version) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_quality_snapshot_policy ON public.quality_settings;
CREATE TRIGGER trg_quality_snapshot_policy
BEFORE UPDATE ON public.quality_settings
FOR EACH ROW
EXECUTE FUNCTION public.quality_snapshot_policy_on_change();