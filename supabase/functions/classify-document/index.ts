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

    console.log('🔍 Classifying document:', fileName);

    // Call Lovable AI for classification and extraction
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
            content: `Você é um especialista em classificar e extrair dados de documentos trabalhistas brasileiros.

Sua tarefa é:
1. PRIMEIRO: Identificar se o documento é um ASO (Atestado de Saúde Ocupacional) ou uma Certificação/Treinamento
2. SEGUNDO: Extrair os dados relevantes do documento

COMO IDENTIFICAR UM ASO:
- Contém termos como: "Atestado de Saúde Ocupacional", "ASO", "Exame Admissional", "Exame Periódico", "Exame Demissional", "Apto para o trabalho", "Inapto"
- Possui dados pessoais do trabalhador (nome, CPF, data nascimento)
- Tem nome e assinatura de médico examinador
- Menciona "NR-7" ou "PCMSO"
- Contém resultado: APTO ou INAPTO

COMO IDENTIFICAR UMA CERTIFICAÇÃO:
- Contém termos como: "Certificado", "Certificamos", "Treinamento", "Curso", "Habilitação"
- Menciona NRs específicas de treinamento: NR-10, NR-33, NR-35, NR-18, NR-20, etc.
- Tem carga horária do curso/treinamento
- Pode ter nome do instrutor ou instituição de ensino
- Não é um exame médico

IMPORTANTE: 
- Analise o CONTEÚDO do documento, não o nome do arquivo
- Se tiver dúvida, classifique como 'unknown'
- A data de emissão do ASO é a data do exame médico (próxima ao médico examinador), NÃO a data de nascimento`
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Analise este documento e:
1. Classifique como 'aso' (Atestado de Saúde Ocupacional), 'certification' (Certificado/Treinamento), ou 'unknown'
2. Extraia os dados relevantes baseado no tipo

Use a função classify_and_extract para retornar os dados.`
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
            name: 'classify_and_extract',
            description: 'Classifica o documento e extrai os dados relevantes',
            parameters: {
              type: 'object',
              properties: {
                document_type: { 
                  type: 'string', 
                  enum: ['aso', 'certification', 'unknown'],
                  description: 'Tipo do documento identificado pelo CONTEÚDO: aso (Atestado Saúde Ocupacional), certification (Certificado/Treinamento), unknown (não identificado)'
                },
                confidence: {
                  type: 'number',
                  description: 'Confiança na classificação de 0 a 1'
                },
                // Campos ASO
                full_name: { type: 'string', description: 'Nome completo (apenas se for ASO)' },
                cpf: { type: 'string', description: 'CPF no formato 000.000.000-00 (apenas se for ASO)' },
                rg: { type: 'string', description: 'RG/Identidade (apenas se for ASO)' },
                birth_date: { type: 'string', description: 'Data de nascimento no formato DD/MM/YYYY (apenas se for ASO)' },
                gender: { type: 'string', enum: ['Masculino', 'Feminino'], description: 'Gênero (apenas se for ASO)' },
                nationality: { type: 'string', description: 'Nacionalidade (apenas se for ASO)' },
                height: { type: 'number', description: 'Altura em cm (apenas se for ASO)' },
                blood_type: { type: 'string', enum: ['A', 'B', 'AB', 'O'], description: 'Tipo sanguíneo (apenas se for ASO)' },
                blood_rh_factor: { type: 'string', enum: ['Positivo', 'Negativo'], description: 'Fator RH (apenas se for ASO)' },
                function: { type: 'string', description: 'Função/Cargo (apenas se for ASO)' },
                sector: { type: 'string', description: 'Setor (apenas se for ASO)' },
                aso_issue_date: { 
                  type: 'string', 
                  description: 'Data de emissão do ASO (data do exame médico) no formato DD/MM/YYYY. Esta é a data próxima ao médico examinador, NÃO a data de nascimento.' 
                },
                aso_valid_until: { type: 'string', description: 'Data de validade do ASO no formato DD/MM/YYYY (apenas se for ASO)' },
                medical_status: { type: 'string', enum: ['fit', 'unfit'], description: 'Status médico: fit para apto, unfit para inapto (apenas se for ASO)' },
                // Campos Certificação
                certificate_name: { 
                  type: 'string', 
                  description: 'Nome ou título completo do certificado (apenas se for certification)' 
                },
                issue_date: { 
                  type: 'string', 
                  description: 'Data de emissão do certificado no formato DD/MM/YYYY (apenas se for certification)' 
                },
                expiry_date: { 
                  type: 'string', 
                  description: 'Data de validade/expiração no formato DD/MM/YYYY (apenas se for certification)' 
                }
              },
              required: ['document_type', 'confidence']
            }
          }
        }],
        tool_choice: { type: 'function', function: { name: 'classify_and_extract' } }
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
    console.log('🔍 Classification result:', extractedData.document_type, 'confidence:', extractedData.confidence);

    // Convert date formats from DD/MM/YYYY to YYYY-MM-DD
    const dateFields = ['birth_date', 'aso_issue_date', 'aso_valid_until', 'issue_date', 'expiry_date'];
    for (const field of dateFields) {
      if (extractedData[field] && extractedData[field].includes('/')) {
        const [day, month, year] = extractedData[field].split('/');
        if (day && month && year) {
          extractedData[field] = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
        }
      }
    }

    // Calculate ASO validity if not present (1 year from issue date)
    if (extractedData.document_type === 'aso' && !extractedData.aso_valid_until && extractedData.aso_issue_date) {
      const issueDate = new Date(extractedData.aso_issue_date);
      const validUntil = new Date(issueDate);
      validUntil.setFullYear(validUntil.getFullYear() + 1);
      
      const year = validUntil.getFullYear();
      const month = String(validUntil.getMonth() + 1).padStart(2, '0');
      const day = String(validUntil.getDate()).padStart(2, '0');
      extractedData.aso_valid_until = `${year}-${month}-${day}`;
      
      console.log(`Calculated ASO validity: ${extractedData.aso_valid_until}`);
    }

    // Calculate certificate expiry if not present
    if (extractedData.document_type === 'certification' && !extractedData.expiry_date && extractedData.issue_date && extractedData.certificate_name) {
      const issueDate = new Date(extractedData.issue_date);
      let validityYears = 2; // Default validity

      const certName = extractedData.certificate_name.toLowerCase();
      
      // Determine validity period based on certificate type
      if (certName.includes('nr 10') || certName.includes('nr10') || certName.includes('nr-10')) {
        validityYears = 2;
      } else if (certName.includes('nr 35') || certName.includes('nr35') || certName.includes('nr-35')) {
        validityYears = 2;
      } else if (certName.includes('nr 33') || certName.includes('nr33') || certName.includes('nr-33')) {
        validityYears = 2;
      } else if (certName.includes('nr 34') || certName.includes('nr34') || certName.includes('nr-34')) {
        validityYears = 2;
      } else if (certName.includes('cipa')) {
        validityYears = 1;
      } else if (certName.includes('primeiros socorros') || certName.includes('primeiro socorro')) {
        validityYears = 2;
      } else if (certName.includes('combate') && certName.includes('incêndio')) {
        validityYears = 1;
      }

      const expiryDate = new Date(issueDate);
      expiryDate.setFullYear(expiryDate.getFullYear() + validityYears);
      
      const year = expiryDate.getFullYear();
      const month = String(expiryDate.getMonth() + 1).padStart(2, '0');
      const day = String(expiryDate.getDate()).padStart(2, '0');
      extractedData.expiry_date = `${year}-${month}-${day}`;
      
      console.log(`Calculated certificate expiry: ${extractedData.expiry_date} (${validityYears} years)`);
    }

    // Prepare response based on document type
    const result: any = {
      document_type: extractedData.document_type,
      confidence: extractedData.confidence
    };

    if (extractedData.document_type === 'aso') {
      result.aso_data = {
        full_name: extractedData.full_name,
        cpf: extractedData.cpf,
        rg: extractedData.rg,
        birth_date: extractedData.birth_date,
        gender: extractedData.gender,
        nationality: extractedData.nationality,
        height: extractedData.height,
        blood_type: extractedData.blood_type,
        blood_rh_factor: extractedData.blood_rh_factor,
        function: extractedData.function,
        sector: extractedData.sector,
        aso_issue_date: extractedData.aso_issue_date,
        aso_valid_until: extractedData.aso_valid_until,
        medical_status: extractedData.medical_status
      };
    } else if (extractedData.document_type === 'certification') {
      result.certificate_data = {
        certificate_name: extractedData.certificate_name,
        issue_date: extractedData.issue_date,
        expiry_date: extractedData.expiry_date
      };
    }

    console.log('📤 Returning classification result:', JSON.stringify(result, null, 2));

    return new Response(
      JSON.stringify({ success: true, data: result }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Classification error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    );
  }
});
