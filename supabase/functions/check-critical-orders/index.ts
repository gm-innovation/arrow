import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.80.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface CriticalOrder {
  id: string;
  order_number: string;
  status: string;
  scheduled_date: string | null;
  created_at: string;
  company_id: string;
  vessel_name: string | null;
  client_name: string | null;
  created_by_name: string | null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    console.log('Starting critical orders check...');

    // Get all active service orders (not completed or cancelled)
    const { data: orders, error: ordersError } = await supabase
      .from('service_orders')
      .select(`
        id,
        order_number,
        status,
        scheduled_date,
        created_at,
        company_id,
        vessels:vessel_id (name),
        clients:client_id (name),
        created_by_profile:created_by (full_name)
      `)
      .neq('status', 'completed')
      .neq('status', 'cancelled');

    if (ordersError) throw ordersError;

    const today = new Date();
    const criticalOrders: CriticalOrder[] = [];

    // Check each order for critical conditions
    orders?.forEach((order: any) => {
      let isCritical = false;
      
      // Check for overdue orders
      if (order.scheduled_date && order.status !== 'completed') {
        const scheduledDate = new Date(order.scheduled_date);
        if (scheduledDate < today) {
          isCritical = true;
        }
      }

      // Check for orders in progress for too long (more than 7 days)
      if (order.status === 'in_progress') {
        const createdDate = new Date(order.created_at);
        const daysDiff = Math.floor((today.getTime() - createdDate.getTime()) / (1000 * 60 * 60 * 24));
        if (daysDiff > 7) {
          isCritical = true;
        }
      }

      // Check for pending orders without schedule (more than 3 days)
      if (order.status === 'pending' && !order.scheduled_date) {
        const createdDate = new Date(order.created_at);
        const daysDiff = Math.floor((today.getTime() - createdDate.getTime()) / (1000 * 60 * 60 * 24));
        if (daysDiff > 3) {
          isCritical = true;
        }
      }

      if (isCritical) {
        criticalOrders.push({
          id: order.id,
          order_number: order.order_number,
          status: order.status,
          scheduled_date: order.scheduled_date,
          created_at: order.created_at,
          company_id: order.company_id,
          vessel_name: order.vessels?.name || null,
          client_name: order.clients?.name || null,
          created_by_name: order.created_by_profile?.full_name || null,
        });
      }
    });

    console.log(`Found ${criticalOrders.length} critical orders`);

    // Group critical orders by company
    const ordersByCompany = criticalOrders.reduce((acc: { [key: string]: CriticalOrder[] }, order) => {
      if (!acc[order.company_id]) {
        acc[order.company_id] = [];
      }
      acc[order.company_id].push(order);
      return acc;
    }, {});

    // Send notifications to managers for each company
    let notificationsSent = 0;

    for (const [companyId, companyOrders] of Object.entries(ordersByCompany)) {
      // Get all managers in this company
      const { data: managers, error: managersError } = await supabase
        .from('profiles')
        .select('id')
        .eq('company_id', companyId)
        .in('id', 
          supabase
            .from('user_roles')
            .select('user_id')
            .eq('role', 'manager')
        );

      if (managersError) {
        console.error('Error fetching managers:', managersError);
        continue;
      }

      // Get manager user IDs
      const { data: managerRoles } = await supabase
        .from('user_roles')
        .select('user_id')
        .eq('role', 'manager');

      const managerIds = managerRoles?.map(r => r.user_id) || [];
      const companyManagerIds = managers?.map(m => m.id).filter(id => managerIds.includes(id)) || [];

      // Send notification to each manager
      for (const managerId of companyManagerIds) {
        // Check if there's already a recent notification about critical orders
        const { data: recentNotifications } = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', managerId)
          .eq('notification_type', 'critical_os')
          .gte('created_at', new Date(today.getTime() - 24 * 60 * 60 * 1000).toISOString())
          .limit(1);

        // Only send if no notification was sent in the last 24 hours
        if (!recentNotifications || recentNotifications.length === 0) {
          const { error: notificationError } = await supabase
            .from('notifications')
            .insert({
              user_id: managerId,
              title: `${companyOrders.length} OS${companyOrders.length > 1 ? 's' : ''} Crítica${companyOrders.length > 1 ? 's' : ''}`,
              message: `Você tem ${companyOrders.length} ordem${companyOrders.length > 1 ? 'ns' : ''} de serviço que requer${companyOrders.length === 1 ? '' : 'em'} atenção: ${companyOrders.slice(0, 3).map(o => `#${o.order_number}`).join(', ')}${companyOrders.length > 3 ? ' e mais...' : ''}`,
              notification_type: 'critical_os',
              read: false,
            });

          if (notificationError) {
            console.error('Error creating notification:', notificationError);
          } else {
            notificationsSent++;
          }
        }
      }
    }

    console.log(`Sent ${notificationsSent} notifications to managers`);

    return new Response(
      JSON.stringify({
        success: true,
        criticalOrdersCount: criticalOrders.length,
        notificationsSent,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error in check-critical-orders:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});
