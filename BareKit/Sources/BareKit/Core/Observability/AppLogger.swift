//
//  AppLogger.swift
//  BareKit
//
//  Centralized logging wrapper over os.Logger with categories and signpost support
//

import Foundation
import OSLog

/// Centralized logger with predefined categories and signpost helpers
public enum AppLogger {
    // MARK: - Subsystem

    /// App subsystem identifier (bundle ID)
    private static let subsystem = AppConfig.mainAppBundleID

    // MARK: - Category Loggers

    /// Logger for authentication flows
    public static let auth = Logger(subsystem: subsystem, category: "auth")

    /// Logger for network operations
    public static let network = Logger(subsystem: subsystem, category: "network")

    /// Logger for UI events and lifecycle
    public static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Logger for analytics events
    public static let analytics = Logger(subsystem: subsystem, category: "analytics")

    /// Logger for feature flags and remote config
    public static let flags = Logger(subsystem: subsystem, category: "flags")

    /// Logger for performance monitoring
    public static let perf = Logger(subsystem: subsystem, category: "perf")

    /// Logger for Share Extension
    public static let shareExt = Logger(subsystem: subsystem, category: "shareext")

    /// Logger for crash reporting
    public static let crash = Logger(subsystem: subsystem, category: "crash")

    /// Logger for general app lifecycle
    public static let app = Logger(subsystem: subsystem, category: "app")

    /// Logger for data persistence and storage
    public static let storage = Logger(subsystem: subsystem, category: "storage")

    // MARK: - Signpost Helpers

    /// Helper for creating signpost intervals for performance measurement
    public struct Signpost {
        private let logger: Logger
        private let name: StaticString
        private let id: OSSignpostID

        fileprivate init(logger: Logger, name: StaticString) {
            self.logger = logger
            self.name = name
            self.id = OSSignpostID(log: OSLog(subsystem: subsystem, category: "signpost"))
        }

        /// Begin the signpost interval
        /// - Parameter message: Optional message with context
        public func begin(_ message: String = "") {
            if message.isEmpty {
                os_signpost(.begin, log: OSLog(subsystem: subsystem, category: "signpost"), name: name, signpostID: id)
            } else {
                os_signpost(.begin, log: OSLog(subsystem: subsystem, category: "signpost"), name: name, signpostID: id, "%{public}s", message)
            }
        }

        /// End the signpost interval
        /// - Parameter message: Optional message with result
        public func end(_ message: String = "") {
            if message.isEmpty {
                os_signpost(.end, log: OSLog(subsystem: subsystem, category: "signpost"), name: name, signpostID: id)
            } else {
                os_signpost(.end, log: OSLog(subsystem: subsystem, category: "signpost"), name: name, signpostID: id, "%{public}s", message)
            }
        }

        /// Emit a signpost event (point in time, not an interval)
        /// - Parameter message: Event message
        public func event(_ message: String) {
            os_signpost(.event, log: OSLog(subsystem: subsystem, category: "signpost"), name: name, signpostID: id, "%{public}s", message)
        }
    }

    /// Create a signpost for performance measurement
    /// - Parameters:
    ///   - logger: Logger to use for context
    ///   - name: Signpost name
    /// - Returns: Signpost helper for begin/end/event calls
    public static func signpost(logger: Logger = AppLogger.perf, name: StaticString) -> Signpost {
        Signpost(logger: logger, name: name)
    }

    /// Measure the execution time of an async operation with signposts
    /// - Parameters:
    ///   - name: Operation name for the signpost
    ///   - logger: Logger to use (defaults to performance logger)
    ///   - operation: Async operation to measure
    /// - Returns: Result of the operation
    @discardableResult
    @inlinable
    public static func measure<T>(
        _ name: StaticString,
        logger: Logger = AppLogger.perf,
        operation: () async throws -> T
    ) async rethrows -> T {
        let signpost = self.signpost(logger: logger, name: name)
        signpost.begin()
        do {
            let result = try await operation()
            signpost.end("success")
            return result
        } catch {
            signpost.end("error")
            throw error
        }
    }

    /// Measure the execution time of a synchronous operation with signposts
    /// - Parameters:
    ///   - name: Operation name for the signpost
    ///   - logger: Logger to use (defaults to performance logger)
    ///   - operation: Synchronous operation to measure
    /// - Returns: Result of the operation
    @discardableResult
    @inlinable
    public static func measure<T>(
        _ name: StaticString,
        logger: Logger = AppLogger.perf,
        operation: () throws -> T
    ) rethrows -> T {
        let signpost = self.signpost(logger: logger, name: name)
        signpost.begin()
        do {
            let result = try operation()
            signpost.end("success")
            return result
        } catch {
            signpost.end("error")
            throw error
        }
    }
}

// MARK: - Privacy Helpers

extension Logger {
    /// Log with automatic privacy redaction for sensitive data
    /// Use this for any PII (emails, names, IDs, etc.)
    public func logPrivate(
        level: OSLogType = .default,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.log(level: level, "[private] \(message, privacy: .private)")
    }

    /// Log with public visibility (safe for system logs)
    /// Use this for non-sensitive operational data
    public func logPublic(
        level: OSLogType = .default,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.log(level: level, "\(message, privacy: .public)")
    }
}
