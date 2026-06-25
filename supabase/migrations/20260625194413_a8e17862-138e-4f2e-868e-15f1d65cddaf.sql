
-- Include 'qualidade' role in RLS policies that operate the SGQ modules.
-- Recreates each policy preserving all existing conditions and adding has_role(... 'qualidade').

-- profiles: privileged viewers
DROP POLICY IF EXISTS "Privileged roles can view company profiles" ON public.profiles;
CREATE POLICY "Privileged roles can view company profiles" ON public.profiles
FOR SELECT TO authenticated
USING (
  has_role(auth.uid(), 'super_admin'::app_role)
  OR (
    (company_id = user_company_id(auth.uid()))
    AND (
      has_role(auth.uid(), 'hr'::app_role)
      OR has_role(auth.uid(), 'admin'::app_role)
      OR has_role(auth.uid(), 'director'::app_role)
      OR has_role(auth.uid(), 'qualidade'::app_role)
    )
  )
);

-- quality_homologations
DROP POLICY IF EXISTS "Quality leaders can view company homologations" ON public.quality_homologations;
CREATE POLICY "Quality leaders can view company homologations" ON public.quality_homologations
FOR SELECT TO authenticated
USING ((company_id = user_company_id(auth.uid())) AND (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role)));

DROP POLICY IF EXISTS "Quality leaders can insert homologations" ON public.quality_homologations;
CREATE POLICY "Quality leaders can insert homologations" ON public.quality_homologations
FOR INSERT TO authenticated
WITH CHECK ((company_id = user_company_id(auth.uid())) AND (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role)));

DROP POLICY IF EXISTS "Quality leaders can update homologations" ON public.quality_homologations;
CREATE POLICY "Quality leaders can update homologations" ON public.quality_homologations
FOR UPDATE TO authenticated
USING ((company_id = user_company_id(auth.uid())) AND (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role)));

DROP POLICY IF EXISTS "Directors can delete homologations" ON public.quality_homologations;
CREATE POLICY "Directors can delete homologations" ON public.quality_homologations
FOR DELETE TO authenticated
USING ((company_id = user_company_id(auth.uid())) AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role)));

-- quality_complaints
DROP POLICY IF EXISTS "sgq read complaints" ON public.quality_complaints;
CREATE POLICY "sgq read complaints" ON public.quality_complaints
FOR SELECT TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

DROP POLICY IF EXISTS "sgq manage complaints" ON public.quality_complaints;
CREATE POLICY "sgq manage complaints" ON public.quality_complaints
FOR ALL TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
WITH CHECK (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

-- quality_satisfaction_campaigns
DROP POLICY IF EXISTS "sgq read campaigns" ON public.quality_satisfaction_campaigns;
CREATE POLICY "sgq read campaigns" ON public.quality_satisfaction_campaigns
FOR SELECT TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

DROP POLICY IF EXISTS "sgq manage campaigns" ON public.quality_satisfaction_campaigns;
CREATE POLICY "sgq manage campaigns" ON public.quality_satisfaction_campaigns
FOR ALL TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
WITH CHECK (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

-- quality_satisfaction_invites
DROP POLICY IF EXISTS "sgq read invites" ON public.quality_satisfaction_invites;
CREATE POLICY "sgq read invites" ON public.quality_satisfaction_invites
FOR SELECT TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

DROP POLICY IF EXISTS "sgq manage invites" ON public.quality_satisfaction_invites;
CREATE POLICY "sgq manage invites" ON public.quality_satisfaction_invites
FOR ALL TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
WITH CHECK (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

-- quality_satisfaction_responses
DROP POLICY IF EXISTS "sgq read responses" ON public.quality_satisfaction_responses;
CREATE POLICY "sgq read responses" ON public.quality_satisfaction_responses
FOR SELECT TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

DROP POLICY IF EXISTS "sgq manage responses" ON public.quality_satisfaction_responses;
CREATE POLICY "sgq manage responses" ON public.quality_satisfaction_responses
FOR ALL TO authenticated
USING (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
WITH CHECK (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

-- quality_management_reviews
DROP POLICY IF EXISTS "mr_insert_director" ON public.quality_management_reviews;
CREATE POLICY "mr_insert_director" ON public.quality_management_reviews
FOR INSERT TO authenticated
WITH CHECK ((company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())) AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role)));

DROP POLICY IF EXISTS "mr_update_director" ON public.quality_management_reviews;
CREATE POLICY "mr_update_director" ON public.quality_management_reviews
FOR UPDATE TO authenticated
USING ((company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())) AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role)));

DROP POLICY IF EXISTS "mr_delete_director" ON public.quality_management_reviews;
CREATE POLICY "mr_delete_director" ON public.quality_management_reviews
FOR DELETE TO authenticated
USING ((company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())) AND (status = 'draft'::quality_review_status) AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role)));

-- quality_management_review_participants
DROP POLICY IF EXISTS "mrp_insert" ON public.quality_management_review_participants;
CREATE POLICY "mrp_insert" ON public.quality_management_review_participants
FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM quality_management_reviews r
  WHERE r.id = quality_management_review_participants.review_id
    AND r.company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())
    AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
));

DROP POLICY IF EXISTS "mrp_delete" ON public.quality_management_review_participants;
CREATE POLICY "mrp_delete" ON public.quality_management_review_participants
FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM quality_management_reviews r
  WHERE r.id = quality_management_review_participants.review_id
    AND r.company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())
    AND r.status <> 'closed'::quality_review_status
    AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
));

DROP POLICY IF EXISTS "mrp_update" ON public.quality_management_review_participants;
CREATE POLICY "mrp_update" ON public.quality_management_review_participants
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM quality_management_reviews r WHERE r.id = quality_management_review_participants.review_id AND r.company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid()))
  AND (user_id = auth.uid() OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
);

-- quality_management_review_inputs
DROP POLICY IF EXISTS "mri_all" ON public.quality_management_review_inputs;
CREATE POLICY "mri_all" ON public.quality_management_review_inputs
FOR ALL TO authenticated
USING (EXISTS (
  SELECT 1 FROM quality_management_reviews r
  WHERE r.id = quality_management_review_inputs.review_id
    AND r.company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())
    AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
))
WITH CHECK (EXISTS (
  SELECT 1 FROM quality_management_reviews r
  WHERE r.id = quality_management_review_inputs.review_id
    AND r.company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())
    AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
));

-- quality_management_review_outputs
DROP POLICY IF EXISTS "mro_all" ON public.quality_management_review_outputs;
CREATE POLICY "mro_all" ON public.quality_management_review_outputs
FOR ALL TO authenticated
USING (EXISTS (
  SELECT 1 FROM quality_management_reviews r
  WHERE r.id = quality_management_review_outputs.review_id
    AND r.company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())
    AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
))
WITH CHECK (EXISTS (
  SELECT 1 FROM quality_management_reviews r
  WHERE r.id = quality_management_review_outputs.review_id
    AND r.company_id = (SELECT profiles.company_id FROM profiles WHERE profiles.id = auth.uid())
    AND (has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role))
));

-- quality_improvements_manual
DROP POLICY IF EXISTS "qim_select_own_or_privileged" ON public.quality_improvements_manual;
CREATE POLICY "qim_select_own_or_privileged" ON public.quality_improvements_manual
FOR SELECT TO authenticated
USING (submitted_by = auth.uid() OR has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

DROP POLICY IF EXISTS "qim_update_privileged" ON public.quality_improvements_manual;
CREATE POLICY "qim_update_privileged" ON public.quality_improvements_manual
FOR UPDATE TO authenticated
USING (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));

DROP POLICY IF EXISTS "qim_delete_privileged" ON public.quality_improvements_manual;
CREATE POLICY "qim_delete_privileged" ON public.quality_improvements_manual
FOR DELETE TO authenticated
USING (has_role(auth.uid(), 'coordinator'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'qualidade'::app_role));
