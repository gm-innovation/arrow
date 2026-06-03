// Cria job de fine tuning OpenAI a partir de exemplos curados
import { corsHeaders } from 'npm:@supabase/supabase-js@2/cors';
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (!OPENAI_API_KEY) {
      return new Response(JSON.stringify({
        error: 'OPENAI_API_KEY não configurado. Adicione via Project Settings → Secrets.',
      }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const { agent_id, base_model = 'gpt-4o-mini-2024-07-18' } = await req.json();
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

    const { data: agent } = await supabase.from('ai_agents').select('*').eq('id', agent_id).maybeSingle();
    if (!agent) throw new Error('Agente não encontrado');

    const { data: examples } = await supabase
      .from('ai_training_examples')
      .select('*')
      .eq('agent_id', agent_id)
      .eq('active', true);

    if (!examples?.length || examples.length < 10) {
      throw new Error('Mínimo de 10 exemplos para fine tuning');
    }

    const system = agent.identity?.persona ?? 'Você é um assistente útil.';
    const jsonl = examples.map((e: any) => JSON.stringify({
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: e.question },
        { role: 'assistant', content: e.ideal_answer },
      ],
    })).join('\n');

    // Upload do arquivo
    const fd = new FormData();
    fd.append('file', new Blob([jsonl], { type: 'application/jsonl' }), 'training.jsonl');
    fd.append('purpose', 'fine-tune');

    const fileRes = await fetch('https://api.openai.com/v1/files', {
      method: 'POST',
      headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
      body: fd,
    });
    if (!fileRes.ok) throw new Error(`Upload OpenAI falhou: ${await fileRes.text()}`);
    const file = await fileRes.json();

    // Criar job
    const jobRes = await fetch('https://api.openai.com/v1/fine_tuning/jobs', {
      method: 'POST',
      headers: { Authorization: `Bearer ${OPENAI_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ training_file: file.id, model: base_model }),
    });
    if (!jobRes.ok) throw new Error(`Criar job falhou: ${await jobRes.text()}`);
    const job = await jobRes.json();

    const { data: saved } = await supabase.from('ai_fine_tune_jobs').insert({
      agent_id,
      company_id: agent.company_id,
      provider: 'openai',
      base_model,
      external_job_id: job.id,
      status: job.status ?? 'pending',
      example_count: examples.length,
    }).select().maybeSingle();

    return new Response(JSON.stringify({ ok: true, job: saved }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e: any) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e.message ?? e) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
