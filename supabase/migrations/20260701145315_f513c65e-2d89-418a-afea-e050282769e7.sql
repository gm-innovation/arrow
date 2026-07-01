
-- ============================================================================
-- Fase 1 (1.1, 1.2, 1.7) — Módulo Qualidade
-- ============================================================================

-- 1.1 Responsável pelo documento
ALTER TABLE public.quality_documents
  ADD COLUMN IF NOT EXISTS responsible_user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 1.2 Cópia Controlada
ALTER TABLE public.quality_document_types
  ADD COLUMN IF NOT EXISTS default_control_mode text
    DEFAULT 'controlled'
    CHECK (default_control_mode IN ('controlled','uncontrolled'));

ALTER TABLE public.quality_documents
  ADD COLUMN IF NOT EXISTS control_mode text
    CHECK (control_mode IS NULL OR control_mode IN ('controlled','uncontrolled'));

COMMENT ON COLUMN public.quality_documents.control_mode IS
  'Cópia controlada/não controlada por documento. NULL herda de quality_document_types.default_control_mode.';

-- ============================================================================
-- 1.7 Autorização Master — reforço RLS no banco
-- Adiciona uma policy permissiva "master do SGQ pode tudo" para cada tabela,
-- somando (OR) às policies existentes sem removê-las.
-- Vale para role 'qualidade' e 'super_admin'.
-- ============================================================================

DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'quality_context_items',
    'quality_context_versions',
    'quality_interested_parties',
    'quality_interested_party_evidences',
    'quality_objectives',
    'quality_objective_parties',
    'quality_objective_risks',
    'quality_risks',
    'quality_risk_actions',
    'quality_risk_events',
    'quality_processes',
    'quality_process_activities',
    'quality_process_sipoc',
    'quality_reference_norms',
    'quality_document_norms',
    'quality_communication_plan',
    'quality_communication_log',
    'quality_awareness_events',
    'quality_awareness_attendees',
    'quality_management_reviews',
    'quality_management_review_inputs',
    'quality_management_review_outputs',
    'quality_management_review_participants',
    'quality_homologations',
    'quality_improvements_manual'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'qms_master_full_access', t);
    EXECUTE format($f$
      CREATE POLICY %I ON public.%I
        FOR ALL
        TO authenticated
        USING (public.has_role(auth.uid(), 'qualidade'::app_role) OR public.has_role(auth.uid(), 'super_admin'::app_role))
        WITH CHECK (public.has_role(auth.uid(), 'qualidade'::app_role) OR public.has_role(auth.uid(), 'super_admin'::app_role))
    $f$, 'qms_master_full_access', t);
  END LOOP;
END$$;
