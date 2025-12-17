//
//  FeatureFlags.swift
//  CStudioKit
//
//  Type-safe feature flags facade
//  Provider-agnostic design allows switching between Firebase, PostHog, etc.
//

import Foundation

/// Type-safe feature flags facade
/// Access flags via static properties: FeatureFlags.isAIChatEnabled
@MainActor
public struct FeatureFlags: Sendable {
    private static var service: FeatureFlagService = NoopFeatureFlagService()
    private static var isConfigured = false

    /// Configure feature flags with a service provider
    /// Call once during app initialization
    /// - Warning: Can only be called once. Subsequent calls are ignored.
    public static func configure(service: FeatureFlagService) {
        guard !isConfigured else {
            #if DEBUG
            print("⚠️ Warning: FeatureFlags.configure() called multiple times. Ignoring.")
            #endif
            return
        }
        self.service = service
        self.isConfigured = true
    }

    // MARK: - Kill Switch Flags (Internal - use KillSwitchChecker)

    // These are accessed internally by KillSwitchChecker
    // Not exposed as static properties to keep API clean

    // MARK: - Example Feature Flags

    // Add your feature flags here as static computed properties
    // Example:
    // public static var isAIChatEnabled: Bool {
    //     service.bool(forKey: "ai_chat_enabled", default: true)
    // }

    // MARK: - Raw Access

    /// Access underlying service for custom flags
    /// Use sparingly - prefer adding typed properties above
    public static var raw: FeatureFlagService {
        service
    }
}
