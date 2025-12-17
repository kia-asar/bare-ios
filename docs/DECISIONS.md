# Key Decisions

## Swift 6.0 Strict Concurrency
**Why**: Eliminates data races at compile time. Future-proof.  
**Trade-off**: More explicit annotations, worth it for safety.

## SwiftUI-First (92%)
**Why**: Modern, declarative, less code. Apple's recommended path.  
**Trade-off**: UIKit bridge needed for system APIs (15 lines acceptable).

## iOS 26 Main / iOS 18 Extension
**Why**: Latest features in main app, broad compatibility for extension.  
**Trade-off**: Can't use iOS 26-only APIs in extension yet.

## async/await Over Closures
**Why**: More readable, structured cancellation, Swift 6.0 aligned.  
**Trade-off**: Requires iOS 13+, already well past that threshold.

## Minimal Architecture
**Why**: Fast iteration, easy to understand, room to grow.  
**Trade-off**: Add structure (MVVM, etc.) as complexity increases.

## Selective MVVM
**Why**: Improves clarity/testability for complex flows while keeping simple views lean.  
**Trade-off**: Added overhead for small screens—use only when justified.

---

## Backend & Data

### Supabase for Backend (2025-01-07)
**Decision**: Use Supabase for auth, database, storage, and Edge Functions  
**Context**: Need rapid development with built-in auth, RLS, and serverless functions  
**Consequences**: (+) Fast setup, great DX, type-safe SDK; (−) Vendor lock-in, less control over infrastructure

### Single Table v1 with JSONB Payload (2025-01-07)
**Decision**: Start with `studio_posts` table using flexible `payload jsonb` field  
**Context**: Ingestion output evolves; avoid frequent migrations early  
**Consequences**: (+) Flexibility, fast iteration; (−) Less type safety, harder querying specific fields (mitigated with GIN indexes)

### Server-Side URL Canonicalization (2025-01-07)
**Decision**: Canonicalize URLs in Edge Functions, not client-only  
**Context**: Single source of truth; hotfix without app updates  
**Consequences**: (+) Consistency, evolvable rules; (−) Slightly higher latency vs pure client

### studio_ Prefix for All Schema Objects (2025-01-07)
**Decision**: Prefix tables, functions, buckets with `studio_`  
**Context**: Shared Supabase project with other services  
**Consequences**: (+) Clear namespace, no collisions; (−) Slightly longer names

### Jobs + DB Webhook Ingestion (2025-01-07)
**Decision**: Durable `studio_ingestion_jobs` table + DB webhook → n8n  
**Context**: Need retries, backoff, observability, and near real-time  
**Consequences**: (+) Reliable, visible, resilient; (−) More components vs direct webhook-only

### Remote-Only Migrations (psql + ledger) (2025-01-07)
**Decision**: SQL files + CI with `studio_migrations` ledger; no local DB required  
**Context**: Avoid running Supabase stack locally  
**Consequences**: (+) Simpler dev environment; (−) Less local testing (can use Supabase staging project)

## iOS Architecture

### CStudioKit Shared Package (2025-01-07)
**Decision**: Create local Swift package for code shared between app and extension  
**Context**: Extensions cannot link to app target code  
**Consequences**: (+) Clean separation, reusable; (−) Extra package management

### Protocol-First DI (2025-01-07)
**Decision**: Lightweight DI with protocols, no heavy container  
**Context**: Testability without third-party DI framework  
**Consequences**: (+) Testable, simple, no dependencies; (−) Manual wiring (acceptable at this scale)

### Email Magic Link Only (v1) (2025-01-07)
**Decision**: Start with email magic link; defer Sign in with Apple
**Context**: Fastest auth to MVP; magic links are passwordless and secure
**Consequences**: (+) Fast implementation, great UX; (−) No Apple/Google SSO yet (add later)

### Observability: Firebase + PostHog + os.log (2025-01-09)
**Decision**: Adopt Firebase (Analytics/RemoteConfig/Crashlytics/Performance) + PostHog + os.log for observability; strict no-IDFA policy
**Context**: Need production-grade analytics, feature flags, crash reporting, and performance monitoring with extension support
**Consequences**:
- (+) Industry-standard stack, proven reliability, rich insights
- (+) Protocol-driven architecture in CStudioKit enables testing and flexibility
- (+) Extension observability via App Group buffering with no Firebase SDK linkage
- (+) Remote Config enables rapid feature rollout without app updates
- (+) Privacy-first: no IDFA, no ATT prompt, privacy manifests enforced by CI
- (+) os.log provides zero-cost structured logging with signposts
- (−) Additional SDKs increase binary size (~2-3MB for Firebase + PostHog)
- (−) Extension analytics delayed (buffered until app launch)
- (−) Dual analytics providers (Firebase + PostHog) add complexity, justified by complementary strengths

---

## Process

- Add a dated entry per change
- Include: Decision, Context, Consequences

```text
Decision: <what>
Context: <why now>
Consequences: <trade-offs>
```

*Document major pivots here. Date entries when added.*

