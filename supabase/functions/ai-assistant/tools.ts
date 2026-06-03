// Tool catalog for the AI assistant. Each tool maps to a SELECT against a
// public table (executed with service_role) filtered by company_id, and is
// gated by a per-role capability map.

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
  | "purchase_requests"
  | "finance_payables"
  | "finance_receivables"
  | "hr_employees"
  | "hr_absences"
  | "quality_ncrs"
  | "quality_audits"
  | "corp_requests"
  | "knowledge_base"
  | "measurements";

const ALL: Module[] = [
  "service_orders", "technicians", "clients", "vessels",
  "crm_leads", "crm_opportunities", "crm_sales", "crm_products", "crm_recurrences", "crm_tasks",
  "purchase_requests", "finance_payables", "finance_receivables",
  "hr_employees", "hr_absences", "quality_ncrs", "quality_audits",
  "corp_requests", "knowledge_base", "measurements",
];

const COORDINATOR: Module[] = [
  "service_orders", "technicians", "clients", "vessels",
  "crm_leads", "crm_opportunities", "crm_sales", "crm_products", "crm_recurrences", "crm_tasks",
  "purchase_requests", "quality_ncrs",
  "corp_requests", "knowledge_base", "measurements",
];

export const ROLE_MODULES: Record<string, Module[]> = {
  technician: ["service_orders", "knowledge_base"],
  coordinator: COORDINATOR,
  admin: COORDINATOR,
  manager: ALL,
  director: ALL,
  super_admin: ALL,
  hr: ["hr_employees", "hr_absences", "corp_requests", "knowledge_base"],
  commercial: ["crm_leads", "crm_opportunities", "crm_sales", "crm_products", "crm_recurrences", "crm_tasks", "clients", "vessels", "knowledge_base"],
  compras: ["purchase_requests", "knowledge_base", "corp_requests"],
  financeiro: ["finance_payables", "finance_receivables", "knowledge_base", "corp_requests"],
  qualidade: ["quality_ncrs", "quality_audits", "knowledge_base", "corp_requests"],
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
  quality_ncrs: "Não-conformidades (Qualidade)",
  quality_audits: "Auditorias (Qualidade)",
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
  supabase: any;
  companyId?: string;
  userId?: string;
  role: string;
}

const LIMIT = 25;

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
      description: "Lista leads comerciais (site/pipeline). Status válidos (em INGLÊS na coluna): 'new', 'contacted', 'qualified', 'converted', 'discarded'. IMPORTANTE: quando o usuário disser 'lead novo/novos', use status='new' (refere-se ao funil), NUNCA use since_days. since_days é apenas para recortes temporais explícitos como 'últimos 7 dias'.",
      table: "public_site_leads",
      fields: ["id", "name", "email", "phone", "company_name", "status", "source", "created_at"],
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
          description: "Busca conhecimento interno (manuais, procedimentos, FAQs).",
          parameters: {
            type: "object",
            properties: { query: { type: "string", description: "Termos de busca" } },
            required: ["query"],
          },
        },
      },
      handler: async (args, ctx) => {
        const q = String(args?.query ?? "").trim();
        if (!q) return { error: "query vazio" };
        const { data } = await ctx.supabase
          .from("crm_knowledge_base")
          .select("id, title, content, segment, priority, tags")
          .or(`title.ilike.%${q}%,content.ilike.%${q}%`)
          .limit(10);
        return {
          count: data?.length ?? 0,
          rows: (data ?? []).map((r: any) => ({
            title: r.title,
            segment: r.segment,
            excerpt: typeof r.content === "string" ? r.content.slice(0, 400) : null,
            tags: r.tags,
          })),
        };
      },
    },
  ];
}

export function getToolsForRole(role: string): { specs: any[]; map: Map<string, ToolDef> } {
  const allowed = new Set(modulesForRole(role));
  const catalog = buildToolCatalog().filter(t => allowed.has(t.module));
  const map = new Map<string, ToolDef>();
  for (const t of catalog) map.set(t.spec.function.name, t);
  return { specs: catalog.map(t => t.spec), map };
}
