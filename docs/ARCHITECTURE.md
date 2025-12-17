# Architecture Guidelines

## Core Principles

**SwiftUI-First**: Prefer SwiftUI for all new development. Use UIKit only when system APIs require it (e.g., share extension bridge).

**Strict Concurrency**: Swift 6.0 strict concurrency mode enabled. Use `async/await`, `@MainActor`, and structured concurrency.

**Minimal Bridges**: Keep UIKit bridges thin (<20 lines). All logic lives in SwiftUI.

**Errors**: Prefer `throws`; fail fast, no silent failures.

**Simplicity & Single Responsibility**: Choose the simplest solution; one clear purpose per type.

**Reuse (DRY)**: Extract shared logic into reusable components/utilities.

## Project Structure Conventions

**⚠️ CRITICAL: Maintain Strict Consistency**

This project follows **strict directory conventions**. Before adding ANY new file:

1. **Check existing patterns** - Look at where similar files live
2. **Follow established structure** - Use existing directories
3. **Never diverge** - Don't create new top-level directories without team discussion
4. **Ask first** - If unsure where a file should go, ask before creating

## Module Structure

### BareKit (Shared Package)
Protocol-driven shared module used by main app, Share Extension, Widgets, and Siri Extensions:

```
BareKit/
├── Config/                   # AppConfig (constants), AppConstants, SupabaseConfig
├── Core/
│   ├── Dependencies/         # Dependencies (actor DI), SupabaseClientProvider
│   ├── AppGroup/             # App Group storage helpers
│   ├── Observability/        # Analytics, flags, crash, perf protocols + AppLogger
│   └── PushNotifications/    # PushNotificationService protocol, NoopPushNotificationService
├── Utilities/                # SemanticVersion, shared utilities
├── Auth/                     # AuthManager (@Observable, magic link, session state)
├── Navigation/               # Navigator (@Observable, navigation state management)
├── Posts/
│   ├── Models/               # Post, JSONValue, input/response DTOs
│   └── PostRepository        # CRUD operations via Supabase
└── AI/                       # AIChatService (placeholder for future)
```

### Main App (`bare`)

```
bare/
├── Core/                         # App lifecycle (bareApp.swift, AppDelegate), DI initialization
├── Config/                       # ObservabilityConfig, GoogleService-Info.plist, RemoteConfigDefaults
├── Configuration/                # ImageConfiguration (Nuke setup)
├── Services/
│   ├── Observability/            # Firebase & PostHog adapters, multiplex, relay
│   └── PushNotifications/        # OneSignalPushNotificationService (actor-based)
├── Extensions/                   # Swift extensions (View+Navigation, Notification+Extensions)
├── Navigation/                   # AppRoute (route definitions)
├── Models/                       # UI-specific models (ContentItem)
├── ViewModels/                   # @Observable view models (ContentViewModel)
└── Views/                        # SwiftUI views (ContentView, SignInView, PushPermissionPrimer)
```

### Share Extension

```
ShareExtension/
├── Models/              # LinkPreview
├── Services/            # LinkPreviewService (HTML parsing)
└── UI/                  # ShareView (integrated with BareKit + observability)
                         # Uses AppLogger + AppGroupEventBuffer (no Firebase SDKs)
```

## Data Model

### Database Schema (Supabase)

**studio_posts** - User saved posts with flexible JSONB payload
- `id`, `user_id`, `original_url`, `canonical_url`
- `thumbnail_url`, `user_instructions`, `payload` (JSONB)
- `ingestion_status`, `ingestion_error`, `ingested_at`
- `created_at`, `updated_at`
- Unique constraint on `(user_id, canonical_url)`
- Owner-only RLS policies

**studio_ingestion_jobs** - Durable job queue for content processing
- `id`, `post_id` (FK), `status`, `attempts`
- `next_run_at`, `locked_by`, `locked_at`, `last_error`
- Managed via SECURITY DEFINER RPCs

## Dependency Injection

Lightweight DI with protocol-first repos and a single actor container:

```swift
protocol PostRepositoryProtocol: Sendable { ... }

// Actor container; initialize once at app start
public actor DependencyContainer {
    public static let shared: DependencyContainer
    public func initialize(config: SupabaseConfig, observability: Observability) async
    public var current: Dependencies { get }
    public func getAuthManager() async -> AuthManager
}
```

**Testability**: Repositories are protocol-based for easy mocking. `AuthManager` is the stateful source of truth for auth. Observability services use protocol facades with no-op implementations for testing.

## Observability Pipeline

Unified observability stack combining Firebase (Analytics, Remote Config, Crashlytics, Performance), PostHog (product analytics), and os.log (structured logging).

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ App Target                                                  │
│                                                             │
│  ┌─────────────┐                                           │
│  │ Observability│ (facade)                                 │
│  │  ├─ analytics (MultiplexAnalyticsService)               │
│  │  │   ├─ FirebaseAnalyticsService                        │
│  │  │   └─ PostHogAnalyticsService                         │
│  │  ├─ flags (FirebaseRemoteConfigService)                 │
│  │  ├─ crash (FirebaseCrashReportingService)               │
│  │  └─ perf (FirebasePerformanceTraceService)              │
│  └─────────────┘                                           │
│         │                                                   │
│         │ (initialized at app launch)                       │
│         ▼                                                   │
│  DependencyContainer ────> LiveDependencies                │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Share Extension                                             │
│                                                             │
│  ┌─────────────────────┐                                   │
│  │ AppLogger           │ (os.log categories + signposts)   │
│  │ AppGroupEventBuffer │ (JSONL buffering)                 │
│  └─────────────────────┘                                   │
│         │                                                   │
│         ▼                                                   │
│  App Group Container (shared storage)                       │
│         │                                                   │
└─────────│───────────────────────────────────────────────────┘
          │
          │ (drained on app launch)
          ▼
    AnalyticsEventRelay ────> Firebase + PostHog
```

### Key Design Decisions

1. **SDKs in app only**: Firebase SDKs (Analytics, Crashlytics, etc.) are not extension-safe and only linked in the app target
2. **Protocol-driven**: All services implement protocols (`AnalyticsService`, `FeatureFlagService`, etc.) defined in BareKit for testability
3. **Extension buffering**: Share Extension buffers events to App Group, relayed by app on next launch with UUID deduplication
4. **Remote Config mirroring**: App fetches Remote Config and mirrors active flags to App Group UserDefaults for extension access
5. **No-IDFA policy**: Strict enforcement via privacy manifests and CI checks—no advertiser identifiers or ATT prompts

### Consent & Privacy

- **Debug**: Analytics disabled by default
- **Release**: Analytics enabled (implied consent via privacy policy)
- **No tracking**: `NSPrivacyTracking = false` in privacy manifests
- **Privacy-first**: os.log with automatic PII redaction, no PII in analytics events

See [OBSERVABILITY.md](./OBSERVABILITY.md) for detailed usage guidelines.

## Push Notifications

Protocol-based push notification system using OneSignal with permission pre-prompting and comprehensive analytics.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ BareKit (Protocol Layer)                                 │
│                                                             │
│  PushNotificationService ─────┐                            │
│  ├─ initialize(appId)          │                            │
│  ├─ getPermissionStatus()      │                            │
│  ├─ requestPermission()        │                            │
│  ├─ setExternalUserId()        │                            │
│  ├─ setNotificationOpenedHandler() │                        │
│  └─ addPermissionObserver()    │                            │
│                                 │                            │
│  NoopPushNotificationService   │ (for testing/previews)     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                                  │
                                  │ (implemented in main app)
                                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Main App (Implementation)                                   │
│                                                             │
│  OneSignalPushNotificationService (actor-based)             │
│  ├─ ServiceState (actor for thread-safe state)             │
│  ├─ NotificationOpenedListener (Obj-C bridge)              │
│  └─ PermissionObserver (Obj-C bridge)                       │
│                                                             │
│  PushPermissionPrimer (SwiftUI pre-prompt)                  │
│  ├─ Context-aware UI (first-time vs denied)                │
│  ├─ Settings deep link for re-engagement                    │
│  └─ Uses DesignTokens exclusively                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Protocol-based**: Service interface defined in BareKit for testability and flexibility
2. **Actor isolation**: Swift 6 actor pattern for thread-safe state management, bridging OneSignal's callback API
3. **Pre-prompt UX**: Custom UI shown before system dialog to educate users and improve conversion
4. **Permission observers**: Track all permission state changes including Settings revocations
5. **Auth sync**: User IDs automatically synced with OneSignal on login/logout for targeted notifications
6. **Deep linking**: Type-safe navigation from notification payloads via `AppRoute` enum
7. **Required configuration**: App fails fast with clear error if OneSignal not configured (no silent degradation)

### Configuration Pattern

Uses `.xcconfig` → `Info.plist` → `ObservabilityConfig.swift` pattern (consistent with Firebase/PostHog):

```swift
// Dev.xcconfig / Prod.xcconfig (git-ignored)
ONESIGNAL_APP_ID = your-app-id-here

// Info.plist (auto-injected at build time)
<key>ONESIGNAL_APP_ID</key>
<string>$(ONESIGNAL_APP_ID)</string>

// ObservabilityConfig.swift (runtime access)
public let oneSignalAppId: String?
```

### Permission Flow

**First Launch** (`.notDetermined`):
1. User signs in and sees content (establishes value)
2. After 1 second, pre-prompt appears with value proposition
3. User taps "Enable Notifications" → system permission dialog
4. Analytics tracked at each step for funnel analysis

**Previously Denied** (`.denied`):
1. Pre-prompt shows different messaging and "Open Settings" button
2. Deep links to iOS Settings for re-engagement
3. Permission observer detects if user enables in Settings

**Already Authorized** (`.authorized`):
- Pre-prompt skipped entirely
- No unnecessary UI shown

### Analytics Events

All permission funnel steps tracked:
- `push_permission_initial_state` - App launch (status: notDetermined/denied/authorized/provisional)
- `push_permission_pre_prompt_accepted` - User tapped "Enable"
- `push_permission_pre_prompt_dismissed` - User tapped "Not Now"
- `push_permission_system_prompt_result` - iOS dialog (granted: true/false)
- `push_permission_state_changed` - Any state change (catches Settings revocations)
- `push_permission_settings_opened` - Deep link to Settings used

### Swift 6 Concurrency

**Actor Pattern for State:**
```swift
private actor ServiceState {
    private var notificationOpenedHandler: (@Sendable (PushNotificationData) -> Void)?
    private var permissionObservers: [(@Sendable (Bool) -> Void)] = []

    func handleNotificationData(...) { }
    func notifyPermissionChange(_ granted: Bool) { }
}
```

**Bridging Objective-C Callbacks:**
```swift
private final class PermissionObserver: NSObject, OSNotificationPermissionObserver, @unchecked Sendable {
    private let state: ServiceState

    nonisolated func onNotificationPermissionDidChange(_ permission: Bool) {
        // Extract Sendable data first
        Task { await state.notifyPermissionChange(permission) }
    }
}
```

**Key Principle**: Extract/convert to Sendable types BEFORE crossing isolation boundaries with Task/await.

## Edge Functions / RPCs

### Edge Functions (TypeScript)
- `studio_canonicalize_and_check` - preview canonical URL and check existence
- `studio_create_post_with_canonicalization` - create/upsert post with server-side canonicalization

### Database RPCs (SQL)
- `studio_claim_ingestion_job` - atomically claim a job (worker pattern)
- `studio_complete_ingestion_job` - mark job complete, update post
- `studio_retry_ingestion_job` - retry with exponential backoff
- `studio_enqueue_ingestion_job` - idempotent job creation

## Ingestion Flow

1. User shares URL → app calls `studio_create_post_with_canonicalization` Edge Function
2. Edge Function canonicalizes URL, upserts post, enqueues job
3. DB webhook triggers n8n workflow on `studio_ingestion_jobs` INSERT
4. n8n calls `studio_claim_ingestion_job` RPC
5. Worker fetches content, processes, uploads thumbnails
6. On success: calls `studio_complete_ingestion_job` with payload
7. On failure: calls `studio_retry_ingestion_job` with error

## Session Sharing (App ↔ Extension)

- Keychain session storage via KeychainAccess; uses the first Keychain Sharing group from entitlements
- Ensure both targets list the same first keychain access group to share sessions
- `KeychainSessionStorage` conforms to `AuthLocalStorage` for Supabase SDK
- Auth Configuration:
  - `flowType: .pkce` - PKCE flow for secure authentication
  - `emitLocalSessionAsInitialSession: true` - Always emit stored sessions (future-proof for SDK v3.0)

### App Group Storage
- Use `AppGroup` helper for shared storage:
  - `AppGroup.userDefaults` for small key/value data
  - `AppGroup.containerURL` for files/caches
- All identifiers sourced from `AppConfig` (never hardcode)
- Debug builds validate configuration at app launch

## Configuration Management

**Single Source of Truth**: All app identifiers, URL schemes, and service names are defined in `AppConfig`:
- Bundle identifiers (`mainAppBundleID`, `shareExtensionBundleID`)
- URL schemes (`urlScheme`, `authCallbackURL`)
- App Group identifier (`appGroupIdentifier`)
- Keychain identifiers (`keychainAccessGroupSuffix`, `keychainServiceID`)
- Error domains (`shareExtensionErrorDomain`)

**Rule**: Never hardcode these values anywhere in the codebase. Always reference `AppConfig` constants.

## Navigation Architecture

**Type-Safe Routing**: All navigation uses `AppRoute` enum (defined in BareKit) for compile-time safety and cross-target compatibility.

**Navigator Pattern**: Centralized navigation state management via `Navigator` class.

### Core Components

**AppRoute** (`bare/Navigation/AppRoute.swift`)
- Enum defining all possible navigation destinations
- Lives in main app target (references ContentItem and other UI models)
- Supports deep linking via custom URL scheme (`bareapp://`) and universal links
- Methods: `from(url:)`, `toURL()`, `toUniversalLink()`

**Navigator** (`BareKit/Navigation/Navigator.swift`)
- `@Observable` class managing NavigationPath
- Methods: `navigate(to:)`, `pop()`, `popToRoot()`, `handleDeepLink(_:)`, `replace(with:)`
- Shared across all app targets for consistent navigation behavior

**View+Navigation** (`bare/Extensions/View+Navigation.swift`)
- SwiftUI extension providing `.withAppRouteDestinations()` modifier
- Maps AppRoute cases to actual SwiftUI views
- Lives in main app (not BareKit) since it references app-specific views

### Usage Pattern

```swift
// In a view with navigation
struct ContentGridView: View {
    @State private var navigator = Navigator()

    var body: some View {
        NavigationStack(path: $navigator.path) {
            // Grid content with NavigationLinks
            NavigationLink(value: AppRoute.contentDetail(item)) {
                ThumbnailCell(item: item)
            }
        }
        .withAppRouteDestinations() // Add this modifier
    }
}
```

### Deep Linking

**Supported Sources:**
- Custom URL scheme: `bareapp://post/{uuid}`
- Universal links: `https://bare.app/post/{uuid}`
- Widget tap actions
- Push notifications
- Email links
- Siri shortcuts

**Implementation:**
```swift
func handleDeepLink(_ url: URL) {
    navigator.handleDeepLink(url) // Automatically parses and navigates
}
```

### SwiftUI Navigation Best Practices

**Critical Rule**: `.navigationDestination()` modifiers must NEVER be placed on lazy containers (ScrollView, LazyVGrid, List, LazyVStack).

**Why**: Lazy containers only create child views when needed for rendering. If `.navigationDestination()` is attached to a lazy container, SwiftUI may not register the destination handler when NavigationStack initializes, breaking navigation.

**Correct Placement:**
```swift
ZStack {
    ScrollView {
        LazyVGrid {
            NavigationLink(value: route) { ... }
        }
    }
}
.navigationDestination(for: AppRoute.self) { ... } // ✅ On ZStack (non-lazy)
```

**Incorrect Placement:**
```swift
ScrollView {
    LazyVGrid {
        NavigationLink(value: route) { ... }
    }
}
.navigationDestination(for: AppRoute.self) { ... } // ❌ On ScrollView (lazy)
```

### Future Extensions

When adding new routes:
1. Add case to `AppRoute` enum in BareKit
2. Add URL parsing logic in `AppRoute.from(url:)` and `toURL()`
3. Add view mapping in `View+Navigation.swift` extension

This architecture supports:
- Widgets (via `Link(destination: route.toURL())`)
- Siri Intents (via Navigator)
- Share Extensions (navigation after sharing)
- Push Notifications (deep link handling)
- Email/Web links (universal links)

## State Management

- `@State` for local view state
- `@StateObject` for view-owned objects
- `@Observable` for shared state (Swift 6.0+)
- `Navigator` for navigation state (use `@State private var navigator = Navigator()`)

## MVVM & Component Architecture

### When to Use MVVM

**Use ViewModels when views have:**
- Network calls or repository access
- Complex validation logic
- Multi-step workflows with intermediate state
- Side effects beyond simple UI updates
- Business logic that should be testable independently

**Keep views simple when:**
- Purely presentational (no side effects)
- Single responsibility (e.g., display a card, show a button)
- Less than ~150 lines

### Refactoring Triggers

**Extract ViewModel + Components when a view:**
- Exceeds 400+ lines
- Mixes concerns (UI + validation + networking + state)
- Has 5+ `@State` properties managing different concerns
- Contains business logic that should be unit tested

### Component Extraction Patterns

**Create reusable components for:**
- Input fields with validation (e.g., `URLInputField`)
- Cards displaying data (e.g., `LinkPreviewCard`)
- Action button groups (e.g., `ActionButtons`)
- State-specific views (loading, error, placeholder)

**Components should:**
- Be self-contained and reusable
- Accept bindings for state they modify
- Accept callbacks for actions
- Use DesignTokens exclusively
- Live in separate files when 50+ lines

### ViewModel Guidelines

**Responsibilities:**
- Orchestrate async work (network, database, services)
- Manage view state via `@Published` properties
- Validate user input and derive error messages
- Coordinate between services/repositories
- Transform domain models to view-friendly state

**Anti-patterns - ViewModels should NEVER:**
- Import UIKit for rendering
- Return SwiftUI views
- Contain layout or styling logic
- Hardcode UI values (spacing, colors, etc.)

**Type & Lifecycle:**
- Prefer `@Observable` (Swift 6.0+). Fallback: `ObservableObject`
- Hold with `@StateObject` in view: `@StateObject private var viewModel`
- Construct in view init, inject dependencies via initializer
- Mark `@MainActor` for UI-affecting properties/methods

**Example Structure:**
```swift
@MainActor
final class MyViewModel: ObservableObject {
    // Published state
    @Published var data: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Dependencies (injected)
    private let repository: ItemRepositoryProtocol

    init(repository: ItemRepositoryProtocol) {
        self.repository = repository
    }

    // Public API
    func loadData() async { ... }
    func save() async { ... }

    // Private helpers
    private func validate() -> Bool { ... }
}

## Design System & Centralization

**DesignTokens (BareKit/UI/DesignTokens.swift)**

All UI values must use centralized design tokens to ensure consistency across all targets (main app, Share Extension, widgets, notifications, etc.):

```swift
import BareKit

// Use tokens for all UI values
.padding(DesignTokens.Spacing.md)
.background(DesignTokens.Colors.surfaceLight)
.cornerRadius(DesignTokens.CornerRadius.md)
```

**Categories:**
- `DesignTokens.Colors.*` - Color palette with semantic naming
- `DesignTokens.Spacing.*` - Standardized spacing values (xs/sm/md/lg/xl/xxl/xxxl)
- `DesignTokens.CornerRadius.*` - Consistent corner radius values

**Why in BareKit?**
- Accessible to all app targets (main, extensions, widgets)
- Single source of truth for design updates
- Prevents UI fragmentation across targets

**General Principles:**
- Centralize configuration/constants; prefer dependency injection for testability
- Build reusable, composable components

## Key Patterns

- Lifecycle: `.task` over `onAppear` for async work
- Timing: `Task.sleep` not `DispatchQueue.asyncAfter`
- Concurrency: Structured concurrency, avoid raw threads

- Logging: Minimal and privacy-safe; avoid noisy logs in extensions
- Accessibility: Support Dynamic Type; follow Apple HIG

## Security

- RLS policies on all tables (`auth.uid() = user_id`)
- Anon key in app; service key only in Edge Functions/CI
- Secrets in `.xcconfig` files (git-ignored, injected into Info.plist at build time)
- SECURITY DEFINER RPCs for job management (no direct client access to jobs table)

---

*These are guidelines, not rules. Adapt as needed.*

