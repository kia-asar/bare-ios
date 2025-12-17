//
//  AppConfig.swift
//  CStudioKit
//
//  Centralized configuration constants extracted from Info.plist and entitlements
//  Single source of truth for shared identifiers across app and extension
//

import Foundation

/// Centralized app configuration constants
/// These values must match corresponding entries in Info.plist and entitlements
public enum AppConfig {
    // MARK: - App Group
    
    /// Shared App Group identifier for data sharing between app and extension
    /// Must match: `com.apple.security.application-groups` in both target entitlements
    public static let appGroupIdentifier = "group.social.curo.cstudio"
    
    // MARK: - Keychain
    
    /// Keychain access group suffix (will be prefixed with AppIdentifierPrefix at runtime)
    /// Must match: `keychain-access-groups` in both target entitlements
    public static let keychainAccessGroupSuffix = "social.curo.cstudio.sharedkeychain"
    
    // MARK: - URL Scheme
    
    /// Custom URL scheme for deep linking
    /// Must match: `CFBundleURLSchemes` in Info.plist
    public static let urlScheme = "cstudio"
    
    /// Auth callback URL for magic link authentication
    public static let authCallbackURL = URL(string: "\(urlScheme)://auth-callback")!
    
    // MARK: - Bundle Identifiers
    
    /// Main app bundle identifier
    public static let mainAppBundleID = "social.curo.cstudio"
    
    /// Share extension bundle identifier
    public static let shareExtensionBundleID = "\(mainAppBundleID).ShareExtension"
    
    // MARK: - Internal Services
    
    /// Keychain service identifier for Supabase auth storage
    public static let keychainServiceID = "\(mainAppBundleID).auth"
    
    /// Error domain for Share Extension
    public static let shareExtensionErrorDomain = "com.cstudio.shareextension"
}

// MARK: - Debug Validation

extension AppConfig {
    /// Validates configuration at runtime in Debug builds
    /// Call once at app launch to catch configuration mismatches early
    public static func validate() {
#if DEBUG
        // Validate App Group
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
        assert(container != nil, """
            ❌ App Group '\(appGroupIdentifier)' not configured in entitlements.
            Add to both app and extension targets under 'App Groups' capability.
            """)
        
        // Validate UserDefaults suite
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        assert(defaults != nil, """
            ❌ App Group UserDefaults suite '\(appGroupIdentifier)' not accessible.
            Verify entitlements configuration.
            """)
        
        print("✅ AppConfig validation passed")
#else
        // No-op in non-debug builds
#endif
    }
}

