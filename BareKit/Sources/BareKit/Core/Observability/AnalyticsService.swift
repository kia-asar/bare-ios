//
//  AnalyticsService.swift
//  BareKit
//
//  Protocol for analytics tracking services
//

import Foundation

/// Protocol for analytics event tracking
/// Uses Sendable types for Swift 6 strict concurrency
public protocol AnalyticsService: Sendable {
    /// Track a custom event with optional parameters
    /// - Parameters:
    ///   - name: Event name (use snake_case convention)
    ///   - parameters: Optional dictionary of event parameters (must be Sendable types)
    func track(event name: String, parameters: [String: Sendable]?) async

    /// Set a user property
    /// - Parameters:
    ///   - name: Property name
    ///   - value: Property value (String, Int, Double, Bool, or nil)
    func setUserProperty(_ name: String, value: (any Sendable)?) async

    /// Set the user identifier
    /// - Parameter userId: User ID (nil to clear)
    func setUserId(_ userId: String?) async

    /// Reset all user data (on logout)
    func reset() async
}

/// No-op implementation for testing or when analytics is disabled
public struct NoopAnalyticsService: AnalyticsService {
    public init() {}

    public func track(event name: String, parameters: [String: Sendable]?) async {}
    public func setUserProperty(_ name: String, value: (any Sendable)?) async {}
    public func setUserId(_ userId: String?) async {}
    public func reset() async {}
}
