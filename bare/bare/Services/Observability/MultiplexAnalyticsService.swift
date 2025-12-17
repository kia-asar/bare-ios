//
//  MultiplexAnalyticsService.swift
//  bare
//
//  Multiplexes analytics events to multiple providers (Firebase + PostHog)
//

import Foundation
import BareKit
import OSLog

/// Multiplexes analytics events to multiple providers
/// Fans out all calls to multiple analytics services in parallel
/// Automatically enriches events with super properties from AnalyticsContextManager
public final class MultiplexAnalyticsService: AnalyticsService, @unchecked Sendable {
    private let services: [AnalyticsService]
    private let contextManager: AnalyticsContextManager

    /// Initialize with a list of analytics services and context manager
    /// - Parameters:
    ///   - services: Array of analytics services to multiplex to
    ///   - contextManager: Context manager providing super properties
    public init(services: [AnalyticsService], contextManager: AnalyticsContextManager) {
        self.services = services
        self.contextManager = contextManager
        AppLogger.analytics.info("MultiplexAnalyticsService initialized with \(services.count) provider(s)")
    }

    public func track(event name: String, parameters: [String: Sendable]?) async {
        // Merge super properties with event parameters
        // Event parameters take precedence (allow overrides)
        let enrichedParameters = await enrichParameters(parameters)

        // Fan out to all services in parallel
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.track(event: name, parameters: enrichedParameters)
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Enrich event parameters with super properties
    /// Event parameters take precedence over super properties
    private func enrichParameters(_ parameters: [String: Sendable]?) async -> [String: Sendable] {
        let superProps = await MainActor.run { contextManager.superProperties }

        // Start with super properties, then merge in event parameters
        var enriched = superProps
        if let parameters = parameters {
            enriched.merge(parameters) { _, new in new }
        }

        return enriched
    }
    
    public func setUserProperty(_ name: String, value: (any Sendable)?) async {
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.setUserProperty(name, value: value)
                }
            }
        }
    }
    
    public func setUserId(_ userId: String?) async {
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.setUserId(userId)
                }
            }
        }
    }
    
    public func reset() async {
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.reset()
                }
            }
        }
    }
}

