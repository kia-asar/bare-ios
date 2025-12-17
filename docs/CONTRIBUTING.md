# Contributing Guidelines

## Development Setup

```bash
Xcode 16+, iOS 26 SDK
Swift 6.0 with strict concurrency
Supabase project (see SETUP.md)
```

Follow [SETUP.md](../SETUP.md) for complete configuration including:
- Supabase credentials and database setup
- CStudioKit package integration
- Entitlements configuration (Keychain, App Groups, URL scheme)

## Plan Before Implementing

- Outline approach and key edge cases before coding
- Validate fit with architecture and simplicity goals

## Code Style

**Clarity over cleverness**. Prioritize readable, maintainable code.

- SwiftUI conventions (declarative, composition)
- Explicit types when improving clarity
- `async/await` for asynchronous code
- No force unwraps in production code

### UI & Design System

**Use DesignTokens for all UI values** (import from `CStudioKit`):

```swift
import CStudioKit

// ✅ Correct
.padding(DesignTokens.Spacing.md)
.background(DesignTokens.Colors.surfaceLight)
.cornerRadius(DesignTokens.CornerRadius.md)

// ❌ Incorrect
.padding(16)
.background(Color.gray.opacity(0.1))
.cornerRadius(12)
```

**Rules:**
- **Never hardcode** colors with opacity (e.g., `Color.gray.opacity(0.1)`)
- **Never hardcode** spacing values (e.g., `.padding(16)`)
- **Never hardcode** corner radius (e.g., `.cornerRadius(12)`)
- **Applies to ALL targets**: main app, Share Extension, widgets, notifications, Watch app, etc.
- Use semantic token names that describe purpose, not appearance
- Add new tokens to `DesignTokens.swift` (in CStudioKit) when needed, don't create one-off values

**Why CStudioKit?**
- DesignTokens lives in CStudioKit so it's accessible to all targets
- Ensures consistent UI across main app, extensions, and widgets
- Single source of truth for design updates

**Available Tokens:**
- `DesignTokens.Colors.*` - backgroundOverlay, surfaceLight, surfaceMedium, borderLight, borderError, interactiveOverlay, primaryGradientStart, shadowLight, shadowBlue
- `DesignTokens.Spacing.*` - xs (8), sm (12), md (16), lg (20), xl (24), xxl (32), xxxl (40)
- `DesignTokens.CornerRadius.*` - sm (8), md (12), lg (16), xl (20)

### Analytics & Logging Rules

#### Event Naming
- Use **snake_case**: `post_created`, `share_extension_opened`
- Include action verb: `user_signed_in`, `link_preview_loaded`

#### PII Policy
- **NEVER** include PII in events/parameters
- Use `AppLogger.logPrivate()` for sensitive values in logs

#### Logging Categories
Use predefined categories: `AppLogger.auth`, `AppLogger.network`, `AppLogger.analytics`, etc.

See [OBSERVABILITY.md](./OBSERVABILITY.md) for full guidelines.

## Making Changes

1. Keep changes focused and atomic
2. Test in target environment (simulator + device)
3. Verify strict concurrency compliance
4. Update docs if changing architecture

## MVVM Usage

- Introduce a `ViewModel` when logic is beyond trivial or side effects exist
- Keep views thin: no networking/storage in views
- Prefer `@Observable` view models; use `@StateObject` only for `ObservableObject`
- Add focused unit tests for view models when practical

## Branch & PR Conventions

- Branches: `feat/*`, `fix/*`, `chore/*`
- PR titles: Conventional Commit style, e.g., `feat(share): describe change`

## Commit Messages

- Imperative mood: "Add", "Fix", "Refactor"
- Explain the why when not obvious; keep concise
- Do not mention AI/tools in commit messages

## Testing

- Test share extension in real apps (Safari, Photos, etc.)
- Verify iOS 18+ compatibility for extensions
- Check both light/dark mode
- Verify key screens on multiple device sizes
- Basic accessibility checks: Dynamic Type, VoiceOver
- Test auth flow (magic link) end-to-end
- Verify posts sync between app and extension

## Naming Conventions

### Database & Backend
- **All tables, functions, buckets**: Prefix with `studio_` (e.g., `studio_posts`, `studio_claim_ingestion_job`)
- **RLS policies**: Descriptive names in quotes (e.g., `"studio_posts readable by owner"`)
- **Edge Functions**: Prefix with `studio_` (e.g., `studio_create_post_with_canonicalization`)

### Swift/iOS
- Standard Swift conventions (PascalCase types, camelCase properties/functions)
- Prefer protocol-first for repositories/services that need mocking (e.g., `PostRepositoryProtocol`)
- View models: `ViewModel` suffix (e.g., `ContentViewModel`)
- **Configuration constants**: **Always** use `AppConfig` - never hardcode bundle IDs, URL schemes, or identifiers

## Adding Migrations

1. Create a new `.sql` file in `migrations/` with a sequential prefix:
   ```
   migrations/003_add_feature.sql
   ```

2. Include a migration ledger insert at the end:
   ```sql
   INSERT INTO public.studio_migrations (filename)
   VALUES ('003_add_feature.sql')
   ON CONFLICT (filename) DO NOTHING;
   ```

3. Apply manually or wait for CI/CD pipeline

## Adding a New Service/Repository

1. Define a protocol in CStudioKit (e.g., `FooRepositoryProtocol`)
2. Implement the concrete type (e.g., `FooRepository`)
3. Add to `Dependencies` if app-wide
4. Wire in `LiveDependencies` initializer
5. Inject via initializer in views/view models

Note: Authentication uses a stateful `AuthManager` (@Observable) as the single source of truth, not a protocol service.

## Adding an Edge Function or RPC

1. **Edge Function**: Create `edge-functions/studio_<name>/index.ts`
2. **RPC**: Add to a migration file as a `CREATE FUNCTION` with `SECURITY DEFINER`
3. Document contracts in ARCHITECTURE.md
4. Deploy via Supabase CLI or CI

## RLS Best Practices

- Always enable RLS on new tables: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`
- Default policy: owner-only via `auth.uid() = user_id`
- Use `SECURITY DEFINER` functions for service-role operations (e.g., job management)
- Test with negative cases (ensure users can't access other users' data)

---

*Focus on intent, not ceremony.*

