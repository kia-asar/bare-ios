//
//  AppGroupEventBuffer.swift
//  CStudioKit
//
//  Buffered analytics events for Share Extension, relayed by main app
//

import Foundation
import OSLog

/// Buffered analytics event that can be relayed by the main app
public struct BufferedAnalyticsEvent: Codable, Sendable {
    /// Unique event identifier for deduplication
    public let id: UUID

    /// Event name
    public let name: String

    /// Event parameters (must be JSON-serializable)
    public let parameters: [String: String]?

    /// Timestamp when event was created
    public let timestamp: Date

    /// Source of the event (e.g., "app", "share_extension")
    public let source: String

    public init(
        id: UUID = UUID(),
        name: String,
        parameters: [String: String]? = nil,
        timestamp: Date = Date(),
        source: String
    ) {
        self.id = id
        self.name = name
        self.parameters = parameters
        self.timestamp = timestamp
        self.source = source
    }
}

/// Thread-safe event buffer using App Group storage for extension-to-app communication
public actor AppGroupEventBuffer {
    public static let shared = AppGroupEventBuffer()

    /// Maximum number of events to buffer (prevent unbounded growth)
    private static let maxBufferSize = 1000

    /// Maximum age of events in seconds (7 days)
    private static let maxEventAge: TimeInterval = 7 * 24 * 60 * 60

    /// File name for buffered events in App Group container
    private static let bufferFileName = "analytics_event_buffer.jsonl"

    private let logger = Logger(subsystem: AppConfig.mainAppBundleID, category: "analytics")

    private init() {}

    /// File URL for the event buffer
    private var bufferFileURL: URL? {
        AppGroup.containerURL?.appendingPathComponent(Self.bufferFileName)
    }

    /// Append an event to the buffer
    /// - Parameter event: Event to buffer
    public func append(_ event: BufferedAnalyticsEvent) {
        guard let fileURL = bufferFileURL else {
            logger.error("App Group container not available, cannot buffer event: \(event.name)")
            return
        }

        do {
            // Encode event as single-line JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(event)

            // Append to file (create if doesn't exist)
            let fileHandle: FileHandle
            if FileManager.default.fileExists(atPath: fileURL.path) {
                fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
            } else {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
                fileHandle = try FileHandle(forWritingTo: fileURL)
            }

            defer { try? fileHandle.close() }

            // Write JSON line + newline
            fileHandle.write(jsonData)
            fileHandle.write("\n".data(using: .utf8)!)

            logger.debug("Buffered event: \(event.name) (id: \(event.id.uuidString))")
        } catch {
            logger.error("Failed to buffer event: \(error.localizedDescription)")
        }
    }

    /// Read all buffered events
    /// - Returns: Array of buffered events (oldest first)
    public func readAll() -> [BufferedAnalyticsEvent] {
        guard let fileURL = bufferFileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let lines = String(data: data, encoding: .utf8)?.split(separator: "\n") ?? []

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let events = lines.compactMap { line -> BufferedAnalyticsEvent? in
                guard let lineData = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(BufferedAnalyticsEvent.self, from: lineData)
            }

            // Filter out stale events
            let cutoffDate = Date().addingTimeInterval(-Self.maxEventAge)
            let freshEvents = events.filter { $0.timestamp > cutoffDate }

            logger.info("Read \(freshEvents.count) buffered events (filtered \(events.count - freshEvents.count) stale)")
            return freshEvents
        } catch {
            logger.error("Failed to read buffered events: \(error.localizedDescription)")
            return []
        }
    }

    /// Clear all buffered events
    public func clear() {
        guard let fileURL = bufferFileURL else { return }

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                logger.info("Cleared event buffer")
            }
        } catch {
            logger.error("Failed to clear event buffer: \(error.localizedDescription)")
        }
    }

    /// Prune buffer to prevent unbounded growth
    /// Keeps most recent events up to maxBufferSize
    public func prune() {
        let events = readAll()

        guard events.count > Self.maxBufferSize else { return }

        // Keep only most recent events
        let recentEvents = Array(events.suffix(Self.maxBufferSize))

        // Rewrite buffer with pruned events
        clear()
        for event in recentEvents {
            append(event)
        }

        logger.info("Pruned buffer from \(events.count) to \(recentEvents.count) events")
    }

    /// Get buffer statistics
    public func stats() -> (count: Int, oldestEvent: Date?, newestEvent: Date?) {
        let events = readAll()
        return (
            count: events.count,
            oldestEvent: events.first?.timestamp,
            newestEvent: events.last?.timestamp
        )
    }
}

// MARK: - Consent-Aware Buffering Helper

extension AppGroupEventBuffer {
    /// Check if analytics consent is granted (reads from App Group UserDefaults)
    /// For US-only apps, Release builds default to true (implied consent via privacy policy)
    /// Debug builds default to false to avoid test data pollution
    private var isConsentGranted: Bool {
        #if DEBUG
        // Disabled in debug by default to avoid polluting analytics with test data
        return AppGroup.userDefaults?.bool(forKey: "analytics_consent_granted") ?? false
        #else
        // Enabled in release (US-only, implied consent via privacy policy)
        // If explicit consent is needed (e.g., EU), update this logic
        return AppGroup.userDefaults?.bool(forKey: "analytics_consent_granted") ?? true
        #endif
    }

    /// Append event only if consent is granted
    /// - Parameter event: Event to buffer
    public func appendIfConsented(_ event: BufferedAnalyticsEvent) {
        guard isConsentGranted else {
            logger.debug("Skipping event due to no consent: \(event.name)")
            return
        }
        append(event)
    }
}
