// Ingest knowledge: extrai texto de PDF/DOCX/TXT/manual, chunka e gera embeddings via Lovable AI Gateway
import { corsHeaders } from 'npm:@supabase/supabase-js@2/cors';
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const LOVABLE_API_KEY = Deno.env.get('LOVABLE_API_KEY')!;

async function extractText(storagePath: string | null, sourceType: string, raw: string | null, supabase: any): Promise<string> {
  if (raw) return raw;
  if (!storagePath) return '';
  const { data, error } = await supabase.storage.from('ai-knowledge').download(storagePath);
  if (error) throw error;

  if (sourceType === 'txt') {
    return await data.text();
  }
  if (sourceType === 'pdf') {
    try {
      const { extractText: unpdfExtract, getDocumentProxy } = await import('https://esm.sh/unpdf@0.12.1');
      const buf = new Uint8Array(await data.arrayBuffer());
      const pdf = await getDocumentProxy(buf);
      const { text } = await unpdfExtract(pdf, { mergePages: true });
      return Array.isArray(text) ? text.join('\n\n') : String(text ?? '');
    } catch (e) {
      console.error('pdf parse error', e);
      return '';
    }
  }
  if (sourceType === 'docx') {
    try {
      const mammoth: any = await import('https://esm.sh/mammoth@1.7.0');
      const buf = await data.arrayBuffer();
      const result = await mammoth.extractRawText({ arrayBuffer: buf });
      return result.value;
    } catch (e) {
      console.error('docx parse error', e);
      return '';
    }
  }
  return '';
}

function chunkText(text: string, size = 800, overlap = 100): string[] {
  const words = text.split(/\s+/).filter(Boolean);
  const chunks: string[] = [];
  for (let i = 0; i < words.length; i += size - overlap) {
    chunks.push(words.slice(i, i + size).join(' '));
    if (i + size >= words.length) break;
  }
  return chunks;
}

async function embed(text: string): Promise<number[] | null> {
  // Lovable AI Gateway: usar Gemini embeddings via OpenAI-compatible path
  const res = await fetch('https://ai.gateway.lovable.dev/v1/embeddings', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LOVABLE_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model: 'google/text-embedding-004', input: text }),
  });
  if (!res.ok) {
    console.error('embed failed', res.status, await res.text());
    return null;
  }
  const json = await res.json();
  return json.data?.[0]?.embedding ?? null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { source_id } = await req.json();
    if (!source_id) {
      return new Response(JSON.stringify({ error: 'source_id required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

    await supabase.from('ai_knowledge_sources').update({ status: 'processing', error_message: null }).eq('id', source_id);

    const { data: source, error: sErr } = await supabase
      .from('ai_knowledge_sources')
      .select('*')
      .eq('id', source_id)
      .maybeSingle();

    if (sErr || !source) throw new Error('source not found');

    const text = await extractText(source.storage_path, source.source_type, source.raw_text, supabase);
    if (!text.trim()) throw new Error('Texto vazio após extração');

    const chunks = chunkText(text);

    // limpar chunks antigos
    await supabase.from('ai_knowledge_chunks').delete().eq('source_id', source_id);

    let inserted = 0;
    for (let i = 0; i < chunks.length; i++) {
      const emb = await embed(chunks[i]);
      const { error: iErr } = await supabase.from('ai_knowledge_chunks').insert({
        source_id,
        agent_id: source.agent_id,
        company_id: source.company_id,
        chunk_index: i,
        content: chunks[i],
        embedding: emb,
        token_count: chunks[i].split(/\s+/).length,
      });
      if (!iErr) inserted++;
    }

    await supabase.from('ai_knowledge_sources').update({
      status: 'indexed',
      chunk_count: inserted,
    }).eq('id', source_id);

    return new Response(JSON.stringify({ ok: true, chunks: inserted }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e: any) {
    console.error('ingest error', e);
    try {
      const { source_id } = await req.clone().json();
      const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);
      await supabase.from('ai_knowledge_sources').update({
        status: 'error',
        error_message: String(e.message ?? e),
      }).eq('id', source_id);
    } catch {}
    return new Response(JSON.stringify({ error: String(e.message ?? e) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
