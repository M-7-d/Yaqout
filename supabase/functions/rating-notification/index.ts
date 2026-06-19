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
    console.log('Received rating webhook payload:', JSON.stringify(payload))

    const record = payload.record

    if (!record) {
      console.error('No record in payload')
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    if (!record.product_id || !record.reviewer_id) {
      console.error('Missing required fields:', JSON.stringify(record))
      return new Response(JSON.stringify({ error: 'Missing product_id or reviewer_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 1. Get the product to find the seller_id
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('seller_id, title')
      .eq('id', record.product_id)
      .single()

    if (productError || !product) {
      console.error('Product fetch error:', JSON.stringify(productError))
      return new Response(JSON.stringify({ error: 'Product not found', details: productError }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    console.log('Product found:', JSON.stringify(product))

    const sellerId = product.seller_id

    // Don't notify if the seller is reviewing their own product
    if (record.reviewer_id === sellerId) {
      console.log('Reviewer is the seller — skipping notification')
      return new Response(JSON.stringify({ skipped: true, reason: 'self-review' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 2. Check seller's notification preferences
    const { data: prefs } = await supabase
      .from('notification_preferences')
      .select('push_notifications, ratings_reviews')
      .eq('user_id', sellerId)
      .single()

    if (prefs) {
      if (prefs.push_notifications === false) {
        console.log('Seller has push_notifications disabled — skipping')
        return new Response(JSON.stringify({ skipped: true, reason: 'push_notifications off' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
      if (prefs.ratings_reviews === false) {
        console.log('Seller has ratings_reviews disabled — skipping')
        return new Response(JSON.stringify({ skipped: true, reason: 'ratings_reviews off' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // 3. Get reviewer's profile name
    const { data: reviewerProfile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', record.reviewer_id)
      .single()

    const reviewerName = reviewerProfile?.full_name || 'Someone'
    const rating = record.rating || 0
    const productTitle = product.title || 'your product'

    // Build star string for display (e.g. "⭐⭐⭐⭐⭐")
    const stars = '⭐'.repeat(Math.min(rating, 5))

    // 4. Read OneSignal credentials
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID')
    const oneSignalRestApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY')

    if (!oneSignalAppId || !oneSignalRestApiKey) {
      console.error('Missing OneSignal env vars')
      return new Response(JSON.stringify({ error: 'OneSignal keys not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 5. Build notification content
    const heading = `${stars} New Rating!`
    let content = `${reviewerName} rated "${productTitle}" ${rating}/5`
    if (record.comment) {
      content += `: "${record.comment}"`
    }

    const notificationBody = {
      app_id: oneSignalAppId,
      include_aliases: { external_id: [sellerId] },
      target_channel: 'push',
      headings: { en: heading },
      contents: { en: content },
      data: {
        type: 'rating',
        productId: record.product_id,
        reviewId: record.id
      }
    }

    console.log('Sending rating notification:', JSON.stringify(notificationBody))

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
