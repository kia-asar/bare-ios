//
//  AppConstants.swift
//  BareKit
//
//  Centralized app constants that don't fit configuration categories
//

import Foundation

/// Centralized app constants
public enum AppConstants {
    // MARK: - App Store

    /// App Store URL for updates
    /// TODO: Replace APP_ID with actual App Store ID once published
    public static let appStoreURL = URL(string: "https://apps.apple.com/app/idAPP_ID")!

    // MARK: - App Version

    /// Current app version from bundle
    /// Computed lazily on first access
    public static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
}
