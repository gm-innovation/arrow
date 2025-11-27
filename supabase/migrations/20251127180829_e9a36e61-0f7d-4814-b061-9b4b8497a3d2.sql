-- Add description field to photos in existing task_reports
UPDATE task_reports
SET report_data = jsonb_set(
  report_data,
  ARRAY[(SELECT jsonb_object_keys(report_data) LIMIT 1), 'photos'],
  (
    SELECT jsonb_agg(
      CASE 
        WHEN photo ? 'description' THEN photo
        ELSE photo || '{"description": ""}'::jsonb
      END
    )
    FROM jsonb_array_elements(
      report_data->(SELECT jsonb_object_keys(report_data) LIMIT 1)->'photos'
    ) AS photo
  )
)
WHERE report_data IS NOT NULL
  AND (SELECT jsonb_object_keys(report_data) LIMIT 1) IS NOT NULL
  AND report_data->(SELECT jsonb_object_keys(report_data) LIMIT 1)->'photos' IS NOT NULL;