# n8n Ingestion Workflow

Workflow for processing content ingestion jobs triggered by Supabase database webhooks.

## Setup

1. **Import workflow**: Import `n8n_workflow.json` into n8n
2. **Configure Supabase Config node**: Set `supabaseUrl` to your project URL
3. **Create Supabase API credential**:
   - Type: **Supabase API**
   - Host: Your Supabase project URL
   - Service Role Secret: Your service role key (not anon key)
4. **Attach credential** to: `Claim Job`, `Fetch Post Data`, `Complete Job`, `Retry Job`
5. **Configure Supabase webhook**: Point to n8n webhook URL (`/webhook/ingestion-webhook`)

## Workflow Flow

```
Webhook → Supabase Config → Claim Job → Format Response
    ↓
[Job?] → [No] → End
    ↓ [Yes]
Fetch Post → Fetch URL → Extract Metadata → Process Thumbnail
    ↓
[Success?] → [Yes] → Complete Job
    ↓ [No]
Error Handler → Retry Job
```

## Key Concepts

### Job Queue Pattern
- Jobs are claimed atomically via `studio_claim_ingestion_job` RPC (prevents duplicate processing)
- Worker ID (`n8n-worker-1`) identifies this n8n instance
- Jobs retry with exponential backoff (2min → 4min → 8min → 16min → 32min)
- Max 5 attempts, then marked as `failed`

### Metadata Extraction
- Extracts: title, description, thumbnail_url, site_name, author
- Decodes HTML entities (`&amp;` → `&`)
- Resolves relative image URLs to absolute
- Validates thumbnail URLs (http/https only)

### Error Handling
- HTTP errors route to Error Handler node
- Error Handler formats error and passes to Retry Job
- Retry Job calls `studio_retry_ingestion_job` RPC with error message
- Error messages limited to 500 chars

### Configuration
- **Supabase Config node**: Centralizes `supabaseUrl` and `workerId` (non-secret)
- **Supabase API credential**: Stores service role key (secret)
- URL changes only require updating the Config node

## RPC Endpoints Used

- `studio_claim_ingestion_job(worker_id)` - Claims next available job
- `studio_complete_ingestion_job(job_id, new_payload, new_thumbnail_url)` - Marks job complete
- `studio_retry_ingestion_job(job_id, error_message)` - Schedules retry with backoff

## Troubleshooting

**Jobs not claimed**: Check credential is attached, verify jobs exist with `status IN ('queued', 'retry')` and `next_run_at <= NOW()`

**Metadata extraction fails**: Check URL accessibility, some sites block bots or require JavaScript

**Jobs stuck**: Manually reset: `UPDATE studio_ingestion_jobs SET status = 'queued', locked_by = NULL WHERE status = 'processing' AND locked_at < NOW() - INTERVAL '10 minutes'`
