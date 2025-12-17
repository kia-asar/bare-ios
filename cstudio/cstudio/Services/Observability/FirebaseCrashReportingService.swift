//
//  FirebaseCrashReportingService.swift
//  cstudio
//
//  Firebase Crashlytics adapter implementing CrashReportingService protocol
//

import Foundation
import CStudioKit
import OSLog
import FirebaseCrashlytics

/// Firebase Crashlytics implementation of CrashReportingService
///
/// Thread Safety: Uses @unchecked Sendable because the Firebase Crashlytics SDK
/// is internally thread-safe. All calls to Crashlytics methods are safe from any thread
/// as Firebase handles synchronization internally.
public final class FirebaseCrashReportingService: CrashReportingService, @unchecked Sendable {
    private let crashlytics: Crashlytics

    public init() {
        self.crashlytics = Crashlytics.crashlytics()
        AppLogger.crash.info("Firebase Crashlytics initialized")
    }

    public func recordError(_ error: Error) async {
        crashlytics.record(error: error)
        AppLogger.crash.error("🚨 Error recorded: \(error.localizedDescription)")
    }

    public func recordError(_ error: Error, userInfo: [String: Any]) async {
        crashlytics.record(error: error, userInfo: userInfo)
        AppLogger.crash.error("🚨 Error recorded with context: \(error.localizedDescription)")
    }

    public func setCustomValue(_ value: Any, forKey key: String) async {
        let stringValue: String = {
            switch value {
            case let string as String:
                return string
            case let int as Int:
                return String(int)
            case let double as Double:
                return String(double)
            case let bool as Bool:
                return String(bool)
            default:
                return String(describing: value)
            }
        }()

        crashlytics.setCustomValue(stringValue, forKey: key)
        AppLogger.crash.debug("Custom key set: \(key)")
    }

    public func setUserId(_ userId: String?) async {
        crashlytics.setUserID(userId)
        if userId != nil {
            AppLogger.crash.logPrivate("User ID set for crash reports")
        } else {
            AppLogger.crash.info("User ID cleared for crash reports")
        }
    }

    public func log(_ message: String) async {
        crashlytics.log(message)
        AppLogger.crash.debug("📝 \(message)")
    }
}
