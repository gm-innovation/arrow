import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Haversine formula to calculate distance between two coordinates
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

interface GeofenceResult {
  canCheckIn: boolean;
  canCheckOut: boolean;
  distanceToVessel: number | null;
  technicianContext: string;
  vesselContext: string | null;
  isOnMainland: boolean | null;
  nearestAccessPoint: {
    id: string;
    name: string;
    distance: number;
  } | null;
  warnings: string[];
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { 
      technician_latitude, 
      technician_longitude, 
      vessel_id,
      service_order_id,
      check_in_radius = 20 // Default 20 meters
    } = await req.json();
    
    if (!technician_latitude || !technician_longitude) {
      return new Response(
        JSON.stringify({ error: 'Technician coordinates are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const mapboxToken = Deno.env.get('VITE_MAPBOX_ACCESS_TOKEN');
    
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    const result: GeofenceResult = {
      canCheckIn: false,
      canCheckOut: false,
      distanceToVessel: null,
      technicianContext: 'unknown',
      vesselContext: null,
      isOnMainland: null,
      nearestAccessPoint: null,
      warnings: []
    };
    
    // Get vessel position if vessel_id provided
    if (vessel_id) {
      const { data: vesselPosition } = await supabase
        .from('vessel_positions')
        .select('*')
        .eq('vessel_id', vessel_id)
        .order('recorded_at', { ascending: false })
        .limit(1)
        .single();
        
      if (vesselPosition) {
        result.distanceToVessel = calculateDistance(
          technician_latitude,
          technician_longitude,
          Number(vesselPosition.latitude),
          Number(vesselPosition.longitude)
        );
        result.vesselContext = vesselPosition.location_context;
        
        // Check if technician can check-in (within radius)
        result.canCheckIn = result.distanceToVessel <= check_in_radius;
        
        if (!result.canCheckIn && result.distanceToVessel <= 100) {
          result.warnings.push(`Você está a ${Math.round(result.distanceToVessel)}m do navio. Aproxime-se mais para fazer check-in.`);
        } else if (!result.canCheckIn) {
          result.warnings.push(`Você está a ${Math.round(result.distanceToVessel)}m do navio.`);
        }
      } else {
        result.warnings.push('Posição AIS do navio não disponível.');
      }
    }
    
    // Get service order context if provided
    if (service_order_id) {
      const { data: serviceOrder } = await supabase
        .from('service_orders')
        .select('expected_context, planned_location, boarding_method')
        .eq('id', service_order_id)
        .single();
        
      if (serviceOrder) {
        // Check if vessel context matches expected context
        if (result.vesselContext && serviceOrder.expected_context) {
          if (result.vesselContext !== serviceOrder.expected_context) {
            result.warnings.push(
              `Atenção: Navio está ${translateContext(result.vesselContext)}, mas era esperado ${translateContext(serviceOrder.expected_context)}.`
            );
          }
        }
      }
    }
    
    // Check nearest access point
    const { data: companyProfile } = await supabase
      .from('profiles')
      .select('company_id')
      .single();
      
    if (companyProfile?.company_id) {
      const { data: accessPoints } = await supabase
        .from('access_points')
        .select('*')
        .eq('company_id', companyProfile.company_id);
        
      if (accessPoints && accessPoints.length > 0) {
        let nearestPoint = null;
        let nearestDistance = Infinity;
        
        for (const point of accessPoints) {
          if (point.latitude && point.longitude) {
            const distance = calculateDistance(
              technician_latitude,
              technician_longitude,
              Number(point.latitude),
              Number(point.longitude)
            );
            
            if (distance < nearestDistance) {
              nearestDistance = distance;
              nearestPoint = point;
            }
          }
        }
        
        if (nearestPoint && nearestDistance < 5000) { // Within 5km
          result.nearestAccessPoint = {
            id: nearestPoint.id,
            name: nearestPoint.name,
            distance: Math.round(nearestDistance)
          };
          
          // If at access point, technician is likely at port
          if (nearestDistance <= 100) {
            result.technicianContext = 'at_port';
            result.isOnMainland = nearestPoint.is_mainland;
          }
        }
      }
    }
    
    // Use Mapbox reverse geocoding to determine if on land
    if (mapboxToken && result.isOnMainland === null) {
      try {
        const geocodeUrl = `https://api.mapbox.com/geocoding/v5/mapbox.places/${technician_longitude},${technician_latitude}.json?access_token=${mapboxToken}&types=place,locality,neighborhood,address`;
        
        const geocodeResponse = await fetch(geocodeUrl);
        if (geocodeResponse.ok) {
          const geocodeData = await geocodeResponse.json();
          
          // If we get results, technician is on land
          if (geocodeData.features && geocodeData.features.length > 0) {
            result.isOnMainland = true;
            result.technicianContext = result.technicianContext === 'unknown' ? 'on_land' : result.technicianContext;
          } else {
            // No results means likely at sea
            result.isOnMainland = false;
            result.technicianContext = 'at_sea';
          }
        }
      } catch (error) {
        console.error('Geocoding error:', error);
      }
    }
    
    // Determine if check-out is allowed
    // Can check-out if: on mainland OR at a port access point
    result.canCheckOut = result.isOnMainland === true || result.technicianContext === 'at_port';
    
    // If vessel is at port (docked), check-out is always allowed
    if (result.vesselContext === 'port') {
      result.canCheckOut = true;
    }
    
    console.log('Geofence check result:', result);
    
    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Error in geofence-check:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

function translateContext(context: string): string {
  const translations: Record<string, string> = {
    'port': 'atracado no porto',
    'bay': 'fundeado na baía',
    'offshore': 'em área offshore',
    'at_sea': 'navegando em alto mar',
    'docked': 'atracado',
    'anchored': 'fundeado',
    'unknown': 'em local desconhecido'
  };
  return translations[context] || context;
}
