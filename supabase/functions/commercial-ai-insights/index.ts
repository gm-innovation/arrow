// Commercial/Marketing AI Insights: aggregates CRM data and asks the model for
// actionable recommendations (client recovery, recurring opportunities, upsell).
import { corsHeaders } from 'npm:@supabase/supabase-js@2/cors';
import { createClient } from 'npm:@supabase/supabase-js@2';
import { callLLM } from '../_shared/llm.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userRes, error: userErr } = await supabase.auth.getUser();
    if (userErr || !userRes?.user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', userRes.user.id)
      .maybeSingle();

    if (!profile?.company_id) {
      return new Response(JSON.stringify({ error: 'Company not found' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const companyId = profile.company_id;
    const now = new Date();
    const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 3600 * 1000).toISOString();
    const oneEightyDaysAgo = new Date(now.getTime() - 180 * 24 * 3600 * 1000).toISOString();

    // Aggregate data snapshots in parallel (bounded).
    const [ordersRes, salesRes, measRes, oppsRes, leadsRes, clientsRes] = await Promise.all([
      supabase
        .from('service_orders')
        .select('id, order_number, client_id, status, created_at, scheduled_date, clients(name)')
        .eq('company_id', companyId)
        .gte('created_at', oneEightyDaysAgo)
        .order('created_at', { ascending: false })
        .limit(200),
      supabase
        .from('crm_sales')
        .select('id, client_id, total_amount, status, created_at')
        .eq('company_id', companyId)
        .gte('created_at', oneEightyDaysAgo)
        .limit(200),
      supabase
        .from('measurements')
        .select('id, total_amount, status, category, created_at')
        .gte('created_at', oneEightyDaysAgo)
        .limit(200),
      supabase
        .from('crm_opportunities')
        .select('id, title, stage, value, client_id, created_at')
        .eq('company_id', companyId)
        .gte('created_at', oneEightyDaysAgo)
        .limit(200),
      supabase
        .from('public_site_leads')
        .select('id, name, email, type, status, created_at')
        .gte('created_at', oneEightyDaysAgo)
        .order('created_at', { ascending: false })
        .limit(100),
      supabase
        .from('clients')
        .select('id, name, created_at')
        .eq('company_id', companyId)
        .limit(500),
    ]);

    const orders = ordersRes.data || [];
    const sales = salesRes.data || [];
    const meas = measRes.data || [];
    const opps = oppsRes.data || [];
    const leads = leadsRes.data || [];
    const clients = clientsRes.data || [];

    // ---- Deterministic KPIs ----
    const totalRevenue =
      sales.reduce((s, x: any) => s + (Number(x.total_amount) || 0), 0) +
      meas.reduce((s, x: any) => s + (Number(x.total_amount) || 0), 0);

    const activeClientIds = new Set<string>();
    orders.forEach((o: any) => o.client_id && activeClientIds.add(o.client_id));
    sales.forEach((s: any) => s.client_id && activeClientIds.add(s.client_id));

    const inactiveClients = clients.filter(
      (c: any) => !activeClientIds.has(c.id),
    );

    // Clients with orders 90-180d ago but nothing in the last 90d = churn risk.
    const recentActive = new Set<string>();
    orders.forEach((o: any) => {
      if (o.created_at > ninetyDaysAgo && o.client_id) recentActive.add(o.client_id);
    });
    sales.forEach((s: any) => {
      if (s.created_at > ninetyDaysAgo && s.client_id) recentActive.add(s.client_id);
    });
    const churnRisk = Array.from(activeClientIds).filter((id) => !recentActive.has(id));

    // Recurring clients (>=2 orders in 180d).
    const orderCountByClient = new Map<string, number>();
    orders.forEach((o: any) => {
      if (!o.client_id) return;
      orderCountByClient.set(o.client_id, (orderCountByClient.get(o.client_id) || 0) + 1);
    });
    const recurringClients = Array.from(orderCountByClient.entries())
      .filter(([, c]) => c >= 2)
      .map(([id, c]) => ({ id, count: c }));

    const openOpps = opps.filter((o: any) => !['won', 'lost'].includes(o.stage));
    const openLeads = leads.filter((l: any) => !['converted', 'lost', 'archived'].includes(l.status));

    const kpis = {
      total_revenue: totalRevenue,
      orders_180d: orders.length,
      sales_180d: sales.length,
      measurements_180d: meas.length,
      total_clients: clients.length,
      active_clients_180d: activeClientIds.size,
      inactive_clients: inactiveClients.length,
      churn_risk_clients: churnRisk.length,
      recurring_clients: recurringClients.length,
      open_opportunities: openOpps.length,
      open_site_leads: openLeads.length,
    };

    // ---- Build compact context for the model ----
    const clientNameById = new Map(clients.map((c: any) => [c.id, c.name]));
    const topRecurring = recurringClients
      .sort((a, b) => b.count - a.count)
      .slice(0, 10)
      .map((r) => ({ name: clientNameById.get(r.id) || r.id, orders: r.count }));

    const topChurn = churnRisk
      .slice(0, 10)
      .map((id) => ({ name: clientNameById.get(id) || id }));

    const context = {
      kpis,
      top_recurring_clients: topRecurring,
      top_churn_risk_clients: topChurn,
      open_opportunities_sample: openOpps.slice(0, 10).map((o: any) => ({
        title: o.title,
        stage: o.stage,
        value: o.value,
      })),
      open_leads_sample: openLeads.slice(0, 10).map((l: any) => ({
        name: l.name,
        type: l.type,
        status: l.status,
      })),
    };

    const systemPrompt = `Você é um analista comercial sênior de uma empresa de serviços marítimos.
Analise os dados fornecidos e gere INSIGHTS ACIONÁVEIS em português.
Retorne SOMENTE JSON válido com o formato:
{
  "resumo_executivo": "2-3 frases",
  "recuperacao_clientes": [{"cliente":"","motivo":"","acao_sugerida":"","prioridade":"alta|media|baixa"}],
  "oportunidades_recorrencia": [{"cliente":"","padrao_observado":"","acao_sugerida":""}],
  "upsell_cross_sell": [{"segmento":"","oportunidade":"","acao_sugerida":""}],
  "alertas": [{"tipo":"","descricao":"","prioridade":"alta|media|baixa"}]
}
Use no máximo 5 itens por lista. Seja específico e cite números/nomes dos dados.`;

    const userPrompt = `Dados dos últimos 180 dias:\n${JSON.stringify(context, null, 2)}`;

    const llm = await callLLM({
      provider: 'lovable',
      model: 'google/gemini-2.5-flash',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.4,
    });

    if (!llm.ok) {
      const errText = await llm.response.text();
      if (llm.status === 429) {
        return new Response(
          JSON.stringify({ kpis, insights: null, error: 'Limite de requisições atingido. Tente novamente em instantes.' }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }
      if (llm.status === 402) {
        return new Response(
          JSON.stringify({ kpis, insights: null, error: 'Créditos de IA esgotados. Adicione créditos no workspace.' }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }
      return new Response(
        JSON.stringify({ kpis, insights: null, error: `Falha no gateway (${llm.status}): ${errText.slice(0, 300)}` }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const json = await llm.response.json();
    const content: string = json?.choices?.[0]?.message?.content ?? '';
    let insights: any = null;
    try {
      // Model may wrap in ```json fences
      const cleaned = content.replace(/```json\s*|\s*```/g, '').trim();
      insights = JSON.parse(cleaned);
    } catch {
      insights = { raw_text: content };
    }

    return new Response(
      JSON.stringify({ kpis, insights, generated_at: new Date().toISOString() }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String((err as Error).message || err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
