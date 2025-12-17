//
//  PushNotificationService.swift
//  BareKit
//
//  Protocol-based push notification service supporting OneSignal and test implementations
//

import Foundation

// MARK: - Permission Status

/// Push notification permission status
public enum PushPermissionStatus: String, Sendable {
    case notDetermined  // User hasn't been asked yet
    case denied         // User explicitly denied
    case authorized     // User granted permission
    case provisional    // iOS 12+ quiet notifications (reserved for future use)
}

// MARK: - PushNotificationService Protocol

/// Protocol for push notification services (OneSignal, testing, etc.)
///
/// Design principles:
/// - Sendable for Swift 6 concurrency safety
/// - Async/await throughout for modern Swift
/// - Graceful degradation if service fails
/// - Test-friendly with Noop implementation
public protocol PushNotificationService: Sendable {
    /// Initialize the push notification service
    /// - Parameter appId: The OneSignal App ID or service identifier
    func initialize(appId: String) async

    /// Get current permission status
    /// - Returns: Current permission state
    func getPermissionStatus() async -> PushPermissionStatus

    /// Request permission to send notifications to the user
    /// - Returns: True if permission was granted, false otherwise
    func requestPermission() async -> Bool

    /// Associate the device with a user ID for targeted notifications
    /// - Parameter userId: The external user ID (from your auth system)
    func setExternalUserId(_ userId: String) async

    /// Remove the user ID association (e.g., on logout)
    func removeExternalUserId() async

    /// Set handler for when a notification is opened/tapped
    /// - Parameter handler: Closure called when notification is opened
    func setNotificationOpenedHandler(_ handler: @escaping @Sendable (PushNotificationData) -> Void)

    /// Add observer for permission state changes
    /// - Parameter observer: Closure called when permission state changes (true = granted, false = denied)
    ///
    /// Use this to:
    /// - Track permission grant/denial in analytics
    /// - Update UI based on permission state
    /// - Detect when users revoke permission in Settings
    func addPermissionObserver(_ observer: @escaping @Sendable (Bool) -> Void)
}

// MARK: - Data Models

/// Push notification data extracted from notification payload
public struct PushNotificationData: Sendable {
    /// Unique notification ID
    public let notificationId: String

    /// Optional deep link route URL (e.g., "bareapp://post/uuid")
    public let routeURL: URL?

    /// Additional custom data from notification payload
    public let additionalData: [String: String]

    public init(
        notificationId: String,
        routeURL: URL?,
        additionalData: [String: String] = [:]
    ) {
        self.notificationId = notificationId
        self.routeURL = routeURL
        self.additionalData = additionalData
    }
}

// MARK: - Error Handling

/// Errors that can occur with push notification service
public enum PushNotificationError: LocalizedError {
    case initializationFailed(String)
    case permissionDenied
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Push notification initialization failed: \(reason)"
        case .permissionDenied:
            return "User denied notification permission"
        case .invalidConfiguration:
            return "Push notification service configuration is invalid"
        }
    }
}
