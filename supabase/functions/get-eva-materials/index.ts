import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const EVA_API_BASE = "https://api.eva-googlemarine.com/departamentos/suprimentos";

interface EvaMaterial {
  produto_id: number;
  codigo: string;
  nome: string;
  custo_unitario: string;
  embarcacao: string;
}

interface EvaApiResponse {
  ok: boolean;
  meta: {
    os_numero: string;
    count: number;
  };
  data: EvaMaterial[];
}

interface FormattedMaterial {
  external_product_id: number;
  external_product_code: string;
  name: string;
  unit_value: number;
  quantity: number;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const orderNumber = url.searchParams.get('order_number');

    if (!orderNumber) {
      console.error("Missing order_number parameter");
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Número da OS é obrigatório" 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    console.log(`Fetching materials for OS: ${orderNumber}`);

    // Fetch from Eva API
    const evaResponse = await fetch(
      `${EVA_API_BASE}/get-os-data?numero_os=${encodeURIComponent(orderNumber)}`,
      {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        },
      }
    );

    if (!evaResponse.ok) {
      console.error(`Eva API returned status ${evaResponse.status}`);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Erro ao consultar API Eva: ${evaResponse.status}` 
        }),
        { 
          status: 502, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    const evaData: EvaApiResponse = await evaResponse.json();
    console.log(`Eva API response:`, JSON.stringify(evaData));

    if (!evaData.ok) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "API Eva retornou erro" 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Group materials by product_id and sum quantities
    const materialMap = new Map<number, FormattedMaterial>();
    let vesselName = "";

    for (const item of evaData.data) {
      // Capture vessel name from first item
      if (!vesselName && item.embarcacao) {
        vesselName = item.embarcacao;
      }

      const existingMaterial = materialMap.get(item.produto_id);
      const unitValue = parseFloat(item.custo_unitario) || 0;

      if (existingMaterial) {
        // Same product found, increment quantity
        existingMaterial.quantity += 1;
      } else {
        // New product
        materialMap.set(item.produto_id, {
          external_product_id: item.produto_id,
          external_product_code: item.codigo,
          name: item.nome,
          unit_value: unitValue,
          quantity: 1,
        });
      }
    }

    const materials = Array.from(materialMap.values());

    console.log(`Processed ${materials.length} unique materials, vessel: ${vesselName}`);

    return new Response(
      JSON.stringify({
        success: true,
        vesselName,
        orderNumber: evaData.meta.os_numero,
        totalItems: evaData.meta.count,
        materials,
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );

  } catch (error) {
    console.error("Error in get-eva-materials:", error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message || "Erro interno do servidor" 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
