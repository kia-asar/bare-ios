//
//  Observability.swift
//  CStudioKit
//
//  Unified facade for all observability services
//

import Foundation

/// Unified observability facade containing all observability services
public struct Observability: Sendable {
    /// Analytics event tracking service
    public let analytics: AnalyticsService

    /// Feature flags and remote configuration service
    public let flags: FeatureFlagService

    /// Crash reporting and error tracking service
    public let crash: CrashReportingService

    /// Performance monitoring and tracing service
    public let performance: PerformanceTraceService

    /// Initialize observability with all services
    /// - Parameters:
    ///   - analytics: Analytics service implementation
    ///   - flags: Feature flag service implementation
    ///   - crash: Crash reporting service implementation
    ///   - performance: Performance trace service implementation
    public init(
        analytics: AnalyticsService,
        flags: FeatureFlagService,
        crash: CrashReportingService,
        performance: PerformanceTraceService
    ) {
        self.analytics = analytics
        self.flags = flags
        self.crash = crash
        self.performance = performance
    }

    /// No-op observability for testing or when disabled
    public static let noop = Observability(
        analytics: NoopAnalyticsService(),
        flags: NoopFeatureFlagService(),
        crash: NoopCrashReportingService(),
        performance: NoopPerformanceTraceService()
    )
}
