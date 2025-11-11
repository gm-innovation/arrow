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

    console.log('Extracting certificate data from:', fileName);

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
            content: 'Você é um especialista em extrair dados de certificados e documentos técnicos. Extraia APENAS as informações que estão claramente visíveis. Se um campo não estiver presente, não o inclua na resposta.'
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: 'Extraia os dados deste certificado em formato estruturado. Use a função extract_certificate_data para retornar os dados.'
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
            name: 'extract_certificate_data',
            description: 'Extrai dados estruturados de um certificado técnico',
            parameters: {
              type: 'object',
              properties: {
                certificate_name: { 
                  type: 'string', 
                  description: 'Nome ou título do certificado' 
                },
                issue_date: { 
                  type: 'string', 
                  description: 'Data de emissão no formato DD/MM/YYYY' 
                },
                expiry_date: { 
                  type: 'string', 
                  description: 'Data de validade/expiração no formato DD/MM/YYYY' 
                },
              },
              required: []
            }
          }
        }],
        tool_choice: { type: 'function', function: { name: 'extract_certificate_data' } }
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
    if (extractedData.issue_date) {
      const [day, month, year] = extractedData.issue_date.split('/');
      extractedData.issue_date = `${year}-${month}-${day}`;
    }
    if (extractedData.expiry_date) {
      const [day, month, year] = extractedData.expiry_date.split('/');
      extractedData.expiry_date = `${year}-${month}-${day}`;
    }

    // Calculate expiry_date if not present based on certificate type and issue_date
    if (!extractedData.expiry_date && extractedData.issue_date && extractedData.certificate_name) {
      const issueDate = new Date(extractedData.issue_date);
      let validityYears = 2; // Default validity

      const certName = extractedData.certificate_name.toLowerCase();
      
      // Determine validity period based on certificate type
      if (certName.includes('nr 10') || certName.includes('nr10')) {
        validityYears = 2; // NR 10 - 2 years
      } else if (certName.includes('nr 35') || certName.includes('nr35')) {
        validityYears = 2; // NR 35 - 2 years
      } else if (certName.includes('nr 33') || certName.includes('nr33')) {
        validityYears = 2; // NR 33 - 2 years
      } else if (certName.includes('nr 34') || certName.includes('nr34')) {
        validityYears = 2; // NR 34 - 2 years
      } else if (certName.includes('nr 18') || certName.includes('nr18')) {
        validityYears = 2; // NR 18 - 2 years
      }

      const expiryDate = new Date(issueDate);
      expiryDate.setFullYear(expiryDate.getFullYear() + validityYears);
      
      const year = expiryDate.getFullYear();
      const month = String(expiryDate.getMonth() + 1).padStart(2, '0');
      const day = String(expiryDate.getDate()).padStart(2, '0');
      extractedData.expiry_date = `${year}-${month}-${day}`;
      
      console.log(`Calculated expiry_date: ${extractedData.expiry_date} (${validityYears} years from issue_date)`);
    }

    console.log('Extracted certificate data:', extractedData);

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
