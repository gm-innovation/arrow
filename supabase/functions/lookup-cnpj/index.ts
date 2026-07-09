import "https://deno.land/std@0.224.0/dotenv/load.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function digits(s: string): string {
  return (s || "").replace(/\D/g, "");
}

function validCnpj(cnpj: string): boolean {
  const d = digits(cnpj);
  if (d.length !== 14) return false;
  if (/^(\d)\1+$/.test(d)) return false;
  const calc = (base: string, weights: number[]) => {
    const sum = base.split("").reduce((acc, c, i) => acc + Number(c) * weights[i], 0);
    const r = sum % 11;
    return r < 2 ? 0 : 11 - r;
  };
  const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const d1 = calc(d.slice(0, 12), w1);
  const d2 = calc(d.slice(0, 12) + d1, w2);
  return d1 === Number(d[12]) && d2 === Number(d[13]);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    let cnpjRaw = "";
    if (req.method === "GET") {
      const url = new URL(req.url);
      cnpjRaw = url.searchParams.get("cnpj") || "";
    } else {
      const body = await req.json().catch(() => ({}));
      cnpjRaw = body?.cnpj || "";
    }

    const cnpj = digits(cnpjRaw);
    if (!validCnpj(cnpj)) {
      return new Response(
        JSON.stringify({ error: "CNPJ inválido" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Consult BrasilAPI (public, no key)
    const resp = await fetch(`https://brasilapi.com.br/api/cnpj/v1/${cnpj}`, {
      headers: { Accept: "application/json" },
    });

    if (resp.status === 404) {
      return new Response(
        JSON.stringify({ error: "CNPJ não encontrado" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!resp.ok) {
      const text = await resp.text();
      console.error("BrasilAPI error", resp.status, text);
      return new Response(
        JSON.stringify({ error: "Falha ao consultar BrasilAPI", details: text }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const data = await resp.json();

    const fantasia = (data.nome_fantasia || "").trim() || (data.razao_social || "").trim();
    const razao = (data.razao_social || "").trim();
    const email = (data.email || "").trim().toLowerCase() || null;
    const ddd = data.ddd_telefone_1 ? String(data.ddd_telefone_1).replace(/\D/g, "") : "";
    const phone = ddd ? ddd : null;

    const cep = data.cep ? String(data.cep).replace(/\D/g, "") : null;
    const street = [data.logradouro, ""].filter(Boolean).join("").trim() || null;
    const number = data.numero ? String(data.numero) : null;
    const complement = data.complemento || null;
    const district = data.bairro || null;
    const city = data.municipio || null;
    const state = data.uf || null;

    const cnaePrincipal = data.cnae_fiscal_descricao || null;
    const situacao = data.descricao_situacao_cadastral || null;

    return new Response(
      JSON.stringify({
        cnpj,
        razao_social: razao,
        nome_fantasia: fantasia,
        email,
        phone,
        address: {
          cep,
          street,
          number,
          complement,
          district,
          city,
          state,
        },
        cnae: cnaePrincipal,
        situacao,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("lookup-cnpj crashed", e);
    return new Response(
      JSON.stringify({ error: "Erro interno", details: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
