// Edge Function: studio_create_post_with_canonicalization
// Create or update a post with URL canonicalization and enqueue ingestion

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import normalizeUrl from 'https://esm.sh/normalize-url@8.0.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  original_url: string
  user_instructions?: string
  thumbnail_url?: string
}

interface Post {
  id: string
  user_id: string
  original_url: string
  canonical_url: string
  thumbnail_url?: string
  user_instructions?: string
  payload: Record<string, any>
  ingestion_status: string
  ingestion_error?: string
  ingested_at?: string
  created_at: string
  updated_at: string
}

interface Response {
  created: boolean
  post: Post
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
    const body = await req.json() as RequestBody

    if (!body.original_url) {
      return new Response(
        JSON.stringify({ error: 'Missing original_url' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Canonicalize URL
    const canonical_url = normalizeUrl(body.original_url, {
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

    // Create Supabase client with service role for RPC access
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get user ID from auth
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    // Upsert post
    const { data: posts, error: upsertError } = await supabaseClient
      .from('studio_posts')
      .upsert(
        {
          user_id: user.id,
          original_url: body.original_url,
          canonical_url: canonical_url,
          thumbnail_url: body.thumbnail_url,
          user_instructions: body.user_instructions,
          payload: {},
          ingestion_status: 'pending',
        },
        {
          onConflict: 'user_id,canonical_url',
          ignoreDuplicates: false,
        }
      )
      .select()

    if (upsertError) {
      console.error('Upsert error:', upsertError)
      throw upsertError
    }

    const post = posts?.[0]
    if (!post) {
      throw new Error('Failed to create or retrieve post')
    }

    // Check if this was a new insert or an update
    const created = post.created_at === post.updated_at

    // Enqueue ingestion job using RPC
    const { error: enqueueError } = await supabaseClient
      .rpc('studio_enqueue_ingestion_job', { p_post_id: post.id })

    if (enqueueError) {
      console.error('Enqueue error:', enqueueError)
      // Don't fail the request, just log
    }

    const response: Response = {
      created,
      post: post as Post
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


