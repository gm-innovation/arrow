-- Create forecast_history table to store predictions
CREATE TABLE IF NOT EXISTS public.forecast_history (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  forecast_month DATE NOT NULL,
  predicted_orders INTEGER NOT NULL,
  predicted_completed INTEGER NOT NULL,
  confidence TEXT NOT NULL CHECK (confidence IN ('alta', 'média', 'baixa')),
  actual_orders INTEGER,
  actual_completed INTEGER,
  coordinator_id UUID REFERENCES public.profiles(id),
  client_id UUID REFERENCES public.clients(id),
  metadata JSONB
);

-- Enable RLS
ALTER TABLE public.forecast_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Managers can view forecasts in their company"
  ON public.forecast_history
  FOR SELECT
  USING (
    company_id = user_company_id(auth.uid())
    AND has_role(auth.uid(), 'manager'::app_role)
  );

CREATE POLICY "Admins can view forecasts in their company"
  ON public.forecast_history
  FOR SELECT
  USING (
    company_id = user_company_id(auth.uid())
    AND has_role(auth.uid(), 'admin'::app_role)
  );

CREATE POLICY "Managers can create forecasts"
  ON public.forecast_history
  FOR INSERT
  WITH CHECK (
    company_id = user_company_id(auth.uid())
    AND has_role(auth.uid(), 'manager'::app_role)
  );

CREATE POLICY "Super admins can manage all forecasts"
  ON public.forecast_history
  FOR ALL
  USING (has_role(auth.uid(), 'super_admin'::app_role));

-- Create index for faster queries
CREATE INDEX idx_forecast_history_company_month 
  ON public.forecast_history(company_id, forecast_month);

CREATE INDEX idx_forecast_history_created_at 
  ON public.forecast_history(created_at DESC);

-- Create function to update actual values
CREATE OR REPLACE FUNCTION public.update_forecast_actuals()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  forecast_record RECORD;
  month_start DATE;
  month_end DATE;
BEGIN
  -- Update forecasts for months that have passed
  FOR forecast_record IN 
    SELECT 
      fh.id,
      fh.forecast_month,
      fh.company_id,
      fh.coordinator_id,
      fh.client_id
    FROM forecast_history fh
    WHERE fh.forecast_month < DATE_TRUNC('month', CURRENT_DATE)
      AND fh.actual_orders IS NULL
  LOOP
    month_start := DATE_TRUNC('month', forecast_record.forecast_month);
    month_end := month_start + INTERVAL '1 month' - INTERVAL '1 day';
    
    -- Calculate actual orders for that month
    UPDATE forecast_history fh
    SET 
      actual_orders = (
        SELECT COUNT(*)
        FROM service_orders so
        WHERE so.company_id = forecast_record.company_id
          AND DATE(so.created_at) >= month_start
          AND DATE(so.created_at) <= month_end
          AND (forecast_record.coordinator_id IS NULL OR so.created_by = forecast_record.coordinator_id)
          AND (forecast_record.client_id IS NULL OR so.client_id = forecast_record.client_id)
      ),
      actual_completed = (
        SELECT COUNT(*)
        FROM service_orders so
        WHERE so.company_id = forecast_record.company_id
          AND DATE(so.created_at) >= month_start
          AND DATE(so.created_at) <= month_end
          AND so.status = 'completed'
          AND (forecast_record.coordinator_id IS NULL OR so.created_by = forecast_record.coordinator_id)
          AND (forecast_record.client_id IS NULL OR so.client_id = forecast_record.client_id)
      )
    WHERE fh.id = forecast_record.id;
  END LOOP;
END;
$$;
