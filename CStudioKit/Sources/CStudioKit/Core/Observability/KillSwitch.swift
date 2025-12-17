//
//  KillSwitch.swift
//  CStudioKit
//
//  Kill switch state and checking logic
//

import Foundation

/// Kill switch state with precedence: Emergency > Hard > Maintenance > Soft > None
public enum KillSwitchState: Sendable, CustomStringConvertible {
    case none
    case soft(message: String)
    case maintenance(message: String, endTime: Date?)
    case hard(message: String)
    case emergency(message: String)

    /// Returns true if this state blocks app usage completely
    public var isBlocking: Bool {
        switch self {
        case .none, .soft:
            return false
        case .maintenance, .hard, .emergency:
            return true
        }
    }

    public var description: String {
        switch self {
        case .none:
            return "none"
        case .soft:
            return "soft"
        case .maintenance:
            return "maintenance"
        case .hard:
            return "hard"
        case .emergency:
            return "emergency"
        }
    }
}

/// Checks kill switch conditions based on app version and remote config
public struct KillSwitchChecker: Sendable {
    private let flags: FeatureFlagService
    private let currentVersion: SemanticVersion
    private nonisolated(unsafe) static let iso8601Formatter = ISO8601DateFormatter()

    /// Cached parsed version for efficient reuse across multiple checks
    private nonisolated(unsafe) static var cachedVersion: SemanticVersion?

    /// Initialize with feature flag service and current app version
    public init(flags: FeatureFlagService, currentVersion: String = AppConstants.currentVersion) {
        self.flags = flags

        // Use cached version if available (startup optimization)
        if let cached = Self.cachedVersion {
            self.currentVersion = cached
        } else if let version = SemanticVersion(string: currentVersion) {
            self.currentVersion = version
            Self.cachedVersion = version
        } else {
            // Log warning for invalid version and use fallback
            self.currentVersion = SemanticVersion(major: 0, minor: 0, patch: 0)
            Self.cachedVersion = self.currentVersion
            #if DEBUG
            print("⚠️ Warning: Invalid app version '\(currentVersion)', using 0.0.0 as fallback")
            #endif
        }
    }

    /// Check all kill switch conditions and return appropriate state
    /// Priority: Emergency > Hard > Maintenance > Soft > None
    public func check() -> KillSwitchState {
        // Emergency kill switch (highest priority)
        if flags.bool(forKey: "emergency_kill_switch_enabled", default: false) {
            let message = flags.string(
                forKey: "emergency_kill_switch_message",
                default: "We're experiencing technical difficulties. Please try again later."
            )
            return .emergency(message: message)
        }

        // Hard kill switch (version-based)
        if flags.bool(forKey: "hard_kill_switch_enabled", default: false) && isVersionBlocked() {
            let message = flags.string(
                forKey: "hard_kill_switch_message",
                default: "This version of CStudio is no longer supported. Please update to continue using the app."
            )
            return .hard(message: message)
        }

        // Maintenance mode
        if flags.bool(forKey: "maintenance_mode", default: false) {
            let message = flags.string(
                forKey: "maintenance_message",
                default: "Scheduled maintenance in progress. Please check back soon."
            )
            let endTimeString = flags.string(forKey: "maintenance_end_time", default: "")
            let endTime = Self.iso8601Formatter.date(from: endTimeString)
            return .maintenance(message: message, endTime: endTime)
        }

        // Soft kill switch (version-based, lowest priority)
        if flags.bool(forKey: "soft_kill_switch_enabled", default: false) && isVersionBlocked() {
            let message = flags.string(
                forKey: "soft_kill_switch_message",
                default: "A new version of CStudio is available. Please update for the best experience."
            )
            return .soft(message: message)
        }

        return .none
    }

    /// Check if current version is blocked based on minimum version or blocked list
    private func isVersionBlocked() -> Bool {
        // Check minimum required version first (most common case)
        let minVersionString = flags.string(forKey: "minimum_required_version", default: "")
        if !minVersionString.isEmpty, let minVersion = SemanticVersion(string: minVersionString) {
            if currentVersion < minVersion {
                return true
            }
        }

        // Check blocked versions list
        // Note: Firebase Remote Config stores arrays, so we need allFlags()
        // This is only called when hard/soft kill switches are enabled, so impact is minimal
        let allFlagsDict = flags.allFlags()
        if let blockedVersions = allFlagsDict["blocked_versions"] as? [String] {
            let currentVersionString = currentVersion.description
            if blockedVersions.contains(currentVersionString) {
                return true
            }
        }

        return false
    }
}
