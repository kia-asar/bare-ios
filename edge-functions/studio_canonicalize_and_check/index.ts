// Edge Function: studio_canonicalize_and_check
// Canonicalize a URL and check if it already exists for the user

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import normalizeUrl from 'https://esm.sh/normalize-url@8.0.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Request {
  original_url: string
}

interface Response {
  canonical_url: string
  exists: boolean
  post_id?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get auth token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    // Parse request
    const { original_url } = await req.json() as Request

    if (!original_url) {
      return new Response(
        JSON.stringify({ error: 'Missing original_url' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Canonicalize URL
    const canonical_url = normalizeUrl(original_url, {
      stripHash: true,
      stripProtocol: false,
      stripWWW: false,
      removeQueryParameters: [
        /^utm_\w+/i,
        'fbclid',
        'gclid',
        'mc_eid',
        'msclkid',
        'ref',
        'ref_src',
        'ref_url'
      ],
      sortQueryParameters: true,
    })

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Check if post exists
    const { data, error } = await supabaseClient
      .from('studio_posts')
      .select('id')
      .eq('canonical_url', canonical_url)
      .maybeSingle()

    if (error) {
      console.error('Database error:', error)
      throw error
    }

    const response: Response = {
      canonical_url,
      exists: !!data,
      post_id: data?.id
    }

    return new Response(
      JSON.stringify(response),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})


