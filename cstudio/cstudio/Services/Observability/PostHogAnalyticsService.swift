//
//  PostHogAnalyticsService.swift
//  cstudio
//
//  PostHog analytics adapter implementing AnalyticsService protocol
//

import Foundation
import CStudioKit
import OSLog
import PostHog

/// PostHog implementation of AnalyticsService
///
/// Thread Safety: Uses @unchecked Sendable because the PostHog SDK
/// is internally thread-safe. All calls to PostHog methods are safe from any thread
/// as the SDK handles synchronization internally.
public final class PostHogAnalyticsService: AnalyticsService, @unchecked Sendable {
    private let apiKey: String
    private let host: String
    private let enabled: Bool
    private let posthog: PostHogSDK

    /// Initialize PostHog analytics service
    /// - Parameters:
    ///   - apiKey: PostHog API key
    ///   - host: PostHog host URL
    ///   - enabled: Whether analytics collection is enabled
    ///   - distinctIdProvider: Function to provide stable anonymous distinct ID
    public init(
        apiKey: String,
        host: String,
        enabled: Bool,
        distinctIdProvider: @escaping () -> String
    ) {
        self.apiKey = apiKey
        self.host = host
        self.enabled = enabled
        self.posthog = PostHogSDK.shared

        guard enabled else {
            AppLogger.analytics.info("PostHog analytics disabled")
            return
        }

        // Configure PostHog
        let config = PostHogConfig(apiKey: apiKey, host: host)
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false // Manual screen tracking
        config.appGroupIdentifier = AppConfig.appGroupIdentifier

        posthog.setup(config)

        // Set anonymous distinct ID from App Group (shared with extension)
        let distinctId = distinctIdProvider()
        posthog.identify(distinctId)

        AppLogger.analytics.info("PostHog initialized with host: \(host)")
    }

    /// Register super properties that will be automatically added to every event
    /// Should be called after initialization with context from AnalyticsContextManager
    /// - Parameter properties: Dictionary of super properties to register
    public func registerSuperProperties(_ properties: [String: Sendable]) {
        guard enabled else { return }

        // Convert Sendable dictionary to [String: Any] for PostHog SDK
        let anyProps = properties.mapValues { $0 as Any }
        posthog.register(anyProps)

        AppLogger.analytics.info("PostHog super properties registered: \(properties.count) properties")
    }

    /// Update super properties (call when dynamic properties change)
    /// - Parameter properties: Updated super properties
    public func updateSuperProperties(_ properties: [String: Sendable]) {
        registerSuperProperties(properties)
    }

    /// Convenience initializer using default distinct ID provider
    public convenience init(
        apiKey: String,
        host: String,
        enabled: Bool
    ) {
        self.init(
            apiKey: apiKey,
            host: host,
            enabled: enabled,
            distinctIdProvider: PostHogAnalyticsService.defaultDistinctIdProvider
        )
    }

    public func track(event name: String, parameters: [String: Sendable]?) async {
        guard enabled else { return }

        // PostHog supports rich properties
        // Convert Sendable dictionary to [String: Any] for PostHog SDK
        let anyParams = parameters?.mapValues { $0 as Any }
        posthog.capture(name, properties: anyParams)
        AppLogger.analytics.info("📊 [PostHog] Event: \(name)")
    }

    public func setUserProperty(_ name: String, value: (any Sendable)?) async {
        guard enabled else { return }

        // PostHog uses "super properties" for user properties
        if let value = value {
            posthog.register([name: value as Any])
        } else {
            posthog.unregister(name)
        }
        AppLogger.analytics.info("👤 [PostHog] User property: \(name)")
    }

    public func setUserId(_ userId: String?) async {
        guard enabled else { return }

        if let userId = userId {
            posthog.identify(userId)
            AppLogger.analytics.logPrivate("👤 [PostHog] User identified")
        } else {
            // Reset to anonymous ID
            let anonymousId = Self.defaultDistinctIdProvider()
            posthog.identify(anonymousId)
            AppLogger.analytics.info("👤 [PostHog] Reset to anonymous")
        }
    }

    public func reset() async {
        guard enabled else { return }

        posthog.reset()
        AppLogger.analytics.info("🔄 [PostHog] Analytics reset")
    }

    // MARK: - Distinct ID Provider

    /// Default distinct ID provider using App Group storage for consistency
    /// This ensures the same anonymous ID is used across app and extension
    public static func defaultDistinctIdProvider() -> String {
        let key = "posthog_anonymous_distinct_id"

        if let existingId = AppGroup.userDefaults?.string(forKey: key) {
            return existingId
        }

        // Generate new anonymous ID
        let newId = UUID().uuidString
        AppGroup.userDefaults?.set(newId, forKey: key)
        return newId
    }
}
