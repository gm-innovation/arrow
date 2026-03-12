CREATE TABLE public.university_reward_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  reward_type text NOT NULL,
  xp_value integer NOT NULL DEFAULT 15,
  icon text NOT NULL DEFAULT '📚',
  badge_title_template text NOT NULL DEFAULT 'Curso: {name}',
  post_to_feed boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (company_id, reward_type)
);

ALTER TABLE public.university_reward_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own company settings" ON public.university_reward_settings
  FOR SELECT TO authenticated
  USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "HR/Director can manage settings" ON public.university_reward_settings
  FOR ALL TO authenticated
  USING (public.is_hr_or_director_in_company(auth.uid(), company_id))
  WITH CHECK (public.is_hr_or_director_in_company(auth.uid(), company_id));