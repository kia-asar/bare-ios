//
//  Notification+Extensions.swift
//  bare
//
//  Notification names for app-wide events
//

import Foundation

extension Notification.Name {
    /// Posted when Remote Config is updated with new values
    ///
    /// Swift 6: `nonisolated(unsafe)` is the recommended approach for static
    /// constant values that are thread-safe by design (immutable structs)
    nonisolated(unsafe) static let remoteConfigUpdated = Notification.Name("remoteConfigUpdated")

    /// Posted when a push notification is opened and should navigate to a route
    /// UserInfo contains "routeURL" key with URL value
    ///
    /// Swift 6: `nonisolated(unsafe)` is the recommended approach for static
    /// constant values that are thread-safe by design (immutable structs)
    nonisolated(unsafe) static let navigateToRoute = Notification.Name("navigateToRoute")
}
