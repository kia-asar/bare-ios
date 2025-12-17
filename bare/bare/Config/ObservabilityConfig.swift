//
//  ObservabilityConfig.swift
//  bare
//
//  Configuration loader for observability services from Info.plist (injected from .xcconfig)
//

import Foundation
import BareKit

/// Configuration for observability services loaded from Info.plist
public struct ObservabilityConfig {
    // MARK: - PostHog

    public let posthogAPIKey: String
    public let posthogHost: String

    // MARK: - Analytics

    public let analyticsEnabled: Bool
    public let firebaseEnabled: Bool

    // MARK: - Remote Config

    public let remoteConfigFetchInterval: TimeInterval

    // MARK: - Privacy

    /// Whether analytics requires explicit user consent
    /// Set to false for US-only apps with implied consent via privacy policy
    public let analyticsRequiresExplicitConsent: Bool

    // MARK: - Push Notifications

    /// OneSignal App ID for push notifications (optional)
    /// Returns nil if not configured - app will gracefully degrade to noop service
    public let oneSignalAppId: String?

    // MARK: - Initialization

    /// Load configuration from Info.plist (values injected from .xcconfig files)
    public static func load() throws -> ObservabilityConfig {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            throw ConfigError.missingConfiguration
        }

        guard let posthogAPIKey = infoDictionary["POSTHOG_API_KEY"] as? String,
              !posthogAPIKey.isEmpty,
              !posthogAPIKey.contains("YOUR_"),
              let posthogHost = infoDictionary["POSTHOG_HOST"] as? String,
              !posthogHost.isEmpty else {
            throw ConfigError.missingRequiredKey("POSTHOG_API_KEY or POSTHOG_HOST")
        }

        // Parse boolean values from string (Info.plist stores as string when injected from .xcconfig)
        let analyticsEnabled = parseBool(infoDictionary["ANALYTICS_ENABLED"] as? String, defaultValue: false)
        let firebaseEnabled = parseBool(infoDictionary["FIREBASE_ENABLED"] as? String, defaultValue: false)
        let analyticsRequiresExplicitConsent = parseBool(infoDictionary["ANALYTICS_REQUIRES_EXPLICIT_CONSENT"] as? String, defaultValue: false)

        // Parse integer
        let remoteConfigFetchInterval = TimeInterval(
            Int(infoDictionary["REMOTE_CONFIG_FETCH_INTERVAL_SECONDS"] as? String ?? "3600") ?? 3600
        )

        // OneSignal App ID (optional - graceful degradation if not configured)
        let oneSignalAppId: String? = {
            guard let appId = infoDictionary["ONESIGNAL_APP_ID"] as? String,
                  !appId.isEmpty,
                  !appId.contains("YOUR_") else {
                return nil
            }
            return appId
        }()

        return ObservabilityConfig(
            posthogAPIKey: posthogAPIKey,
            posthogHost: posthogHost,
            analyticsEnabled: analyticsEnabled,
            firebaseEnabled: firebaseEnabled,
            remoteConfigFetchInterval: remoteConfigFetchInterval,
            analyticsRequiresExplicitConsent: analyticsRequiresExplicitConsent,
            oneSignalAppId: oneSignalAppId
        )
    }

    /// Parse boolean from string value (handles YES/NO and true/false)
    private static func parseBool(_ value: String?, defaultValue: Bool) -> Bool {
        guard let value = value?.uppercased() else { return defaultValue }
        return value == "YES" || value == "TRUE" || value == "1"
    }

    // MARK: - Errors

    public enum ConfigError: LocalizedError {
        case missingConfiguration
        case missingRequiredKey(String)

        public var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Info.plist not found or inaccessible"
            case .missingRequiredKey(let key):
                return "Missing required key in configuration: \(key). Check your Dev.xcconfig or Prod.xcconfig file."
            }
        }
    }
}
