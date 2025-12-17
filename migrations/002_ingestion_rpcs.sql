-- Migration: 002_ingestion_rpcs.sql
-- Description: RPC functions for ingestion job management
-- Date: 2025-01-07

-- ============================================================================
-- Claim an ingestion job (SECURITY DEFINER for service role access)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.studio_claim_ingestion_job(worker_id TEXT)
RETURNS public.studio_ingestion_jobs
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    job public.studio_ingestion_jobs;
BEGIN
    -- Find one eligible job and lock it
    SELECT * INTO job
    FROM public.studio_ingestion_jobs
    WHERE status IN ('queued', 'retry')
      AND next_run_at <= NOW()
    ORDER BY next_run_at ASC
    FOR UPDATE SKIP LOCKED
    LIMIT 1;

    -- If no job found, return NULL
    IF job.id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Mark as processing and set lease
    UPDATE public.studio_ingestion_jobs
    SET status = 'processing',
        locked_by = worker_id,
        locked_at = NOW(),
        updated_at = NOW()
    WHERE id = job.id
    RETURNING * INTO job;

    RETURN job;
END;
$$;

-- ============================================================================
-- Complete an ingestion job
-- ============================================================================

CREATE OR REPLACE FUNCTION public.studio_complete_ingestion_job(
    job_id UUID,
    new_payload JSONB DEFAULT NULL,
    new_thumbnail_url TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the job status
    UPDATE public.studio_ingestion_jobs
    SET status = 'completed',
        updated_at = NOW()
    WHERE id = job_id;

    -- Update the related post
    UPDATE public.studio_posts
    SET payload = COALESCE(new_payload, payload),
        thumbnail_url = COALESCE(new_thumbnail_url, thumbnail_url),
        ingestion_status = 'completed',
        ingested_at = NOW(),
        ingestion_error = NULL,
        updated_at = NOW()
    WHERE id = (SELECT post_id FROM public.studio_ingestion_jobs WHERE id = job_id);
END;
$$;

-- ============================================================================
-- Retry an ingestion job with exponential backoff
-- ============================================================================

CREATE OR REPLACE FUNCTION public.studio_retry_ingestion_job(
    job_id UUID,
    error_message TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_attempts INT;
    max_attempts INT := 5;
    new_status TEXT;
    backoff_seconds INT;
BEGIN
    -- Get current attempts
    SELECT attempts INTO current_attempts
    FROM public.studio_ingestion_jobs
    WHERE id = job_id;

    -- Increment attempts
    current_attempts := current_attempts + 1;

    -- Determine new status
    IF current_attempts >= max_attempts THEN
        new_status := 'failed';
    ELSE
        new_status := 'retry';
    END IF;

    -- Calculate exponential backoff (min 1 minute, doubles each time, max 60 minutes)
    backoff_seconds := LEAST(60 * POWER(2, current_attempts), 3600);

    -- Update the job
    UPDATE public.studio_ingestion_jobs
    SET status = new_status,
        attempts = current_attempts,
        next_run_at = NOW() + (backoff_seconds || ' seconds')::INTERVAL,
        last_error = error_message,
        locked_by = NULL,
        locked_at = NULL,
        updated_at = NOW()
    WHERE id = job_id;

    -- Update the related post with error if failed
    IF new_status = 'failed' THEN
        UPDATE public.studio_posts
        SET ingestion_status = 'failed',
            ingestion_error = error_message,
            updated_at = NOW()
        WHERE id = (SELECT post_id FROM public.studio_ingestion_jobs WHERE id = job_id);
    ELSE
        UPDATE public.studio_posts
        SET ingestion_status = 'processing',
            updated_at = NOW()
        WHERE id = (SELECT post_id FROM public.studio_ingestion_jobs WHERE id = job_id);
    END IF;
END;
$$;

-- ============================================================================
-- Enqueue a job for a post (idempotent)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.studio_enqueue_ingestion_job(p_post_id UUID)
RETURNS public.studio_ingestion_jobs
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    job public.studio_ingestion_jobs;
BEGIN
    -- Try to insert a new job
    INSERT INTO public.studio_ingestion_jobs (post_id, status, next_run_at)
    VALUES (p_post_id, 'queued', NOW())
    ON CONFLICT (post_id) DO UPDATE
    SET status = CASE
            WHEN studio_ingestion_jobs.status IN ('completed', 'failed') THEN 'queued'
            ELSE studio_ingestion_jobs.status
        END,
        next_run_at = CASE
            WHEN studio_ingestion_jobs.status IN ('completed', 'failed') THEN NOW()
            ELSE studio_ingestion_jobs.next_run_at
        END,
        attempts = CASE
            WHEN studio_ingestion_jobs.status IN ('completed', 'failed') THEN 0
            ELSE studio_ingestion_jobs.attempts
        END,
        updated_at = NOW()
    RETURNING * INTO job;

    RETURN job;
END;
$$;

-- ============================================================================
-- Record migration
-- ============================================================================

INSERT INTO public.studio_migrations (filename)
VALUES ('002_ingestion_rpcs.sql')
ON CONFLICT (filename) DO NOTHING;


