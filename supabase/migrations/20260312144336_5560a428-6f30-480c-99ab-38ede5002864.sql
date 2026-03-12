
-- University Courses
CREATE TABLE public.university_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  category text DEFAULT 'geral',
  thumbnail_url text,
  duration_minutes integer DEFAULT 0,
  is_published boolean DEFAULT false,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- University Modules
CREATE TABLE public.university_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL REFERENCES public.university_courses(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  content_type text NOT NULL DEFAULT 'text', -- video, pdf, text
  content_url text,
  sort_order integer DEFAULT 0,
  duration_minutes integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- University Trails
CREATE TABLE public.university_trails (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  is_published boolean DEFAULT false,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now()
);

-- Trail <-> Course M:N
CREATE TABLE public.university_trail_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trail_id uuid NOT NULL REFERENCES public.university_trails(id) ON DELETE CASCADE,
  course_id uuid NOT NULL REFERENCES public.university_courses(id) ON DELETE CASCADE,
  sort_order integer DEFAULT 0,
  UNIQUE(trail_id, course_id)
);

-- Enrollments
CREATE TABLE public.university_enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  course_id uuid NOT NULL REFERENCES public.university_courses(id) ON DELETE CASCADE,
  is_mandatory boolean DEFAULT false,
  assigned_by uuid REFERENCES public.profiles(id),
  status text DEFAULT 'not_started', -- not_started, in_progress, completed
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, course_id)
);

-- Progress per module
CREATE TABLE public.university_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid NOT NULL REFERENCES public.university_enrollments(id) ON DELETE CASCADE,
  module_id uuid NOT NULL REFERENCES public.university_modules(id) ON DELETE CASCADE,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  UNIQUE(enrollment_id, module_id)
);

-- Certificates
CREATE TABLE public.university_certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid NOT NULL REFERENCES public.university_enrollments(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  course_id uuid NOT NULL REFERENCES public.university_courses(id) ON DELETE CASCADE,
  issued_at timestamptz DEFAULT now(),
  certificate_code text NOT NULL DEFAULT encode(gen_random_bytes(8), 'hex')
);

-- Enable RLS on all tables
ALTER TABLE public.university_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_trails ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_trail_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_certificates ENABLE ROW LEVEL SECURITY;

-- Helper: check if user is HR in their company
CREATE OR REPLACE FUNCTION public.is_hr_in_company(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM user_roles ur
    WHERE ur.user_id = _user_id
      AND ur.role = 'hr'
  )
$$;

-- Helper: get user's company_id
CREATE OR REPLACE FUNCTION public.user_company_id(_user_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id FROM profiles WHERE id = _user_id
$$;

-- COURSES RLS
CREATE POLICY "Users can view published courses in their company" ON public.university_courses
  FOR SELECT TO authenticated
  USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "HR can insert courses" ON public.university_courses
  FOR INSERT TO authenticated
  WITH CHECK (company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid()));

CREATE POLICY "HR can update courses" ON public.university_courses
  FOR UPDATE TO authenticated
  USING (company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid()));

CREATE POLICY "HR can delete courses" ON public.university_courses
  FOR DELETE TO authenticated
  USING (company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid()));

-- MODULES RLS
CREATE POLICY "Users can view modules of their company courses" ON public.university_modules
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM university_courses c WHERE c.id = course_id AND c.company_id = user_company_id(auth.uid())));

CREATE POLICY "HR can insert modules" ON public.university_modules
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM university_courses c WHERE c.id = course_id AND c.company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid())));

CREATE POLICY "HR can update modules" ON public.university_modules
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM university_courses c WHERE c.id = course_id AND c.company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid())));

CREATE POLICY "HR can delete modules" ON public.university_modules
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM university_courses c WHERE c.id = course_id AND c.company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid())));

-- TRAILS RLS
CREATE POLICY "Users can view trails in their company" ON public.university_trails
  FOR SELECT TO authenticated
  USING (company_id = user_company_id(auth.uid()));

CREATE POLICY "HR can manage trails" ON public.university_trails
  FOR ALL TO authenticated
  USING (company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid()));

-- TRAIL_COURSES RLS
CREATE POLICY "Users can view trail courses" ON public.university_trail_courses
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM university_trails t WHERE t.id = trail_id AND t.company_id = user_company_id(auth.uid())));

CREATE POLICY "HR can manage trail courses" ON public.university_trail_courses
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM university_trails t WHERE t.id = trail_id AND t.company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid())));

-- ENROLLMENTS RLS
CREATE POLICY "Users can view own enrollments" ON public.university_enrollments
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR (company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid())));

CREATE POLICY "HR can insert enrollments" ON public.university_enrollments
  FOR INSERT TO authenticated
  WITH CHECK (company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid()));

CREATE POLICY "HR can update enrollments" ON public.university_enrollments
  FOR UPDATE TO authenticated
  USING (company_id = user_company_id(auth.uid()) AND (user_id = auth.uid() OR is_hr_in_company(auth.uid())));

CREATE POLICY "HR can delete enrollments" ON public.university_enrollments
  FOR DELETE TO authenticated
  USING (company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid()));

-- PROGRESS RLS
CREATE POLICY "Users can view own progress" ON public.university_progress
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM university_enrollments e WHERE e.id = enrollment_id AND (e.user_id = auth.uid() OR (e.company_id = user_company_id(auth.uid()) AND is_hr_in_company(auth.uid())))));

CREATE POLICY "Users can upsert own progress" ON public.university_progress
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM university_enrollments e WHERE e.id = enrollment_id AND e.user_id = auth.uid()));

CREATE POLICY "Users can update own progress" ON public.university_progress
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM university_enrollments e WHERE e.id = enrollment_id AND e.user_id = auth.uid()));

-- CERTIFICATES RLS
CREATE POLICY "Users can view own certificates" ON public.university_certificates
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR is_hr_in_company(auth.uid()));

CREATE POLICY "System can insert certificates" ON public.university_certificates
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() OR is_hr_in_company(auth.uid()));

-- Storage bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('university-content', 'university-content', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Authenticated users can view university content" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'university-content');

CREATE POLICY "HR can upload university content" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'university-content' AND is_hr_in_company(auth.uid()));

CREATE POLICY "HR can update university content" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'university-content' AND is_hr_in_company(auth.uid()));

CREATE POLICY "HR can delete university content" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'university-content' AND is_hr_in_company(auth.uid()));
