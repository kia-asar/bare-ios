//
//  NoopPushNotificationService.swift
//  CStudioKit
//
//  No-op implementation for testing and previews
//

import Foundation

/// No-op push notification service for testing, previews, and graceful degradation
///
/// Usage in previews:
/// ```swift
/// #Preview {
///     ContentView()
///         .task {
///             await DependencyContainer.shared.initialize(
///                 config: mockConfig,
///                 observability: .noop,
///                 pushNotificationService: NoopPushNotificationService()
///             )
///         }
/// }
/// ```
public final class NoopPushNotificationService: PushNotificationService {
    public init() {}

    public func initialize(appId: String) async {
        // No-op: do nothing
    }

    public func getPermissionStatus() async -> PushPermissionStatus {
        // Always return notDetermined in testing
        return .notDetermined
    }

    public func requestPermission() async -> Bool {
        // Always return false in testing
        return false
    }

    public func setExternalUserId(_ userId: String) async {
        // No-op: do nothing
    }

    public func removeExternalUserId() async {
        // No-op: do nothing
    }

    public func setNotificationOpenedHandler(_ handler: @escaping @Sendable (PushNotificationData) -> Void) {
        // No-op: do nothing
    }

    public func addPermissionObserver(_ observer: @escaping @Sendable (Bool) -> Void) {
        // No-op: do nothing
    }
}
