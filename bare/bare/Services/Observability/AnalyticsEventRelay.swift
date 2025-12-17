//
//  AnalyticsEventRelay.swift
//  bare
//
//  Relays buffered analytics events from App Group to analytics providers
//

import Foundation
import BareKit
import OSLog

/// Service for draining and relaying buffered analytics events from Share Extension
public actor AnalyticsEventRelay {
    private let analytics: AnalyticsService
    private let buffer: AppGroupEventBuffer
    private var processedEventIds: Set<UUID> = []

    /// Initialize relay with analytics service
    /// - Parameter analytics: Analytics service to relay events to
    public init(analytics: AnalyticsService, buffer: AppGroupEventBuffer = .shared) {
        self.analytics = analytics
        self.buffer = buffer
    }

    /// Drain all buffered events and relay to analytics providers
    /// - Returns: Number of events relayed
    @discardableResult
    public func drainAndRelay() async -> Int {
        let events = await buffer.readAll()

        guard !events.isEmpty else {
            AppLogger.analytics.debug("No buffered events to relay")
            return 0
        }

        var relayedCount = 0

        for event in events {
            // Skip if already processed (deduplication)
            guard !processedEventIds.contains(event.id) else {
                AppLogger.analytics.debug("Skipping duplicate event: \(event.id.uuidString)")
                continue
            }

            // Convert parameters to [String: Sendable] for analytics service
            var enrichedParams: [String: Sendable] = event.parameters ?? [:]

            // Add metadata about event source and relay
            enrichedParams["_source"] = event.source
            enrichedParams["_relayed"] = true
            enrichedParams["_original_timestamp"] = ISO8601DateFormatter().string(from: event.timestamp)

            // Relay event
            await analytics.track(event: event.name, parameters: enrichedParams)

            // Mark as processed
            processedEventIds.insert(event.id)
            relayedCount += 1
        }

        // Clear buffer after successful relay
        if relayedCount > 0 {
            await buffer.clear()
            AppLogger.analytics.info("✅ Relayed \(relayedCount) buffered events")
        }

        // Prune processed IDs to prevent unbounded growth (keep last 10k)
        if processedEventIds.count > 10_000 {
            let idsToKeep = Set(processedEventIds.suffix(10_000))
            processedEventIds = idsToKeep
            AppLogger.analytics.debug("Pruned processed event IDs")
        }

        return relayedCount
    }

    /// Get relay statistics
    public func stats() async -> (buffered: Int, processed: Int) {
        let stats = await buffer.stats()
        return (buffered: stats.count, processed: processedEventIds.count)
    }
}
