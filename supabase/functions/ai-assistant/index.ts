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

// Patterns to detect operational questions - AVAILABILITY
const availabilityPatterns = [
  /t[eé]cnicos?\s*(dispon[ií]ve[il]s?|livres?)/i,
  /quem\s*(est[aá]|pode|vai)?\s*(dispon[ií]vel|livre)/i,
  /disponibilidade\s*(de\s*)?t[eé]cnicos?/i,
  /quais?\s*t[eé]cnicos?/i,
  /t[eé]cnicos?\s*para\s*(amanh[aã]|hoje|essa\s*semana)/i,
];

// Patterns for date detection
const tomorrowPatterns = [/amanh[aã]/i];
const todayPatterns = [/hoje/i];
const nextWeekPatterns = [/pr[oó]xim[ao]s?\s*dias?/i, /essa\s*semana/i, /semana\s*que\s*vem/i];

// Patterns for OS status questions
const osStatusPatterns = [
  /quantas?\s*os\s*(pendentes?|atrasadas?|urgentes?|abertas?)/i,
  /status\s*(das?|de)\s*os/i,
  /os\s*(pendentes?|em\s*andamento|atrasadas?)/i,
  /ordens?\s*de\s*servi[çc]o/i,
];

// Patterns for technician productivity questions
const productivityPatterns = [
  /t[eé]cnicos?\s*(com\s*)?(mais|menos|maior|menor)\s*(atendimentos?|servi[çc]os?|os|tarefas?|conclu[ií]d[oa]s?)/i,
  /quem\s*(tem|fez|realizou)\s*mais\s*(atendimentos?|servi[çc]os?|os)/i,
  /ranking\s*(de\s*)?t[eé]cnicos?/i,
  /produtividade\s*(dos?\s*)?t[eé]cnicos?/i,
  /performance\s*(dos?\s*)?t[eé]cnicos?/i,
  /desempenho\s*(dos?\s*)?t[eé]cnicos?/i,
  /melhores?\s*t[eé]cnicos?/i,
  /top\s*t[eé]cnicos?/i,
];

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Include conversation history from frontend
    const { message, image, userRole, context, messages: conversationHistory } = await req.json();
    
    console.log("AI Assistant Request:", { 
      message: message?.substring(0, 100), 
      userRole, 
      companyId: context?.companyId,
      hasHistory: !!conversationHistory?.length 
    });
    
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const lovableApiKey = Deno.env.get('LOVABLE_API_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    let contextData: any = {};
    let systemPrompt = '';
    let useTools = false;
    let tools: any[] = [];
    
    // Check intents
    const hasReportIntent = reportIntentPatterns.some(p => p.test(message));
    const hasAvailabilityQuestion = availabilityPatterns.some(p => p.test(message));
    const hasOsStatusQuestion = osStatusPatterns.some(p => p.test(message));
    const hasProductivityQuestion = productivityPatterns.some(p => p.test(message));
    
    console.log("Intent detection:", { hasReportIntent, hasAvailabilityQuestion, hasOsStatusQuestion, hasProductivityQuestion });
    
    // Detect target date for availability questions
    const targetDateInfo = detectTargetDate(message);
    
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
      
      console.log("Admin context check:", { 
        hasAvailabilityQuestion, 
        companyId: context?.companyId,
        targetDate: targetDateInfo.dateStr
      });
      
      // PROACTIVE: Fetch availability data when question is detected
      if (hasAvailabilityQuestion && context?.companyId) {
        console.log("Fetching availability for:", context.companyId, targetDateInfo.date);
        const availabilityData = await fetchTechnicianAvailability(supabase, context.companyId, targetDateInfo.date);
        console.log("Availability result:", { 
          freeTechnicians: availabilityData.freeTechnicians?.length,
          scheduledTechnicians: availabilityData.scheduledTechnicians?.length
        });
        contextData.availabilityReport = {
          ...availabilityData,
          dateStr: targetDateInfo.dateStr,
          dateLabel: targetDateInfo.label
        };
      }
      
      // PROACTIVE: Fetch OS status data when question is detected
      if (hasOsStatusQuestion && context?.companyId) {
        const osStatusData = await fetchOsStatus(supabase, context.companyId);
        contextData.osStatusReport = osStatusData;
      }
      
      // PROACTIVE: Fetch technician productivity data
      if (hasProductivityQuestion && context?.companyId) {
        console.log("Fetching technician productivity for:", context.companyId);
        const productivityData = await fetchTechnicianProductivity(supabase, context.companyId);
        console.log("Productivity result:", { techniciansCount: productivityData?.length });
        contextData.productivityReport = productivityData;
      }
      
      // Always fetch basic stats for coordinators
      if (context?.companyId) {
        const { data: recentOrders } = await supabase
          .from('service_orders')
          .select('id, status, created_at, scheduled_date')
          .eq('company_id', context.companyId)
          .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
          .order('created_at', { ascending: false })
          .limit(50);
        contextData.recentOrders = recentOrders;
        
        // Get technician count
        const { data: technicians } = await supabase
          .from('technicians')
          .select('id, active, specialty, profiles:user_id(full_name)')
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
    
    // Build conversation messages array - include history for context
    const conversationMessages = [
      { role: "system", content: systemPrompt },
    ];
    
    // Add conversation history (last 10 messages for context)
    if (conversationHistory && Array.isArray(conversationHistory)) {
      const recentHistory = conversationHistory.slice(-10);
      recentHistory.forEach((msg: any) => {
        if (msg.role && msg.content) {
          conversationMessages.push({
            role: msg.role,
            content: msg.content
          });
        }
      });
    }
    
    // Add current message
    conversationMessages.push({ role: "user", content: messageContent });
    
    // Build request body
    const requestBody: any = {
      // Use Pro model for images (better multimodal), Flash for text-only
      model: image ? "google/gemini-2.5-pro" : "google/gemini-2.5-flash",
      messages: conversationMessages,
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

// Detect target date from message - IMPROVED VERSION
function detectTargetDate(message: string): { date: Date; dateStr: string; label: string } {
  const today = new Date();
  const currentYear = today.getFullYear();
  const currentMonth = today.getMonth();
  
  // Pattern for "dia X" or "dia X/Y" or "dia X de mês"
  const dayPattern = /dia\s*(\d{1,2})(?:\s*(?:de\s*|\/)\s*(\d{1,2}|janeiro|fevereiro|março|marco|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro))?(?:\s*(?:de\s*|\/)\s*(\d{2,4}))?/i;
  
  // Pattern for "DD/MM" or "DD/MM/YYYY"
  const dateSlashPattern = /(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?/;
  
  // Pattern for "DD-MM" or "DD-MM-YYYY"
  const dateDashPattern = /(\d{1,2})-(\d{1,2})(?:-(\d{2,4}))?/;
  
  // Weekday patterns
  const weekdayPatterns: { pattern: RegExp; dayOfWeek: number }[] = [
    { pattern: /(?:pr[oó]xim[ao]?\s*)?segunda(?:-feira)?/i, dayOfWeek: 1 },
    { pattern: /(?:pr[oó]xim[ao]?\s*)?ter[çc]a(?:-feira)?/i, dayOfWeek: 2 },
    { pattern: /(?:pr[oó]xim[ao]?\s*)?quarta(?:-feira)?/i, dayOfWeek: 3 },
    { pattern: /(?:pr[oó]xim[ao]?\s*)?quinta(?:-feira)?/i, dayOfWeek: 4 },
    { pattern: /(?:pr[oó]xim[ao]?\s*)?sexta(?:-feira)?/i, dayOfWeek: 5 },
    { pattern: /(?:pr[oó]xim[ao]?\s*)?s[aá]bado/i, dayOfWeek: 6 },
    { pattern: /(?:pr[oó]xim[ao]?\s*)?domingo/i, dayOfWeek: 0 },
  ];
  
  const monthNames: { [key: string]: number } = {
    'janeiro': 0, 'fevereiro': 1, 'março': 2, 'marco': 2, 'abril': 3,
    'maio': 4, 'junho': 5, 'julho': 6, 'agosto': 7,
    'setembro': 8, 'outubro': 9, 'novembro': 10, 'dezembro': 11
  };
  
  // Helper to build date and return result
  const buildResult = (date: Date) => ({
    date,
    dateStr: date.toISOString().split('T')[0],
    label: formatDateBR(date)
  });
  
  // Check for "dia X" pattern first
  const dayMatch = message.match(dayPattern);
  if (dayMatch) {
    const day = parseInt(dayMatch[1], 10);
    let month = currentMonth;
    let year = currentYear;
    
    if (dayMatch[2]) {
      const monthPart = dayMatch[2].toLowerCase();
      if (monthNames[monthPart] !== undefined) {
        month = monthNames[monthPart];
      } else {
        month = parseInt(monthPart, 10) - 1;
      }
    }
    
    if (dayMatch[3]) {
      year = parseInt(dayMatch[3], 10);
      if (year < 100) year += 2000;
    }
    
    // If the date is in the past for current month, assume next month
    const targetDate = new Date(year, month, day);
    if (targetDate < today && !dayMatch[2] && !dayMatch[3]) {
      // Only day was specified and it's in the past, assume next month
      targetDate.setMonth(targetDate.getMonth() + 1);
    }
    
    return buildResult(targetDate);
  }
  
  // Check for DD/MM or DD/MM/YYYY pattern
  const slashMatch = message.match(dateSlashPattern);
  if (slashMatch) {
    const day = parseInt(slashMatch[1], 10);
    const month = parseInt(slashMatch[2], 10) - 1;
    let year = slashMatch[3] ? parseInt(slashMatch[3], 10) : currentYear;
    if (year < 100) year += 2000;
    
    return buildResult(new Date(year, month, day));
  }
  
  // Check for DD-MM or DD-MM-YYYY pattern
  const dashMatch = message.match(dateDashPattern);
  if (dashMatch) {
    const day = parseInt(dashMatch[1], 10);
    const month = parseInt(dashMatch[2], 10) - 1;
    let year = dashMatch[3] ? parseInt(dashMatch[3], 10) : currentYear;
    if (year < 100) year += 2000;
    
    return buildResult(new Date(year, month, day));
  }
  
  // Check for weekday patterns
  for (const { pattern, dayOfWeek } of weekdayPatterns) {
    if (pattern.test(message)) {
      const targetDate = new Date(today);
      const currentDayOfWeek = today.getDay();
      let daysToAdd = dayOfWeek - currentDayOfWeek;
      
      // If the target day is today or already passed this week, go to next week
      if (daysToAdd <= 0) {
        daysToAdd += 7;
      }
      
      targetDate.setDate(today.getDate() + daysToAdd);
      return buildResult(targetDate);
    }
  }
  
  // Check for tomorrow
  if (tomorrowPatterns.some(p => p.test(message))) {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return buildResult(tomorrow);
  }
  
  // Check for next week
  if (nextWeekPatterns.some(p => p.test(message))) {
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    return {
      date: nextWeek,
      dateStr: nextWeek.toISOString().split('T')[0],
      label: `Próximos 7 dias`
    };
  }
  
  // Check for today explicitly
  if (todayPatterns.some(p => p.test(message))) {
    return buildResult(today);
  }
  
  // Default to today
  return buildResult(today);
}

function formatDateBR(date: Date): string {
  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

// Fetch technician availability for a specific date - USES RPC FOR COMPLETE AVAILABILITY CHECK
async function fetchTechnicianAvailability(supabase: any, companyId: string, targetDate: Date) {
  try {
    const dateStr = targetDate.toISOString().split('T')[0];
    
    console.log("Fetching availability for date:", dateStr, "company:", companyId);
    
    // Fetch all active technicians with full info
    const { data: allTechnicians, error: techError } = await supabase
      .from('technicians')
      .select('id, specialty, profiles:user_id(full_name, phone)')
      .eq('company_id', companyId)
      .eq('active', true);
    
    if (techError) {
      console.error("Error fetching technicians:", techError);
      return { freeTechnicians: [], unavailableTechnicians: [], scheduledVisits: [], totalTechnicians: 0 };
    }
    
    console.log("Found technicians:", allTechnicians?.length);
    
    // Use the RPC to check availability for each technician (checks absences, on-call, holidays)
    const availabilityResults = await Promise.all(
      (allTechnicians || []).map(async (tech: any) => {
        try {
          const { data, error } = await supabase.rpc('get_technician_availability', {
            _technician_id: tech.id,
            _check_date: dateStr,
          });
          
          if (error) {
            console.error("Error checking availability for", tech.profiles?.full_name, error);
            return { ...tech, availability: { is_available: true, status_type: 'available', status_description: 'Disponível' } };
          }
          
          const availability = data?.[0] || { is_available: true, status_type: 'available', status_description: 'Disponível' };
          return { ...tech, availability };
        } catch (err) {
          console.error("RPC error for technician:", tech.id, err);
          return { ...tech, availability: { is_available: true, status_type: 'available', status_description: 'Disponível' } };
        }
      })
    );
    
    // Fetch visits scheduled for target date to check for scheduling conflicts
    const { data: scheduledVisits, error: visitError } = await supabase
      .from('service_visits')
      .select(`
        id,
        visit_date,
        status,
        service_order:service_order_id(
          id,
          order_number,
          location,
          company_id,
          client:client_id(name),
          vessel:vessel_id(name)
        )
      `)
      .eq('visit_date', dateStr)
      .in('status', ['pending', 'in_progress']);
    
    // Filter visits by company
    const companyVisits = scheduledVisits?.filter(
      (v: any) => v.service_order?.company_id === companyId
    ) || [];
    
    // Get visit IDs and fetch assigned technicians
    const visitIds = companyVisits.map((v: any) => v.id);
    let assignedTechIds: Set<string> = new Set();
    let visitTechnicianMap: Map<string, any[]> = new Map();
    let techVisitMap: Map<string, any> = new Map(); // Map tech ID to their assigned visit
    
    if (visitIds.length > 0) {
      const { data: visitTechnicians } = await supabase
        .from('visit_technicians')
        .select('visit_id, technician_id')
        .in('visit_id', visitIds);
      
      visitTechnicians?.forEach((vt: any) => {
        assignedTechIds.add(vt.technician_id);
        if (!visitTechnicianMap.has(vt.visit_id)) {
          visitTechnicianMap.set(vt.visit_id, []);
        }
        visitTechnicianMap.get(vt.visit_id)!.push(vt.technician_id);
        
        // Find the visit for this technician
        const visit = companyVisits.find((v: any) => v.id === vt.visit_id);
        if (visit) {
          techVisitMap.set(vt.technician_id, visit);
        }
      });
    }
    
    // Classify technicians into categories
    const freeTechnicians: any[] = [];
    const unavailableTechnicians: any[] = [];
    
    availabilityResults.forEach((tech: any) => {
      const isAbsent = !tech.availability?.is_available;
      const isScheduled = assignedTechIds.has(tech.id);
      const assignedVisit = techVisitMap.get(tech.id);
      
      if (isAbsent) {
        // Technician has absence (vacation, sick leave, day off, etc.)
        unavailableTechnicians.push({
          ...tech,
          unavailableReason: tech.availability?.status_description || 'Ausência',
          reasonType: tech.availability?.status_type || 'absence'
        });
      } else if (isScheduled) {
        // Technician is scheduled for a visit
        unavailableTechnicians.push({
          ...tech,
          unavailableReason: `Agendado para OS #${assignedVisit?.service_order?.order_number || '?'} - ${assignedVisit?.service_order?.vessel?.name || assignedVisit?.service_order?.client?.name || 'Cliente'}`,
          reasonType: 'scheduled',
          assignedVisit
        });
      } else {
        // Technician is available
        freeTechnicians.push(tech);
      }
    });
    
    // Build enriched visit data
    const enrichedVisits = companyVisits.map((visit: any) => {
      const techIds = visitTechnicianMap.get(visit.id) || [];
      const techNames = techIds.map((tid: string) => {
        const tech = allTechnicians?.find((t: any) => t.id === tid);
        return tech?.profiles?.full_name || 'Desconhecido';
      });
      return {
        ...visit,
        technician_names: techNames
      };
    });
    
    console.log("Availability result:", { 
      free: freeTechnicians.length, 
      unavailable: unavailableTechnicians.length,
      visits: enrichedVisits.length
    });
    
    return {
      freeTechnicians,
      unavailableTechnicians,
      scheduledVisits: enrichedVisits,
      totalTechnicians: allTechnicians?.length || 0,
      dateChecked: dateStr
    };
  } catch (error) {
    console.error("Error in fetchTechnicianAvailability:", error);
    return { freeTechnicians: [], unavailableTechnicians: [], scheduledVisits: [], totalTechnicians: 0 };
  }
}

// Fetch OS status summary
async function fetchOsStatus(supabase: any, companyId: string) {
  try {
    const { data: orders, error } = await supabase
      .from('service_orders')
      .select('id, status, scheduled_date, created_at, order_number, location, client:client_id(name)')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false })
      .limit(100);
    
    if (error) {
      console.error("Error fetching OS status:", error);
      return null;
    }
    
    const today = new Date();
    const statusCount = {
      pending: 0,
      in_progress: 0,
      completed: 0,
      cancelled: 0,
      overdue: 0
    };
    
    const overdueOrders: any[] = [];
    const pendingOrders: any[] = [];
    
    orders?.forEach((order: any) => {
      statusCount[order.status as keyof typeof statusCount] = 
        (statusCount[order.status as keyof typeof statusCount] || 0) + 1;
      
      // Check if overdue (scheduled date passed but not completed)
      if (order.scheduled_date && order.status !== 'completed' && order.status !== 'cancelled') {
        const scheduledDate = new Date(order.scheduled_date);
        if (scheduledDate < today) {
          statusCount.overdue++;
          overdueOrders.push(order);
        }
      }
      
      if (order.status === 'pending') {
        pendingOrders.push(order);
      }
    });
    
    return {
      statusCount,
      overdueOrders: overdueOrders.slice(0, 5),
      pendingOrders: pendingOrders.slice(0, 5),
      totalOrders: orders?.length || 0
    };
  } catch (error) {
    console.error("Error in fetchOsStatus:", error);
    return null;
  }
}

// Fetch technician productivity data
async function fetchTechnicianProductivity(supabase: any, companyId: string) {
  try {
    // Get all active technicians with their basic info
    const { data: technicians, error: techError } = await supabase
      .from('technicians')
      .select('id, specialty, profiles:user_id(full_name)')
      .eq('company_id', companyId)
      .eq('active', true);
    
    if (techError || !technicians) {
      console.error("Error fetching technicians for productivity:", techError);
      return [];
    }
    
    // Get all completed tasks for this company in the last 90 days
    const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
    
    const { data: tasks, error: taskError } = await supabase
      .from('tasks')
      .select(`
        id,
        assigned_to,
        status,
        completed_at,
        service_order:service_order_id(company_id)
      `)
      .eq('status', 'completed')
      .gte('completed_at', ninetyDaysAgo);
    
    if (taskError) {
      console.error("Error fetching tasks for productivity:", taskError);
    }
    
    // Filter tasks by company and count by technician
    const companyTasks = tasks?.filter((t: any) => t.service_order?.company_id === companyId) || [];
    const taskCountByTech: Map<string, number> = new Map();
    
    companyTasks.forEach((task: any) => {
      if (task.assigned_to) {
        taskCountByTech.set(task.assigned_to, (taskCountByTech.get(task.assigned_to) || 0) + 1);
      }
    });
    
    // Also get approved reports count per technician
    const { data: reports, error: reportError } = await supabase
      .from('task_reports')
      .select(`
        id,
        task:task_uuid(
          assigned_to,
          service_order:service_order_id(company_id)
        )
      `)
      .eq('status', 'approved')
      .gte('created_at', ninetyDaysAgo);
    
    const reportCountByTech: Map<string, number> = new Map();
    reports?.forEach((report: any) => {
      if (report.task?.service_order?.company_id === companyId && report.task?.assigned_to) {
        reportCountByTech.set(report.task.assigned_to, (reportCountByTech.get(report.task.assigned_to) || 0) + 1);
      }
    });
    
    // Build productivity report for each technician
    const productivityData = technicians.map((tech: any) => ({
      id: tech.id,
      name: tech.profiles?.full_name || 'Sem nome',
      specialty: tech.specialty || 'Geral',
      completedTasks: taskCountByTech.get(tech.id) || 0,
      approvedReports: reportCountByTech.get(tech.id) || 0,
    }));
    
    // Sort by completed tasks (descending)
    productivityData.sort((a: any, b: any) => b.completedTasks - a.completedTasks);
    
    return productivityData;
  } catch (error) {
    console.error("Error in fetchTechnicianProductivity:", error);
    return [];
  }
}

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
  const today = new Date();
  const todayStr = formatDateBR(today);
  
  return `Você é o NavalOS AI, um assistente inteligente para coordenadores de serviços técnicos navais.

🚨 REGRAS CRÍTICAS DE COMPORTAMENTO:
1. SEMPRE responda DIRETAMENTE com os dados disponíveis no contexto
2. NUNCA pergunte "qual a data de amanhã" - hoje é ${todayStr}
3. NUNCA peça informações que já estão no contexto fornecido
4. Seja PROATIVO - forneça respostas completas e acionáveis imediatamente
5. Se precisar de mais detalhes, faça NO MÁXIMO 1 pergunta específica

Suas responsabilidades:
1. Informar disponibilidade de técnicos usando SEMPRE os dados do contexto
2. Ajudar na tomada de decisões sobre atribuição de ordens de serviço
3. Alertar sobre OS críticas ou atrasadas
4. Fornecer visão operacional clara e objetiva

Formato para perguntas de disponibilidade:
- Liste técnicos LIVRES primeiro (nome + especialidade + telefone se disponível)
- Depois liste técnicos COM AGENDAMENTO (nome + qual OS + onde)
- Sugira quem atribuir baseado em especialidade e localização

Formato para perguntas de status de OS:
- Mostre resumo quantitativo (pendentes, em andamento, concluídas, atrasadas)
- Liste OS atrasadas ou críticas com detalhes
- Sugira ações prioritárias

Diretrizes:
- Seja analítico e baseie-se nos dados do contexto
- Sugira ações concretas e mensuráveis
- Priorize eficiência operacional
- Responda sempre em português brasileiro
- Use formatação markdown, tabelas e emojis para organizar informações
- Use ✅ para técnicos livres, 🔴 para ocupados, ⚠️ para alertas`;
}

function buildManagerSystemPrompt() {
  const today = new Date();
  const todayStr = formatDateBR(today);
  
  return `Você é o NavalOS AI, um assistente inteligente para gerentes de operações navais.

🚨 REGRAS CRÍTICAS:
1. Responda DIRETAMENTE com os dados disponíveis - não faça perguntas desnecessárias
2. Hoje é ${todayStr}
3. Use os dados do contexto para fornecer análises imediatas

Suas responsabilidades:
1. Fornecer análises comparativas entre coordenadores
2. Identificar tendências e padrões operacionais
3. Sugerir melhorias baseadas em dados históricos
4. Apoiar decisões estratégicas

Diretrizes:
- Foque em métricas e KPIs relevantes
- Apresente dados de forma clara e visual
- Sugira ações estratégicas fundamentadas
- Responda sempre em português brasileiro
- Use tabelas, gráficos em texto e emojis para organizar`;
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
    // AVAILABILITY REPORT - Detailed information with absence reasons
    if (contextData.availabilityReport) {
      const ar = contextData.availabilityReport;
      const dateLabel = ar.dateChecked ? formatDateBR(new Date(ar.dateChecked)) : ar.dateLabel;
      
      contextParts.push(`\n📅 DISPONIBILIDADE DE TÉCNICOS - ${dateLabel}:

✅ TÉCNICOS DISPONÍVEIS (${ar.freeTechnicians?.length || 0} de ${ar.totalTechnicians || 0}):
${ar.freeTechnicians?.length > 0 
  ? ar.freeTechnicians.map((t: any) => 
    `- ${t.profiles?.full_name || 'Sem nome'} | ${t.specialty || 'Geral'} | Tel: ${t.profiles?.phone || 'N/A'}`
  ).join('\n')
  : '- Nenhum técnico disponível nesta data'}

🔴 TÉCNICOS INDISPONÍVEIS (${ar.unavailableTechnicians?.length || 0}):
${ar.unavailableTechnicians?.length > 0 
  ? ar.unavailableTechnicians.map((t: any) => {
    const emoji = t.reasonType === 'scheduled' ? '📋' : 
                  t.reasonType === 'vacation' ? '🏖️' :
                  t.reasonType === 'day_off' ? '🛌' :
                  t.reasonType === 'sick_leave' ? '🏥' :
                  t.reasonType === 'training' ? '📚' :
                  t.reasonType === 'on_call' ? '📱' : '❌';
    return `- ${t.profiles?.full_name || 'Sem nome'} | ${t.specialty || 'Geral'} | ${emoji} ${t.unavailableReason || 'Indisponível'}`;
  }).join('\n')
  : '- Todos os técnicos estão disponíveis'}

${ar.scheduledVisits?.length > 0 ? `📋 VISITAS AGENDADAS NESTA DATA:
${ar.scheduledVisits.map((v: any) => 
  `- OS #${v.service_order?.order_number || 'N/A'}: ${v.service_order?.vessel?.name || v.service_order?.client?.name || 'Cliente N/A'} em ${v.service_order?.location || 'Local não definido'} | Equipe: ${v.technician_names?.join(', ') || 'N/A'}`
).join('\n')}` : ''}

⚠️ INSTRUÇÃO: Responda DIRETAMENTE com esses dados. Liste os técnicos disponíveis e indisponíveis de forma clara, incluindo o motivo da indisponibilidade.`);
    }
    
    // OS STATUS REPORT
    if (contextData.osStatusReport) {
      const osr = contextData.osStatusReport;
      contextParts.push(`\n📊 STATUS DAS ORDENS DE SERVIÇO:

Resumo Geral (últimas ${osr.totalOrders} OS):
- 🟡 Pendentes: ${osr.statusCount.pending}
- 🔵 Em Andamento: ${osr.statusCount.in_progress}
- 🟢 Concluídas: ${osr.statusCount.completed}
- ⚠️ Atrasadas: ${osr.statusCount.overdue}
- ❌ Canceladas: ${osr.statusCount.cancelled}

${osr.overdueOrders?.length > 0 ? `⚠️ OS ATRASADAS (ação necessária):
${osr.overdueOrders.map((o: any) => 
  `- OS #${o.order_number}: ${o.client?.name || 'N/A'} - Agendada: ${o.scheduled_date}`
).join('\n')}` : ''}

${osr.pendingOrders?.length > 0 ? `🟡 PRÓXIMAS OS PENDENTES:
${osr.pendingOrders.map((o: any) => 
  `- OS #${o.order_number}: ${o.client?.name || 'N/A'} - ${o.location || 'Local N/A'}`
).join('\n')}` : ''}`);
    }
    
    // PRODUCTIVITY REPORT
    if (contextData.productivityReport && contextData.productivityReport.length > 0) {
      const pr = contextData.productivityReport;
      const totalTasks = pr.reduce((sum: number, t: any) => sum + t.completedTasks, 0);
      
      contextParts.push(`\n🏆 PRODUTIVIDADE DOS TÉCNICOS (últimos 90 dias):

📈 RANKING POR TAREFAS CONCLUÍDAS:
${pr.map((t: any, index: number) => 
  `${index + 1}. ${t.name} | ${t.specialty} | ✅ ${t.completedTasks} tarefas | 📝 ${t.approvedReports} relatórios`
).join('\n')}

📊 RESUMO:
- Total de tarefas concluídas: ${totalTasks}
- Técnicos com atividade: ${pr.filter((t: any) => t.completedTasks > 0).length} de ${pr.length}
- Média por técnico: ${pr.length > 0 ? (totalTasks / pr.length).toFixed(1) : 0} tarefas

⚠️ INSTRUÇÃO: Use esses dados para responder diretamente sobre produtividade e performance dos técnicos.`);
    }
    
    // Basic stats (always included)
    if (contextData.recentOrders && !contextData.availabilityReport && !contextData.osStatusReport) {
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
    
    if (contextData.availableTechnicians && !contextData.availabilityReport) {
      contextParts.push(`\n👥 TÉCNICOS ATIVOS: ${contextData.availableTechnicians.length}`);
    }
  }
  
  const contextString = contextParts.length > 0 
    ? `\n\n--- CONTEXTO DO SISTEMA ---${contextParts.join('\n')}\n--- FIM DO CONTEXTO ---\n\n`
    : '';
  
  return `${contextString}Pergunta do usuário: ${message}`;
}
