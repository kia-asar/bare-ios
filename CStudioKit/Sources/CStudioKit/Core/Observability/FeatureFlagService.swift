//
//  FeatureFlagService.swift
//  CStudioKit
//
//  Protocol for feature flag and remote configuration services
//

import Foundation

/// Protocol for feature flag and remote configuration
public protocol FeatureFlagService: Sendable {
    /// Fetch and activate remote configuration
    /// - Returns: True if new config was activated
    @discardableResult
    func fetchAndActivate() async throws -> Bool

    /// Get a boolean flag value
    /// - Parameters:
    ///   - key: Flag key
    ///   - defaultValue: Default value if flag doesn't exist
    /// - Returns: Flag value
    func bool(forKey key: String, default defaultValue: Bool) -> Bool

    /// Get a string flag value
    /// - Parameters:
    ///   - key: Flag key
    ///   - defaultValue: Default value if flag doesn't exist
    /// - Returns: Flag value
    func string(forKey key: String, default defaultValue: String) -> String

    /// Get an integer flag value
    /// - Parameters:
    ///   - key: Flag key
    ///   - defaultValue: Default value if flag doesn't exist
    /// - Returns: Flag value
    func integer(forKey key: String, default defaultValue: Int) -> Int

    /// Get a double flag value
    /// - Parameters:
    ///   - key: Flag key
    ///   - defaultValue: Default value if flag doesn't exist
    /// - Returns: Flag value
    func double(forKey key: String, default defaultValue: Double) -> Double

    /// Get all active flags as dictionary
    /// - Returns: Dictionary of all active flags
    func allFlags() -> [String: Any]
}

/// No-op implementation that returns default values
public struct NoopFeatureFlagService: FeatureFlagService {
    public init() {}

    public func fetchAndActivate() async throws -> Bool { false }
    public func bool(forKey key: String, default defaultValue: Bool) -> Bool { defaultValue }
    public func string(forKey key: String, default defaultValue: String) -> String { defaultValue }
    public func integer(forKey key: String, default defaultValue: Int) -> Int { defaultValue }
    public func double(forKey key: String, default defaultValue: Double) -> Double { defaultValue }
    public func allFlags() -> [String: Any] { [:] }
}
