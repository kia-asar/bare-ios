//
//  OneSignalPushNotificationService.swift
//  cstudio
//
//  OneSignal implementation of PushNotificationService
//

import Foundation
import CStudioKit
import OneSignalFramework
import OSLog
import UserNotifications

/// OneSignal implementation of push notification service
///
/// Thread Safety:
/// - Uses an actor for internal state management (Swift 6 best practice)
/// - Bridges between OneSignal's callback-based API and async/await
/// - Properly handles isolation boundaries for concurrency safety
///
/// Handles:
/// - Push notification initialization and setup
/// - Permission requests
/// - User ID association for targeted notifications
/// - Notification opened event handling with deep linking
///
/// ## Usage
/// ```swift
/// let service = OneSignalPushNotificationService()
/// await service.initialize(appId: "your-app-id")
/// let granted = await service.requestPermission()
/// await service.setExternalUserId(userId)
/// ```
public final class OneSignalPushNotificationService: PushNotificationService, Sendable {
    private let state: ServiceState

    public init() {
        self.state = ServiceState()
    }

    // MARK: - PushNotificationService Protocol

    public func initialize(appId: String) async {
        AppLogger.app.info("Initializing OneSignal with app ID: \(appId, privacy: .public)")

        // Initialize OneSignal (safe to call from any context)
        // Note: OneSignal handles its own lifecycle via method swizzling
        OneSignal.initialize(appId, withLaunchOptions: nil)

        // Set up handler for when notifications are opened
        // Keep strong reference since listener lives for app lifetime
        let openedListener = NotificationOpenedListener(state: state)
        await state.storeListener(openedListener)
        OneSignal.Notifications.addClickListener(openedListener)

        AppLogger.app.info("OneSignal initialized successfully")
    }

    public func getPermissionStatus() async -> PushPermissionStatus {
        // Use UNUserNotificationCenter directly for accurate permission status
        // This provides proper .notDetermined, .authorized, .denied, and .provisional states
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .provisional:
            return .provisional
        @unknown default:
            return .notDetermined
        }
    }

    public func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            OneSignal.Notifications.requestPermission({ accepted in
                AppLogger.app.info("Push notification permission: \(accepted ? "granted" : "denied")")
                continuation.resume(returning: accepted)
            }, fallbackToSettings: true)
        }
    }

    public func setExternalUserId(_ userId: String) async {
        AppLogger.app.info("Setting OneSignal external user ID: \(userId, privacy: .private(mask: .hash))")
        OneSignal.login(userId)
    }

    public func removeExternalUserId() async {
        AppLogger.app.info("Removing OneSignal external user ID")
        OneSignal.logout()
    }

    public func setNotificationOpenedHandler(_ handler: @escaping @Sendable (PushNotificationData) -> Void) {
        Task {
            await state.setHandler(handler)
        }
    }

    public func addPermissionObserver(_ observer: @escaping @Sendable (Bool) -> Void) {
        // Create and store permission observer
        let permissionObserver = PermissionObserver(state: state)
        Task {
            await state.addPermissionObserver(observer, listener: permissionObserver)
        }

        // Register with OneSignal
        OneSignal.Notifications.addPermissionObserver(permissionObserver)
    }
}

// MARK: - Actor for Thread-Safe State

/// Actor to manage mutable state with proper isolation
/// This is the Swift 6 best practice for thread-safe state management
private actor ServiceState {
    private var notificationOpenedHandler: (@Sendable (PushNotificationData) -> Void)?
    private var openedListener: NotificationOpenedListener?
    private var permissionObservers: [(@Sendable (Bool) -> Void)] = []
    private var permissionListeners: [PermissionObserver] = []

    func setHandler(_ handler: @escaping @Sendable (PushNotificationData) -> Void) {
        self.notificationOpenedHandler = handler
    }

    func storeListener(_ listener: NotificationOpenedListener) {
        self.openedListener = listener
    }

    func addPermissionObserver(_ observer: @escaping @Sendable (Bool) -> Void, listener: PermissionObserver) {
        permissionObservers.append(observer)
        permissionListeners.append(listener)
    }

    func notifyPermissionChange(_ granted: Bool) {
        // Call all registered observers
        for observer in permissionObservers {
            observer(granted)
        }
    }

    func handleNotificationData(
        notificationId: String,
        stringData: [String: String]
    ) {
        AppLogger.app.info("Notification opened: \(notificationId)")

        // Extract route URL from additional data
        var routeURL: URL?
        if let routeString = stringData["route"] {
            routeURL = URL(string: routeString)
            AppLogger.app.info("Notification route: \(routeString)")
        }

        // Create notification data
        let notificationData = PushNotificationData(
            notificationId: notificationId,
            routeURL: routeURL,
            additionalData: stringData
        )

        // Call handler
        notificationOpenedHandler?(notificationData)
    }
}

// MARK: - Notification Opened Listener

/// Notification opened listener conforming to OneSignal's protocol
///
/// Design: Uses unstructured Task to bridge from OneSignal's callback-based API
/// to our async/await actor-based state management. This is the recommended
/// approach for interfacing with legacy callback APIs in Swift 6.
private final class NotificationOpenedListener: NSObject, OSNotificationClickListener, @unchecked Sendable {
    private let state: ServiceState

    nonisolated init(state: ServiceState) {
        self.state = state
        super.init()
    }

    nonisolated func onClick(event: OSNotificationClickEvent) {
        // Extract and convert data to Sendable types before crossing isolation boundary
        // This ensures we don't capture non-Sendable types in the Task closure
        let notificationId = String(event.notification.notificationId ?? "unknown")
        let rawData = event.notification.additionalData ?? [:]

        // Convert to string dictionary for Sendable conformance
        let stringData: [String: String] = rawData.compactMap { key, value -> (String, String)? in
            guard let stringKey = key as? String else { return nil }
            if let string = value as? String {
                return (stringKey, string)
            } else if let number = value as? NSNumber {
                return (stringKey, number.stringValue)
            }
            return nil
        }.reduce(into: [:]) { dict, pair in
            dict[pair.0] = pair.1
        }

        // Use unstructured Task to call into actor-isolated state
        // This is safe because we've already extracted all needed data
        Task {
            await state.handleNotificationData(
                notificationId: notificationId,
                stringData: stringData
            )
        }
    }
}

// MARK: - Permission Observer

/// Permission observer conforming to OneSignal's protocol
///
/// Design: Bridges OneSignal's callback-based permission events to our actor-based state
/// Calls all registered observers when permission state changes
private final class PermissionObserver: NSObject, OSNotificationPermissionObserver, @unchecked Sendable {
    private let state: ServiceState

    nonisolated init(state: ServiceState) {
        self.state = state
        super.init()
    }

    nonisolated func onNotificationPermissionDidChange(_ permission: Bool) {
        AppLogger.app.info("Push notification permission changed: \(permission ? "granted" : "denied")")

        // Notify all observers via actor
        Task {
            await state.notifyPermissionChange(permission)
        }
    }
}
