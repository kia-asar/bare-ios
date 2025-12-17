# Observability Integration Guide

This document provides step-by-step instructions to complete the observability integration for Bare iOS.

## What Has Been Implemented

### ✅ Core Infrastructure (Complete)

1. **Protocols & Facades** (`BareKit/Core/Observability/`)
   - `AnalyticsService`, `FeatureFlagService`, `CrashReportingService`, `PerformanceTraceService`
   - `Observability` unified facade
   - `AppLogger` with categories and signposts
   - `AppGroupEventBuffer` for Share Extension analytics

2. **Service Implementations** (`bare/Services/Observability/`)
   - `FirebaseAnalyticsService`
   - `FirebaseRemoteConfigService`
   - `FirebaseCrashReportingService`
   - `FirebasePerformanceTraceService`
   - `PostHogAnalyticsService`
   - `MultiplexAnalyticsService`
   - `AnalyticsEventRelay`

3. **Configuration Files**
   - `Secrets.plist.template` with PostHog placeholders
   - `RemoteConfigDefaults.plist` with default feature flags
   - `GoogleService-Info.plist` directory structure
   - `ObservabilityConfig.swift` loader

4. **App Integration**
   - Updated `Dependencies.swift` with `Observability`
   - Updated `bareApp.swift` initialization flow
   - Share Extension analytics buffering

5. **Privacy & Compliance**
   - `PrivacyInfo.xcprivacy` for app and BareKit
   - CI workflow for IDFA/ATT prevention
   - No-op implementations for testing

6. **Documentation**
   - Comprehensive `OBSERVABILITY.md`
   - Updated `ARCHITECTURE.md`, `TECHNOLOGY_STACK.md`, `DECISIONS.md`
   - Updated `CONTRIBUTING.md`, `SETUP.md`, `QUICKSTART.md`

## What You Need to Do

### 1. Add Firebase SDK Dependencies in Xcode

The Firebase service implementations have placeholder comments where SDK calls will go. You need to:

1. **Add Firebase Package**:
   - Open `bare/bare.xcodeproj` in Xcode
   - File → Add Package Dependencies
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Select version: Latest (11.x)
   - Add to **app target only** (NOT BareKit, NOT ShareExtension)

2. **Select Products**:
   - `FirebaseAnalytics` (or `FirebaseAnalyticsWithoutAdIdSupport` - recommended for no-IDFA policy)
   - `FirebaseRemoteConfig`
   - `FirebaseCrashlytics`
   - `FirebasePerformance`

3. **Uncomment Firebase SDK Calls**:
   After adding the package, search for commented Firebase code:
   ```bash
   grep -r "// Firebase" bare/bare/Services/Observability/
   ```

   Uncomment the imports and SDK calls in:
   - `FirebaseAnalyticsService.swift`
   - `FirebaseRemoteConfigService.swift`
   - `FirebaseCrashReportingService.swift`
   - `FirebasePerformanceTraceService.swift`
   - `ObservabilityInitializer.swift`

### 2. Add PostHog SDK Dependency in Xcode

1. **Add PostHog Package**:
   - File → Add Package Dependencies
   - URL: `https://github.com/PostHog/posthog-ios`
   - Add to **app target only**

2. **Uncomment PostHog SDK Calls**:
   - Open `PostHogAnalyticsService.swift`
   - Uncomment imports and SDK calls

### 3. Configure Firebase Projects

1. **Create Firebase Projects**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create `bare-dev` (for Debug builds)
   - Create `bare-prod` (for Release builds)

2. **Download Configuration Files**:
   - For each project, add an iOS app
   - Bundle ID: `co.bareapp.bare`
   - Download `GoogleService-Info.plist`

3. **Place Configuration Files**:
   ```
   bare/bare/Config/Firebase/Debug/GoogleService-Info.plist
   bare/bare/Config/Firebase/Release/GoogleService-Info.plist
   ```

4. **Enable Firebase Services**:
   In Firebase Console for each project:
   - Analytics (ensure "Google Analytics for Firebase" is enabled)
   - Remote Config (no setup needed, just enable)
   - Crashlytics (enable in Console)
   - Performance Monitoring (enable in Console)

5. **Add to Xcode**:
   - Drag the `Firebase` folder into Xcode (add folder reference)
   - Ensure it's added to the app target
   - Select appropriate file based on build configuration

### 4. Create Secrets.plist

1. **Copy Template**:
   ```bash
   cp bare/bare/Config/Secrets.plist.template bare/bare/Config/Secrets.plist
   ```

2. **Get PostHog Credentials**:
   - Sign up at [PostHog](https://posthog.com/)
   - Create a project
   - Copy Project API Key and Host

3. **Edit Secrets.plist**:
   ```xml
   <key>POSTHOG_API_KEY</key>
   <string>phc_YOUR_KEY_HERE</string>
   <key>POSTHOG_HOST</key>
   <string>https://app.posthog.com</string>
   ```

4. **Add to Xcode** (if not already):
   - Drag `Secrets.plist` into Xcode project
   - Ensure it's added to app target
   - Verify it's in `.gitignore` (or commit carefully)

### 5. Add Crashlytics & Performance Run Scripts

In Xcode, app target → Build Phases → + New Run Script Phase:

**Script 1: Crashlytics dSYM Upload** (place after "Compile Sources"):
```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

**Script 2: Performance Symbol Upload** (place after Crashlytics):
```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/FirebasePerformance/run"
```

**Input Files** for both scripts:
- `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}`
- `${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}`

### 6. Add Privacy Manifests to Xcode

Ensure these files are added to the appropriate targets:

1. **App Target**:
   - `bare/bare/PrivacyInfo.xcprivacy` → app target

2. **BareKit**:
   - `BareKit/PrivacyInfo.xcprivacy` → BareKit framework

3. **Verify in Build Phases**:
   - Both files should appear in "Copy Bundle Resources" for their respective targets

### 7. Build Configuration Setup

In Xcode, configure GoogleService-Info.plist selection by build configuration:

**Option A: Manual Selection (Simpler)**
1. Keep both plists in project
2. Manually switch before building for Debug/Release
3. Documented in `Config/Firebase/README.md`

**Option B: Automated (Advanced)**
1. Add custom build script to copy correct plist based on `${CONFIGURATION}`
2. Example in `SETUP.md` section 5.1

### 8. Test the Integration

1. **Build the App**:
   ```bash
   # Debug build
   xcodebuild -scheme bare -configuration Debug build

   # Release build
   xcodebuild -scheme bare -configuration Release build
   ```

2. **Verify Initialization**:
   - Launch app in simulator
   - Check Console.app for "✅ Observability initialized" log
   - Look for Firebase configuration logs

3. **Test Analytics**:
   ```swift
   // In Debug, enable analytics first
   AppGroup.userDefaults?.set(true, forKey: "analytics_consent_granted")

   // Test event tracking
   await deps.observability.analytics.track(event: "test_event", parameters: nil)
   ```

4. **Test Share Extension**:
   - Share a URL from Safari
   - Check that event is buffered (Console.app logs)
   - Launch main app
   - Verify events are drained and sent

5. **Test Remote Config**:
   - Set a flag in Firebase Console
   - Fetch in app: `try await observability.flags.fetchAndActivate()`
   - Verify flag value: `observability.flags.bool(forKey: "test_flag", default: false)`

6. **Test Crashlytics**:
   - Record a test error: `await observability.crash.recordError(TestError())`
   - Wait a few minutes
   - Check Firebase Crashlytics dashboard

7. **Run CI Check**:
   ```bash
   # Verify no IDFA/ATT violations
   .github/workflows/privacy-check.yml
   ```

## Implementation Checklist

- [ ] Add Firebase SDK to Xcode (app target only)
- [ ] Add PostHog SDK to Xcode (app target only)
- [ ] Uncomment Firebase SDK calls in service implementations
- [ ] Uncomment PostHog SDK calls in `PostHogAnalyticsService`
- [ ] Create Firebase projects (Debug + Release)
- [ ] Download and place `GoogleService-Info.plist` files
- [ ] Enable Firebase services in Console (Analytics, RemoteConfig, Crashlytics, Performance)
- [ ] Create PostHog account and project
- [ ] Create and configure `Secrets.plist`
- [ ] Add Crashlytics run script to Build Phases
- [ ] Add Performance run script to Build Phases
- [ ] Add privacy manifests to Xcode targets
- [ ] Configure build settings for environment-specific Firebase plists
- [ ] Build and test in Debug
- [ ] Build and test in Release
- [ ] Test Share Extension buffering and relay
- [ ] Verify analytics events in dashboards
- [ ] Verify Remote Config fetch/activate
- [ ] Verify Crashlytics error recording
- [ ] Run privacy CI check

## Troubleshooting

### Firebase Not Initialized
- Check that `GoogleService-Info.plist` is in the app bundle
- Verify Firebase SDK is linked to app target
- Look for "FirebaseApp.configure()" in initialization logs

### PostHog Events Not Appearing
- Check API key and host in `Secrets.plist`
- Verify analytics consent is granted (Debug default: false)
- Check PostHog dashboard may have 1-2 minute delay

### Share Extension Events Not Relaying
- Check App Group is configured: `group.co.bareapp.bare`
- Verify buffer file exists in App Group container
- Check Console.app for "Drained X buffered events" log on app launch

### Privacy Check CI Failing
- Review error output
- Ensure no `AdSupport.framework` or `AppTrackingTransparency.framework` references
- Verify `NSPrivacyTracking = false` in privacy manifests
- Check no `NSUserTrackingUsageDescription` in Info.plist

### Build Errors After Adding SDKs
- Clean build folder: Cmd+Shift+K
- Reset package caches: File → Packages → Reset Package Caches
- Resolve packages: File → Packages → Resolve Package Versions
- Restart Xcode if needed

## Reference Documentation

- [OBSERVABILITY.md](docs/OBSERVABILITY.md) - Complete observability guidelines
- [SETUP.md](SETUP.md) - Full setup instructions
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Architecture with observability pipeline
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [PostHog iOS SDK](https://posthog.com/docs/libraries/ios)

## Questions?

If you encounter issues or have questions, refer to the troubleshooting sections in:
- `OBSERVABILITY.md` - Observability-specific issues
- `SETUP.md` - General setup issues

---

**Next Steps**: Follow the checklist above to complete the integration. Start with adding SDKs in Xcode, then configure Firebase projects, and finally test the complete flow.
