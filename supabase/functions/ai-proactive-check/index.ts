import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface AlertConfig {
  type: string;
  title: string;
  checkFn: (supabase: any, companyId: string, userId: string) => Promise<AlertResult[]>;
}

interface AlertResult {
  userId: string;
  title: string;
  message: string;
  referenceData?: Record<string, unknown>;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    const lovableApiKey = Deno.env.get('LOVABLE_API_KEY');

    console.log('Starting proactive check...');

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
        .eq('role', 'admin')
        .in('user_id', coordinators?.map(c => c.id) || []);

      const coordinatorIds = userRoles?.map(r => r.user_id) || [];

      // Check 1: Overdue Service Orders
      const { data: overdueOrders } = await supabase
        .from('service_orders')
        .select('id, order_number, scheduled_date, client:client_id(name)')
        .eq('company_id', company.id)
        .in('status', ['pending', 'in_progress'])
        .lt('scheduled_date', new Date().toISOString().split('T')[0])
        .limit(10);

      if (overdueOrders && overdueOrders.length > 0) {
        for (const coordId of coordinatorIds) {
          // Check if alert already exists for this user today
          const today = new Date().toISOString().split('T')[0];
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
              message: `Você tem ${overdueOrders.length} OS(s) atrasada(s). A mais antiga é a OS #${overdueOrders[0].order_number} do cliente ${overdueOrders[0].client?.name || 'N/A'}.`,
              reference_data: { order_ids: overdueOrders.map(o => o.id) }
            });
          }
        }
      }

      // Check 2: Idle Technicians (no tasks in 3+ days)
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

      const { data: technicians } = await supabase
        .from('technicians')
        .select(`
          id,
          active,
          profiles:user_id(full_name)
        `)
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
              const today = new Date().toISOString().split('T')[0];
              const { data: existingAlert } = await supabase
                .from('ai_proactive_alerts')
                .select('id')
                .eq('user_id', coordId)
                .eq('alert_type', 'idle_technician')
                .eq('reference_data->technician_id', tech.id)
                .gte('created_at', `${today}T00:00:00`)
                .single();

              if (!existingAlert) {
                alerts.push({
                  user_id: coordId,
                  company_id: company.id,
                  alert_type: 'idle_technician',
                  title: 'Técnico Sem Atividade',
                  message: `O técnico ${tech.profiles?.full_name || 'N/A'} está sem tarefas atribuídas há mais de 3 dias.`,
                  reference_data: { technician_id: tech.id }
                });
              }
            }
          }
        }
      }

      // Check 3: Expiring Certificates (within 30 days)
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

      const { data: expiringDocs } = await supabase
        .from('technician_documents')
        .select(`
          id,
          certificate_name,
          expiry_date,
          technician:technician_id(
            id,
            user_id,
            profiles:user_id(full_name)
          )
        `)
        .not('expiry_date', 'is', null)
        .lte('expiry_date', thirtyDaysFromNow.toISOString().split('T')[0])
        .gte('expiry_date', new Date().toISOString().split('T')[0]);

      if (expiringDocs) {
        for (const doc of expiringDocs) {
          const techUserId = doc.technician?.user_id;
          if (techUserId) {
            const today = new Date().toISOString().split('T')[0];
            const { data: existingAlert } = await supabase
              .from('ai_proactive_alerts')
              .select('id')
              .eq('user_id', techUserId)
              .eq('alert_type', 'expiring_certificate')
              .eq('reference_data->document_id', doc.id)
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

      // Check 4: High volume from same client (5+ OS in last 7 days)
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
              acc[order.client_id] = { count: 0, name: order.client?.name || 'N/A' };
            }
            acc[order.client_id].count++;
          }
          return acc;
        }, {});

        for (const [clientId, data] of Object.entries(clientCounts)) {
          if (data.count >= 5) {
            // Get managers
            const { data: managers } = await supabase
              .from('user_roles')
              .select('user_id')
              .eq('role', 'manager');

            const managerIds = managers?.map(m => m.user_id) || [];

            for (const managerId of managerIds) {
              // Check if manager belongs to this company
              const { data: profile } = await supabase
                .from('profiles')
                .select('company_id')
                .eq('id', managerId)
                .single();

              if (profile?.company_id === company.id) {
                const today = new Date().toISOString().split('T')[0];
                const { data: existingAlert } = await supabase
                  .from('ai_proactive_alerts')
                  .select('id')
                  .eq('user_id', managerId)
                  .eq('alert_type', 'high_client_demand')
                  .eq('reference_data->client_id', clientId)
                  .gte('created_at', `${today}T00:00:00`)
                  .single();

                if (!existingAlert) {
                  alerts.push({
                    user_id: managerId,
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

    console.log(`Proactive check completed. Created ${alerts.length} alerts.`);

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
