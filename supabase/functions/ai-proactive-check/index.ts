import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    console.log('Starting enhanced proactive check...');

    // Get all companies
    const { data: companies, error: companiesError } = await supabase
      .from('companies')
      .select('id, name');

    if (companiesError) {
      throw new Error(`Failed to fetch companies: ${companiesError.message}`);
    }

    const alerts: Array<{
      user_id: string;
      company_id: string;
      alert_type: string;
      title: string;
      message: string;
      reference_data: Record<string, unknown> | null;
    }> = [];

    for (const company of companies || []) {
      // Get coordinators (admins) for this company
      const { data: coordinators } = await supabase
        .from('profiles')
        .select('id')
        .eq('company_id', company.id);

      const { data: userRoles } = await supabase
        .from('user_roles')
        .select('user_id')
        .eq('role', 'coordinator')
        .in('user_id', coordinators?.map(c => c.id) || []);

      const coordinatorIds = userRoles?.map(r => r.user_id) || [];
      const today = new Date().toISOString().split('T')[0];

      // ==========================================
      // CHECK 1: Overdue Service Orders
      // ==========================================
      const { data: overdueOrders } = await supabase
        .from('service_orders')
        .select('id, order_number, scheduled_date, client:client_id(name)')
        .eq('company_id', company.id)
        .in('status', ['pending', 'in_progress'])
        .lt('scheduled_date', today)
        .limit(10);

      if (overdueOrders && overdueOrders.length > 0) {
        for (const coordId of coordinatorIds) {
          const { data: existingAlert } = await supabase
            .from('ai_proactive_alerts')
            .select('id')
            .eq('user_id', coordId)
            .eq('alert_type', 'overdue_orders')
            .gte('created_at', `${today}T00:00:00`)
            .single();

          if (!existingAlert) {
            alerts.push({
              user_id: coordId,
              company_id: company.id,
              alert_type: 'overdue_orders',
              title: 'Ordens de Serviço Atrasadas',
              message: `Você tem ${overdueOrders.length} OS(s) atrasada(s). A mais antiga é a OS #${overdueOrders[0].order_number} do cliente ${(overdueOrders[0].client as any)?.name || 'N/A'}.`,
              reference_data: { order_ids: overdueOrders.map(o => o.id) }
            });
          }
        }
      }

      // ==========================================
      // CHECK 2: Idle Technicians (no tasks in 3+ days)
      // ==========================================
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

      const { data: technicians } = await supabase
        .from('technicians')
        .select(`id, active, profiles:user_id(full_name)`)
        .eq('company_id', company.id)
        .eq('active', true);

      if (technicians) {
        for (const tech of technicians) {
          const { data: recentTasks } = await supabase
            .from('tasks')
            .select('id')
            .eq('assigned_to', tech.id)
            .gte('created_at', threeDaysAgo.toISOString())
            .limit(1);

          if (!recentTasks || recentTasks.length === 0) {
            for (const coordId of coordinatorIds) {
              const { data: existingAlert } = await supabase
                .from('ai_proactive_alerts')
                .select('id')
                .eq('user_id', coordId)
                .eq('alert_type', 'idle_technician')
                .gte('created_at', `${today}T00:00:00`)
                .single();

              if (!existingAlert) {
                alerts.push({
                  user_id: coordId,
                  company_id: company.id,
                  alert_type: 'idle_technician',
                  title: 'Técnico Sem Atividade',
                  message: `O técnico ${(tech.profiles as any)?.full_name || 'N/A'} está sem tarefas atribuídas há mais de 3 dias.`,
                  reference_data: { technician_id: tech.id }
                });
              }
            }
          }
        }
      }

      // ==========================================
      // CHECK 3: Expiring Certificates (within 30 days)
      // ==========================================
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

      const { data: expiringDocs } = await supabase
        .from('technician_documents')
        .select(`
          id, certificate_name, expiry_date,
          technician:technician_id(id, user_id, profiles:user_id(full_name))
        `)
        .not('expiry_date', 'is', null)
        .lte('expiry_date', thirtyDaysFromNow.toISOString().split('T')[0])
        .gte('expiry_date', today);

      if (expiringDocs) {
        for (const doc of expiringDocs) {
          const techUserId = (doc.technician as any)?.user_id;
          if (techUserId) {
            const { data: existingAlert } = await supabase
              .from('ai_proactive_alerts')
              .select('id')
              .eq('user_id', techUserId)
              .eq('alert_type', 'expiring_certificate')
              .gte('created_at', `${today}T00:00:00`)
              .single();

            if (!existingAlert) {
              const daysLeft = Math.ceil(
                (new Date(doc.expiry_date!).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24)
              );
              
              alerts.push({
                user_id: techUserId,
                company_id: company.id,
                alert_type: 'expiring_certificate',
                title: 'Certificado Expirando',
                message: `Seu certificado "${doc.certificate_name || 'N/A'}" expira em ${daysLeft} dias. Providencie a renovação.`,
                reference_data: { document_id: doc.id, expiry_date: doc.expiry_date }
              });
            }
          }
        }
      }

      // ==========================================
      // CHECK 4: High volume from same client (5+ OS in last 7 days)
      // ==========================================
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const { data: clientOrders } = await supabase
        .from('service_orders')
        .select('client_id, client:client_id(name)')
        .eq('company_id', company.id)
        .gte('created_at', sevenDaysAgo.toISOString());

      if (clientOrders) {
        const clientCounts = clientOrders.reduce((acc: Record<string, { count: number; name: string }>, order) => {
          if (order.client_id) {
            if (!acc[order.client_id]) {
              acc[order.client_id] = { count: 0, name: (order.client as any)?.name || 'N/A' };
            }
            acc[order.client_id].count++;
          }
          return acc;
        }, {});

        for (const [clientId, data] of Object.entries(clientCounts)) {
          if (data.count >= 5) {
            for (const coordId of coordinatorIds) {
              const { data: existingAlert } = await supabase
                .from('ai_proactive_alerts')
                .select('id')
                .eq('user_id', coordId)
                .eq('alert_type', 'high_client_demand')
                .gte('created_at', `${today}T00:00:00`)
                .single();

              if (!existingAlert) {
                alerts.push({
                  user_id: coordId,
                  company_id: company.id,
                  alert_type: 'high_client_demand',
                  title: 'Alta Demanda de Cliente',
                  message: `O cliente "${data.name}" abriu ${data.count} OS nos últimos 7 dias. Considere alocar mais recursos.`,
                  reference_data: { client_id: clientId, order_count: data.count }
                });
              }
            }
          }
        }
      }

      // ==========================================
      // CHECK 5: Recurrent Issues Detection (NEW)
      // ==========================================
      const { data: completedReports } = await supabase
        .from('task_reports')
        .select(`
          id, report_data, task_uuid,
          task:task_uuid(
            service_order:service_order_id(
              vessel_id, client_id, company_id
            )
          )
        `)
        .eq('status', 'approved')
        .gte('created_at', sevenDaysAgo.toISOString());

      if (completedReports) {
        // Group by vessel and analyze issues
        const vesselIssues: Record<string, { count: number; issues: string[]; vesselId: string }> = {};
        
        for (const report of completedReports) {
          const vesselId = (report.task as any)?.service_order?.vessel_id;
          const reportData = report.report_data as any;
          const issue = reportData?.reportedIssue || reportData?.executedWork;
          
          if (vesselId && issue) {
            if (!vesselIssues[vesselId]) {
              vesselIssues[vesselId] = { count: 0, issues: [], vesselId };
            }
            vesselIssues[vesselId].count++;
            vesselIssues[vesselId].issues.push(issue);
          }
        }

        // Check for patterns (3+ similar issues on same vessel)
        for (const [vesselId, data] of Object.entries(vesselIssues)) {
          if (data.count >= 3) {
            // Get vessel info
            const { data: vessel } = await supabase
              .from('vessels')
              .select('name, client:client_id(name)')
              .eq('id', vesselId)
              .single();

            if (vessel) {
              // Record pattern
              const { data: existingPattern } = await supabase
                .from('ai_failure_patterns')
                .select('id, occurrences')
                .eq('vessel_id', vesselId)
                .eq('pattern_type', 'recurrent_issue')
                .single();

              if (existingPattern) {
                await supabase
                  .from('ai_failure_patterns')
                  .update({
                    occurrences: existingPattern.occurrences + 1,
                    last_occurrence: new Date().toISOString(),
                  })
                  .eq('id', existingPattern.id);
              } else {
                await supabase
                  .from('ai_failure_patterns')
                  .insert({
                    company_id: company.id,
                    vessel_id: vesselId,
                    pattern_type: 'recurrent_issue',
                    description: `Embarcação "${vessel.name}" apresentou ${data.count} problemas nos últimos 7 dias`,
                    suggested_action: 'Considere realizar uma inspeção preventiva completa',
                    confidence_score: Math.min(0.95, 0.5 + (data.count * 0.1)),
                  });
              }

              // Alert coordinators
              for (const coordId of coordinatorIds) {
                const { data: existingAlert } = await supabase
                  .from('ai_proactive_alerts')
                  .select('id')
                  .eq('user_id', coordId)
                  .eq('alert_type', 'recurrent_issue')
                  .gte('created_at', `${today}T00:00:00`)
                  .single();

                if (!existingAlert) {
                  alerts.push({
                    user_id: coordId,
                    company_id: company.id,
                    alert_type: 'recurrent_issue',
                    title: 'Padrão de Problemas Detectado',
                    message: `A embarcação "${vessel.name}" do cliente "${(vessel.client as any)?.name}" apresentou ${data.count} ocorrências nos últimos 7 dias. Recomendamos uma inspeção preventiva.`,
                    reference_data: { vessel_id: vesselId, issue_count: data.count }
                  });
                }
              }
            }
          }
        }
      }

      // ==========================================
      // CHECK 6: Task Time Estimates Update (NEW)
      // ==========================================
      const { data: completedTasks } = await supabase
        .from('tasks')
        .select(`
          id, task_type_id, created_at, completed_at,
          service_order:service_order_id(vessel:vessel_id(vessel_type))
        `)
        .eq('status', 'completed')
        .not('completed_at', 'is', null)
        .gte('completed_at', sevenDaysAgo.toISOString());

      if (completedTasks) {
        // Group by task type and calculate averages
        const taskTypeDurations: Record<string, { durations: number[]; vesselType: string | null }> = {};

        for (const task of completedTasks) {
          if (task.task_type_id && task.completed_at && task.created_at) {
            const duration = Math.round(
              (new Date(task.completed_at).getTime() - new Date(task.created_at).getTime()) / (1000 * 60)
            );

            if (duration > 0 && duration < 10080) { // Less than 1 week
              if (!taskTypeDurations[task.task_type_id]) {
                taskTypeDurations[task.task_type_id] = { durations: [], vesselType: null };
              }
              taskTypeDurations[task.task_type_id].durations.push(duration);
              taskTypeDurations[task.task_type_id].vesselType = 
                (task.service_order as any)?.vessel?.vessel_type || null;
            }
          }
        }

        // Update estimates
        for (const [taskTypeId, data] of Object.entries(taskTypeDurations)) {
          if (data.durations.length >= 3) {
            const sorted = data.durations.sort((a, b) => a - b);
            const avg = Math.round(sorted.reduce((a, b) => a + b, 0) / sorted.length);
            const min = sorted[0];
            const max = sorted[sorted.length - 1];

            const { data: existing } = await supabase
              .from('task_time_estimates')
              .select('id')
              .eq('company_id', company.id)
              .eq('task_type_id', taskTypeId)
              .single();

            if (existing) {
              await supabase
                .from('task_time_estimates')
                .update({
                  average_duration_minutes: avg,
                  min_duration_minutes: min,
                  max_duration_minutes: max,
                  sample_count: data.durations.length,
                  last_updated: new Date().toISOString(),
                })
                .eq('id', existing.id);
            } else {
              await supabase
                .from('task_time_estimates')
                .insert({
                  company_id: company.id,
                  task_type_id: taskTypeId,
                  vessel_type: data.vesselType,
                  average_duration_minutes: avg,
                  min_duration_minutes: min,
                  max_duration_minutes: max,
                  sample_count: data.durations.length,
                });
            }
          }
        }
      }

      // ==========================================
      // CHECK 7: Predictive Maintenance Alert (NEW)
      // ==========================================
      const { data: patterns } = await supabase
        .from('ai_failure_patterns')
        .select('*')
        .eq('company_id', company.id)
        .gte('occurrences', 3);

      if (patterns) {
        for (const pattern of patterns) {
          // Check if last occurrence was recent
          if (pattern.last_occurrence) {
            const lastOccurrence = new Date(pattern.last_occurrence);
            const daysSince = Math.floor(
              (Date.now() - lastOccurrence.getTime()) / (1000 * 60 * 60 * 24)
            );

            if (daysSince < 14 && pattern.confidence_score && pattern.confidence_score > 0.7) {
              for (const coordId of coordinatorIds) {
                const { data: existingAlert } = await supabase
                  .from('ai_proactive_alerts')
                  .select('id')
                  .eq('user_id', coordId)
                  .eq('alert_type', 'predictive_maintenance')
                  .gte('created_at', `${today}T00:00:00`)
                  .single();

                if (!existingAlert) {
                  alerts.push({
                    user_id: coordId,
                    company_id: company.id,
                    alert_type: 'predictive_maintenance',
                    title: 'Manutenção Preventiva Sugerida',
                    message: pattern.suggested_action || 
                      `Baseado em ${pattern.occurrences} ocorrências, recomendamos uma verificação preventiva.`,
                    reference_data: { pattern_id: pattern.id, confidence: pattern.confidence_score }
                  });
                }
              }
            }
          }
        }
      }
    }

    // Insert all alerts
    if (alerts.length > 0) {
      const { error: insertError } = await supabase
        .from('ai_proactive_alerts')
        .insert(alerts);

      if (insertError) {
        console.error('Error inserting alerts:', insertError);
      }
    }

    console.log(`Enhanced proactive check completed. Created ${alerts.length} alerts.`);

    return new Response(JSON.stringify({ 
      success: true, 
      alertsCreated: alerts.length 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Proactive check error:', error);
    return new Response(JSON.stringify({ 
      error: error instanceof Error ? error.message : 'Unknown error' 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
