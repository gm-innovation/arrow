import "https://deno.land/x/xhr@0.1.0/mod.ts";
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
    const { message, userRole, context } = await req.json();
    
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const lovableApiKey = Deno.env.get('LOVABLE_API_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    let contextData: any = {};
    let systemPrompt = '';
    
    // Build context based on user role
    if (userRole === 'technician') {
      systemPrompt = buildTechnicianSystemPrompt();
      
      // Search for similar reports if the message seems like a technical question
      if (message.length > 10) {
        const similarReports = await searchSimilarReports(supabase, message, context?.companyId);
        contextData.similarReports = similarReports;
        
        // Get technicians who solved similar problems
        if (similarReports.length > 0) {
          const technicianIds = [...new Set(similarReports.map((r: any) => r.technician_id).filter(Boolean))];
          if (technicianIds.length > 0) {
            const { data: technicians } = await supabase
              .from('technicians')
              .select('id, user_id, profiles:user_id(full_name, phone)')
              .in('id', technicianIds);
            contextData.experiencedTechnicians = technicians;
          }
        }
      }
      
      // Get task type info if context has task_type_id
      if (context?.taskTypeId) {
        const { data: taskType } = await supabase
          .from('task_types')
          .select('name, description, tools, steps')
          .eq('id', context.taskTypeId)
          .single();
        contextData.taskType = taskType;
      }
    } else if (userRole === 'admin') {
      systemPrompt = buildCoordinatorSystemPrompt();
      
      // Get productivity insights
      if (context?.companyId) {
        const { data: recentOrders } = await supabase
          .from('service_orders')
          .select('id, status, created_at, scheduled_date')
          .eq('company_id', context.companyId)
          .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
          .order('created_at', { ascending: false })
          .limit(50);
        contextData.recentOrders = recentOrders;
        
        // Get technician availability
        const { data: technicians } = await supabase
          .from('technicians')
          .select('id, active, profiles:user_id(full_name)')
          .eq('company_id', context.companyId)
          .eq('active', true);
        contextData.availableTechnicians = technicians;
      }
    } else if (userRole === 'manager') {
      systemPrompt = buildManagerSystemPrompt();
      
      // Get company-wide metrics
      if (context?.companyId) {
        const { data: metrics } = await supabase
          .from('service_orders')
          .select('status, created_by')
          .eq('company_id', context.companyId)
          .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());
        contextData.companyMetrics = metrics;
      }
    }
    
    // Build the full prompt with context
    const fullPrompt = buildPromptWithContext(message, contextData, userRole);
    
    // Call Lovable AI
    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${lovableApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: fullPrompt }
        ],
        stream: true,
      }),
    });

    if (!response.ok) {
      if (response.status === 429) {
        return new Response(JSON.stringify({ error: "Limite de requisições excedido. Tente novamente em alguns segundos." }), {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (response.status === 402) {
        return new Response(JSON.stringify({ error: "Créditos insuficientes. Entre em contato com o administrador." }), {
          status: 402,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const errorText = await response.text();
      console.error("AI gateway error:", response.status, errorText);
      return new Response(JSON.stringify({ error: "Erro ao processar sua solicitação." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(response.body, {
      headers: { ...corsHeaders, "Content-Type": "text/event-stream" },
    });

  } catch (error) {
    console.error("AI Assistant error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function searchSimilarReports(supabase: any, searchText: string, companyId?: string) {
  // Extract keywords from the search text
  const keywords = searchText
    .toLowerCase()
    .replace(/[^\w\sáéíóúãõâêîôûç]/g, '')
    .split(/\s+/)
    .filter(word => word.length > 3);
  
  if (keywords.length === 0) return [];
  
  // Build search query
  let query = supabase
    .from('task_reports')
    .select(`
      id,
      task_id,
      report_data,
      created_at,
      task:task_uuid(
        id,
        assigned_to,
        service_order:service_order_id(
          id,
          order_number,
          company_id,
          vessel:vessel_id(name),
          client:client_id(name)
        )
      )
    `)
    .eq('status', 'approved')
    .order('created_at', { ascending: false })
    .limit(20);
  
  const { data: reports, error } = await query;
  
  if (error || !reports) return [];
  
  // Filter and score reports based on keyword matching
  const scoredReports = reports
    .filter((report: any) => {
      if (companyId && report.task?.service_order?.company_id !== companyId) {
        return false;
      }
      return true;
    })
    .map((report: any) => {
      const reportData = report.report_data || {};
      const searchableText = [
        reportData.reportedIssue || '',
        reportData.executedWork || '',
        reportData.result || '',
        reportData.modelInfo || '',
        reportData.brandInfo || ''
      ].join(' ').toLowerCase();
      
      let score = 0;
      keywords.forEach(keyword => {
        if (searchableText.includes(keyword)) {
          score += 1;
        }
      });
      
      return { ...report, score };
    })
    .filter((report: any) => report.score > 0)
    .sort((a: any, b: any) => b.score - a.score)
    .slice(0, 5);
  
  // Get technician info for matched reports
  const technicianIds = scoredReports
    .map((r: any) => r.task?.assigned_to)
    .filter(Boolean);
  
  if (technicianIds.length > 0) {
    const { data: technicians } = await supabase
      .from('technicians')
      .select('id, profiles:user_id(full_name)')
      .in('id', technicianIds);
    
    const techMap = new Map(technicians?.map((t: any) => [t.id, t.profiles?.full_name]) || []);
    
    return scoredReports.map((report: any) => ({
      ...report,
      technician_name: techMap.get(report.task?.assigned_to) || 'Desconhecido',
      technician_id: report.task?.assigned_to
    }));
  }
  
  return scoredReports;
}

function buildTechnicianSystemPrompt() {
  return `Você é o NavalOS AI, um assistente inteligente especializado em ajudar técnicos de manutenção naval e marítima.

Suas responsabilidades:
1. Ajudar técnicos a resolver problemas técnicos baseado em relatórios históricos
2. Sugerir soluções e procedimentos baseados em experiências anteriores
3. Identificar técnicos experientes que já resolveram problemas similares
4. Fornecer orientações sobre ferramentas e passos necessários

Diretrizes:
- Seja direto e prático nas respostas
- Priorize soluções comprovadas de relatórios anteriores
- Sugira contato com técnicos experientes quando apropriado
- Use linguagem técnica mas acessível
- Responda sempre em português brasileiro
- Formate suas respostas usando markdown para melhor legibilidade
- Use emojis para destacar pontos importantes (🔧 para ferramentas, ✅ para soluções, 👤 para técnicos)`;
}

function buildCoordinatorSystemPrompt() {
  return `Você é o NavalOS AI, um assistente inteligente para coordenadores de serviços técnicos navais.

Suas responsabilidades:
1. Fornecer insights sobre produtividade e alocação de técnicos
2. Ajudar na tomada de decisões sobre atribuição de ordens de serviço
3. Alertar sobre OS críticas ou atrasadas
4. Analisar padrões de demanda de clientes

Diretrizes:
- Seja analítico e baseie-se em dados
- Sugira ações concretas e mensuráveis
- Priorize eficiência operacional
- Responda sempre em português brasileiro
- Use formatação markdown e tabelas quando apropriado`;
}

function buildManagerSystemPrompt() {
  return `Você é o NavalOS AI, um assistente inteligente para gerentes de operações navais.

Suas responsabilidades:
1. Fornecer análises comparativas entre coordenadores
2. Identificar tendências e padrões operacionais
3. Sugerir melhorias baseadas em dados históricos
4. Apoiar decisões estratégicas

Diretrizes:
- Foque em métricas e KPIs relevantes
- Apresente dados de forma clara e visual
- Sugira ações estratégicas fundamentadas
- Responda sempre em português brasileiro`;
}

function buildPromptWithContext(message: string, contextData: any, userRole: string) {
  let contextParts: string[] = [];
  
  if (userRole === 'technician') {
    if (contextData.similarReports?.length > 0) {
      contextParts.push('\n📋 RELATÓRIOS SIMILARES ENCONTRADOS:');
      contextData.similarReports.forEach((report: any, index: number) => {
        const data = report.report_data || {};
        contextParts.push(`
${index + 1}. OS #${report.task?.service_order?.order_number || 'N/A'}
   - Técnico: ${report.technician_name}
   - Cliente: ${report.task?.service_order?.client?.name || 'N/A'}
   - Embarcação: ${report.task?.service_order?.vessel?.name || 'N/A'}
   - Problema Reportado: ${data.reportedIssue || 'N/A'}
   - Trabalho Executado: ${data.executedWork || 'N/A'}
   - Resultado: ${data.result || 'N/A'}
   - Equipamento: ${data.brandInfo || ''} ${data.modelInfo || ''}`);
      });
    }
    
    if (contextData.taskType) {
      contextParts.push(`\n🔧 TIPO DE TAREFA ATUAL:
- Nome: ${contextData.taskType.name}
- Descrição: ${contextData.taskType.description || 'N/A'}
- Ferramentas: ${contextData.taskType.tools?.join(', ') || 'N/A'}
- Passos: ${contextData.taskType.steps?.join(' → ') || 'N/A'}`);
    }
  }
  
  if (userRole === 'admin') {
    if (contextData.recentOrders) {
      const statusCount = contextData.recentOrders.reduce((acc: any, order: any) => {
        acc[order.status] = (acc[order.status] || 0) + 1;
        return acc;
      }, {});
      contextParts.push(`\n📊 RESUMO DOS ÚLTIMOS 30 DIAS:
- Total de OS: ${contextData.recentOrders.length}
- Pendentes: ${statusCount.pending || 0}
- Em Andamento: ${statusCount.in_progress || 0}
- Concluídas: ${statusCount.completed || 0}`);
    }
    
    if (contextData.availableTechnicians) {
      contextParts.push(`\n👥 TÉCNICOS DISPONÍVEIS: ${contextData.availableTechnicians.length}`);
    }
  }
  
  const contextString = contextParts.length > 0 
    ? `\n\n--- CONTEXTO DO SISTEMA ---${contextParts.join('\n')}\n--- FIM DO CONTEXTO ---\n\n`
    : '';
  
  return `${contextString}Pergunta do usuário: ${message}`;
}
