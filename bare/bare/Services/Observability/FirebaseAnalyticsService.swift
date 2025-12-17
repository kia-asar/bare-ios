//
//  FirebaseAnalyticsService.swift
//  bare
//
//  Firebase Analytics adapter implementing AnalyticsService protocol
//

import Foundation
import BareKit
import OSLog
import FirebaseAnalytics

/// Firebase Analytics implementation of AnalyticsService
///
/// Thread Safety: Uses @unchecked Sendable because the Firebase Analytics SDK
/// is internally thread-safe. All calls to Analytics methods are safe from any thread
/// as Firebase handles synchronization internally.
public final class FirebaseAnalyticsService: AnalyticsService, @unchecked Sendable {
    private let enabled: Bool

    /// Initialize Firebase Analytics service
    /// - Parameter enabled: Whether analytics collection is enabled
    public init(enabled: Bool) {
        self.enabled = enabled
        // Configure Firebase Analytics collection
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }

    /// Set static user properties for context (app version, platform, environment)
    /// Firebase doesn't support event-level super properties, so we use user properties
    /// - Parameter properties: Dictionary of static properties to set as user properties
    public func setStaticUserProperties(_ properties: [String: Sendable]) async {
        guard enabled else { return }

        // Only set static properties that are meaningful as user properties
        let staticKeys = ["platform", "app_name", "app_version", "environment", "os_name", "os_version"]

        for key in staticKeys {
            if let value = properties[key] {
                let stringValue = stringifyValue(value)
                Analytics.setUserProperty(stringValue, forName: key)
            }
        }

        AppLogger.analytics.info("[Firebase] Static user properties set")
    }

    /// Convert Sendable value to string for Firebase
    private func stringifyValue(_ value: any Sendable) -> String {
        switch value {
        case let string as String:
            return string
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let bool as Bool:
            return String(bool)
        default:
            return String(describing: value)
        }
    }

    public func track(event name: String, parameters: [String: Sendable]?) async {
        guard enabled else { return }

        // Convert parameters to Firebase-compatible format
        let firebaseParams = parameters?.compactMapValues { value -> Any? in
            // Firebase Analytics supports: String, Int, Double, Bool
            // All these types are Sendable
            switch value {
            case let string as String:
                return string
            case let int as Int:
                return int
            case let double as Double:
                return double
            case let bool as Bool:
                return bool
            default:
                return String(describing: value)
            }
        }

        // Log to Firebase Analytics
        Analytics.logEvent(name, parameters: firebaseParams)
        AppLogger.analytics.info("📊 [Firebase] Event: \(name)")
    }

    public func setUserProperty(_ name: String, value: (any Sendable)?) async {
        guard enabled else { return }

        let stringValue: String? = {
            guard let value = value else { return nil }
            switch value {
            case let string as String:
                return string
            case let int as Int:
                return String(int)
            case let double as Double:
                return String(double)
            case let bool as Bool:
                return String(bool)
            default:
                return String(describing: value)
            }
        }()

        Analytics.setUserProperty(stringValue, forName: name)
        AppLogger.analytics.info("👤 [Firebase] User property: \(name) = \(stringValue ?? "nil")")
    }

    public func setUserId(_ userId: String?) async {
        guard enabled else { return }

        Analytics.setUserID(userId)
        if let userId = userId {
            AppLogger.analytics.logPrivate("👤 [Firebase] User ID set")
        } else {
            AppLogger.analytics.info("👤 [Firebase] User ID cleared")
        }
    }

    public func reset() async {
        guard enabled else { return }

        // Clear user data
        await setUserId(nil)
        Analytics.resetAnalyticsData()
        AppLogger.analytics.info("🔄 [Firebase] Analytics reset")
    }
}
