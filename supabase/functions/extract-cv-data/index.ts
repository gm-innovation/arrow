import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { fileBase64, fileName } = await req.json();
    if (!fileBase64) throw new Error('fileBase64 obrigatório');

    const response = await fetch('https://ai.gateway.lovable.dev/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('LOVABLE_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'google/gemini-2.5-flash',
        messages: [
          {
            role: 'system',
            content: 'Você é um especialista em análise de currículos. Extraia informações estruturadas com precisão. Se uma informação não estiver disponível, omita o campo.',
          },
          {
            role: 'user',
            content: [
              { type: 'text', text: `Analise este currículo (arquivo: ${fileName || 'cv'}) e extraia os dados via função extract_cv_data.` },
              { type: 'image_url', image_url: { url: `data:image/png;base64,${fileBase64}` } },
            ],
          },
        ],
        tools: [{
          type: 'function',
          function: {
            name: 'extract_cv_data',
            description: 'Extrai dados estruturados de um currículo',
            parameters: {
              type: 'object',
              properties: {
                full_name: { type: 'string' },
                email: { type: 'string' },
                phone: { type: 'string' },
                city: { type: 'string' },
                state: { type: 'string' },
                linkedin_url: { type: 'string' },
                summary: { type: 'string', description: 'Resumo profissional em 2-3 frases' },
                years_of_experience: { type: 'number' },
                current_position: { type: 'string' },
                skills: { type: 'array', items: { type: 'string' } },
                languages: { type: 'array', items: { type: 'string' } },
                education: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      degree: { type: 'string' },
                      institution: { type: 'string' },
                      period: { type: 'string' },
                    },
                  },
                },
                experiences: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      role: { type: 'string' },
                      company: { type: 'string' },
                      period: { type: 'string' },
                      description: { type: 'string' },
                    },
                  },
                },
                certifications: { type: 'array', items: { type: 'string' } },
              },
              required: [],
            },
          },
        }],
        tool_choice: { type: 'function', function: { name: 'extract_cv_data' } },
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('AI error', response.status, text);
      return new Response(JSON.stringify({ error: `AI error: ${response.status}` }), {
        status: response.status === 429 || response.status === 402 ? response.status : 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const result = await response.json();
    const args = result.choices?.[0]?.message?.tool_calls?.[0]?.function?.arguments;
    if (!args) throw new Error('Sem dados extraídos');
    const data = JSON.parse(args);

    return new Response(JSON.stringify({ success: true, data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    console.error('extract-cv-data error', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
