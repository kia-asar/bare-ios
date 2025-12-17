//
//  AnalyticsContextManager.swift
//  CStudioKit
//
//  Manages analytics context (super properties) for all events
//  Collects app-level, device-level, and dynamic properties
//

import Foundation
import UIKit

/// Manages analytics context and super properties
/// Provides centralized collection of app and device properties for analytics events
@MainActor
public final class AnalyticsContextManager: @unchecked Sendable {

    // MARK: - Static Properties (set once)

    private let staticProperties: [String: Sendable]

    // MARK: - Dynamic Properties (refreshed on foreground)

    private var dynamicProperties: [String: Sendable] = [:]

    // MARK: - Initialization

    public init() {
        // Collect static properties at initialization
        self.staticProperties = Self.collectStaticProperties()

        // Collect initial dynamic properties
        self.dynamicProperties = Self.collectDynamicProperties()
    }

    // MARK: - Public API

    /// All super properties (static + dynamic)
    /// These properties are automatically added to every analytics event
    public var superProperties: [String: Sendable] {
        staticProperties.merging(dynamicProperties) { _, new in new }
    }

    /// Refresh dynamic properties (call on app foreground)
    public func refreshDynamicContext() {
        dynamicProperties = Self.collectDynamicProperties()
    }

    // MARK: - Property Collection

    private static func collectStaticProperties() -> [String: Sendable] {
        var properties: [String: Sendable] = [:]

        // Platform & App Identity
        properties["platform"] = "ios"
        properties["app_name"] = "CStudio iOS"

        // App Version & Build
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            properties["app_version"] = "\(version) (\(build))"
            properties["app_version_name"] = version
            properties["app_build_number"] = build
        }

        // Environment (dev or prod)
        if let environment = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String {
            properties["environment"] = environment
        } else {
            // Fallback: detect from bundle identifier or compilation flags
            #if DEV
            properties["environment"] = "dev"
            #else
            properties["environment"] = "prod"
            #endif
        }

        // Device Information
        let device = UIDevice.current
        properties["device_model"] = device.model // "iPhone" or "iPad"
        properties["device_system_name"] = device.systemName // "iOS"
        properties["device_system_version"] = device.systemVersion // "18.0.1"

        // More specific device model (e.g., "iPhone15,3")
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
        properties["device_identifier"] = modelCode

        // Screen Information
        let screen = UIScreen.main
        properties["screen_width"] = Int(screen.bounds.width)
        properties["screen_height"] = Int(screen.bounds.height)
        properties["screen_scale"] = screen.scale

        // OS Information (consistent naming)
        properties["os_name"] = device.systemName
        properties["os_version"] = device.systemVersion

        return properties
    }

    private static func collectDynamicProperties() -> [String: Sendable] {
        var properties: [String: Sendable] = [:]

        // Locale & Language
        properties["locale"] = Locale.current.identifier // "en_US"
        properties["timezone"] = TimeZone.current.identifier // "America/Los_Angeles"
        properties["timezone_offset"] = TimeZone.current.secondsFromGMT()

        if let languageCode = Locale.current.language.languageCode?.identifier {
            properties["preferred_language"] = languageCode
        }

        // Dark Mode
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            properties["dark_mode"] = window.traitCollection.userInterfaceStyle == .dark
        }

        // Accessibility Settings
        properties["voiceover_enabled"] = UIAccessibility.isVoiceOverRunning
        properties["larger_text_enabled"] = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        properties["reduce_motion_enabled"] = UIAccessibility.isReduceMotionEnabled
        properties["bold_text_enabled"] = UIAccessibility.isBoldTextEnabled

        // Network Information
        // Note: For detailed network type (WiFi vs Cellular), would need Network framework
        // For simplicity, using basic reachability concept
        properties["network_type"] = "unknown" // Could be enhanced with NWPathMonitor

        // Battery Information
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel >= 0 { // -1 means unknown
            properties["battery_level"] = Double(batteryLevel)
        }

        let batteryState = UIDevice.current.batteryState
        switch batteryState {
        case .charging:
            properties["battery_state"] = "charging"
        case .full:
            properties["battery_state"] = "full"
        case .unplugged:
            properties["battery_state"] = "unplugged"
        case .unknown:
            properties["battery_state"] = "unknown"
        @unknown default:
            properties["battery_state"] = "unknown"
        }

        // Low Power Mode
        properties["low_power_mode"] = ProcessInfo.processInfo.isLowPowerModeEnabled

        return properties
    }
}
