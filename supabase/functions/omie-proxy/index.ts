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

async function getCredentials(supabase: any, userId: string): Promise<OmieCredentials> {
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("company_id")
    .eq("id", userId)
    .single();

  if (profileError || !profile?.company_id) {
    throw new Error("Perfil ou empresa não encontrados");
  }

  const { data: company, error: companyError } = await supabase
    .from("companies")
    .select("omie_app_key, omie_app_secret, omie_sync_enabled")
    .eq("id", profile.company_id)
    .single();

  if (companyError || !company) {
    throw new Error("Empresa não encontrada");
  }

  if (!company.omie_app_key || !company.omie_app_secret) {
    throw new Error("Credenciais Omie não configuradas");
  }

  return { app_key: company.omie_app_key, app_secret: company.omie_app_secret };
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
    if (!res.ok) {
      throw new Error(`Omie API error ${res.status}: ${text.substring(0, 200)}`);
    }
    throw new Error(`Resposta inválida do Omie: ${text.substring(0, 200)}`);
  }

  // Handle REDUNDANT error with automatic retry
  if (parsed.faultstring && parsed.faultstring.includes("REDUNDANT") && retryCount < 1) {
    console.log("Omie REDUNDANT error detected, waiting 10s before retry...");
    await new Promise(resolve => setTimeout(resolve, 10000));
    return callOmie(endpoint, call, params, creds, retryCount + 1);
  }

  if (!res.ok) {
    const faultMsg = parsed.faultstring || text.substring(0, 200);
    throw new Error(`Omie API error ${res.status}: ${faultMsg}`);
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

async function handleListOrders(creds: OmieCredentials, params: any) {
  const page = params?.page || 1;
  const result = await callOmie("/servicos/os/", "ListarOS", {
    pagina: page,
    registros_por_pagina: 100,
    apenas_importado_api: "N",
  }, creds);
  return {
    orders: result.osCadastro || [],
    total: result.total_de_registros || 0,
    pages: result.total_de_paginas || 0,
    current_page: page,
  };
}

async function handleSearchOrders(creds: OmieCredentials, params: any) {
  const searchTerm = (params?.search || "").toLowerCase().trim();
  if (!searchTerm) {
    return handleListOrders(creds, { page: 1 });
  }

  const allMatches: any[] = [];
  let page = 1;
  let totalPages = 1;
  const maxPages = 10; // safety limit

  while (page <= totalPages && page <= maxPages) {
    const result = await callOmie("/servicos/os/", "ListarOS", {
      pagina: page,
      registros_por_pagina: 100,
      apenas_importado_api: "N",
    }, creds);

    totalPages = result.total_de_paginas || 1;
    const orders = result.osCadastro || [];

    for (const order of orders) {
      const cab = order.Cabecalho || {};
      const info = order.InformacoesAdicionais || {};
      const numOS = (cab.cNumOS || "").toLowerCase();
      const codOS = (cab.nCodOS?.toString() || "");
      const clientName = (info.cNomeCliente || "").toLowerCase();

      if (
        numOS.includes(searchTerm) ||
        codOS.includes(searchTerm) ||
        clientName.includes(searchTerm)
      ) {
        allMatches.push(order);
      }
    }

    // If we found results on this page, likely enough
    if (allMatches.length >= 20) break;

    page++;
  }

  return {
    orders: allMatches,
    total: allMatches.length,
    pages: 1,
    current_page: 1,
    searched_pages: page,
  };
}

async function handleConsultOrder(creds: OmieCredentials, params: any) {
  if (!params?.nCodOS && !params?.cCodIntOS) {
    throw new Error("nCodOS ou cCodIntOS é obrigatório");
  }
  const consultParams: any = {};
  if (params.nCodOS) consultParams.nCodOS = params.nCodOS;
  if (params.cCodIntOS) consultParams.cCodIntOS = params.cCodIntOS;

  const result = await callOmie("/servicos/os/", "ConsultarOS", consultParams, creds);
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

    // Get company_id
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
      // All other actions need Omie credentials
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
        case "list_orders":
          result = await handleListOrders(creds, params);
          break;
        case "search_orders":
          result = await handleSearchOrders(creds, params);
          break;
        case "consult_order":
          result = await handleConsultOrder(creds, params);
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
