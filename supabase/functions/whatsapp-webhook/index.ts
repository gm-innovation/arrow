import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Normalize phone number to consistent format
function normalizePhone(phone: string): string {
  // Remove "whatsapp:", "+", spaces, dashes, parentheses
  return phone.replace(/whatsapp:|[+\s\-()]/g, '');
}

// Get user by phone number
async function getUserByPhone(supabase: any, phoneNumber: string) {
  const normalizedPhone = normalizePhone(phoneNumber);
  
  // Try different phone formats
  const phoneVariants = [
    normalizedPhone,
    `+${normalizedPhone}`,
    normalizedPhone.replace(/^55/, ''), // Without country code
    `55${normalizedPhone}`, // With Brazil country code
  ];
  
  console.log("Searching for phone variants:", phoneVariants);
  
  for (const variant of phoneVariants) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, full_name, company_id, phone, email')
      .or(`phone.ilike.%${variant.slice(-9)}%`) // Last 9 digits
      .limit(1)
      .single();
    
    if (profile) {
      console.log("Found user:", profile.full_name);
      return profile;
    }
  }
  
  return null;
}

// Get user role
async function getUserRole(supabase: any, userId: string): Promise<string> {
  const { data: role } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', userId)
    .single();
  
  return role?.role || 'technician';
}

// Get recent conversation history
async function getConversationHistory(supabase: any, phoneNumber: string, limit = 10) {
  const normalizedPhone = normalizePhone(phoneNumber);
  
  const { data: messages } = await supabase
    .from('whatsapp_conversations')
    .select('direction, message, created_at')
    .ilike('phone_number', `%${normalizedPhone.slice(-9)}%`)
    .order('created_at', { ascending: false })
    .limit(limit);
  
  if (!messages) return [];
  
  // Convert to AI message format (reversed to chronological order)
  return messages.reverse().map((m: any) => ({
    role: m.direction === 'inbound' ? 'user' : 'assistant',
    content: m.message
  }));
}

// Save message to history
async function saveMessage(
  supabase: any, 
  phoneNumber: string, 
  message: string, 
  direction: 'inbound' | 'outbound',
  userId?: string,
  messageSid?: string
) {
  const { error } = await supabase
    .from('whatsapp_conversations')
    .insert({
      phone_number: normalizePhone(phoneNumber),
      message,
      direction,
      user_id: userId,
      message_sid: messageSid
    });
  
  if (error) {
    console.error("Error saving message:", error);
  }
}

// Send WhatsApp response via Twilio
async function sendWhatsAppResponse(to: string, message: string) {
  const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
  const authToken = Deno.env.get('TWILIO_AUTH_TOKEN');
  const fromNumber = Deno.env.get('TWILIO_WHATSAPP_NUMBER');
  
  if (!accountSid || !authToken || !fromNumber) {
    throw new Error("Twilio credentials not configured");
  }
  
  const formattedTo = to.startsWith('whatsapp:') ? to : `whatsapp:${to}`;
  const formattedFrom = fromNumber.startsWith('whatsapp:') ? fromNumber : `whatsapp:${fromNumber}`;
  
  const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
  
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa(`${accountSid}:${authToken}`),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      To: formattedTo,
      From: formattedFrom,
      Body: message,
    }),
  });
  
  if (!response.ok) {
    const errorText = await response.text();
    console.error("Twilio error:", errorText);
    throw new Error(`Failed to send WhatsApp: ${response.status}`);
  }
  
  return await response.json();
}

// Call AI Assistant
async function callAIAssistant(
  message: string,
  userRole: string,
  companyId: string,
  conversationHistory: any[]
) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  
  const response = await fetch(`${supabaseUrl}/functions/v1/ai-assistant`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
    body: JSON.stringify({
      message,
      userRole,
      context: { companyId },
      messages: conversationHistory
    })
  });
  
  if (!response.ok) {
    console.error("AI Assistant error:", await response.text());
    throw new Error("Failed to get AI response");
  }
  
  // Handle streaming response
  const text = await response.text();
  
  // If it's SSE format, parse it
  if (text.includes('data:')) {
    let fullContent = '';
    const lines = text.split('\n');
    for (const line of lines) {
      if (line.startsWith('data:')) {
        const jsonStr = line.slice(5).trim();
        if (jsonStr && jsonStr !== '[DONE]') {
          try {
            const parsed = JSON.parse(jsonStr);
            const content = parsed.choices?.[0]?.delta?.content;
            if (content) fullContent += content;
          } catch (e) {
            // Skip invalid JSON
          }
        }
      }
    }
    return fullContent || "Desculpe, não consegui processar sua solicitação.";
  }
  
  // Try to parse as JSON
  try {
    const json = JSON.parse(text);
    return json.choices?.[0]?.message?.content || text;
  } catch {
    return text;
  }
}

// Process special commands
function processCommand(message: string): { isCommand: boolean; response?: string } {
  const lowerMessage = message.toLowerCase().trim();
  
  if (lowerMessage === '/ajuda' || lowerMessage === '/help') {
    return {
      isCommand: true,
      response: `🤖 *Comandos Disponíveis*

📋 Perguntas que posso responder:
• "Quais técnicos estão disponíveis amanhã?"
• "Qual o status das OS?"
• "Quais OS estão pendentes?"
• "Minhas tarefas de hoje"

💡 Você também pode fazer perguntas em linguagem natural sobre:
• Disponibilidade de técnicos
• Status de ordens de serviço
• Suas tarefas (se for técnico)
• Dúvidas técnicas sobre equipamentos

Digite sua pergunta normalmente!`
    };
  }
  
  return { isCommand: false };
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    // Parse Twilio webhook payload (form-urlencoded)
    const formData = await req.formData();
    const from = formData.get('From') as string;
    const body = formData.get('Body') as string;
    const messageSid = formData.get('MessageSid') as string;
    
    console.log("WhatsApp webhook received:", { from, body: body?.substring(0, 50), messageSid });
    
    if (!from || !body) {
      return new Response(
        JSON.stringify({ error: "Missing From or Body" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Check for commands first
    const commandResult = processCommand(body);
    if (commandResult.isCommand && commandResult.response) {
      await saveMessage(supabase, from, body, 'inbound', undefined, messageSid);
      await sendWhatsAppResponse(from, commandResult.response);
      await saveMessage(supabase, from, commandResult.response, 'outbound');
      
      return new Response(
        '<?xml version="1.0" encoding="UTF-8"?><Response></Response>',
        { headers: { ...corsHeaders, 'Content-Type': 'text/xml' } }
      );
    }
    
    // Find user by phone
    const user = await getUserByPhone(supabase, from);
    
    if (!user) {
      // Unknown user
      const unknownResponse = `Olá! 👋

Não encontrei seu cadastro no sistema NavalOS.

Para usar o assistente via WhatsApp, peça ao administrador para cadastrar seu número de telefone no seu perfil.

Se você já está cadastrado, verifique se o número está correto no sistema.`;
      
      await saveMessage(supabase, from, body, 'inbound', undefined, messageSid);
      await sendWhatsAppResponse(from, unknownResponse);
      await saveMessage(supabase, from, unknownResponse, 'outbound');
      
      return new Response(
        '<?xml version="1.0" encoding="UTF-8"?><Response></Response>',
        { headers: { ...corsHeaders, 'Content-Type': 'text/xml' } }
      );
    }
    
    // Save inbound message
    await saveMessage(supabase, from, body, 'inbound', user.id, messageSid);
    
    // Get user role and conversation history
    const userRole = await getUserRole(supabase, user.id);
    const history = await getConversationHistory(supabase, from);
    
    console.log("Processing for user:", { 
      name: user.full_name, 
      role: userRole, 
      companyId: user.company_id,
      historyLength: history.length 
    });
    
    // Call AI Assistant
    let aiResponse: string;
    try {
      aiResponse = await callAIAssistant(body, userRole, user.company_id, history);
    } catch (error) {
      console.error("AI Assistant error:", error);
      aiResponse = "Desculpe, ocorreu um erro ao processar sua mensagem. Por favor, tente novamente em alguns instantes.";
    }
    
    // Truncate response if too long for WhatsApp (1600 char limit for good UX)
    if (aiResponse.length > 1500) {
      aiResponse = aiResponse.substring(0, 1500) + "\n\n_(Resposta truncada devido ao tamanho)_";
    }
    
    // Send response
    await sendWhatsAppResponse(from, aiResponse);
    
    // Save outbound message
    await saveMessage(supabase, from, aiResponse, 'outbound', user.id);
    
    console.log("Response sent successfully to:", user.full_name);
    
    // Return empty TwiML (we already sent the message via API)
    return new Response(
      '<?xml version="1.0" encoding="UTF-8"?><Response></Response>',
      { headers: { ...corsHeaders, 'Content-Type': 'text/xml' } }
    );
    
  } catch (error) {
    console.error("WhatsApp webhook error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
