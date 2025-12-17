# Technology Stack

## Current

| Component | Version | Rationale |
|-----------|---------|-----------|
| iOS | 26 (main) / 18 (ext) | Latest features, broad compat |
| Swift | 6.0 | Strict concurrency, modern |
| SwiftUI | Primary | Declarative UI, less code |
| UIKit | Bridges only | System requirements |
| Dependencies | SwiftPM | First-party preferred; avoid heavy libs |

## Backend & Infrastructure

| Component | Usage | Rationale |
|-----------|-------|-----------|
| Supabase | Auth, DB, Storage, Edge Functions | Integrated backend, great DX |
| PostgreSQL | Database (via Supabase) | RLS, JSONB, mature |
| Edge Functions | TypeScript serverless | Canonicalization, upsert logic |
| n8n | Ingestion workflows | Visual automation, connectors |
| GitHub Actions | CI/CD, migrations | Automated deployments |

## Observability & Analytics

| Component | Usage | Rationale |
|-----------|-------|-----------|
| Firebase Analytics | Event tracking, user properties | Industry-standard mobile analytics |
| Firebase Remote Config | Feature flags, A/B testing | Dynamic config without app updates |
| Firebase Crashlytics | Crash reports, non-fatal errors | Comprehensive crash tracking |
| Firebase Performance | Network traces, custom metrics | Performance monitoring |
| PostHog | Product analytics, funnels | Modern analytics, rich insights |
| os.log | Structured logging, signposts | Native, privacy-aware, zero-cost when disabled |

## Dependencies

### iOS (SwiftPM)
- `supabase-swift` v2.0+ - Supabase client SDK
- `firebase-ios-sdk` - Firebase platform (Analytics, RemoteConfig, Crashlytics, Performance)
- `posthog-ios` - PostHog product analytics SDK
- `CStudioKit` (local) - Shared code between app and extension
- `KeychainAccess` - Secure keychain storage (shared app/extension)
- Observation framework (`@Observable`) - Auth state propagation

### Backend
- `normalize-url` (Edge Functions) - URL canonicalization
- PostgreSQL extensions: `pgvector` (future, for AI/RAG)

## Adoption Strategy

**Adopt Fast**: Swift language features, async patterns, SwiftUI APIs  
**Adopt Carefully**: iOS version bumps (consider extension compatibility)  
**Avoid**: Third-party dependencies unless essential

## Version Policy

- Main app: Latest iOS (1 year trailing at most)
- Extensions: iOS 18+ for compatibility
- Swift: Latest stable (current: 6.0)

## Future Considerations

- SwiftData (when mature)
- Swift Testing (as it evolves)
- Observation framework (already using)

---

*Stay current, but prioritize stability over bleeding edge.*

