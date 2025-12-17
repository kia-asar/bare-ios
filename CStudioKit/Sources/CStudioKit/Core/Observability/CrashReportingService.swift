//
//  CrashReportingService.swift
//  CStudioKit
//
//  Protocol for crash reporting and error tracking services
//

import Foundation

/// Protocol for crash reporting and non-fatal error tracking
public protocol CrashReportingService: Sendable {
    /// Record a non-fatal error
    /// - Parameter error: Error to record
    func recordError(_ error: Error) async

    /// Record a non-fatal error with additional context
    /// - Parameters:
    ///   - error: Error to record
    ///   - userInfo: Additional context dictionary
    func recordError(_ error: Error, userInfo: [String: Any]) async

    /// Set a custom key-value pair for crash reports
    /// - Parameters:
    ///   - key: Key name
    ///   - value: Value (String, Int, Double, or Bool)
    func setCustomValue(_ value: Any, forKey key: String) async

    /// Set user identifier for crash reports
    /// - Parameter userId: User ID (nil to clear)
    func setUserId(_ userId: String?) async

    /// Log a message that will appear in crash reports
    /// - Parameter message: Message to log
    func log(_ message: String) async
}

/// No-op implementation for testing or when crash reporting is disabled
public struct NoopCrashReportingService: CrashReportingService {
    public init() {}

    public func recordError(_ error: Error) async {}
    public func recordError(_ error: Error, userInfo: [String: Any]) async {}
    public func setCustomValue(_ value: Any, forKey key: String) async {}
    public func setUserId(_ userId: String?) async {}
    public func log(_ message: String) async {}
}
