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
    const { query, mapbox_id } = await req.json();
    
    const MAPBOX_TOKEN = Deno.env.get('VITE_MAPBOX_ACCESS_TOKEN');
    
    if (!MAPBOX_TOKEN) {
      console.error('Mapbox token not configured');
      throw new Error('Mapbox token not configured');
    }

    // If mapbox_id is provided, retrieve full details including coordinates
    if (mapbox_id) {
      const url = `https://api.mapbox.com/search/searchbox/v1/retrieve/${mapbox_id}?session_token=${crypto.randomUUID()}&access_token=${MAPBOX_TOKEN}`;
      
      console.log('Retrieving details for mapbox_id:', mapbox_id);
      
      const response = await fetch(url);
      const data = await response.json();
      
      console.log('Retrieve response status:', response.status);
      
      return new Response(
        JSON.stringify(data),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Otherwise, search for suggestions
    if (!query || query.length < 3) {
      return new Response(
        JSON.stringify({ features: [] }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Using Search Box API for better autocomplete results
    const url = `https://api.mapbox.com/search/searchbox/v1/suggest?q=${encodeURIComponent(query)}&language=pt&country=BR&limit=5&session_token=${crypto.randomUUID()}&access_token=${MAPBOX_TOKEN}`;
    
    console.log('Fetching from Mapbox Search Box API');
    
    const response = await fetch(url);
    const data = await response.json();
    
    console.log('Mapbox response status:', response.status);
    
    // Transform Search Box API response to match expected format
    const features = data.suggestions?.map((suggestion: any) => ({
      id: suggestion.mapbox_id,
      place_name: suggestion.full_address || suggestion.name,
      name: suggestion.name,
      mapbox_id: suggestion.mapbox_id,
    })) || [];
    
    const transformedData = {
      features: features
    };

    return new Response(
      JSON.stringify(transformedData),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in mapbox-geocoding function:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
