//
//  ObservabilityInitializer.swift
//  cstudio
//
//  Initializes and configures all observability services
//

import Foundation
import CStudioKit
import OSLog
import FirebaseCore
import Supabase

/// Handles initialization of observability stack (Firebase, PostHog, os.log)
/// All methods are static - this is a stateless utility
public enum ObservabilityInitializer {
    /// Context manager for analytics super properties
    private static var contextManager: AnalyticsContextManager?

    /// Initialize observability services
    /// - Returns: Configured Observability facade
    /// - Note: Never throws - returns noop observability on configuration failure
    public static func initialize() async -> Observability {
        AppLogger.app.info("Initializing observability...")

        // Load configuration (fall back to noop on failure)
        let config: ObservabilityConfig
        do {
            config = try await MainActor.run { try ObservabilityConfig.load() }
        } catch {
            AppLogger.app.error("Failed to load observability config: \(error.localizedDescription)")
            AppLogger.app.warning("Falling back to noop observability")
            return .noop
        }

        // Initialize Firebase with environment-specific configuration
        if config.firebaseEnabled {
            await initializeFirebase()
        }

        // Build observability services
        let observability = await buildObservability(config: config)

        // Set up analytics context (super properties)
        await setupAnalyticsContext(observability: observability)

        // Configure global FeatureFlags facade
        await MainActor.run {
            FeatureFlags.configure(service: observability.flags)
        }

        // Fetch and activate Remote Config (non-blocking, best effort)
        if config.firebaseEnabled {
            Task.detached(priority: .utility) {
                do {
                    let activated = try await observability.flags.fetchAndActivate()
                    if activated {
                        AppLogger.flags.info("Remote Config activated with new values")
                        // Post notification for kill switch check after fetch
                        await MainActor.run {
                            NotificationCenter.default.post(name: .remoteConfigUpdated, object: nil)
                        }
                    } else {
                        AppLogger.flags.debug("Remote Config already up to date")
                    }
                } catch {
                    AppLogger.flags.error("Failed to fetch Remote Config: \(error.localizedDescription)")
                    // Non-fatal: app continues with default config
                }
            }
        }

        // Drain buffered events from Share Extension (non-blocking)
        Task.detached(priority: .utility) {
            await drainBufferedEvents(analytics: observability.analytics)
        }

        AppLogger.app.info("✅ Observability initialized")
        return observability
    }

    /// Initialize Firebase SDK with environment-specific configuration
    private static func initializeFirebase() async {
        // Select environment-specific plist file
        #if DEV
        let plistName = "GoogleService-Info-Dev"
        let environment = "Dev"
        #else
        let plistName = "GoogleService-Info-Prod"
        let environment = "Prod"
        #endif

        // Load Firebase options from environment-specific plist
        guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            AppLogger.app.error("Failed to load \(plistName).plist")
            AppLogger.app.error("Firebase initialization failed - using noop services")
            return
        }

        FirebaseApp.configure(options: options)
        AppLogger.app.info("✅ Firebase configured for environment: \(environment)")
    }

    /// Build observability facade with all services
    private static func buildObservability(config: ObservabilityConfig) async -> Observability {
        // Create analytics context manager
        let manager = await MainActor.run { AnalyticsContextManager() }
        contextManager = manager

        // Analytics service - multiplex to Firebase + PostHog
        let analytics: AnalyticsService

        if config.analyticsEnabled {
            var services: [AnalyticsService] = []

            // Add Firebase Analytics if enabled
            if config.firebaseEnabled {
                services.append(FirebaseAnalyticsService(enabled: true))
            }

            // Add PostHog Analytics (validated during config load)
            if !config.posthogAPIKey.contains("YOUR_") {
                services.append(PostHogAnalyticsService(
                    apiKey: config.posthogAPIKey,
                    host: config.posthogHost,
                    enabled: true
                ))
                AppLogger.analytics.info("PostHog analytics enabled")
            } else {
                AppLogger.analytics.warning("PostHog API key not configured - skipping PostHog")
            }

            // Multiplex to all providers with context manager
            analytics = MultiplexAnalyticsService(services: services, contextManager: manager)
        } else {
            analytics = NoopAnalyticsService()
        }

        // Feature flags
        let flags: FeatureFlagService = config.firebaseEnabled
            ? FirebaseRemoteConfigService(fetchInterval: config.remoteConfigFetchInterval)
            : NoopFeatureFlagService()

        // Crash reporting
        let crash: CrashReportingService = config.firebaseEnabled
            ? FirebaseCrashReportingService()
            : NoopCrashReportingService()

        // Performance monitoring
        let performance: PerformanceTraceService = config.firebaseEnabled
            ? FirebasePerformanceTraceService()
            : NoopPerformanceTraceService()

        return Observability(
            analytics: analytics,
            flags: flags,
            crash: crash,
            performance: performance
        )
    }

    /// Drain buffered analytics events from Share Extension
    private static func drainBufferedEvents(analytics: AnalyticsService) async {
        let relay = AnalyticsEventRelay(analytics: analytics)
        let count = await relay.drainAndRelay()

        if count > 0 {
            AppLogger.analytics.info("Drained \(count) buffered events from Share Extension")
        }
    }

    /// Set up consent (if needed in the future)
    public static func updateConsent(granted: Bool) {
        AppGroup.userDefaults?.set(granted, forKey: "analytics_consent_granted")
        AppLogger.analytics.info("Analytics consent updated: \(granted)")
    }

    /// Set up analytics context (super properties) for PostHog and Firebase
    private static func setupAnalyticsContext(observability: Observability) async {
        guard let contextManager = contextManager else { return }

        let superProperties = await MainActor.run { contextManager.superProperties }

        // Register super properties with PostHog (automatically added to every event)
        if let multiplex = observability.analytics as? MultiplexAnalyticsService {
            // PostHog handles super properties via register()
            // This is already done via MultiplexAnalyticsService enriching parameters
            AppLogger.analytics.debug("Analytics context configured with \(superProperties.count) properties")
        }

        // Set static user properties for Firebase (best effort)
        // Note: We need to access the individual Firebase service to call setStaticUserProperties
        // For now, Firebase will get enriched parameters via MultiplexAnalyticsService
        // which includes super properties on every event

        AppLogger.analytics.info("✅ Analytics context initialized")
    }

    /// Refresh dynamic context properties (call on app foreground)
    public static func refreshDynamicContext() async {
        await MainActor.run {
            contextManager?.refreshDynamicContext()
        }

        AppLogger.analytics.debug("Dynamic analytics context refreshed")
    }

    /// Setup auth integration - call after DependencyContainer initializes AuthManager
    /// - Parameter authManager: The app's auth manager
    /// - Parameter analytics: The analytics service
    public static func setupAuthIntegration(authManager: AuthManager, analytics: AnalyticsService) {
        authManager.onAuthStateChange = { event, session in
            Task {
                await handleAuthStateChange(event: event, session: session, analytics: analytics)
            }
        }
    }

    /// Handle auth state changes for analytics
    private static func handleAuthStateChange(
        event: AuthChangeEvent,
        session: Session?,
        analytics: AnalyticsService
    ) async {
        switch event {
        case .signedIn:
            // User just signed in - set user ID
            if let userId = session?.user.id {
                await analytics.setUserId(userId.uuidString)
                AppLogger.analytics.info("User identified in analytics")
            }

        case .signedOut, .userDeleted:
            // User signed out - reset analytics and reapply super properties
            await analytics.reset()
            AppLogger.analytics.info("Analytics reset on sign out")

        case .initialSession:
            // Restoring previous session - set user ID if valid
            if let userId = session?.user.id {
                await analytics.setUserId(userId.uuidString)
                AppLogger.analytics.debug("User ID restored from session")
            }

        case .tokenRefreshed, .mfaChallengeVerified, .userUpdated, .passwordRecovery:
            // No action needed for these events
            break
        }
    }
}
