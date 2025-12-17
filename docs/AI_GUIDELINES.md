# AI Coding Assistant Guidelines

> **Central reference for all AI tools** (Claude Code, Cursor, Copilot, etc.)

## CRITICAL: UI Design System

**ALWAYS use DesignTokens from BareKit - NEVER hardcode UI values**

```swift
import BareKit

// ✅ CORRECT
.padding(DesignTokens.Spacing.md)
.background(DesignTokens.Colors.surfaceLight)
.cornerRadius(DesignTokens.CornerRadius.md)

// ❌ WRONG
.padding(16)
.background(Color.gray.opacity(0.1))
.cornerRadius(12)
```

### Mandatory Rules

- **NEVER** hardcode colors with opacity - use `DesignTokens.Colors.*`
- **NEVER** hardcode spacing/padding values - use `DesignTokens.Spacing.*`
- **NEVER** hardcode corner radius - use `DesignTokens.CornerRadius.*`
- Applies to **ALL targets**: main app, Share Extension, widgets, notifications, etc.
- DesignTokens is in BareKit - accessible everywhere
- If you need a new value, add it to `BareKit/Sources/BareKit/UI/DesignTokens.swift` first

### Available Tokens

**Colors:**
- `backgroundOverlay`, `surfaceLight`, `surfaceMedium`
- `borderLight`, `borderError`
- `interactiveOverlay`, `primaryGradientStart`
- `shadowLight`, `shadowBlue`

**Spacing:**
- `xs` (8pt), `sm` (12pt), `md` (16pt), `lg` (20pt)
- `xl` (24pt), `xxl` (32pt), `xxxl` (40pt)

**Corner Radius:**
- `sm` (8pt), `md` (12pt), `lg` (16pt), `xl` (20pt)

### Why This Matters

- Ensures visual consistency across all app targets
- Single source of truth for design updates
- Supports theming and design system evolution
- Prevents UI fragmentation between main app and extensions

## Code Quality Standards

### DRY (Don't Repeat Yourself)

- Extract common functionality into reusable components/utilities
- No code duplication - if you need it twice, abstract it
- Maximize reusability across the codebase

### Simplicity & Clear Responsibilities

- Choose the simplest solution that solves the problem
- Each component has one clear responsibility
- Avoid over-engineering - build what's needed, not what might be needed

### Swift 6.0 & Strict Concurrency

- Use `async/await` for asynchronous code
- Proper `@MainActor` usage for UI-affecting code
- Respect actor isolation
- No force unwraps in production code

**State Management:**
- ✅ Use `actor` for mutable state (not `NSLock` + `@unchecked Sendable`)
- ✅ Use `@MainActor` for all UI updates and NotificationCenter posts
- ✅ Use `nonisolated(unsafe)` for immutable static constants only

**Sendable Boundaries:**
- ✅ Extract/convert to Sendable types BEFORE Task/await
- ✅ Use `@unchecked Sendable` only when bridging Objective-C APIs

**Examples:**
```swift
// State: Use actors
private actor State {
    var handler: (() -> Void)?
}

// UI: Wrap in @MainActor
Task { @MainActor in
    NotificationCenter.default.post(...)
}

// Static constants
nonisolated(unsafe) static let myNotification = Notification.Name("...")

// Bridging callbacks
func onCallback(data: NSData) {
    let copy = String(data)  // Convert first
    Task { await actor.handle(copy) }
}
```

### Modern SwiftUI State Management

**Use `@Observable` for state management - avoid Combine-based patterns**

- ViewModels: Use `@Observable` macro with plain `var` properties
- Views: Use `@State` for view models (not `@StateObject` or `@ObservedObject`)
- No `@Published`, no `ObservableObject`, no `import Combine`
- Simpler, more performant, recommended by Apple (Swift 5.9+)

### Configuration Management

- **ALWAYS** use `AppConfig` for identifiers
- Never hardcode bundle IDs, URL schemes, or service names
- Centralize constants in appropriate locations

## Architecture Patterns

### Multi-Target Support

- Main app, Share Extension, widgets, notifications all share BareKit
- Keep UI consistent across all targets using DesignTokens
- Use protocol-based dependency injection

### MVVM & Component Architecture

**When to refactor:**
- Views exceed 400+ lines or mix concerns (UI + validation + networking)
- Complex flows with network calls, validation, or testable business logic

**Quick rules:**
- ViewModels handle state, validation, async work - NEVER return SwiftUI views
- Components are reusable, accept bindings/callbacks, use DesignTokens exclusively
- Views focus on layout and composition only

See [ARCHITECTURE.md § MVVM & Component Architecture](./ARCHITECTURE.md#mvvm--component-architecture) for detailed guidelines

### Dependency Injection

- Use `DependencyContainer` for app-wide services
- Protocol-first for repositories/services (e.g., `PostRepositoryProtocol`)
- Inject via initializer in views/view models

### Permission UX Best Practices

**Two-Step Permission Flow:**
- **Never** request iOS permissions on app launch
- Show value first (let user see app working)
- Use custom pre-prompt to educate before system dialog
- Track both pre-prompt and system prompt for funnel analysis

**Context-Aware UI:**
- First time (`.notDetermined`): Show value proposition
- Previously denied (`.denied`): Offer Settings deep link for re-engagement
- Already granted (`.authorized`): Skip prompt entirely

**Analytics Tracking:**
- Track initial permission state on app launch
- Track pre-prompt acceptance/dismissal
- Track system dialog result (granted/denied)
- Track Settings deep link usage
- Use permission observers to detect revocations

**Implementation Pattern:**
```swift
// Delay permission request until value is established
Task {
    try? await Task.sleep(for: .seconds(1))
    showPermissionPrimer = true
}

// Check current state before showing UI
let status = await pushService.getPermissionStatus()
if status == .authorized {
    // Skip prompt - already granted
} else if status == .denied {
    // Show Settings deep link
} else {
    // Show value proposition + request
}

// Always await analytics before state-changing operations
await analytics.track(event: "permission_action")
await MainActor.run {
    UIApplication.shared.open(settingsURL)
}
```

## Documentation

### Update Existing Docs

- Add to `ARCHITECTURE.md` for architectural changes
- Update `CONTRIBUTING.md` for workflow changes
- Modify relevant existing docs - **don't create new ones**

### Never Create

- Implementation summaries or task completion logs
- "CHANGES_MADE.md" or similar files
- Temporary documentation (unless explicitly requested)

## Git & Commit Practices

### Commit Messages

- Use imperative mood: "Add feature" not "Added feature"
- Explain the why when not obvious
- **NEVER mention AI/Claude/LLM in commit messages**
- Keep commits atomic (one logical change per commit)

### Good Examples

- "Add user authentication flow"
- "Fix memory leak in image cache"
- "Refactor network layer for better error handling"

## Analytics & Logging

### Event Naming

- Use **snake_case**: `post_created`, `share_extension_opened`
- Include action verb: `user_signed_in`, `link_preview_loaded`

### PII Policy

- **NEVER** include PII in events/parameters
- Use `AppLogger.logPrivate()` for sensitive values in logs

### Logging Categories

Use predefined categories: `AppLogger.auth`, `AppLogger.network`, `AppLogger.analytics`

## Testing

- Write testable code from the start
- Test share extension in real apps (Safari, Photos, etc.)
- Verify iOS 18+ compatibility for extensions
- Check both light/dark mode
- Basic accessibility checks: Dynamic Type, VoiceOver

## Reference Documentation

For detailed information, see:

- **Architecture**: `docs/ARCHITECTURE.md`
- **Contributing**: `docs/CONTRIBUTING.md`
- **Project Guidelines**: `.claude/CLAUDE.md`
- **Observability**: `docs/OBSERVABILITY.md`

---

*Focus on intent, not ceremony.*
