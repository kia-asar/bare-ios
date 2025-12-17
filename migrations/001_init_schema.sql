-- Migration: 001_init_schema.sql
-- Description: Initialize studio_posts and studio_ingestion_jobs tables with RLS
-- Date: 2025-01-07

-- Create migration ledger table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.studio_migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- studio_posts table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.studio_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    original_url TEXT NOT NULL,
    canonical_url TEXT NOT NULL,
    thumbnail_url TEXT,
    user_instructions TEXT,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    ingestion_status TEXT NOT NULL DEFAULT 'pending' CHECK (ingestion_status IN ('pending', 'processing', 'completed', 'failed')),
    ingestion_error TEXT,
    ingested_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT studio_posts_user_canonical_url_unique UNIQUE (user_id, canonical_url)
);

-- Indexes for studio_posts
CREATE INDEX IF NOT EXISTS studio_posts_user_created_at_idx ON public.studio_posts (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS studio_posts_created_at_idx ON public.studio_posts (created_at);
CREATE INDEX IF NOT EXISTS studio_posts_canonical_url_idx ON public.studio_posts (canonical_url);
CREATE INDEX IF NOT EXISTS studio_posts_payload_gin_idx ON public.studio_posts USING gin (payload);

-- Enable RLS on studio_posts
ALTER TABLE public.studio_posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for studio_posts
DROP POLICY IF EXISTS "studio_posts readable by owner" ON public.studio_posts;
CREATE POLICY "studio_posts readable by owner"
    ON public.studio_posts
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "studio_posts insertable by owner" ON public.studio_posts;
CREATE POLICY "studio_posts insertable by owner"
    ON public.studio_posts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "studio_posts updatable by owner" ON public.studio_posts;
CREATE POLICY "studio_posts updatable by owner"
    ON public.studio_posts
    FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "studio_posts deletable by owner" ON public.studio_posts;
CREATE POLICY "studio_posts deletable by owner"
    ON public.studio_posts
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- studio_ingestion_jobs table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.studio_ingestion_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.studio_posts(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'retry', 'completed', 'failed')),
    attempts INT NOT NULL DEFAULT 0,
    next_run_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_by TEXT,
    locked_at TIMESTAMPTZ,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT studio_ingestion_jobs_post_id_unique UNIQUE (post_id)
);

-- Indexes for studio_ingestion_jobs
CREATE INDEX IF NOT EXISTS studio_ingestion_jobs_next_run_idx ON public.studio_ingestion_jobs (next_run_at);
CREATE INDEX IF NOT EXISTS studio_ingestion_jobs_status_idx ON public.studio_ingestion_jobs (status);

-- Enable RLS on studio_ingestion_jobs (restrict access to service role only)
ALTER TABLE public.studio_ingestion_jobs ENABLE ROW LEVEL SECURITY;

-- No policies for studio_ingestion_jobs - access only via SECURITY DEFINER RPCs

-- ============================================================================
-- Updated_at trigger function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to studio_posts
DROP TRIGGER IF EXISTS update_studio_posts_updated_at ON public.studio_posts;
CREATE TRIGGER update_studio_posts_updated_at
    BEFORE UPDATE ON public.studio_posts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Apply updated_at trigger to studio_ingestion_jobs
DROP TRIGGER IF EXISTS update_studio_ingestion_jobs_updated_at ON public.studio_ingestion_jobs;
CREATE TRIGGER update_studio_ingestion_jobs_updated_at
    BEFORE UPDATE ON public.studio_ingestion_jobs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- Record migration
-- ============================================================================

INSERT INTO public.studio_migrations (filename)
VALUES ('001_init_schema.sql')
ON CONFLICT (filename) DO NOTHING;


