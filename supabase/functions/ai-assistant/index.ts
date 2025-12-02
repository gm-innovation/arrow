import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Patterns to detect report generation intent
const reportIntentPatterns = [
  /gerar\s*relat[oó]rio/i,
  /preencher\s*relat[oó]rio/i,
  /criar\s*relat[oó]rio/i,
  /montar\s*relat[oó]rio/i,
  /fazer\s*relat[oó]rio/i,
  /relat[oó]rio\s*autom[aá]tico/i,
];

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { message, image, userRole, context } = await req.json();
    
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const lovableApiKey = Deno.env.get('LOVABLE_API_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    let contextData: any = {};
    let systemPrompt = '';
    let useTools = false;
    let tools: any[] = [];
    
    // Check if user wants to generate a report
    const hasReportIntent = reportIntentPatterns.some(p => p.test(message));
    
    // Build context based on user role
    if (userRole === 'technician') {
      systemPrompt = buildTechnicianSystemPrompt(!!image, hasReportIntent);
      
      // Try semantic search first, fallback to keyword search
      if (message.length > 10) {
        const similarReports = await searchSimilarReportsSemantic(supabase, message, context?.companyId);
        if (similarReports.length > 0) {
          contextData.similarReports = similarReports;
          contextData.searchMethod = 'semantic';
        } else {
          // Fallback to keyword search
          const keywordReports = await searchSimilarReportsKeyword(supabase, message, context?.companyId);
          contextData.similarReports = keywordReports;
          contextData.searchMethod = 'keyword';
        }
        
        // Get technicians who solved similar problems
        if (contextData.similarReports?.length > 0) {
          const technicianIds = [...new Set(contextData.similarReports.map((r: any) => r.technician_id).filter(Boolean))];
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
      
      // Setup tool calling for report generation
      if (hasReportIntent) {
        useTools = true;
        tools = [{
          type: "function",
          function: {
            name: "generate_report_fields",
            description: "Extrai campos estruturados de um relatório técnico a partir da descrição fornecida pelo técnico",
            parameters: {
              type: "object",
              properties: {
                reportedIssue: { 
                  type: "string", 
                  description: "Problema reportado pelo cliente ou identificado pelo técnico" 
                },
                executedWork: { 
                  type: "string", 
                  description: "Trabalho executado pelo técnico para resolver o problema" 
                },
                result: { 
                  type: "string", 
                  enum: ["Solucionado", "Parcialmente Solucionado", "Pendente", "Não Solucionado"],
                  description: "Resultado do serviço realizado"
                },
                brandInfo: { type: "string", description: "Marca do equipamento trabalhado" },
                modelInfo: { type: "string", description: "Modelo do equipamento trabalhado" },
                serialNumber: { type: "string", description: "Número de série do equipamento" },
                observations: { type: "string", description: "Observações adicionais relevantes" }
              },
              required: ["reportedIssue", "executedWork", "result"]
            }
          }
        }];
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
    
    // Build message content (text or multimodal)
    let messageContent: any;
    if (image) {
      // Multimodal message with image
      messageContent = [
        { type: "text", text: fullPrompt },
        { type: "image_url", image_url: { url: image.startsWith('data:') ? image : `data:image/jpeg;base64,${image}` } }
      ];
    } else {
      messageContent = fullPrompt;
    }
    
    // Build request body
    const requestBody: any = {
      // Use Pro model for images (better multimodal), Flash for text-only
      model: image ? "google/gemini-2.5-pro" : "google/gemini-2.5-flash",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: messageContent }
      ],
      stream: !useTools, // Don't stream when using tools
    };
    
    // Add tools if needed
    if (useTools && tools.length > 0) {
      requestBody.tools = tools;
      requestBody.tool_choice = { type: "function", function: { name: "generate_report_fields" } };
    }
    
    // Call Lovable AI
    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${lovableApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
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

    // Handle tool calling response (non-streaming)
    if (useTools) {
      const responseData = await response.json();
      const toolCalls = responseData.choices?.[0]?.message?.tool_calls;
      
      if (toolCalls && toolCalls.length > 0) {
        const functionCall = toolCalls[0];
        const reportFields = JSON.parse(functionCall.function.arguments);
        
        return new Response(JSON.stringify({
          type: 'report_generation',
          fields: reportFields,
          message: "Campos do relatório extraídos com sucesso! Revise e confirme os dados abaixo."
        }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      
      // If no tool calls, return the regular response
      const content = responseData.choices?.[0]?.message?.content || "Desculpe, não consegui processar sua solicitação.";
      return new Response(JSON.stringify({ type: 'text', content }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Stream response
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

// Semantic search using embeddings
async function searchSimilarReportsSemantic(supabase: any, searchText: string, companyId?: string) {
  try {
    // Generate pseudo-embedding for the query (same method as in generate-embeddings)
    const queryEmbedding = generatePseudoEmbedding(searchText);
    
    // Call the search function
    const { data, error } = await supabase.rpc('search_similar_reports', {
      query_embedding: `[${queryEmbedding.join(',')}]`,
      match_threshold: 0.3,
      match_count: 5,
      p_company_id: companyId || null
    });
    
    if (error) {
      console.error("Semantic search error:", error);
      return [];
    }
    
    if (!data || data.length === 0) {
      return [];
    }
    
    // Get technician info
    const reportIds = data.map((r: any) => r.task_report_id);
    const { data: reports } = await supabase
      .from('task_reports')
      .select(`
        id,
        task_id,
        report_data,
        task:task_uuid(
          assigned_to,
          service_order:service_order_id(
            order_number,
            vessel:vessel_id(name),
            client:client_id(name)
          )
        )
      `)
      .in('id', reportIds);
    
    const reportMap = new Map(reports?.map((r: any) => [r.id, r]) || []);
    
    // Get technician names
    const technicianIds = reports?.map((r: any) => r.task?.assigned_to).filter(Boolean) || [];
    let technicianMap = new Map();
    
    if (technicianIds.length > 0) {
      const { data: technicians } = await supabase
        .from('technicians')
        .select('id, profiles:user_id(full_name)')
        .in('id', technicianIds);
      technicianMap = new Map(technicians?.map((t: any) => [t.id, t.profiles?.full_name]) || []);
    }
    
    return data.map((result: any) => {
      const report = reportMap.get(result.task_report_id);
      return {
        ...report,
        similarity: result.similarity,
        technician_name: technicianMap.get(report?.task?.assigned_to) || 'Desconhecido',
        technician_id: report?.task?.assigned_to
      };
    });
  } catch (error) {
    console.error("Semantic search failed:", error);
    return [];
  }
}

// Generate pseudo-embedding (must match the one in generate-embeddings)
function generatePseudoEmbedding(text: string): number[] {
  const embedding = new Array(768).fill(0);
  const normalizedText = text.toLowerCase();
  
  for (let i = 0; i < normalizedText.length && i < 768; i++) {
    const charCode = normalizedText.charCodeAt(i);
    embedding[i % 768] += (charCode - 96) / 26;
  }

  const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
  if (magnitude > 0) {
    for (let i = 0; i < 768; i++) {
      embedding[i] = embedding[i] / magnitude;
    }
  }

  return embedding;
}

// Keyword-based search (fallback)
async function searchSimilarReportsKeyword(supabase: any, searchText: string, companyId?: string) {
  const keywords = searchText
    .toLowerCase()
    .replace(/[^\w\sáéíóúãõâêîôûç]/g, '')
    .split(/\s+/)
    .filter(word => word.length > 3);
  
  if (keywords.length === 0) return [];
  
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

function buildTechnicianSystemPrompt(hasImage: boolean, hasReportIntent: boolean) {
  let basePrompt = `Você é o NavalOS AI, um assistente inteligente especializado em ajudar técnicos de manutenção naval e marítima.

Suas responsabilidades:
1. Ajudar técnicos a resolver problemas técnicos baseado em relatórios históricos
2. Sugerir soluções e procedimentos baseados em experiências anteriores
3. Identificar técnicos experientes que já resolveram problemas similares
4. Fornecer orientações sobre ferramentas e passos necessários`;

  if (hasImage) {
    basePrompt += `

ANÁLISE DE IMAGEM:
Você recebeu uma imagem junto com a mensagem. Analise a imagem detalhadamente e:
- Identifique equipamentos, componentes ou problemas visíveis
- Descreva o estado do equipamento (desgaste, danos, corrosão, etc.)
- Sugira possíveis diagnósticos ou próximos passos de inspeção
- Compare com problemas similares de relatórios históricos se disponíveis`;
  }

  if (hasReportIntent) {
    basePrompt += `

GERAÇÃO DE RELATÓRIO:
O técnico quer gerar um relatório. Use a função generate_report_fields para extrair os campos estruturados da descrição fornecida. Seja preciso e extraia todas as informações relevantes.`;
  }

  basePrompt += `

Diretrizes:
- Seja direto e prático nas respostas
- Priorize soluções comprovadas de relatórios anteriores
- Sugira contato com técnicos experientes quando apropriado
- Use linguagem técnica mas acessível
- Responda sempre em português brasileiro
- Formate suas respostas usando markdown para melhor legibilidade
- Use emojis para destacar pontos importantes (🔧 para ferramentas, ✅ para soluções, 👤 para técnicos, 📷 para análise de imagem)`;

  return basePrompt;
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
      const searchMethod = contextData.searchMethod === 'semantic' ? '(busca semântica)' : '(busca por palavras-chave)';
      contextParts.push(`\n📋 RELATÓRIOS SIMILARES ENCONTRADOS ${searchMethod}:`);
      contextData.similarReports.forEach((report: any, index: number) => {
        const data = report.report_data || {};
        const similarity = report.similarity ? ` (${Math.round(report.similarity * 100)}% similar)` : '';
        contextParts.push(`
${index + 1}. OS #${report.task?.service_order?.order_number || 'N/A'}${similarity}
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
