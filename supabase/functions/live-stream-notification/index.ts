import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    console.log('Received webhook payload:', JSON.stringify(payload))

    const record = payload.record

    if (!record) {
      console.error('No record in payload')
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Only notify when status is 'live' (not 'scheduled' or 'ended')
    if (record.status !== 'live') {
      console.log(`Skipping — stream status is "${record.status}", not "live"`)
      return new Response(JSON.stringify({ skipped: true, reason: 'not live' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const sellerId = record.seller_id
    const streamId = record.id
    const streamTitle = record.title || 'Live Stream'

    console.log(`Seller ${sellerId} started stream "${streamTitle}" (${streamId})`)

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 1. Get seller name
    const { data: sellerProfile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', sellerId)
      .single()

    const sellerName = sellerProfile?.full_name || 'A seller you follow'

    // 2. Get all followers of this seller
    const { data: follows, error: followsError } = await supabase
      .from('follows')
      .select('follower_id')
      .eq('seller_id', sellerId)

    if (followsError) {
      console.error('Error fetching follows:', JSON.stringify(followsError))
      return new Response(JSON.stringify({ error: 'Failed to fetch followers', details: followsError }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    if (!follows || follows.length === 0) {
      console.log('No followers found for seller, nothing to notify.')
      return new Response(JSON.stringify({ success: true, notified: 0 }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const followerIds = follows.map((f: { follower_id: string }) => f.follower_id)
    console.log(`Found ${followerIds.length} followers to notify:`, followerIds)

    // 2b. Filter out followers who disabled live_stream_notifications or push_notifications
    const { data: disabledPrefs } = await supabase
      .from('notification_preferences')
      .select('user_id')
      .in('user_id', followerIds)
      .or('push_notifications.eq.false,live_stream_notifications.eq.false')

    const disabledUserIds = new Set(
      (disabledPrefs || []).map((p: { user_id: string }) => p.user_id)
    )

    const eligibleFollowerIds = followerIds.filter(
      (id: string) => !disabledUserIds.has(id)
    )

    console.log(`${eligibleFollowerIds.length} of ${followerIds.length} followers have notifications enabled`)

    if (eligibleFollowerIds.length === 0) {
      console.log('All followers have notifications disabled — skipping')
      return new Response(JSON.stringify({ success: true, notified: 0, reason: 'all disabled' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }


    // 3. Send OneSignal push to all followers
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID')
    const oneSignalRestApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY')

    if (!oneSignalAppId || !oneSignalRestApiKey) {
      console.error('Missing OneSignal environment variables')
      return new Response(JSON.stringify({ error: 'OneSignal keys not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const notificationBody = {
      app_id: oneSignalAppId,
      // Target eligible followers (those with notifications enabled)
      include_aliases: { external_id: eligibleFollowerIds },
      target_channel: 'push',
      headings: { en: `🎥 ${sellerName} is LIVE!` },
      contents: { en: streamTitle },
      data: {
        type: 'live',
        streamId: streamId,
        deeplink: `/live/${streamId}`
      }
    }

    console.log('Sending OneSignal notification to', eligibleFollowerIds.length, 'followers')

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

    return new Response(JSON.stringify({ success: true, notified: eligibleFollowerIds.length, result }), {
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
