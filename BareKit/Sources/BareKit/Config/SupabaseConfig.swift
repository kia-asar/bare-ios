//
//  SupabaseConfig.swift
//  BareKit
//
//  Supabase configuration loaded from Info.plist (injected from .xcconfig)
//

import Foundation

/// Configuration for Supabase connection
public struct SupabaseConfig: Sendable {
    public let url: URL
    public let anonKey: String

    public init(url: URL, anonKey: String) {
        self.url = url
        self.anonKey = anonKey
    }

    /// Load configuration from Info.plist (values injected from .xcconfig files)
    /// - Parameter bundle: Bundle to load from (defaults to .main)
    /// - Returns: SupabaseConfig instance
    /// - Throws: ConfigError if configuration is missing or invalid
    public static func fromBundle(_ bundle: Bundle = .main) async throws -> SupabaseConfig {
        // Perform Info.plist read on background thread to avoid blocking main thread
        try await Task.detached(priority: .userInitiated) {
            guard let infoDictionary = bundle.infoDictionary else {
                throw ConfigError.missingConfiguration
            }

            guard let urlString = infoDictionary["SUPABASE_URL"] as? String,
                  !urlString.isEmpty,
                  !urlString.contains("YOUR_"),
                  let url = URL(string: urlString) else {
                throw ConfigError.invalidURL
            }

            guard let anonKey = infoDictionary["SUPABASE_ANON_KEY"] as? String,
                  !anonKey.isEmpty,
                  !anonKey.contains("YOUR_") else {
                throw ConfigError.missingAnonKey
            }

            return SupabaseConfig(url: url, anonKey: anonKey)
        }.value
    }
}

/// Errors that can occur during configuration loading
public enum ConfigError: Error, LocalizedError {
    case missingConfiguration
    case invalidURL
    case missingAnonKey

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Info.plist not found or inaccessible"
        case .invalidURL:
            return "Invalid Supabase URL in configuration. Check SUPABASE_URL in Dev.xcconfig or Prod.xcconfig"
        case .missingAnonKey:
            return "Missing or empty Supabase anon key. Check SUPABASE_ANON_KEY in Dev.xcconfig or Prod.xcconfig"
        }
    }
}


