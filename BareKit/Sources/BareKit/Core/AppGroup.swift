//
//  AppGroup.swift
//  BareKit
//
//  App Group storage helpers using centralized configuration
//

import Foundation

/// App Group storage helpers for sharing data between main app and extensions
public enum AppGroup {
    /// Shared App Group identifier (from AppConfig)
    public static let identifier = AppConfig.appGroupIdentifier
    
    /// Shared UserDefaults for lightweight key-value storage
    /// - Returns: UserDefaults suite or nil if App Group is not configured
    public static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
    
    /// Shared file container for storing files/caches
    /// - Returns: Container URL or nil if App Group is not configured
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}


