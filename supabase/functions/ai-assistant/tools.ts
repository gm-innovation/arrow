// Tool catalog for the AI assistant. Each tool maps to a SELECT against a
// public table (executed with service_role) filtered by company_id, and is
// gated by a per-role capability map.

import { signConfirmToken, verifyConfirmToken } from "../_shared/ai-confirm-token.ts";


export type Role =
  | "technician"
  | "coordinator"
  | "manager"
  | "director"
  | "hr"
  | "commercial"
  | "compras"
  | "financeiro"
  | "qualidade"
  | "super_admin"
  | "admin"; // legacy alias for coordinator

// Module names the user can talk about
export type Module =
  | "service_orders"
  | "technicians"
  | "clients"
  | "vessels"
  | "crm_leads"
  | "crm_opportunities"
  | "crm_sales"
  | "crm_products"
  | "crm_recurrences"
  | "crm_tasks"
  | "crm_buyers"
  | "purchase_requests"
  | "finance_payables"
  | "finance_receivables"
  | "hr_employees"
  | "hr_absences"
  | "hr_vacation_requests"
  | "hr_health_exams"
  | "quality_ncrs"
  | "quality_audits"
  | "quality_documents"
  | "quality_company_documents"
  | "corp_requests"
  | "knowledge_base"
  | "measurements";

const ALL: Module[] = [
  "service_orders", "technicians", "clients", "vessels",
  "crm_leads", "crm_opportunities", "crm_sales", "crm_products", "crm_recurrences", "crm_tasks", "crm_buyers",
  "purchase_requests", "finance_payables", "finance_receivables",
  "hr_employees", "hr_absences", "hr_vacation_requests", "hr_health_exams",
  "quality_ncrs", "quality_audits", "quality_documents", "quality_company_documents",
  "corp_requests", "knowledge_base", "measurements",
];

const COORDINATOR: Module[] = [
  "service_orders", "technicians", "clients", "vessels",
  "crm_leads", "crm_opportunities", "crm_sales", "crm_products", "crm_recurrences", "crm_tasks", "crm_buyers",
  "purchase_requests", "quality_ncrs", "quality_documents",
  "corp_requests", "knowledge_base", "measurements",
];

export const ROLE_MODULES: Record<string, Module[]> = {
  technician: ["service_orders", "knowledge_base"],
  coordinator: COORDINATOR,
  admin: COORDINATOR,
  manager: ALL,
  director: ALL,
  super_admin: ALL,
  hr: ["hr_employees", "hr_absences", "hr_vacation_requests", "hr_health_exams", "corp_requests", "quality_documents", "knowledge_base"],
  commercial: ["crm_leads", "crm_opportunities", "crm_sales", "crm_products", "crm_recurrences", "crm_tasks", "crm_buyers", "clients", "vessels", "knowledge_base"],
  marketing: ["crm_leads", "crm_opportunities", "crm_sales", "crm_products", "crm_recurrences", "crm_tasks", "crm_buyers", "clients", "vessels", "knowledge_base"],
  compras: ["purchase_requests", "knowledge_base", "corp_requests"],
  financeiro: ["finance_payables", "finance_receivables", "knowledge_base", "corp_requests"],
  qualidade: ["quality_ncrs", "quality_audits", "quality_documents", "quality_company_documents", "knowledge_base", "corp_requests"],
};

export const MODULE_LABELS: Record<Module, string> = {
  service_orders: "Ordens de Serviço",
  technicians: "Técnicos e disponibilidade",
  clients: "Clientes",
  vessels: "Embarcações",
  crm_leads: "Leads (CRM)",
  crm_opportunities: "Oportunidades (CRM)",
  crm_sales: "Vendas (CRM)",
  crm_products: "Produtos (CRM)",
  crm_recurrences: "Recorrências de cliente (CRM)",
  crm_tasks: "Tarefas comerciais",
  purchase_requests: "Solicitações de compra",
  finance_payables: "Contas a pagar",
  finance_receivables: "Contas a receber",
  hr_employees: "Colaboradores (RH)",
  hr_absences: "Ausências (RH)",
  hr_vacation_requests: "Solicitações de férias (RH)",
  hr_health_exams: "Exames ocupacionais (RH)",
  crm_buyers: "Compradores (CRM)",
  quality_ncrs: "Não-conformidades (Qualidade)",
  quality_audits: "Auditorias (Qualidade)",
  quality_documents: "Lista Mestra de Documentos (Qualidade)",
  quality_company_documents: "Documentos da Empresa (Qualidade)",
  corp_requests: "Solicitações corporativas",
  knowledge_base: "Base de conhecimento",
  measurements: "Medições de OS",
};

export function modulesForRole(role: string): Module[] {
  return ROLE_MODULES[role] ?? [];
}

// Tool definitions – one per module (some modules expose more than one tool)
interface ToolDef {
  module: Module;
  spec: any; // OpenAI tool-calling spec
  handler: (args: any, ctx: ToolCtx) => Promise<any>;
}

export interface ToolCtx {
  supabase: any;          // service-role client (read + audit log)
  userSupabase?: any;     // JWT-authenticated client (writes go through RLS)
  companyId?: string;
  userId?: string;
  role: string;
  agentId?: string;
  writeActions?: Record<string, { create?: boolean; update?: boolean; delete?: boolean }>;
}

function isWriteAllowed(ctx: ToolCtx, table: string, action: "create" | "update" | "delete"): boolean {
  const cfg = ctx.writeActions?.[table];
  if (!cfg) return true; // default retrocompatível
  return cfg[action] !== false;
}
const ACTION_PT = { create: "criar", update: "editar", delete: "excluir" } as const;
function writeDeniedMsg(table: string, action: "create" | "update" | "delete") {
  return { error: `Esta assistente não está autorizada a ${ACTION_PT[action]} em ${table}. Peça ao super admin para habilitar em Configurações do agente → Ações de Escrita.` };
}

const LIMIT = 25;

// ---- audit log helper ----
async function logAction(ctx: ToolCtx, entry: {
  tool: string; table: string; row_id?: string | null;
  action: "create" | "update" | "delete";
  before?: any; after?: any; success: boolean; error?: string | null;
}) {
  try {
    await ctx.supabase.from("ai_assistant_actions").insert({
      user_id: ctx.userId ?? null,
      company_id: ctx.companyId ?? null,
      role: ctx.role,
      agent_id: ctx.agentId ?? null,
      tool_name: entry.tool,
      table_name: entry.table,
      row_id: entry.row_id ?? null,
      action: entry.action,
      payload_before: entry.before ?? null,
      payload_after: entry.after ?? null,
      success: entry.success,
      error_message: entry.error ?? null,
    });
  } catch (e) { console.error("audit log fail", e); }
}

function pickFields<T extends Record<string, any>>(rows: T[] | null | undefined, fields: string[]): any[] {
  if (!rows) return [];
  return rows.map(r => {
    const out: Record<string, any> = {};
    for (const f of fields) {
      const v = (r as any)[f];
      if (v !== undefined) out[f] = typeof v === "string" && v.length > 300 ? v.slice(0, 300) + "…" : v;
    }
    return out;
  });
}

// ---- tool factory helpers ----
function basicQueryTool(opts: {
  module: Module;
  name: string;
  description: string;
  table: string;
  fields: string[];
  searchFields?: string[];
  statusField?: string;
  dateField?: string;
  extraSelect?: string;
}): ToolDef {
  return {
    module: opts.module,
    spec: {
      type: "function",
      function: {
        name: opts.name,
        description: opts.description,
        parameters: {
          type: "object",
          properties: {
            search: { type: "string", description: "Busca textual" },
            status: { type: "string", description: "Filtro de status" },
            since_days: { type: "number", description: "Apenas para intervalos temporais EXPLÍCITOS do usuário (ex.: 'últimos 7 dias', 'este mês', 'hoje'). NÃO usar para a palavra 'novo/novos' — isso é status, não data. Se o usuário não mencionar período, NÃO envie este parâmetro." },
            limit: { type: "number", description: `Máximo de resultados (padrão ${LIMIT})` },
          },
        },
      },
    },
    handler: async (args, ctx) => {
      if (!ctx.companyId && ctx.role !== "super_admin") return { error: "company_id ausente" };
      const select = opts.extraSelect ?? opts.fields.join(", ");
      let q = ctx.supabase.from(opts.table).select(select).limit(Math.min(args?.limit ?? LIMIT, 50));
      if (ctx.companyId) q = q.eq("company_id", ctx.companyId);
      if (args?.status && opts.statusField) q = q.eq(opts.statusField, args.status);
      if (args?.since_days && opts.dateField) {
        const since = new Date(Date.now() - args.since_days * 86400000).toISOString();
        q = q.gte(opts.dateField, since);
      }
      if (args?.search && opts.searchFields?.length) {
        const ors = opts.searchFields.map(f => `${f}.ilike.%${args.search}%`).join(",");
        q = q.or(ors);
      }
      if (opts.dateField) q = q.order(opts.dateField, { ascending: false });
      const { data, error } = await q;
      if (error) return { error: error.message };
      return { count: data?.length ?? 0, rows: pickFields(data as any, opts.fields) };
    },
  };
}

// ---- catalog ----
export function buildToolCatalog(): ToolDef[] {
  return [
    basicQueryTool({
      module: "service_orders",
      name: "query_service_orders",
      description: "Lista ordens de serviço da empresa com filtros opcionais (status, período, busca por número/cliente).",
      table: "service_orders",
      fields: ["id", "order_number", "status", "scheduled_date", "created_at", "client_reference"],
      searchFields: ["order_number", "client_reference"],
      statusField: "status",
      dateField: "created_at",
    }),
    {
      module: "technicians",
      spec: {
        type: "function",
        function: {
          name: "query_technicians",
          description: "Lista técnicos ativos da empresa com especialidade e telefone.",
          parameters: { type: "object", properties: { search: { type: "string" } } },
        },
      },
      handler: async (args, ctx) => {
        if (!ctx.companyId) return { error: "company_id ausente" };
        let q = ctx.supabase
          .from("technicians")
          .select("id, specialty, active, profiles:user_id(full_name, phone)")
          .eq("company_id", ctx.companyId)
          .eq("active", true)
          .limit(50);
        const { data, error } = await q;
        if (error) return { error: error.message };
        let rows = (data ?? []).map((t: any) => ({
          id: t.id,
          name: t.profiles?.full_name,
          phone: t.profiles?.phone,
          specialty: t.specialty,
        }));
        if (args?.search) {
          const s = String(args.search).toLowerCase();
          rows = rows.filter(r => (r.name ?? "").toLowerCase().includes(s) || (r.specialty ?? "").toLowerCase().includes(s));
        }
        return { count: rows.length, rows };
      },
    },
    basicQueryTool({
      module: "clients",
      name: "query_clients",
      description: "Lista clientes da empresa (nome, CNPJ, status).",
      table: "clients",
      fields: ["id", "name", "cnpj", "status", "city", "state"],
      searchFields: ["name", "cnpj"],
      statusField: "status",
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "vessels",
      name: "query_vessels",
      description: "Lista embarcações cadastradas.",
      table: "vessels",
      fields: ["id", "name", "imo", "flag", "vessel_type"],
      searchFields: ["name", "imo"],
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "crm_leads",
      name: "query_crm_leads",
      description: "Lista leads comerciais (site/pipeline). Retorna também 'message' (texto livre da solicitação do lead) e 'items' (produtos/serviços de interesse) — use esses campos para responder follow-ups sobre 'o que cada lead pediu' / 'quais as solicitações'. Status válidos (em INGLÊS na coluna): 'new', 'contacted', 'qualified', 'converted', 'discarded'. IMPORTANTE: quando o usuário disser 'lead novo/novos', use status='new' (refere-se ao funil), NUNCA use since_days. since_days é apenas para recortes temporais explícitos como 'últimos 7 dias'.",
      table: "public_site_leads",
      fields: ["id", "name", "email", "phone", "company_name", "status", "source", "type", "message", "items", "created_at"],
      searchFields: ["name", "email", "company_name"],
      statusField: "status",
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "crm_opportunities",
      name: "query_crm_opportunities",
      description: "Lista oportunidades comerciais com estágio, valor estimado e responsável.",
      table: "crm_opportunities",
      fields: ["id", "title", "stage", "estimated_value", "expected_close_date", "created_at"],
      searchFields: ["title"],
      statusField: "stage",
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "crm_sales",
      name: "query_crm_sales",
      description: "Lista vendas registradas no CRM.",
      table: "crm_sales",
      fields: ["id", "sale_number", "status", "total_value", "sold_at", "created_at"],
      searchFields: ["sale_number"],
      statusField: "status",
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "crm_products",
      name: "query_crm_products",
      description: "Lista produtos/serviços do catálogo comercial.",
      table: "crm_products",
      fields: ["id", "name", "sku", "category", "unit_price", "lead_time_days"],
      searchFields: ["name", "sku", "category"],
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "crm_recurrences",
      name: "query_crm_recurrences",
      description: "Lista recorrências contratuais de clientes (renovações).",
      table: "crm_client_recurrences",
      fields: ["id", "title", "frequency", "next_due_date", "status"],
      searchFields: ["title"],
      statusField: "status",
      dateField: "next_due_date",
    }),
    basicQueryTool({
      module: "crm_tasks",
      name: "query_crm_tasks",
      description: "Lista tarefas comerciais (follow-ups, ligações).",
      table: "crm_tasks",
      fields: ["id", "title", "status", "due_date", "priority", "assigned_to"],
      searchFields: ["title"],
      statusField: "status",
      dateField: "due_date",
    }),
    basicQueryTool({
      module: "purchase_requests",
      name: "query_purchase_requests",
      description: "Lista solicitações de compra com status e total.",
      table: "purchase_requests",
      fields: ["id", "request_number", "status", "total_value", "requested_at", "created_at"],
      searchFields: ["request_number"],
      statusField: "status",
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "finance_payables",
      name: "query_finance_payables",
      description: "Lista contas a pagar.",
      table: "finance_payables",
      fields: ["id", "description", "amount", "status", "due_date", "paid_at"],
      searchFields: ["description"],
      statusField: "status",
      dateField: "due_date",
    }),
    basicQueryTool({
      module: "finance_receivables",
      name: "query_finance_receivables",
      description: "Lista contas a receber.",
      table: "finance_receivables",
      fields: ["id", "description", "amount", "status", "due_date", "received_at"],
      searchFields: ["description"],
      statusField: "status",
      dateField: "due_date",
    }),
    {
      module: "hr_employees",
      spec: {
        type: "function",
        function: {
          name: "query_hr_employees",
          description: "Lista colaboradores da empresa (perfis).",
          parameters: { type: "object", properties: { search: { type: "string" } } },
        },
      },
      handler: async (args, ctx) => {
        if (!ctx.companyId) return { error: "company_id ausente" };
        let q = ctx.supabase
          .from("profiles")
          .select("id, full_name, email, phone, position")
          .eq("company_id", ctx.companyId)
          .limit(50);
        if (args?.search) q = q.or(`full_name.ilike.%${args.search}%,email.ilike.%${args.search}%,position.ilike.%${args.search}%`);
        const { data, error } = await q;
        if (error) return { error: error.message };
        return { count: data?.length ?? 0, rows: data };
      },
    },
    basicQueryTool({
      module: "hr_absences",
      name: "query_hr_absences",
      description: "Lista ausências de técnicos (férias, atestado, folga).",
      table: "technician_absences",
      fields: ["id", "absence_type", "start_date", "end_date", "status", "reason"],
      statusField: "status",
      dateField: "start_date",
    }),
    basicQueryTool({
      module: "quality_ncrs",
      name: "query_quality_ncrs",
      description: "Lista não-conformidades (NCRs).",
      table: "quality_ncrs",
      fields: ["id", "ncr_number", "title", "status", "severity", "created_at"],
      searchFields: ["ncr_number", "title"],
      statusField: "status",
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "quality_audits",
      name: "query_quality_audits",
      description: "Lista auditorias de qualidade.",
      table: "quality_audits",
      fields: ["id", "audit_number", "title", "status", "scheduled_date", "created_at"],
      searchFields: ["audit_number", "title"],
      statusField: "status",
      dateField: "scheduled_date",
    }),
    basicQueryTool({
      module: "corp_requests",
      name: "query_corp_requests",
      description: "Lista solicitações corporativas internas.",
      table: "corp_requests",
      fields: ["id", "title", "status", "priority", "department_id", "created_at"],
      searchFields: ["title"],
      statusField: "status",
      dateField: "created_at",
    }),
    basicQueryTool({
      module: "measurements",
      name: "query_measurements",
      description: "Lista medições (boletins) de OS.",
      table: "measurements",
      fields: ["id", "service_order_id", "status", "subtotal", "total", "created_at"],
      statusField: "status",
      dateField: "created_at",
    }),
    {
      module: "knowledge_base",
      spec: {
        type: "function",
        function: {
          name: "search_knowledge_base",
          description: "Busca conhecimento interno (manuais, procedimentos, FAQs, artigos de qualidade). Se 'query' for omitido ou vazio, retorna os itens mais recentes.",
          parameters: {
            type: "object",
            properties: { query: { type: "string", description: "Termos de busca (opcional)" }, limit: { type: "number" } },
          },
        },
      },
      handler: async (args, ctx) => {
        const q = String(args?.query ?? "").trim();
        const limit = Math.min(Number(args?.limit) || 15, 30);
        let kb = ctx.supabase.from("crm_knowledge_base").select("id, title, content, segment, tags, updated_at").limit(limit).order("updated_at", { ascending: false });
        if (q) kb = kb.or(`title.ilike.%${q}%,content.ilike.%${q}%`);
        const { data: kbData } = await kb;
        return {
          count: kbData?.length ?? 0,
          rows: (kbData ?? []).map((r: any) => ({
            source: "knowledge_base",
            title: r.title, segment: r.segment,
            excerpt: typeof r.content === "string" ? r.content.slice(0, 400) : null,
            tags: r.tags,
          })),
        };
      },
    },
    // ---- Quality documents (Lista Mestra) ----
    {
      module: "quality_documents",
      spec: {
        type: "function",
        function: {
          name: "query_quality_master_list",
          description: "Lista documentos da Lista Mestra (procedimentos, políticas, manuais, formulários). Suporta filtros e resumo agregado. Use sem filtros para obter uma visão geral.",
          parameters: {
            type: "object",
            properties: {
              search: { type: "string", description: "Busca por código ou título" },
              status: { type: "string", enum: ["draft", "review", "approved", "published", "obsolete"] },
              origin: { type: "string", description: "Origem (ex.: 'safety', 'quality')" },
              limit: { type: "number", description: "Padrão 50, máx 200" },
              summary: { type: "boolean", description: "Se true, retorna contagens por status/tipo em vez da lista completa" },
            },
          },
        },
      },
      handler: async (args, ctx) => {
        if (!ctx.companyId) return { error: "company_id ausente" };
        let q = ctx.supabase.from("quality_documents")
          .select("id, code, title, revision, status, origin, next_review_date, validity_end, updated_at, document_type:quality_document_types(name, code_prefix)")
          .eq("company_id", ctx.companyId)
          .order("code", { ascending: true })
          .limit(Math.min(Number(args?.limit) || 50, 200));
        if (args?.status) q = q.eq("status", args.status);
        if (args?.origin) q = q.eq("origin", args.origin);
        if (args?.search) q = q.or(`code.ilike.%${args.search}%,title.ilike.%${args.search}%`);
        const { data, error } = await q;
        if (error) return { error: error.message };
        if (args?.summary) {
          const by_status: Record<string, number> = {};
          const by_type: Record<string, number> = {};
          for (const r of (data ?? []) as any[]) {
            by_status[r.status] = (by_status[r.status] ?? 0) + 1;
            const t = r.document_type?.name ?? "sem tipo";
            by_type[t] = (by_type[t] ?? 0) + 1;
          }
          return { total: data?.length ?? 0, by_status, by_type };
        }
        return { count: data?.length ?? 0, rows: data };
      },
    },
    {
      module: "quality_company_documents",
      spec: {
        type: "function",
        function: {
          name: "query_quality_company_documents",
          description: "Lista certificados, licenças e documentos institucionais da empresa. Pode filtrar por vencimento próximo.",
          parameters: {
            type: "object",
            properties: {
              search: { type: "string" },
              status: { type: "string", enum: ["active", "expired", "renewing", "archived"] },
              expiring_within_days: { type: "number", description: "Retorna apenas documentos vencendo em N dias" },
              limit: { type: "number" },
            },
          },
        },
      },
      handler: async (args, ctx) => {
        if (!ctx.companyId) return { error: "company_id ausente" };
        let q = ctx.supabase.from("quality_company_documents")
          .select("id, document_type, title, status, issued_at, expires_at, file_name")
          .eq("company_id", ctx.companyId)
          .order("expires_at", { ascending: true, nullsFirst: false })
          .limit(Math.min(Number(args?.limit) || 50, 100));
        if (args?.status) q = q.eq("status", args.status);
        if (args?.search) q = q.or(`title.ilike.%${args.search}%,document_type.ilike.%${args.search}%`);
        if (args?.expiring_within_days) {
          const until = new Date(Date.now() + args.expiring_within_days * 86400000).toISOString().slice(0, 10);
          q = q.lte("expires_at", until).gte("expires_at", new Date().toISOString().slice(0, 10));
        }
        const { data, error } = await q;
        if (error) return { error: error.message };
        return { count: data?.length ?? 0, rows: data };
      },
    },
    basicQueryTool({
      module: "hr_vacation_requests",
      name: "query_hr_vacation_requests",
      description: "Lista solicitações de férias.",
      table: "hr_vacation_requests",
      fields: ["id", "employee_id", "start_date", "end_date", "days", "status", "created_at"],
      statusField: "status",
      dateField: "start_date",
    }),
    basicQueryTool({
      module: "hr_health_exams",
      name: "query_hr_health_exams",
      description: "Lista exames ocupacionais (ASO) dos colaboradores.",
      table: "hr_health_exams",
      fields: ["id", "employee_id", "exam_type", "exam_date", "expires_at", "status"],
      statusField: "status",
      dateField: "exam_date",
    }),
    basicQueryTool({
      module: "crm_buyers",
      name: "query_crm_buyers",
      description: "Lista compradores/contatos de clientes no CRM.",
      table: "crm_buyers",
      fields: ["id", "name", "email", "phone", "position", "client_id", "created_at"],
      searchFields: ["name", "email"],
      dateField: "created_at",
    }),

    // ================= WRITE TOOLS =================
    ...buildWriteTools(),
  ];
}

// ---- Generic WRITE tool factory ----
// Each entry declares the table, allowed fields per action, PK column, and RLS-relying context.

interface WriteSpec {
  module: Module;
  table: string;
  pk?: string;                    // default "id"
  createFields: Record<string, { type: string; enum?: string[]; description?: string; required?: boolean }>;
  updateFields: Record<string, { type: string; enum?: string[]; description?: string }>;
  labelFn?: (row: any) => string; // for delete summary
  companyScoped?: boolean;        // default true
  ownerField?: string;            // e.g. "created_by" — set to userId on create
}

function fieldsToJsonSchema(fields: Record<string, any>) {
  const properties: Record<string, any> = {};
  const required: string[] = [];
  for (const [k, v] of Object.entries(fields)) {
    const p: any = { type: v.type };
    if (v.enum) p.enum = v.enum;
    if (v.description) p.description = v.description;
    properties[k] = p;
    if (v.required) required.push(k);
  }
  return { type: "object", properties, ...(required.length ? { required } : {}) };
}

function makeCreateTool(w: WriteSpec): ToolDef {
  return {
    module: w.module,
    spec: { type: "function", function: {
      name: `create_${w.module}`,
      description: `Cria um novo registro em ${w.table}. Só execute APÓS o usuário confirmar em linguagem natural o que vai ser criado.`,
      parameters: fieldsToJsonSchema(w.createFields),
    }},
    handler: async (args, ctx) => {
      if (!isWriteAllowed(ctx, w.table, "create")) return writeDeniedMsg(w.table, "create");
      const client = ctx.userSupabase ?? ctx.supabase;
      const payload: any = { ...args };
      if (w.companyScoped !== false && ctx.companyId) payload.company_id = ctx.companyId;
      if (w.ownerField && ctx.userId) payload[w.ownerField] = ctx.userId;
      const { data, error } = await client.from(w.table).insert(payload).select().maybeSingle();
      await logAction(ctx, {
        tool: `create_${w.module}`, table: w.table, row_id: data?.[w.pk ?? "id"] ?? null,
        action: "create", after: data ?? payload, success: !error, error: error?.message,
      });
      if (error) return { error: error.message, hint: "Se o erro for de permissão, seu perfil não pode criar neste módulo." };
      return { ok: true, created: data };
    },
  };
}

function makeUpdateTool(w: WriteSpec): ToolDef {
  const pk = w.pk ?? "id";
  const params: any = { type: "object", properties: {
    [pk]: { type: "string", description: `${pk} do registro a atualizar` },
    ...fieldsToJsonSchema(w.updateFields).properties,
  }, required: [pk] };
  return {
    module: w.module,
    spec: { type: "function", function: {
      name: `update_${w.module}`,
      description: `Atualiza campos de um registro em ${w.table}. Só execute APÓS o usuário confirmar as mudanças em linguagem natural.`,
      parameters: params,
    }},
    handler: async (args, ctx) => {
      if (!isWriteAllowed(ctx, w.table, "update")) return writeDeniedMsg(w.table, "update");
      const client = ctx.userSupabase ?? ctx.supabase;
      const { [pk]: id, ...patch } = args ?? {};
      if (!id) return { error: `${pk} é obrigatório` };
      const { data: before } = await ctx.supabase.from(w.table).select("*").eq(pk, id).maybeSingle();
      const { data, error } = await client.from(w.table).update(patch).eq(pk, id).select().maybeSingle();
      await logAction(ctx, {
        tool: `update_${w.module}`, table: w.table, row_id: String(id),
        action: "update", before, after: data ?? patch, success: !error, error: error?.message,
      });
      if (error) return { error: error.message, hint: "Se o erro for de permissão, seu perfil não pode editar este registro." };
      return { ok: true, updated: data };
    },
  };
}

function makeDeleteTool(w: WriteSpec, signToken: any, verifyToken: any): ToolDef {
  const pk = w.pk ?? "id";
  return {
    module: w.module,
    spec: { type: "function", function: {
      name: `delete_${w.module}`,
      description: `Exclui um registro em ${w.table}. FLUXO OBRIGATÓRIO EM 2 ETAPAS: (1) chame SEM confirm_token — o servidor devolve um resumo e um token; (2) mostre o resumo ao usuário, peça confirmação textual, e SÓ ENTÃO chame de novo com o mesmo id e o confirm_token recebido.`,
      parameters: { type: "object", properties: {
        [pk]: { type: "string" },
        confirm_token: { type: "string", description: "Token devolvido na primeira chamada" },
      }, required: [pk] },
    }},
    handler: async (args, ctx) => {
      if (!isWriteAllowed(ctx, w.table, "delete")) return writeDeniedMsg(w.table, "delete");
      const id = args?.[pk];
      if (!id) return { error: `${pk} é obrigatório` };
      const { data: row } = await ctx.supabase.from(w.table).select("*").eq(pk, id).maybeSingle();
      if (!row) return { error: "registro não encontrado ou sem permissão de leitura" };
      if (!args?.confirm_token) {
        const summary = w.labelFn ? w.labelFn(row) : `${w.table} #${id}`;
        const token = await signToken({ u: ctx.userId!, t: w.table, r: String(id) });
        return {
          requires_confirmation: true,
          summary: `Excluir ${summary}`,
          confirm_token: token,
          expires_in_seconds: 120,
          instruction: "Mostre o resumo ao usuário, peça 'Confirmar exclusão? (sim/não)' e só rechame esta ferramenta com o mesmo confirm_token após resposta afirmativa.",
        };
      }
      const check = await verifyToken(args.confirm_token, { u: ctx.userId!, t: w.table, r: String(id) });
      if (!check.ok) return { error: `Confirmação inválida: ${check.reason}. Reinicie o pedido de exclusão.` };
      const client = ctx.userSupabase ?? ctx.supabase;
      const { error } = await client.from(w.table).delete().eq(pk, id);
      await logAction(ctx, {
        tool: `delete_${w.module}`, table: w.table, row_id: String(id),
        action: "delete", before: row, success: !error, error: error?.message,
      });
      if (error) return { error: error.message, hint: "Se o erro for de permissão, seu perfil não pode excluir este registro." };
      return { ok: true, deleted: { [pk]: id } };
    },
  };
}

// Write specs per module
const WRITE_SPECS: WriteSpec[] = [
  {
    module: "service_orders", table: "service_orders", ownerField: "created_by",
    labelFn: r => `OS #${r.order_number ?? r.id} — status ${r.status}`,
    createFields: {
      order_number: { type: "string", description: "Número da OS" },
      client_reference: { type: "string" },
      scheduled_date: { type: "string", description: "YYYY-MM-DD" },
      status: { type: "string", enum: ["draft", "scheduled", "in_progress", "completed", "cancelled"] },
    },
    updateFields: {
      order_number: { type: "string" }, client_reference: { type: "string" },
      scheduled_date: { type: "string" },
      status: { type: "string", enum: ["draft", "scheduled", "in_progress", "completed", "cancelled"] },
    },
  },
  {
    module: "clients", table: "clients",
    labelFn: r => `Cliente "${r.name}" (${r.cnpj ?? "sem CNPJ"})`,
    createFields: {
      name: { type: "string", required: true },
      cnpj: { type: "string" }, city: { type: "string" }, state: { type: "string" },
      status: { type: "string", enum: ["active", "inactive"] },
    },
    updateFields: { name: { type: "string" }, cnpj: { type: "string" }, city: { type: "string" }, state: { type: "string" }, status: { type: "string", enum: ["active", "inactive"] } },
  },
  {
    module: "vessels", table: "vessels",
    labelFn: r => `Embarcação "${r.name}" (IMO ${r.imo ?? "—"})`,
    createFields: {
      name: { type: "string", required: true }, imo: { type: "string" },
      flag: { type: "string" }, vessel_type: { type: "string" },
    },
    updateFields: { name: { type: "string" }, imo: { type: "string" }, flag: { type: "string" }, vessel_type: { type: "string" } },
  },
  {
    module: "crm_opportunities", table: "crm_opportunities", ownerField: "created_by",
    labelFn: r => `Oportunidade "${r.title}" — estágio ${r.stage}`,
    createFields: {
      title: { type: "string", required: true },
      stage: { type: "string", description: "Estágio do pipeline" },
      estimated_value: { type: "number" },
      expected_close_date: { type: "string" },
    },
    updateFields: { title: { type: "string" }, stage: { type: "string" }, estimated_value: { type: "number" }, expected_close_date: { type: "string" } },
  },
  {
    module: "crm_tasks", table: "crm_tasks", ownerField: "created_by",
    labelFn: r => `Tarefa "${r.title}" — ${r.status}`,
    createFields: {
      title: { type: "string", required: true },
      due_date: { type: "string" },
      priority: { type: "string", enum: ["low", "medium", "high"] },
      status: { type: "string", enum: ["open", "in_progress", "done", "cancelled"] },
    },
    updateFields: { title: { type: "string" }, due_date: { type: "string" }, priority: { type: "string", enum: ["low", "medium", "high"] }, status: { type: "string", enum: ["open", "in_progress", "done", "cancelled"] } },
  },
  {
    module: "crm_buyers", table: "crm_buyers",
    labelFn: r => `Comprador "${r.name}" (${r.email ?? "sem email"})`,
    createFields: {
      name: { type: "string", required: true },
      email: { type: "string" }, phone: { type: "string" }, position: { type: "string" },
      client_id: { type: "string" },
    },
    updateFields: { name: { type: "string" }, email: { type: "string" }, phone: { type: "string" }, position: { type: "string" } },
  },
  {
    module: "crm_products", table: "crm_products",
    labelFn: r => `Produto "${r.name}"`,
    createFields: {
      name: { type: "string", required: true }, sku: { type: "string" },
      category: { type: "string" }, unit_price: { type: "number" }, lead_time_days: { type: "number" },
    },
    updateFields: { name: { type: "string" }, sku: { type: "string" }, category: { type: "string" }, unit_price: { type: "number" }, lead_time_days: { type: "number" } },
  },
  {
    module: "purchase_requests", table: "purchase_requests", ownerField: "created_by",
    labelFn: r => `Solicitação de compra #${r.request_number ?? r.id}`,
    createFields: {
      request_number: { type: "string" },
      status: { type: "string" }, total_value: { type: "number" },
    },
    updateFields: { status: { type: "string" }, total_value: { type: "number" } },
  },
  {
    module: "quality_ncrs", table: "quality_ncrs", ownerField: "created_by",
    labelFn: r => `NCR #${r.ncr_number ?? r.id} — "${r.title}"`,
    createFields: {
      title: { type: "string", required: true },
      severity: { type: "string", enum: ["low", "medium", "high", "critical"] },
      status: { type: "string" },
    },
    updateFields: { title: { type: "string" }, severity: { type: "string", enum: ["low", "medium", "high", "critical"] }, status: { type: "string" } },
  },
  {
    module: "quality_audits", table: "quality_audits", ownerField: "created_by",
    labelFn: r => `Auditoria "${r.title}" — ${r.status}`,
    createFields: {
      title: { type: "string", required: true },
      scheduled_date: { type: "string" }, status: { type: "string" },
    },
    updateFields: { title: { type: "string" }, scheduled_date: { type: "string" }, status: { type: "string" } },
  },
  {
    module: "quality_company_documents", table: "quality_company_documents", ownerField: "created_by",
    labelFn: r => `Documento da empresa "${r.title}" (${r.document_type})`,
    createFields: {
      document_type: { type: "string", required: true },
      title: { type: "string", required: true },
      issued_at: { type: "string" }, expires_at: { type: "string" },
      status: { type: "string", enum: ["active", "expired", "renewing", "archived"] },
      notes: { type: "string" },
    },
    updateFields: {
      title: { type: "string" }, issued_at: { type: "string" }, expires_at: { type: "string" },
      status: { type: "string", enum: ["active", "expired", "renewing", "archived"] }, notes: { type: "string" },
    },
  },
  {
    module: "corp_requests", table: "corp_requests", ownerField: "requester_id",
    labelFn: r => `Solicitação "${r.title}" — ${r.status}`,
    createFields: {
      title: { type: "string", required: true },
      priority: { type: "string", enum: ["low", "medium", "high"] },
      status: { type: "string" },
    },
    updateFields: { title: { type: "string" }, status: { type: "string" }, priority: { type: "string", enum: ["low", "medium", "high"] } },
  },
  {
    module: "finance_payables", table: "finance_payables",
    labelFn: r => `Conta a pagar "${r.description}" R$ ${r.amount}`,
    createFields: {
      description: { type: "string", required: true },
      amount: { type: "number", required: true },
      due_date: { type: "string" }, status: { type: "string" },
    },
    updateFields: { description: { type: "string" }, amount: { type: "number" }, due_date: { type: "string" }, status: { type: "string" } },
  },
  {
    module: "finance_receivables", table: "finance_receivables",
    labelFn: r => `Conta a receber "${r.description}" R$ ${r.amount}`,
    createFields: {
      description: { type: "string", required: true },
      amount: { type: "number", required: true },
      due_date: { type: "string" }, status: { type: "string" },
    },
    updateFields: { description: { type: "string" }, amount: { type: "number" }, due_date: { type: "string" }, status: { type: "string" } },
  },
];

function buildWriteTools(): ToolDef[] {
  const out: ToolDef[] = [];
  for (const w of WRITE_SPECS) {
    out.push(
      makeCreateTool(w),
      makeUpdateTool(w),
      makeDeleteTool(w, signConfirmToken, verifyConfirmToken),
    );
  }
  return out;
}


// ---- Universal tools available to every role ----
async function embedQuery(text: string): Promise<number[] | null> {
  const key = Deno.env.get("LOVABLE_API_KEY");
  if (!key) return null;
  try {
    const r = await fetch("https://ai.gateway.lovable.dev/v1/embeddings", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "openai/text-embedding-3-small", input: text }),
    });
    if (!r.ok) return null;
    const j = await r.json();
    return j.data?.[0]?.embedding ?? null;
  } catch { return null; }
}

const NAV_ROUTES: { keywords: string[]; label: string; path: string; roles?: string[] }[] = [
  { keywords: ["dashboard rh","rh dashboard","recursos humanos"], label: "Dashboard de RH", path: "/hr/dashboard", roles: ["hr","director","super_admin","manager"] },
  { keywords: ["colaborador","funcionario","funcionário","employee"], label: "Colaboradores", path: "/hr/employees", roles: ["hr","director","super_admin","manager"] },
  { keywords: ["ferias","férias","vacation"], label: "Gestão de Férias", path: "/hr/vacations", roles: ["hr","director","super_admin","manager"] },
  { keywords: ["aso","exame ocupacional","exame medico","exame médico"], label: "Exames ocupacionais (ASO)", path: "/hr/health-exams", roles: ["hr","director","super_admin","manager"] },
  { keywords: ["ponto","time control"], label: "Controle de Ponto", path: "/hr/time-control", roles: ["hr","director","super_admin","manager"] },
  { keywords: ["folha","payroll"], label: "Exportação de Folha", path: "/hr/payroll-export", roles: ["hr","director","super_admin","manager"] },
  { keywords: ["compliance documental","documento obrigatorio","documentos obrigatórios"], label: "Compliance documental", path: "/hr/document-compliance", roles: ["hr","director","super_admin","manager"] },
  { keywords: ["lead","oportunidade","kanban","funil"], label: "Leads & Oportunidades", path: "/commercial/opportunities" },
  { keywords: ["cliente","clientes","crm"], label: "Clientes", path: "/commercial/clients" },
  { keywords: ["venda","vendas","sales"], label: "Vendas unificadas", path: "/commercial/sales" },
  { keywords: ["ai insights","insights comercial","inteligencia comercial"], label: "Inteligência Comercial", path: "/commercial/ai-insights" },
  { keywords: ["ordem de servico","ordens de serviço","os","serviço","service order"], label: "Ordens de Serviço", path: "/admin/service-orders" },
  { keywords: ["calendario","calendário","calendar"], label: "Calendário de Serviços", path: "/admin/calendar" },
  { keywords: ["medicao","medição","measurement"], label: "Medições / Faturamento", path: "/admin/measurements" },
  { keywords: ["ncr","nao conformidade","não conformidade"], label: "Não-conformidades", path: "/quality/ncrs" },
  { keywords: ["auditoria","audit"], label: "Auditorias", path: "/quality/audits" },
  { keywords: ["lista mestra","documento qualidade","procedimento"], label: "Lista Mestra (Qualidade)", path: "/quality/documents" },
  { keywords: ["swot","contexto","hub"], label: "Hub de Contexto", path: "/quality/context" },
  { keywords: ["compra","suprimento","purchase"], label: "Solicitações de Compra", path: "/purchasing/requests" },
  { keywords: ["pagar","payable"], label: "Contas a Pagar", path: "/finance/payables" },
  { keywords: ["receber","receivable"], label: "Contas a Receber", path: "/finance/receivables" },
  { keywords: ["configuracao","configurações","conta","meu perfil","perfil"], label: "Minha Conta", path: "/settings" },
  { keywords: ["universidade","curso","treinamento"], label: "Universidade Corporativa", path: "/university" },
  { keywords: ["feed","corporativo","corp"], label: "Feed Corporativo", path: "/corp/feed" },
  { keywords: ["solicita","request"], label: "Solicitações Corporativas", path: "/corp/requests" },
];

const UNIVERSAL_TOOLS: ToolDef[] = [
  {
    module: "knowledge_base",
    spec: {
      type: "function",
      function: {
        name: "search_help",
        description: "Busca semântica na base de conhecimento do Arrow (manuais passo a passo dos módulos de RH, Qualidade, Comercial/Marketing, Coordenador, Financeiro etc.). Use SEMPRE que o usuário perguntar 'como faço', 'onde encontro', 'onde fica', 'como uso', 'passo a passo', ou pedir orientação sobre o sistema.",
        parameters: {
          type: "object",
          properties: {
            query: { type: "string", description: "Pergunta ou termos-chave em linguagem natural" },
            limit: { type: "number", description: "Máx. de trechos (padrão 5)" },
          },
          required: ["query"],
        },
      },
    },
    handler: async (args, ctx) => {
      const q = String(args?.query ?? "").trim();
      if (!q) return { error: "query obrigatória" };
      const limit = Math.min(Number(args?.limit) || 5, 10);
      const emb = await embedQuery(q);
      if (!emb) return { error: "Falha ao gerar embedding da consulta" };
      const { data, error } = await ctx.supabase.rpc("match_ai_knowledge", {
        query_embedding: `[${emb.join(",")}]`,
        p_agent_id: null,
        p_company_id: null,
        match_threshold: 0.3,
        match_count: limit,
      });
      if (error) return { error: error.message };
      const rows = (data ?? []) as any[];
      if (rows.length === 0) return { count: 0, message: "Nenhum trecho encontrado. Responda com seu melhor conhecimento geral do Arrow e ofereça abrir o manual completo." };
      // Buscar títulos das sources
      const sourceIds = [...new Set(rows.map(r => r.source_id).filter(Boolean))];
      const { data: sources } = await ctx.supabase
        .from("ai_knowledge_sources")
        .select("id,title")
        .in("id", sourceIds);
      const titleById = new Map((sources ?? []).map((s: any) => [s.id, s.title]));
      return {
        count: rows.length,
        chunks: rows.map(r => ({
          manual: titleById.get(r.source_id) ?? "Manual",
          similarity: Number(r.similarity?.toFixed?.(3) ?? r.similarity),
          content: r.content,
        })),
        instrucao: "Use estes trechos como fonte primária. Cite o manual entre parênteses e, se útil, sugira também a rota do sistema usando navigate_to.",
      };
    },
  },
  {
    module: "knowledge_base",
    spec: {
      type: "function",
      function: {
        name: "navigate_to",
        description: "Sugere ao usuário onde clicar/ir dentro do Arrow para acessar uma tela ou funcionalidade. Retorna o caminho (rota) e o nome da tela. Use após responder 'como faço X' para indicar o local exato.",
        parameters: {
          type: "object",
          properties: {
            target: { type: "string", description: "Descrição do destino (ex.: 'férias', 'kanban de leads', 'exames ASO')" },
          },
          required: ["target"],
        },
      },
    },
    handler: async (args, ctx) => {
      const t = String(args?.target ?? "").toLowerCase();
      if (!t) return { error: "target obrigatório" };
      const matches = NAV_ROUTES
        .filter(r => !r.roles || r.roles.includes(ctx.role) || ctx.role === "super_admin" || ctx.role === "director")
        .map(r => ({ r, score: r.keywords.reduce((s, k) => s + (t.includes(k) ? k.length : 0), 0) }))
        .filter(x => x.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, 3)
        .map(x => ({ label: x.r.label, path: x.r.path }));
      if (matches.length === 0) return { found: false, message: "Não encontrei uma rota específica; oriente o usuário usando o menu lateral." };
      return { found: true, suggestions: matches, instrucao: "Diga ao usuário: 'Acesse pelo menu lateral em <label>' e mostre o caminho." };
    },
  },
  {
    module: "knowledge_base",
    spec: {
      type: "function",
      function: {
        name: "create_support_ticket",
        description: "Cria um chamado (ticket) para o Super Admin. Use SEMPRE que o usuário reportar um bug, sugerir uma melhoria, fazer uma reclamação ou pedir algo que você não consegue resolver pelo Arrow. Antes de chamar, confirme com o usuário em uma frase o que vai ser registrado.",
        parameters: {
          type: "object",
          properties: {
            title: { type: "string", description: "Título curto (máx 120 chars)" },
            description: { type: "string", description: "Descrição detalhada com passos, tela, erro observado etc." },
            category: { type: "string", enum: ["bug", "feature_request", "question", "complaint", "other"] },
            priority: { type: "string", enum: ["low", "medium", "high", "critical"], description: "Padrão: medium. Use 'high'/'critical' apenas se afetar operação." },
          },
          required: ["title", "description", "category"],
        },
      },
    },
    handler: async (args, ctx) => {
      if (!ctx.userId) return { error: "usuário não autenticado" };
      const client = ctx.userSupabase ?? ctx.supabase;
      // Buscar dados do usuário
      const { data: prof } = await ctx.supabase
        .from("profiles")
        .select("full_name, email")
        .eq("id", ctx.userId)
        .maybeSingle();
      const payload = {
        user_id: ctx.userId,
        company_id: ctx.companyId ?? null,
        user_role: ctx.role,
        user_name: prof?.full_name ?? null,
        user_email: prof?.email ?? null,
        title: String(args?.title ?? "").slice(0, 200),
        description: String(args?.description ?? ""),
        category: args?.category ?? "other",
        priority: args?.priority ?? "medium",
        page_url: (ctx as any).pageUrl ?? null,
        conversation_excerpt: (ctx as any).conversationExcerpt ?? null,
      };
      const { data, error } = await client
        .from("support_tickets")
        .insert(payload)
        .select("id, ticket_number, status")
        .maybeSingle();
      if (error) return { error: error.message };
      return {
        ok: true,
        ticket_number: data?.ticket_number,
        status: data?.status,
        message: `Chamado #${data?.ticket_number} criado e encaminhado ao Super Admin. Você pode acompanhar em /account/tickets.`,
      };
    },
  },
  {
    module: "knowledge_base",
    spec: {
      type: "function",
      function: {
        name: "list_my_tickets",
        description: "Lista os chamados de suporte que o próprio usuário abriu, com status atual.",
        parameters: {
          type: "object",
          properties: {
            status: { type: "string", enum: ["open", "in_review", "in_progress", "resolved", "wont_fix"] },
            limit: { type: "number" },
          },
        },
      },
    },
    handler: async (args, ctx) => {
      if (!ctx.userId) return { error: "usuário não autenticado" };
      let q = ctx.supabase
        .from("support_tickets")
        .select("ticket_number, title, category, priority, status, created_at")
        .eq("user_id", ctx.userId)
        .order("created_at", { ascending: false })
        .limit(Math.min(Number(args?.limit) || 20, 50));
      if (args?.status) q = q.eq("status", args.status);
      const { data, error } = await q;
      if (error) return { error: error.message };
      return { count: data?.length ?? 0, rows: data };
    },
  },
];

export function getToolsForRole(role: string): { specs: any[]; map: Map<string, ToolDef> } {
  const allowed = new Set(modulesForRole(role));
  const catalog = buildToolCatalog().filter(t => allowed.has(t.module));
  const map = new Map<string, ToolDef>();
  for (const t of catalog) map.set(t.spec.function.name, t);
  // Universal tools (help/navigation) — sempre disponíveis
  for (const t of UNIVERSAL_TOOLS) map.set(t.spec.function.name, t);
  const specs = [...catalog.map(t => t.spec), ...UNIVERSAL_TOOLS.map(t => t.spec)];
  return { specs, map };
}
