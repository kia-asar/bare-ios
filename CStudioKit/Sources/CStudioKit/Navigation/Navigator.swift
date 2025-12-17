//
//  Navigator.swift
//  CStudioKit
//
//  Created by Kiarash Asar on 11/13/25.
//

import Foundation
import SwiftUI
import Observation

/// Generic navigation manager for SwiftUI NavigationStack.
///
/// The Navigator class manages navigation state using SwiftUI's NavigationPath.
/// It's designed to work across all app targets (main app, widgets, extensions).
///
/// ## Architecture
/// - **Shared across targets**: Can be used in main app, widgets, Siri extensions
/// - **Observable**: SwiftUI views automatically update when navigation changes
/// - **Generic**: Works with any Hashable route type
///
/// ## Usage in SwiftUI
/// ```swift
/// struct ContentGridView: View {
///     @State private var navigator = Navigator()
///
///     var body: some View {
///         NavigationStack(path: $navigator.path) {
///             // Your content with NavigationLink(value: route)
///         }
///         .navigationDestination(for: AppRoute.self) { route in
///             route.destination()
///         }
///     }
/// }
/// ```
///
/// ## Programmatic Navigation
/// ```swift
/// navigator.navigate(to: AppRoute.contentDetail(item))
/// navigator.pop()
/// navigator.popToRoot()
/// ```
@Observable
@MainActor
public final class Navigator {
    /// The navigation path (stack of routes)
    public var path: NavigationPath

    /// Initializes a new navigator with an empty path
    public init() {
        self.path = NavigationPath()
    }

    /// Navigate to a specific route
    ///
    /// - Parameter route: The destination route (must be Hashable)
    public func navigate<Route: Hashable>(to route: Route) {
        path.append(route)
    }

    /// Pop the current route (go back one level)
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Pop to root (clear entire navigation stack)
    public func popToRoot() {
        path = NavigationPath()
    }

    /// Replace the current route with a new one
    ///
    /// Useful for authentication flows or replacing a placeholder
    ///
    /// - Parameter route: The new route to show
    public func replace<Route: Hashable>(with route: Route) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }
}
