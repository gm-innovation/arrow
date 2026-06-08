
-- Campaign type flags
ALTER TABLE public.quality_satisfaction_campaigns
  ADD COLUMN IF NOT EXISTS collects_nps boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS collects_csat boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS collects_ces boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.quality_satisfaction_campaign_validate()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NOT (COALESCE(NEW.collects_nps,false) OR COALESCE(NEW.collects_csat,false) OR COALESCE(NEW.collects_ces,false)) THEN
    RAISE EXCEPTION 'Campanha deve coletar ao menos um tipo (NPS, CSAT ou CES)';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_qsc_validate ON public.quality_satisfaction_campaigns;
CREATE TRIGGER trg_qsc_validate
BEFORE INSERT OR UPDATE ON public.quality_satisfaction_campaigns
FOR EACH ROW EXECUTE FUNCTION public.quality_satisfaction_campaign_validate();

-- Response score nullability + CES
ALTER TABLE public.quality_satisfaction_responses
  ALTER COLUMN nps_score DROP NOT NULL,
  ALTER COLUMN csat_score DROP NOT NULL;

ALTER TABLE public.quality_satisfaction_responses
  ADD COLUMN IF NOT EXISTS ces_score int NULL CHECK (ces_score IS NULL OR (ces_score BETWEEN 1 AND 7));

-- Drop old trigger to recreate
DROP TRIGGER IF EXISTS trg_qsr_derive ON public.quality_satisfaction_responses;

CREATE OR REPLACE FUNCTION public.quality_satisfaction_response_derive()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.nps_score IS NOT NULL THEN
    NEW.derived_nps := CASE WHEN NEW.nps_score >= 9 THEN 'promoter' WHEN NEW.nps_score >= 7 THEN 'neutral' ELSE 'detractor' END;
  ELSE
    NEW.derived_nps := NULL;
  END IF;
  IF NEW.csat_score IS NOT NULL THEN
    NEW.derived_csat := CASE WHEN NEW.csat_score >= 4 THEN 'satisfied' WHEN NEW.csat_score = 3 THEN 'neutral' ELSE 'dissatisfied' END;
  ELSE
    NEW.derived_csat := NULL;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_qsr_derive
BEFORE INSERT OR UPDATE OF nps_score, csat_score ON public.quality_satisfaction_responses
FOR EACH ROW EXECUTE FUNCTION public.quality_satisfaction_response_derive();
