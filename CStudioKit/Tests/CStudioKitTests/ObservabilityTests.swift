//
//  ObservabilityTests.swift
//  CStudioKitTests
//
//  Unit tests for observability infrastructure
//

import XCTest
@testable import CStudioKit

final class ObservabilityTests: XCTestCase {
    
    // MARK: - AnalyticsService Tests
    
    func testNoopAnalyticsService() async {
        let service = NoopAnalyticsService()
        
        // Should not throw or crash
        await service.track(event: "test_event", parameters: nil)
        await service.setUserProperty("test_prop", value: "test_value")
        await service.setUserId("test_user")
        await service.reset()
    }
    
    // MARK: - FeatureFlagService Tests
    
    func testNoopFeatureFlagService() async {
        let service = NoopFeatureFlagService()
        
        // Should return defaults
        XCTAssertTrue(service.bool(forKey: "test_flag", default: true))
        XCTAssertFalse(service.bool(forKey: "test_flag", default: false))
        XCTAssertEqual(service.string(forKey: "test_key", default: "default"), "default")
        XCTAssertEqual(service.integer(forKey: "test_int", default: 42), 42)
        XCTAssertEqual(service.double(forKey: "test_double", default: 3.14), 3.14, accuracy: 0.001)
        
        // Fetch should succeed but do nothing
        let activated = try await service.fetchAndActivate()
        XCTAssertFalse(activated)
    }
    
    // MARK: - CrashReportingService Tests
    
    func testNoopCrashReportingService() async {
        let service = NoopCrashReportingService()
        
        // Should not throw or crash
        let error = NSError(domain: "test", code: 1, userInfo: nil)
        await service.recordError(error)
        await service.log("test message")
        await service.setCustomValue("value", forKey: "key")
        await service.setUserId("test_user")
    }
    
    // MARK: - PerformanceTraceService Tests
    
    func testNoopPerformanceTraceService() async {
        let service = NoopPerformanceTraceService()
        
        let trace = service.startTrace("test_trace")
        await trace.incrementMetric("test_metric", by: 10)
        await trace.stop()
        
        // Should not throw or crash
        await service.recordNetworkRequest(
            url: URL(string: "https://example.com")!,
            httpMethod: "GET",
            responseCode: 200,
            requestSize: 100,
            responseSize: 500,
            duration: 0.5
        )
    }
    
    // MARK: - Observability Facade Tests
    
    func testObservabilityNoop() async {
        let observability = Observability.noop
        
        // All services should be noop
        await observability.analytics.track(event: "test", parameters: nil)
        XCTAssertFalse(observability.flags.bool(forKey: "test", default: false))
        await observability.crash.log("test")
        let trace = observability.performance.startTrace("test")
        await trace.stop()
    }
    
    func testObservabilityCustomServices() async {
        let analytics = NoopAnalyticsService()
        let flags = NoopFeatureFlagService()
        let crash = NoopCrashReportingService()
        let performance = NoopPerformanceTraceService()
        
        let observability = Observability(
            analytics: analytics,
            flags: flags,
            crash: crash,
            performance: performance
        )
        
        // Services should be accessible
        await observability.analytics.track(event: "test", parameters: nil)
        XCTAssertTrue(observability.flags.bool(forKey: "test", default: true))
        await observability.crash.log("test")
        let trace = observability.performance.startTrace("test")
        await trace.stop()
    }
    
    // MARK: - AppGroupEventBuffer Tests
    
    func testAppGroupEventBufferAppend() async {
        // Use a test container URL
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_buffer.jsonl")
        
        // Clean up before test
        try? FileManager.default.removeItem(at: testURL)
        
        let buffer = AppGroupEventBuffer()
        
        // Append events
        let event1 = BufferedAnalyticsEvent(name: "event1", parameters: nil, source: "test")
        let event2 = BufferedAnalyticsEvent(name: "event2", parameters: ["key": "value"], source: "test")
        let event3 = BufferedAnalyticsEvent(name: "event3", parameters: ["count": "42"], source: "test")
        
        await buffer.append(event1)
        await buffer.append(event2)
        await buffer.append(event3)
        
        // Read events
        let events = await buffer.readAll()
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0].name, "event1")
        XCTAssertEqual(events[1].name, "event2")
        XCTAssertEqual(events[2].name, "event3")
        
        // Clean up
        await buffer.clear()
        let clearedEvents = await buffer.readAll()
        XCTAssertEqual(clearedEvents.count, 0)
    }
    
    func testAppGroupEventBufferClear() async {
        let buffer = AppGroupEventBuffer()
        
        // Add events
        let event1 = BufferedAnalyticsEvent(name: "event1", parameters: nil, source: "test")
        let event2 = BufferedAnalyticsEvent(name: "event2", parameters: nil, source: "test")
        await buffer.append(event1)
        await buffer.append(event2)
        
        // Verify events exist
        var events = await buffer.readAll()
        XCTAssertEqual(events.count, 2)
        
        // Clear buffer
        await buffer.clear()
        
        // Verify empty
        events = await buffer.readAll()
        XCTAssertEqual(events.count, 0)
    }
    
    func testAppGroupEventBufferPersistence() async {
        let buffer = AppGroupEventBuffer()
        
        // Clear any existing events first
        await buffer.clear()
        
        // Add event
        let event = BufferedAnalyticsEvent(name: "persistent_event", parameters: ["persisted": "true"], source: "test")
        await buffer.append(event)
        
        // Read back (simulating app restart by reading from same storage)
        let events = await buffer.readAll()
        XCTAssertGreaterThanOrEqual(events.count, 1)
        XCTAssertTrue(events.contains(where: { $0.name == "persistent_event" }))
        
        // Clean up
        await buffer.clear()
    }
    
    // MARK: - AppLogger Tests
    
    func testAppLoggerCategories() {
        // Test that loggers are accessible
        _ = AppLogger.app
        _ = AppLogger.auth
        _ = AppLogger.network
        _ = AppLogger.ui
        _ = AppLogger.analytics
        _ = AppLogger.flags
        _ = AppLogger.perf
        _ = AppLogger.shareExt
        _ = AppLogger.crash
        _ = AppLogger.storage
    }
    
    func testAppLoggerSignpost() {
        let signpost = AppLogger.signpost(logger: .perf, name: "test_operation")
        signpost.begin()
        // Do work
        signpost.end("completed")
        
        // Should not crash
    }
}

