//
//  FirebaseRemoteConfigService.swift
//  cstudio
//
//  Firebase Remote Config adapter implementing FeatureFlagService protocol
//

import Foundation
import CStudioKit
import OSLog
import FirebaseRemoteConfig

/// Firebase Remote Config implementation of FeatureFlagService
/// Firebase SDK is thread-safe, so we use @unchecked Sendable
public final class FirebaseRemoteConfigService: FeatureFlagService, @unchecked Sendable {
    private let remoteConfig: RemoteConfig
    private let fetchInterval: TimeInterval
    private static let appGroupMirrorKey = "remote_config_mirror"
    private static let killSwitchCacheKey = "kill_switch_cache"

    /// Initialize Firebase Remote Config service
    /// - Parameter fetchInterval: Minimum fetch interval in seconds
    public init(fetchInterval: TimeInterval = 3600) {
        self.fetchInterval = fetchInterval
        self.remoteConfig = RemoteConfig.remoteConfig()

        // Load default values from plist
        loadDefaults()
    }

    /// Load default configuration from RemoteConfigDefaults.plist
    private func loadDefaults() {
        guard Bundle.main.url(forResource: "RemoteConfigDefaults", withExtension: "plist") != nil else {
            AppLogger.flags.warning("RemoteConfigDefaults.plist not found")
            return
        }

        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        AppLogger.flags.info("Loaded Remote Config defaults from plist")
    }

    public func fetchAndActivate() async throws -> Bool {
        // Configure fetch settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = fetchInterval
        remoteConfig.configSettings = settings

        // Fetch and activate
        let status = try await remoteConfig.fetchAndActivate()
        let activated = (status == .successFetchedFromRemote)

        if activated {
            // Mirror to App Group for Share Extension
            await mirrorToAppGroup()
            // Cache kill switch flags for guaranteed offline access
            cacheKillSwitchFlags()
            AppLogger.flags.info("✅ Remote Config fetched and activated")
        } else {
            AppLogger.flags.info("ℹ️ Remote Config already up to date")
        }

        return activated
    }

    public func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        return remoteConfig.configValue(forKey: key).boolValue
    }

    public func string(forKey key: String, default defaultValue: String) -> String {
        let stringValue = remoteConfig.configValue(forKey: key).stringValue
        return stringValue.isEmpty ? defaultValue : stringValue
    }

    public func integer(forKey key: String, default defaultValue: Int) -> Int {
        return remoteConfig.configValue(forKey: key).numberValue.intValue
    }

    public func double(forKey key: String, default defaultValue: Double) -> Double {
        return remoteConfig.configValue(forKey: key).numberValue.doubleValue
    }

    public func allFlags() -> [String: Any] {
        return remoteConfig.allKeys(from: .remote).reduce(into: [:]) { result, key in
            let configValue = remoteConfig.configValue(forKey: key)
            if let json = configValue.jsonValue {
                result[key] = json
                return
            }

            let stringValue = configValue.stringValue

            if let boolValue = Bool(stringValue.lowercased()) {
                result[key] = boolValue
            } else if let intValue = Int(stringValue) {
                result[key] = intValue
            } else if let doubleValue = Double(stringValue) {
                result[key] = doubleValue
            } else if !stringValue.isEmpty {
                result[key] = stringValue
            }
        }
    }

    /// Mirror active Remote Config to App Group UserDefaults for Share Extension
    private func mirrorToAppGroup() async {
        guard let userDefaults = AppGroup.userDefaults else {
            AppLogger.flags.error("App Group UserDefaults not available")
            return
        }

        let flags = allFlags()
        userDefaults.set(flags, forKey: Self.appGroupMirrorKey)
        userDefaults.set(Date(), forKey: "\(Self.appGroupMirrorKey)_updated_at")

        AppLogger.flags.info("Mirrored \(flags.count) flags to App Group")
    }

    /// Read mirrored Remote Config from App Group (for Share Extension)
    public static func readMirroredFlags() -> [String: Any] {
        guard let userDefaults = AppGroup.userDefaults else {
            AppLogger.flags.error("App Group UserDefaults not available")
            return [:]
        }

        return userDefaults.dictionary(forKey: Self.appGroupMirrorKey) ?? [:]
    }

    /// Cache critical kill switch flags to UserDefaults for guaranteed offline access
    private func cacheKillSwitchFlags() {
        guard let userDefaults = AppGroup.userDefaults else {
            AppLogger.flags.error("App Group UserDefaults not available for kill switch cache")
            return
        }

        // Build cache dictionary efficiently - only call allFlags() once
        let allFlagsDict = allFlags()
        let killSwitchCache: [String: Any] = [
            "minimum_required_version": string(forKey: "minimum_required_version", default: ""),
            "blocked_versions": (allFlagsDict["blocked_versions"] as? [String]) ?? [],
            "soft_kill_switch_enabled": bool(forKey: "soft_kill_switch_enabled", default: false),
            "soft_kill_switch_message": string(forKey: "soft_kill_switch_message", default: ""),
            "hard_kill_switch_enabled": bool(forKey: "hard_kill_switch_enabled", default: false),
            "hard_kill_switch_message": string(forKey: "hard_kill_switch_message", default: ""),
            "emergency_kill_switch_enabled": bool(forKey: "emergency_kill_switch_enabled", default: false),
            "emergency_kill_switch_message": string(forKey: "emergency_kill_switch_message", default: ""),
            "maintenance_mode": bool(forKey: "maintenance_mode", default: false),
            "maintenance_message": string(forKey: "maintenance_message", default: ""),
            "maintenance_end_time": string(forKey: "maintenance_end_time", default: "")
        ]

        userDefaults.set(killSwitchCache, forKey: Self.killSwitchCacheKey)
        AppLogger.flags.debug("Cached kill switch flags to UserDefaults")
    }

    /// Read cached kill switch flags from UserDefaults (for offline access)
    public static func readCachedKillSwitchFlags() -> [String: Any] {
        guard let userDefaults = AppGroup.userDefaults else {
            return [:]
        }

        return userDefaults.dictionary(forKey: Self.killSwitchCacheKey) ?? [:]
    }
}
