import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { fileBase64, fileName } = await req.json();

    console.log('Extracting data from:', fileName);

    // Call Lovable AI for extraction
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
            content: 'Você é um especialista em extrair dados de documentos ASO (Atestado de Saúde Ocupacional) brasileiros. Extraia APENAS as informações que estão claramente visíveis no documento. Se um campo não estiver presente, não o inclua na resposta. IMPORTANTE: A data de emissão do ASO (aso_issue_date) é a data em que o exame médico foi realizado, geralmente aparece como "Data do Exame" ou próxima ao nome do médico examinador.'
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: 'Extraia os dados deste ASO em formato estruturado. Localize a data do exame médico/data de emissão do ASO com atenção. Use a função extract_aso_data para retornar os dados.'
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/png;base64,${fileBase64}`
                }
              }
            ]
          }
        ],
        tools: [{
          type: 'function',
          function: {
            name: 'extract_aso_data',
            description: 'Extrai dados estruturados de um ASO brasileiro',
            parameters: {
              type: 'object',
              properties: {
                full_name: { type: 'string', description: 'Nome completo' },
                cpf: { type: 'string', description: 'CPF no formato 000.000.000-00' },
                rg: { type: 'string', description: 'RG/Identidade' },
                birth_date: { type: 'string', description: 'Data de nascimento no formato DD/MM/YYYY' },
                gender: { type: 'string', enum: ['Masculino', 'Feminino'], description: 'Gênero' },
                nationality: { type: 'string', description: 'Nacionalidade' },
                height: { type: 'number', description: 'Altura em cm' },
                blood_type: { type: 'string', enum: ['A', 'B', 'AB', 'O'], description: 'Tipo sanguíneo' },
                blood_rh_factor: { type: 'string', enum: ['Positivo', 'Negativo'], description: 'Fator RH' },
                function: { type: 'string', description: 'Função/Cargo' },
                sector: { type: 'string', description: 'Setor' },
                aso_issue_date: { type: 'string', description: 'Data de emissão do ASO (data do exame médico) no formato DD/MM/YYYY - procure por datas próximas ao médico examinador ou identificadas como "data do exame"' },
                aso_valid_until: { type: 'string', description: 'Data de validade do ASO no formato DD/MM/YYYY' },
                medical_status: { type: 'string', enum: ['fit', 'unfit'], description: 'Status médico: fit para apto, unfit para inapto' }
              },
              required: ['full_name']
            }
          }
        }],
        tool_choice: { type: 'function', function: { name: 'extract_aso_data' } }
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('AI API error:', errorText);
      throw new Error(`AI API error: ${response.status} - ${errorText}`);
    }

    const aiResult = await response.json();
    console.log('AI Result:', JSON.stringify(aiResult, null, 2));

    if (!aiResult.choices?.[0]?.message?.tool_calls?.[0]?.function?.arguments) {
      throw new Error('No data extracted from AI response');
    }

    const extractedData = JSON.parse(aiResult.choices[0].message.tool_calls[0].function.arguments);

    // Convert date format from DD/MM/YYYY to YYYY-MM-DD if present
    if (extractedData.birth_date) {
      const [day, month, year] = extractedData.birth_date.split('/');
      extractedData.birth_date = `${year}-${month}-${day}`;
    }
    if (extractedData.aso_issue_date) {
      const [day, month, year] = extractedData.aso_issue_date.split('/');
      extractedData.aso_issue_date = `${year}-${month}-${day}`;
    }
    if (extractedData.aso_valid_until) {
      const [day, month, year] = extractedData.aso_valid_until.split('/');
      extractedData.aso_valid_until = `${year}-${month}-${day}`;
    }

    // Calculate ASO validity if not present (1 year from issue date)
    if (!extractedData.aso_valid_until && extractedData.aso_issue_date) {
      const issueDate = new Date(extractedData.aso_issue_date);
      const validUntil = new Date(issueDate);
      validUntil.setFullYear(validUntil.getFullYear() + 1);
      
      const year = validUntil.getFullYear();
      const month = String(validUntil.getMonth() + 1).padStart(2, '0');
      const day = String(validUntil.getDate()).padStart(2, '0');
      extractedData.aso_valid_until = `${year}-${month}-${day}`;
      
      console.log(`Calculated ASO validity: ${extractedData.aso_valid_until} (1 year from issue date: ${extractedData.aso_issue_date})`);
    }

    console.log('Extracted data:', extractedData);

    return new Response(
      JSON.stringify({ success: true, data: extractedData }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Extraction error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    );
  }
});
