//
//  FirebasePerformanceTraceService.swift
//  cstudio
//
//  Firebase Performance Monitoring adapter implementing PerformanceTraceService protocol
//

import Foundation
import CStudioKit
import OSLog
import FirebasePerformance

/// Firebase Performance Monitoring implementation of PerformanceTraceService
///
/// Thread Safety: Uses @unchecked Sendable because the Firebase Performance SDK
/// is internally thread-safe. All calls to Performance methods are safe from any thread
/// as Firebase handles synchronization internally.
public final class FirebasePerformanceTraceService: PerformanceTraceService, @unchecked Sendable {
    public init() {
        AppLogger.perf.info("Firebase Performance Monitoring initialized")
    }

    public func startTrace(_ name: String) -> PerformanceTrace {
        guard let trace = Performance.startTrace(name: name) else {
            AppLogger.perf.error("❌ Failed to start Firebase trace: \(name)")
            return NoopPerformanceTrace()
        }
        AppLogger.perf.debug("▶️ Trace started: \(name)")
        return FirebasePerformanceTraceWrapper(name: name, trace: trace)
    }

    public func recordNetworkRequest(
        url: URL,
        httpMethod: String,
        responseCode: Int,
        requestSize: Int64,
        responseSize: Int64,
        duration: TimeInterval
    ) async {
        guard let metric = HTTPMetric(url: url, httpMethod: firebaseHTTPMethod(from: httpMethod)) else {
            AppLogger.perf.error("❌ Failed to create HTTP metric for \(httpMethod) \(url.absoluteString)")
            return
        }

        metric.responseCode = responseCode
        metric.requestPayloadSize = Int(requestSize)
        metric.responsePayloadSize = Int(responseSize)
        metric.start()

        Task {
            try? await Task.sleep(for: .seconds(duration))
            metric.stop()
        }

        AppLogger.perf.debug("🌐 Network request: \(httpMethod) \(url.absoluteString) - \(responseCode) (\(duration)s)")
    }

    private func firebaseHTTPMethod(from method: String) -> HTTPMethod {
        switch method.uppercased() {
        case "GET": return .get
        case "POST": return .post
        case "PUT": return .put
        case "DELETE": return .delete
        case "PATCH": return .patch
        case "HEAD": return .head
        case "OPTIONS": return .options
        case "TRACE": return .trace
        case "CONNECT": return .connect
        default: return .get
        }
    }
}

/// Wrapper for Firebase Performance Trace
private actor FirebasePerformanceTraceWrapper: PerformanceTrace {
    private let name: String
    private let trace: Trace

    init(name: String, trace: Trace) {
        self.name = name
        self.trace = trace
    }

    func stop() async {
        trace.stop()
        AppLogger.perf.debug("⏹️ Trace stopped: \(self.name)")
    }

    func incrementMetric(_ name: String, by value: Int64) async {
        trace.incrementMetric(name, by: value)
        AppLogger.perf.debug("📊 Metric incremented: \(name) += \(value)")
    }

    func setAttribute(_ name: String, value: String) async {
        trace.setValue(value, forAttribute: name)
        AppLogger.perf.debug("🏷️ Attribute set: \(name) = \(value)")
    }
}
