//
//  AppRoute.swift
//  BareKit
//
//  Created by Kiarash Asar on 11/13/25.
//

import Foundation

/// Centralized type-safe navigation routes for the application.
///
/// This enum defines all possible navigation destinations shared across
/// the main app, widgets, Siri extensions, and share extensions.
///
/// Routes store minimal data (IDs) rather than full objects for efficiency
/// and to enable deep linking. The actual data is fetched when needed.
///
/// Using an enum ensures type-safety and makes it easy to handle:
/// - Deep linking from emails and web
/// - Push notification navigation
/// - Widget tap actions (via URL conversion)
/// - Programmatic navigation from anywhere
///
/// ## Usage in Main App
/// ```swift
/// NavigationLink(value: AppRoute.contentDetail(postId: item.id)) {
///     ThumbnailCell(item: item)
/// }
/// ```
///
/// ## Usage in Widgets
/// ```swift
/// Link(destination: AppRoute.contentDetail(postId: postId).toURL()!) {
///     WidgetView(item: item)
/// }
/// ```
///
/// ## Deep Linking
/// Routes can be parsed from URLs:
/// ```swift
/// // bareapp://post/uuid-here
/// if let route = AppRoute.from(url: deepLinkURL) {
///     navigator.navigate(to: route)
/// }
/// ```
public enum AppRoute: Hashable, Sendable {
    /// Navigate to content detail view by post ID
    case contentDetail(postId: UUID)

    // Future routes can be added here:
    // case settings
    // case profile(userId: String)
    // case search(query: String)
    // case addPost(initialURL: URL?)
}

// MARK: - Deep Linking Support

extension AppRoute {
    /// Deep link URL scheme for the app
    public static let scheme = "bareapp"

    /// Parse a URL into an AppRoute
    ///
    /// Supports URLs like:
    /// - `bareapp://post/{uuid}` → `.contentDetail(postId:)`
    /// - `https://bare.app/post/{uuid}` → `.contentDetail(postId:)` (universal links)
    ///
    /// - Parameter url: The URL to parse (from deep link, widget, push notification, etc.)
    /// - Returns: The corresponding AppRoute, or nil if the URL is invalid
    public static func from(url: URL) -> AppRoute? {
        // Support both custom scheme (bareapp://) and universal links (https://bare.app)
        let isCustomScheme = url.scheme == Self.scheme
        let isUniversalLink = url.scheme == "https" && url.host == "bare.app"

        guard isCustomScheme || isUniversalLink else { return nil }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch pathComponents.first {
        case "post":
            // Parse post detail: bareapp://post/{uuid} or https://bare.app/post/{uuid}
            guard pathComponents.count >= 2,
                  let uuid = UUID(uuidString: pathComponents[1]) else {
                return nil
            }
            return .contentDetail(postId: uuid)

        default:
            return nil
        }
    }

    /// Convert a route to a deep link URL
    ///
    /// Useful for:
    /// - Widget Link destinations
    /// - Generating shareable links
    /// - Push notification payloads
    /// - Siri shortcuts
    ///
    /// - Returns: The URL representation of this route
    public func toURL() -> URL? {
        switch self {
        case .contentDetail(let postId):
            return URL(string: "\(Self.scheme)://post/\(postId.uuidString)")
        }
    }

    /// Convert a route to a universal link (https://) for sharing
    ///
    /// Universal links are better for sharing because they work even if the app isn't installed
    ///
    /// - Returns: The universal link URL for this route
    public func toUniversalLink() -> URL? {
        switch self {
        case .contentDetail(let postId):
            return URL(string: "https://bare.app/post/\(postId.uuidString)")
        }
    }
}
