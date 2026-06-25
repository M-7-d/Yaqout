import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    console.log('Received webhook payload:', JSON.stringify(payload))

    // Supabase Database Webhooks send: { type, table, schema, record, old_record }
    const record = payload.record

    if (!record) {
      console.error('No record in payload:', JSON.stringify(payload))
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    if (!record.room_id || !record.sender_id) {
      console.error('Missing required fields in record:', JSON.stringify(record))
      return new Response(JSON.stringify({ error: 'Missing room_id or sender_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 1. Get room details to figure out the receiver
    const { data: room, error: roomError } = await supabase
      .from('chat_rooms')
      .select('buyer_id, seller_id')
      .eq('id', record.room_id)
      .single()

    if (roomError || !room) {
      console.error('Room fetch error:', JSON.stringify(roomError))
      return new Response(JSON.stringify({ error: 'Room not found', details: roomError }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    console.log('Room found:', JSON.stringify(room))

    // 2. Determine receiver ID (whoever is NOT the sender)
    const receiverId = record.sender_id === room.buyer_id ? room.seller_id : room.buyer_id
    console.log(`Sender: ${record.sender_id}, Receiver: ${receiverId}`)

    // 2b. Check receiver's notification preferences
    const { data: prefs } = await supabase
      .from('notification_preferences')
      .select('push_notifications, messages_chat')
      .eq('user_id', receiverId)
      .single()

    if (prefs) {
      if (prefs.push_notifications === false) {
        console.log('Receiver has push_notifications disabled — skipping')
        return new Response(JSON.stringify({ skipped: true, reason: 'push_notifications off' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
      if (prefs.messages_chat === false) {
        console.log('Receiver has messages_chat disabled — skipping')
        return new Response(JSON.stringify({ skipped: true, reason: 'messages_chat off' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // 2c. Check if receiver muted the sender
    const { data: muteData } = await supabase
      .from('chat_mutes')
      .select('id')
      .eq('muted_by_id', receiverId)
      .eq('muted_user_id', record.sender_id)
      .maybeSingle()

    if (muteData) {
      console.log('Receiver has muted the sender — skipping')
      return new Response(JSON.stringify({ skipped: true, reason: 'sender is muted' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 3. Get sender profile for display name
    const { data: senderProfile, error: profileError } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', record.sender_id)
      .single()

    if (profileError) console.warn('Could not fetch sender profile:', profileError)

    const senderName = senderProfile?.full_name || 'New message'
    const messageContent = record.content || 'Sent an attachment'


    // 4. Read OneSignal credentials
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID')
    const oneSignalRestApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY')

    if (!oneSignalAppId || !oneSignalRestApiKey) {
      console.error('Missing OneSignal env vars. APP_ID present:', !!oneSignalAppId, 'REST_KEY present:', !!oneSignalRestApiKey)
      return new Response(JSON.stringify({ error: 'OneSignal keys not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 5. Send push via OneSignal REST API v1
    // Uses include_aliases with external_id (set via OneSignal.login(userId) in the app)
    const notificationBody = {
      app_id: oneSignalAppId,
      include_aliases: { external_id: [receiverId] },
      target_channel: 'push',
      headings: { en: senderName },
      contents: { en: messageContent },
      data: {
        type: 'chat',
        roomId: record.room_id,
        deeplink: `/chat/${record.room_id}`
      }
    }

    console.log('Sending OneSignal notification:', JSON.stringify(notificationBody))

    const response = await fetch('https://api.onesignal.com/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${oneSignalRestApiKey}`
      },
      body: JSON.stringify(notificationBody)
    })

    const result = await response.json()
    console.log('OneSignal response status:', response.status)
    console.log('OneSignal response body:', JSON.stringify(result))

    if (!response.ok) {
      return new Response(JSON.stringify({ error: 'OneSignal API error', details: result }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (err) {
    console.error('Unhandled function error:', err.message, err.stack)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
