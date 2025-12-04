import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface AISPosition {
  latitude: number;
  longitude: number;
  speed_over_ground: number;
  course_over_ground: number;
  heading: number;
  navigation_status: number;
  destination: string;
  location_context: string;
  recorded_at: string;
}

// Calculate location context based on navigation status and coordinates
function calculateLocationContext(navStatus: number, speed: number): string {
  // AIS Navigation Status codes
  // 0 = Under way using engine
  // 1 = At anchor
  // 2 = Not under command
  // 3 = Restricted maneuverability
  // 4 = Constrained by draught
  // 5 = Moored
  // 6 = Aground
  // 7 = Engaged in Fishing
  // 8 = Under way sailing
  
  if (navStatus === 5) return 'port'; // Moored
  if (navStatus === 1) return 'bay'; // At anchor
  if (speed > 0.5) return 'at_sea'; // Moving
  return 'offshore'; // Stationary but not moored/anchored
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { vessel_id, mmsi } = await req.json();
    
    if (!vessel_id && !mmsi) {
      return new Response(
        JSON.stringify({ error: 'vessel_id or mmsi is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const aisApiKey = Deno.env.get('AISSTREAM_API_KEY');
    
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Get vessel MMSI if only vessel_id provided
    let targetMmsi = mmsi;
    let vesselId = vessel_id;
    
    if (!targetMmsi && vesselId) {
      const { data: vessel, error: vesselError } = await supabase
        .from('vessels')
        .select('mmsi')
        .eq('id', vesselId)
        .single();
        
      if (vesselError || !vessel?.mmsi) {
        // Return last known position from database
        const { data: lastPosition } = await supabase
          .from('vessel_positions')
          .select('*')
          .eq('vessel_id', vesselId)
          .order('recorded_at', { ascending: false })
          .limit(1)
          .single();
          
        if (lastPosition) {
          return new Response(
            JSON.stringify({
              position: lastPosition,
              source: 'database',
              message: 'MMSI not configured, using last known position'
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
        
        return new Response(
          JSON.stringify({ error: 'No position data available', position: null }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      
      targetMmsi = vessel.mmsi;
    }
    
    // Try to get position from AISStream API
    if (aisApiKey && targetMmsi) {
      try {
        // AISStream uses WebSocket, but they also have REST endpoint for single vessel lookup
        // Using their REST API to get latest position
        const aisResponse = await fetch(
          `https://api.aisstream.io/v0/vessel/${targetMmsi}/position`,
          {
            headers: {
              'Authorization': `Bearer ${aisApiKey}`,
              'Content-Type': 'application/json'
            }
          }
        );
        
        if (aisResponse.ok) {
          const aisData = await aisResponse.json();
          
          if (aisData && aisData.latitude && aisData.longitude) {
            const locationContext = calculateLocationContext(
              aisData.navigation_status || 0,
              aisData.speed_over_ground || 0
            );
            
            const position: AISPosition = {
              latitude: aisData.latitude,
              longitude: aisData.longitude,
              speed_over_ground: aisData.speed_over_ground || 0,
              course_over_ground: aisData.course_over_ground || 0,
              heading: aisData.heading || 0,
              navigation_status: aisData.navigation_status || 0,
              destination: aisData.destination || '',
              location_context: locationContext,
              recorded_at: new Date().toISOString()
            };
            
            // Store position in database
            if (vesselId) {
              await supabase.from('vessel_positions').insert({
                vessel_id: vesselId,
                ...position
              });
            }
            
            console.log(`AIS position retrieved for MMSI ${targetMmsi}`);
            
            return new Response(
              JSON.stringify({ position, source: 'ais' }),
              { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
          }
        }
      } catch (aisError) {
        console.error('AIS API error:', aisError);
      }
    }
    
    // Fallback to last known position from database
    const { data: lastPosition } = await supabase
      .from('vessel_positions')
      .select('*')
      .eq('vessel_id', vesselId)
      .order('recorded_at', { ascending: false })
      .limit(1)
      .single();
      
    if (lastPosition) {
      return new Response(
        JSON.stringify({ position: lastPosition, source: 'database' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    return new Response(
      JSON.stringify({ position: null, source: 'none', message: 'No position data available' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Error in ais-vessel-position:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
