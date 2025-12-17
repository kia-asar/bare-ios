//
//  PerformanceTraceService.swift
//  BareKit
//
//  Protocol for performance monitoring and tracing
//

import Foundation

/// Protocol for performance trace tracking
public protocol PerformanceTraceService: Sendable {
    /// Start a performance trace
    /// - Parameter name: Trace name
    /// - Returns: Trace handle that can be stopped
    func startTrace(_ name: String) -> PerformanceTrace

    /// Record a network request metric
    /// - Parameters:
    ///   - url: Request URL
    ///   - httpMethod: HTTP method (GET, POST, etc.)
    ///   - responseCode: HTTP response code
    ///   - requestSize: Request payload size in bytes
    ///   - responseSize: Response payload size in bytes
    ///   - duration: Request duration in seconds
    func recordNetworkRequest(
        url: URL,
        httpMethod: String,
        responseCode: Int,
        requestSize: Int64,
        responseSize: Int64,
        duration: TimeInterval
    ) async
}

/// Handle for a performance trace that can be stopped and have metrics attached
public protocol PerformanceTrace: Sendable {
    /// Stop the trace
    func stop() async

    /// Add a custom metric to the trace
    /// - Parameters:
    ///   - name: Metric name
    ///   - value: Metric value
    func incrementMetric(_ name: String, by value: Int64) async

    /// Set a custom attribute on the trace
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    func setAttribute(_ name: String, value: String) async
}

/// No-op implementations
public struct NoopPerformanceTraceService: PerformanceTraceService {
    public init() {}

    public func startTrace(_ name: String) -> PerformanceTrace {
        NoopPerformanceTrace()
    }

    public func recordNetworkRequest(
        url: URL,
        httpMethod: String,
        responseCode: Int,
        requestSize: Int64,
        responseSize: Int64,
        duration: TimeInterval
    ) async {}
}

public struct NoopPerformanceTrace: PerformanceTrace {
    public init() {}

    public func stop() async {}
    public func incrementMetric(_ name: String, by value: Int64) async {}
    public func setAttribute(_ name: String, value: String) async {}
}
