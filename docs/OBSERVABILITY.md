# Observability

This document outlines the observability stack, architecture, and governing principles for analytics, feature flags, crash reporting, and performance monitoring in CStudio.

## Table of Contents

- [Stack Overview](#stack-overview)
- [Architecture](#architecture)
- [Analytics Events](#analytics-events)
- [Feature Flags](#feature-flags)
- [Crash Reporting](#crash-reporting)
- [Performance Monitoring](#performance-monitoring)
- [Privacy & Consent](#privacy--consent)
- [Logging with os.log](#logging-with-oslog)
- [Release Checklist](#release-checklist)
- [Troubleshooting](#troubleshooting)

## Stack Overview

### Why These Tools?

- **Firebase**: Industry-standard mobile backend with Analytics, Remote Config, Crashlytics, and Performance Monitoring tightly integrated
- **PostHog**: Modern product analytics with rich event tracking and user journey analysis
- **os.log**: Apple's native, privacy-aware structured logging with zero overhead when disabled

### Services

| Service | Purpose | Availability |
|---------|---------|--------------|
| Firebase Analytics | Event tracking, user properties | App only |
| Firebase Remote Config | Feature flags, A/B testing | App only (mirrored to extension) |
| Firebase Crashlytics | Crash reports, non-fatal errors | App only |
| Firebase Performance | Network traces, custom metrics | App only |
| PostHog | Product analytics, funnels | App only |
| os.log | Structured logging, signposts | App + Extension |
| App Group Event Buffer | Extension analytics relay | Extension only |

## Architecture

### App Target

```
┌──────────────────────────────────────────────────────┐
│ App Initialization                                   │
│ ┌────────────────────────────────────────────────┐  │
│ │ 1. AppLogger initialized (early)               │  │
│ │ 2. Firebase configured (GoogleService-Info)    │  │
│ │ 3. PostHog initialized (.xcconfig → Info.plist)│  │
│ │ 4. Observability facade built:                 │  │
│ │    - MultiplexAnalyticsService                 │  │
│ │      ├─ FirebaseAnalyticsService               │  │
│ │      └─ PostHogAnalyticsService                │  │
│ │    - FirebaseRemoteConfigService               │  │
│ │    - FirebaseCrashReportingService             │  │
│ │    - FirebasePerformanceTraceService           │  │
│ │ 5. Remote Config fetched & activated           │  │
│ │ 6. Flags mirrored to App Group                 │  │
│ │ 7. Buffered events drained from extension      │  │
│ │ 8. Observability injected into Dependencies    │  │
│ └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### Share Extension

```
┌──────────────────────────────────────────────────────┐
│ Share Extension                                      │
│ ┌────────────────────────────────────────────────┐  │
│ │ 1. AppLogger initialized                       │  │
│ │ 2. Read consent from App Group UserDefaults    │  │
│ │ 3. Read feature flags from App Group mirror    │  │
│ │ 4. Track events → AppGroupEventBuffer          │  │
│ │ 5. os.log signposts for timing                 │  │
│ │ 6. No Firebase SDKs (extension-unsafe)         │  │
│ └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
                           │
                           │ (buffered events)
                           ▼
                   App Group Container
                           │
                           │ (relay on app launch)
                           ▼
              Firebase Analytics + PostHog
```

### Protocols in CStudioKit

All observability services are protocol-driven for testability:

- `AnalyticsService`: Event tracking, user properties
- `FeatureFlagService`: Remote configuration
- `CrashReportingService`: Error tracking
- `PerformanceTraceService`: Performance metrics
- `Observability`: Unified facade containing all services

No-op implementations are provided for testing and when disabled.

## Analytics Events

### Naming Convention

Use **snake_case** for event names:

```swift
// ✅ Good
await observability.analytics.track(event: "post_created", parameters: nil)
await observability.analytics.track(event: "share_extension_opened", parameters: nil)

// ❌ Bad
await observability.analytics.track(event: "PostCreated", parameters: nil)
await observability.analytics.track(event: "share-extension-opened", parameters: nil)
```

### Required Context Properties

Always include these context properties when relevant:

- `source`: Origin of event (`"app"`, `"share_extension"`)
- `user_authenticated`: `"true"` or `"false"`
- `screen`: Current screen name

### PII Policy

**Never track personally identifiable information** in event names or parameters:

```swift
// ❌ NEVER do this
await observability.analytics.track(event: "user_\(email)_logged_in", parameters: nil)

// ✅ Do this instead
await observability.analytics.track(event: "user_logged_in", parameters: nil)
await observability.analytics.setUserProperty("account_type", value: "premium")
```

Use user properties for identifiable data (hashed/anonymized) after consent.

### Event Schema Versioning

Include schema version for breaking changes:

```swift
await observability.analytics.track(event: "post_analyzed_v2", parameters: [
    "schema_version": "2",
    "analysis_type": "summary"
])
```

## Feature Flags

### Lifecycle

1. **Define defaults** in `RemoteConfigDefaults.plist` (version-controlled)
2. **Fetch & activate** on app launch via `FirebaseRemoteConfigService`
3. **Mirror to App Group** UserDefaults for Share Extension access
4. **Access flags** via `observability.flags.bool(forKey:default:)`

### Naming Convention

Use **snake_case** for flag keys:

```swift
let isFeatureEnabled = observability.flags.bool(forKey: "ai_chat_enabled", default: true)
```

### Testing Flags

In Debug builds, override flags via UserDefaults:

```swift
#if DEBUG
AppGroup.userDefaults?.set(true, forKey: "remote_config_override_ai_chat_enabled")
#endif
```

### Rollback Strategy

Always provide safe defaults in code:

```swift
// Default to conservative/safe behavior
let maxAttachments = observability.flags.integer(forKey: "max_post_attachments", default: 10)
```

## Crash Reporting

### Recording Non-Fatal Errors

```swift
do {
    try await riskyOperation()
} catch {
    await observability.crash.recordError(error)
    // Handle gracefully
}
```

### Custom Keys

Add context for debugging:

```swift
await observability.crash.setCustomValue("v2", forKey: "api_version")
await observability.crash.setCustomValue(postId, forKey: "current_post_id")
```

### Logging to Crashlytics

Breadcrumbs for crash context:

```swift
await observability.crash.log("User started post creation")
```

## Performance Monitoring

### Custom Traces

```swift
let trace = observability.performance.startTrace("fetch_posts")
defer { Task { await trace.stop() } }

// ... operation ...
await trace.incrementMetric("posts_fetched", by: Int64(posts.count))
```

### Network Requests

Automatic tracking for Supabase (future enhancement). Manual tracking:

```swift
await observability.performance.recordNetworkRequest(
    url: url,
    httpMethod: "POST",
    responseCode: 200,
    requestSize: 1024,
    responseSize: 2048,
    duration: 0.35
)
```

## Privacy & Consent

### No-IDFA Policy

**Strict policy**: CStudio does **NOT** use IDFA (Identifier for Advertisers) or ATT (App Tracking Transparency).

**What Apple Actually Checks:**
- ❌ Never link `AdSupport.framework` or `AppTrackingTransparency.framework`
- ❌ Never add `NSUserTrackingUsageDescription` to Info.plist
- ❌ Never call IDFA APIs (`identifierForAdvertising`, `ASIdentifierManager`)
- ✅ Privacy manifest declares `NSPrivacyTracking = false`
- ✅ **REQUIRED**: Set `GOOGLE_ANALYTICS_IDFA_COLLECTION_ENABLED = false` in Info.plist
- ✅ CI workflow enforces all of the above

**Firebase Analytics v10+ Note**: Modern Firebase uses a single `FirebaseAnalytics` framework. IDFA collection is controlled by the `GOOGLE_ANALYTICS_IDFA_COLLECTION_ENABLED` flag in Info.plist, not by using separate frameworks. This flag is already set to `false` in our Info.plist, ensuring no IDFA collection.

### Consent Behavior

**US-Only, Implied Consent Model:**

| Environment | Default Behavior | Rationale |
|-------------|------------------|-----------|
| Debug | Analytics **disabled** | Avoid polluting analytics with test data |
| Release | Analytics **enabled** (implied consent) | US-only app with clear privacy policy |

- **No ATT prompt**: We don't use IDFA or cross-app tracking
- **No explicit consent UI**: US privacy laws allow implied consent with disclosure
- **Privacy policy disclosure**: Users accept via Terms of Service
- **Opt-out available**: Contact support to request data deletion

### Updating Consent Programmatically

If you later need explicit consent (e.g., for EU expansion):

```swift
ObservabilityInitializer.updateConsent(granted: true)
```

This sets `analytics_consent_granted` in App Group UserDefaults, respected by both app and extension.

### For EU/GDPR Compliance (Future)

If expanding to EU, implement explicit consent:
1. Show consent dialog on first launch
2. Store consent in App Group UserDefaults before any analytics
3. Update `ANALYTICS_REQUIRES_EXPLICIT_CONSENT = YES` in `.xcconfig` files
4. Gate all analytics calls on consent check

### Privacy Manifest

Both app target and CStudioKit include `PrivacyInfo.xcprivacy`:

- `NSPrivacyTracking`: `false`
- `NSPrivacyCollectedDataTypes`: Analytics, crash, performance (non-linked, non-tracking)
- `NSPrivacyAccessedAPITypes`: UserDefaults, file timestamps (with reasons)

## Logging with os.log

### Category Loggers

Use predefined categories for structured logging:

```swift
AppLogger.auth.info("User signed in")
AppLogger.network.debug("API request: \(endpoint)")
AppLogger.ui.info("Screen appeared: \(screenName)")
AppLogger.analytics.debug("Event tracked: \(eventName)")
AppLogger.flags.info("Feature flag activated: \(flagKey)")
AppLogger.perf.debug("Operation completed in \(duration)s")
AppLogger.shareExt.info("Extension opened")
AppLogger.crash.error("Non-fatal error: \(error.localizedDescription)")
AppLogger.storage.debug("Cache updated")
```

### Privacy Annotations

Redact PII automatically:

```swift
AppLogger.auth.logPrivate("User ID: \(userId)") // Redacted in system logs
AppLogger.network.logPublic("HTTP 200 OK") // Visible in system logs
```

### Signposts for Performance

Measure operations with begin/end:

```swift
let signpost = AppLogger.signpost(logger: .perf, name: "fetch_posts")
signpost.begin()
// ... operation ...
signpost.end("fetched \(count) posts")
```

Or use the helper:

```swift
await AppLogger.measure("fetch_posts") {
    return try await postRepository.fetchAll()
}
```

### Log Levels

- **Debug**: Verbose, disabled in Release (no overhead)
- **Info**: Operational events, visible in Console.app
- **Warning**: Recoverable issues
- **Error**: Non-fatal errors
- **Fault**: Critical failures

## Release Checklist

Before releasing, verify:

- [ ] `GoogleService-Info.plist` for Release environment in place
- [ ] `Prod.xcconfig` contains production PostHog credentials
- [ ] Firebase Crashlytics run script added to build phases
- [ ] Firebase Performance run script added to build phases
- [ ] Privacy manifest `NSPrivacyTracking = false` verified
- [ ] No `AdSupport.framework` or `AppTrackingTransparency.framework` linked (CI checks this)
- [ ] Remote Config defaults plist up to date
- [ ] Event buffer draining tested (open Share Extension → launch app → verify events in dashboard)
- [ ] Consent flow tested (if explicit consent added)

## Troubleshooting

### Events Not Appearing in Firebase/PostHog

1. **Check analytics enabled**: Debug builds default to disabled
2. **Check consent**: `analytics_consent_granted` in App Group UserDefaults
3. **Check network**: Firebase Analytics batches events (up to 1 hour delay)
4. **Check logs**: Search Console.app for "analytics" category

### Remote Config Not Updating

1. **Check fetch interval**: Default 1 hour, may need manual fetch
2. **Check activation**: Fetch does not auto-activate; must call `fetchAndActivate()`
3. **Check App Group mirror**: Verify flags written to UserDefaults after activation

### Share Extension Events Not Relayed

1. **Check App Group**: Verify `group.social.curo.cstudio` configured
2. **Check buffer file**: Inspect `AppGroup.containerURL/analytics_event_buffer.jsonl`
3. **Check relay logic**: Events drained on app launch, not immediately

### Performance Traces Missing

1. **Check Firebase enabled**: Traces only in Release builds by default
2. **Check trace stopped**: Ensure `trace.stop()` called
3. **Check network**: Firebase Performance has upload delay

### Privacy Review Failures

1. **Check privacy manifest**: Must exist in both app and framework
2. **Check required reasons**: All APIs must have declared reasons
3. **Run CI check**: `.github/workflows/privacy-check.yml` enforces policy

---

For implementation details, see:
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [TECHNOLOGY_STACK.md](./TECHNOLOGY_STACK.md) - Technology choices
- [CONTRIBUTING.md](./CONTRIBUTING.md) - Development guidelines
