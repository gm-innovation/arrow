
-- Add status and closed_at to corp_feed_polls
ALTER TABLE public.corp_feed_polls ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active';
ALTER TABLE public.corp_feed_polls ADD COLUMN IF NOT EXISTS closed_at timestamptz;

-- Create corp_badges table
CREATE TABLE public.corp_badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_type text NOT NULL,
  title text NOT NULL,
  description text,
  icon text DEFAULT '🏆',
  awarded_at timestamptz NOT NULL DEFAULT now(),
  awarded_by uuid REFERENCES public.profiles(id)
);

ALTER TABLE public.corp_badges ENABLE ROW LEVEL SECURITY;

-- Everyone in the same company can read badges
CREATE POLICY "Users can view badges in their company"
ON public.corp_badges FOR SELECT TO authenticated
USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- Admin/HR can insert badges
CREATE POLICY "Admin/HR can insert badges"
ON public.corp_badges FOR INSERT TO authenticated
WITH CHECK (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role IN ('admin', 'hr', 'super_admin')
  )
);

-- Admin/HR can delete badges
CREATE POLICY "Admin/HR can delete badges"
ON public.corp_badges FOR DELETE TO authenticated
USING (
  company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role IN ('admin', 'hr', 'super_admin')
  )
);
