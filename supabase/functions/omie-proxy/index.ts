import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

const OMIE_BASE_URL = "https://app.omie.com.br/api/v1";

interface OmieCredentials {
  app_key: string;
  app_secret: string;
}

async function callOmie(endpoint: string, call: string, params: any, creds: OmieCredentials, retryCount = 0): Promise<any> {
  const body = {
    call,
    app_key: creds.app_key,
    app_secret: creds.app_secret,
    param: [params],
  };

  const res = await fetch(`${OMIE_BASE_URL}${endpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const text = await res.text();
  
  let parsed: any;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new Error(`Omie API error ${res.status}: ${text.substring(0, 200)}`);
  }

  // Handle REDUNDANT error with dynamic retry
  if (parsed.faultstring && parsed.faultstring.includes("REDUNDANT") && retryCount < 2) {
    const waitMatch = parsed.faultstring.match(/(\d+)\s*segundo/i);
    const waitSeconds = waitMatch ? Math.min(parseInt(waitMatch[1]) + 2, 30) : 12;
    console.log(`Omie REDUNDANT error, waiting ${waitSeconds}s (retry ${retryCount + 1})...`);
    await new Promise(resolve => setTimeout(resolve, waitSeconds * 1000));
    return callOmie(endpoint, call, params, creds, retryCount + 1);
  }

  if (parsed.faultstring) {
    throw new Error(parsed.faultstring);
  }

  if (!res.ok) {
    throw new Error(`Omie API error ${res.status}: ${text.substring(0, 200)}`);
  }

  return parsed;
}

async function handleTestConnection(creds: OmieCredentials) {
  const result = await callOmie("/geral/clientes/", "ListarClientes", {
    pagina: 1,
    registros_por_pagina: 1,
    apenas_importado_api: "N",
  }, creds);
  return { success: true, total_clients: result.total_de_registros || 0 };
}

async function handleListClients(creds: OmieCredentials, params: any) {
  const page = params?.page || 1;
  const result = await callOmie("/geral/clientes/", "ListarClientes", {
    pagina: page,
    registros_por_pagina: 50,
    apenas_importado_api: "N",
  }, creds);
  return {
    clients: result.clientes_cadastro || [],
    total: result.total_de_registros || 0,
    pages: result.total_de_paginas || 0,
    current_page: page,
  };
}

async function handleSyncClients(creds: OmieCredentials, supabase: any, companyId: string) {
  let page = 1;
  let totalPages = 1;
  let synced = 0;
  let errors: string[] = [];

  while (page <= totalPages) {
    const result = await callOmie("/geral/clientes/", "ListarClientes", {
      pagina: page,
      registros_por_pagina: 500,
      apenas_importado_api: "N",
    }, creds);

    totalPages = result.total_de_paginas || 1;
    const clients = result.clientes_cadastro || [];

    const batch = clients.map((client: any) => ({
      company_id: companyId,
      name: client.nome_fantasia || client.razao_social || "Sem nome",
      email: client.email || null,
      phone: client.telefone1_numero || null,
      cnpj: client.cnpj_cpf || null,
      address: [client.endereco, client.endereco_numero, client.bairro].filter(Boolean).join(", ") || null,
      city: client.cidade || null,
      state: client.estado || null,
      cep: client.cep || null,
      omie_client_id: client.codigo_cliente_omie,
      contact_person: client.contato || null,
    }));

    if (batch.length > 0) {
      const { error: upsertError, data } = await supabase
        .from("clients")
        .upsert(batch, { onConflict: "company_id,omie_client_id", ignoreDuplicates: false })
        .select("id");

      if (upsertError) {
        errors.push(`Página ${page}: ${upsertError.message}`);
      } else {
        synced += data?.length || batch.length;
      }
    }

    page++;
  }

  await supabase.from("crm_integration_logs").insert({
    company_id: companyId,
    entity_type: "omie_sync_clients",
    action: "sync",
    status: errors.length > 0 ? "partial" : "success",
    details: { synced, errors, total_pages: totalPages },
  } as any);

  return { synced, errors, total_pages: totalPages };
}

async function parseServiceDescriptionWithAI(
  text: string,
  supabaseClient: any,
  companyId: string,
  clientId?: string
): Promise<Record<string, any>> {
  const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
  if (!LOVABLE_API_KEY || !text.trim()) return {};

  try {
    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          {
            role: "system",
            content: `You are a data extraction agent. Extract structured information from a Brazilian service order description. The text may contain fields like vessel name, team members, date, location, requester, supervisor, coordinator, and scope/description of work. Extract whatever is available. Dates are in DD/MM/YYYY format. Names may be first names only.`,
          },
          { role: "user", content: text },
        ],
        tools: [
          {
            type: "function",
            function: {
              name: "extract_service_data",
              description: "Extract structured data from a service order description",
              parameters: {
                type: "object",
                properties: {
                  vessel_name: { type: "string", description: "Name of the vessel/ship" },
                  team_members: {
                    type: "array",
                    items: { type: "string" },
                    description: "Names of team members/technicians",
                  },
                  service_date: { type: "string", description: "Date in YYYY-MM-DD format" },
                  service_time: { type: "string", description: "Time in HH:MM format if available" },
                  location: { type: "string", description: "Location/address of the service" },
                  requester_name: { type: "string", description: "Name of the person who requested the service" },
                  supervisor_name: { type: "string", description: "Name of the supervisor" },
                  coordinator_name: { type: "string", description: "Name of the coordinator" },
                  scope_description: { type: "string", description: "Description of the work scope, what services will be performed" },
                },
                required: [],
                additionalProperties: false,
              },
            },
          },
        ],
        tool_choice: { type: "function", function: { name: "extract_service_data" } },
      }),
    });

    if (!response.ok) {
      console.error("AI Gateway error:", response.status, await response.text());
      return {};
    }

    const aiResult = await response.json();
    const toolCall = aiResult.choices?.[0]?.message?.tool_calls?.[0];
    if (!toolCall?.function?.arguments) return {};

    const extracted = JSON.parse(toolCall.function.arguments);
    console.log("AI extracted data:", JSON.stringify(extracted));

    const result: Record<string, any> = {};

    // Match team members to local technicians
    if (extracted.team_members?.length > 0) {
      const matchedTechs: { id: string; name: string }[] = [];
      for (const memberName of extracted.team_members) {
        const { data: techMatch } = await supabaseClient
          .from("technicians")
          .select("id, profiles:user_id(full_name)")
          .eq("company_id", companyId)
          .eq("active", true);

        if (techMatch) {
          const found = techMatch.find((t: any) => {
            const fullName = t.profiles?.full_name || "";
            return fullName.toLowerCase().includes(memberName.toLowerCase()) ||
              memberName.toLowerCase().includes(fullName.split(" ")[0]?.toLowerCase());
          });
          if (found) matchedTechs.push({ id: found.id, name: found.profiles?.full_name });
        }
      }
      if (matchedTechs.length > 0) result.matchedTechnicians = matchedTechs;
    }

    // Match requester to client contacts
    if (extracted.requester_name && clientId) {
      const { data: contacts } = await supabaseClient
        .from("client_contacts")
        .select("id, name")
        .eq("client_id", clientId);

      if (contacts) {
        const found = contacts.find((c: any) =>
          c.name.toLowerCase().includes(extracted.requester_name.toLowerCase()) ||
          extracted.requester_name.toLowerCase().includes(c.name.split(" ")[0]?.toLowerCase())
        );
        if (found) result.matchedRequester = { id: found.id, name: found.name };
      }
    }

    // Match supervisor and coordinator to profiles with coordinator role
    const matchCoordinator = async (name: string, field: string) => {
      if (!name) return;
      const { data: coordRoles } = await supabaseClient
        .from("user_roles")
        .select("user_id")
        .eq("role", "coordinator");

      if (coordRoles?.length) {
        const userIds = coordRoles.map((r: any) => r.user_id);
        const { data: profiles } = await supabaseClient
          .from("profiles")
          .select("id, full_name")
          .in("id", userIds)
          .eq("company_id", companyId);

        if (profiles) {
          const found = profiles.find((p: any) =>
            p.full_name.toLowerCase().includes(name.toLowerCase()) ||
            name.toLowerCase().includes(p.full_name.split(" ")[0]?.toLowerCase())
          );
          if (found) result[field] = { id: found.id, name: found.full_name };
        }
      }
    };

    await matchCoordinator(extracted.supervisor_name, "matchedSupervisor");
    await matchCoordinator(extracted.coordinator_name, "matchedCoordinator");

    // Match task types from scope
    if (extracted.scope_description) {
      const { data: taskTypesData } = await supabaseClient
        .from("task_types")
        .select("id, name")
        .eq("company_id", companyId);

      if (taskTypesData) {
        const matchedTypes = taskTypesData.filter((tt: any) => {
          const ttName = tt.name.toLowerCase();
          const scope = extracted.scope_description.toLowerCase();
          return scope.includes(ttName) || ttName.split(" ").some((w: string) => w.length > 3 && scope.includes(w));
        });
        if (matchedTypes.length > 0) result.matchedTaskTypes = matchedTypes.map((t: any) => ({ id: t.id, name: t.name }));
      }
      result.scopeDescription = extracted.scope_description;
    }

    // Direct fields
    if (extracted.service_date) {
      const time = extracted.service_time || "08:00";
      result.serviceDateTime = `${extracted.service_date}T${time}`;
    }
    if (extracted.location) result.location = extracted.location;

    return result;
  } catch (err) {
    console.error("AI parsing error:", err);
    return {};
  }
}

async function handleConsultOrder(creds: OmieCredentials, params: any, supabase: any, companyId: string) {
  if (!params?.nCodOS && !params?.cCodIntOS && !params?.cNumOS) {
    throw new Error("nCodOS, cCodIntOS ou cNumOS é obrigatório");
  }
  
  const consultParams: any = {};
  if (params.nCodOS) consultParams.nCodOS = Number(params.nCodOS);
  if (params.cCodIntOS) consultParams.cCodIntOS = params.cCodIntOS;
  if (params.cNumOS) consultParams.cNumOS = String(params.cNumOS);

  const result = await callOmie("/servicos/os/", "ConsultarOS", consultParams, creds);

  // Log raw Omie response structure for debugging
  console.log("=== OMIE RAW RESPONSE KEYS ===", JSON.stringify(Object.keys(result)));
  
  // Extract service description from multiple possible Omie fields
  const servicosPrestados = result?.ServicosPrestados || [];
  console.log("=== ServicosPrestados ===", JSON.stringify(servicosPrestados).substring(0, 2000));

  let serviceDescription = "";
  if (servicosPrestados.length > 0) {
    // Try multiple field name variations used by Omie API
    serviceDescription = servicosPrestados
      .map((s: any) => s.cDescServ || s.cDescricao || s.cDescrServico || s.descricao || s.cDescricaoServico || "")
      .filter(Boolean)
      .join("\n");
  }

  // Fallback: check InformacoesAdicionais and Observacoes
  if (!serviceDescription) {
    const infoAdicional = result?.InformacoesAdicionais?.cDadosAdicionaisNF || "";
    const observacoes = result?.Observacoes?.cObsOS || result?.Observacoes?.cObservacao || "";
    serviceDescription = [infoAdicional, observacoes].filter(Boolean).join("\n");
    console.log("=== Fallback description sources ===", { infoAdicional: infoAdicional.substring(0, 200), observacoes: observacoes.substring(0, 200) });
  }

  // Additional fallback: check Descricao at root or Cabecalho level
  if (!serviceDescription) {
    serviceDescription = result?.cDescricaoOS || result?.Cabecalho?.cDescricaoOS || "";
  }

  console.log("=== EXTRACTED SERVICE DESCRIPTION ===", serviceDescription.substring(0, 500));
  result.serviceDescription = serviceDescription;

  // Enrich with local client data
  const nCodCli = result?.Cabecalho?.nCodCli;
  if (nCodCli) {
    const { data: localClient } = await supabase
      .from("clients")
      .select("id, name")
      .eq("company_id", companyId)
      .eq("omie_client_id", nCodCli)
      .maybeSingle();
    if (localClient) {
      result.localClient = localClient;

      // Try to find vessel from service description
      if (serviceDescription) {
        const vesselMatch = serviceDescription.match(/embarca[çc][ãa]o\s*[:;-]\s*(.+)/i);
        if (vesselMatch) {
          const vesselName = vesselMatch[1].trim().split(/[\n\r,;]/)[0].trim();
          if (vesselName) {
            const { data: localVessel } = await supabase
              .from("vessels")
              .select("id, name")
              .eq("client_id", localClient.id)
              .ilike("name", `%${vesselName}%`)
              .maybeSingle();
            if (localVessel) {
              result.localVessel = localVessel;
            }
          }
        }
      }
    }
  }

  // AI-powered extraction from service description
  if (serviceDescription.trim()) {
    try {
      console.log("=== CALLING AI PARSER ===");
      const parsedData = await parseServiceDescriptionWithAI(
        serviceDescription,
        supabase,
        companyId,
        result.localClient?.id
      );
      console.log("=== AI PARSED DATA ===", JSON.stringify(parsedData));
      result.parsedData = parsedData;
    } catch (err) {
      console.error("AI parsing failed, continuing without:", err);
    }
  } else {
    console.log("=== NO SERVICE DESCRIPTION FOUND, SKIPPING AI ===");
  }

  return result;
}

async function handleAttachFile(creds: OmieCredentials, params: any) {
  if (!params?.nCodOS || !params?.cNomeArquivo || !params?.cConteudoBase64) {
    throw new Error("nCodOS, cNomeArquivo e cConteudoBase64 são obrigatórios");
  }

  const result = await callOmie("/servicos/os/", "IncluirAnexo", {
    nCodOS: params.nCodOS,
    cCodIntOS: params.cCodIntOS || "",
    cNomeArquivo: params.cNomeArquivo,
    cConteudoBase64: params.cConteudoBase64,
    cMimeType: params.cMimeType || "application/pdf",
    cTabela: "os-servico",
  }, creds);
  return result;
}

async function handleSaveCredentials(supabase: any, companyId: string, params: any) {
  const { error } = await supabase
    .from("companies")
    .update({
      omie_app_key: params.app_key || null,
      omie_app_secret: params.app_secret || null,
      omie_sync_enabled: params.sync_enabled ?? false,
    })
    .eq("id", companyId);

  if (error) throw new Error("Erro ao salvar credenciais: " + error.message);
  return { success: true };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userId = user.id;

    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("company_id")
      .eq("id", userId)
      .single();

    if (!profile?.company_id) {
      throw new Error("Empresa não encontrada para o usuário");
    }

    const companyId = profile.company_id;
    const body = await req.json();
    const { action, params } = body;

    let result: any;

    if (action === "save_credentials") {
      result = await handleSaveCredentials(supabaseAdmin, companyId, params);
    } else {
      const { data: company } = await supabaseAdmin
        .from("companies")
        .select("omie_app_key, omie_app_secret")
        .eq("id", companyId)
        .single();

      if (!company?.omie_app_key || !company?.omie_app_secret) {
        throw new Error("Credenciais Omie não configuradas");
      }

      const creds: OmieCredentials = {
        app_key: company.omie_app_key,
        app_secret: company.omie_app_secret,
      };

      switch (action) {
        case "test_connection":
          result = await handleTestConnection(creds);
          break;
        case "list_clients":
          result = await handleListClients(creds, params);
          break;
        case "sync_clients":
          result = await handleSyncClients(creds, supabaseAdmin, companyId);
          break;
        case "consult_order":
          result = await handleConsultOrder(creds, params, supabaseAdmin, companyId);
          break;
        case "attach_file":
          result = await handleAttachFile(creds, params);
          break;
        default:
          throw new Error(`Ação desconhecida: ${action}`);
      }
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    console.error("omie-proxy error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Erro interno" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
