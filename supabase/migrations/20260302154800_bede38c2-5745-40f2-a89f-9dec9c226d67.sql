
-- Add birth_date and hire_date to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birth_date date;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS hire_date date;

-- Create corp_groups table
CREATE TABLE public.corp_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  description text,
  group_type text NOT NULL DEFAULT 'custom' CHECK (group_type IN ('role_based', 'custom')),
  role_slug text,
  avatar_url text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create corp_group_members table
CREATE TABLE public.corp_group_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES public.corp_groups(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(group_id, user_id)
);

-- Enable RLS
ALTER TABLE public.corp_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_group_members ENABLE ROW LEVEL SECURITY;

-- RLS for corp_groups: read for same company authenticated users
CREATE POLICY "Users can view groups in their company"
  ON public.corp_groups FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- Anyone authenticated can create custom groups
CREATE POLICY "Users can create custom groups"
  ON public.corp_groups FOR INSERT TO authenticated
  WITH CHECK (
    group_type = 'custom'
    AND company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())
    AND created_by = auth.uid()
  );

-- Creator or admin can update groups
CREATE POLICY "Creator can update their groups"
  ON public.corp_groups FOR UPDATE TO authenticated
  USING (created_by = auth.uid());

-- Creator or admin can delete groups
CREATE POLICY "Creator can delete their groups"
  ON public.corp_groups FOR DELETE TO authenticated
  USING (created_by = auth.uid() AND group_type = 'custom');

-- RLS for corp_group_members: read for same company
CREATE POLICY "Users can view group members"
  ON public.corp_group_members FOR SELECT TO authenticated
  USING (group_id IN (
    SELECT id FROM public.corp_groups WHERE company_id IN (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
  ));

-- Users can join custom groups
CREATE POLICY "Users can join groups"
  ON public.corp_group_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can leave groups
CREATE POLICY "Users can leave groups"
  ON public.corp_group_members FOR DELETE TO authenticated
  USING (user_id = auth.uid());
