//
//  AppDelegate.swift
//  bare
//
//  UIKit AppDelegate bridge for OneSignal integration
//

import UIKit

/// Minimal UIKit AppDelegate bridge for OneSignal
///
/// OneSignal requires a UIApplicationDelegate to hook into the app lifecycle
/// via method swizzling. This provides the minimal bridge needed while keeping
/// the app primarily SwiftUI-based.
///
/// ## Integration
/// Connect to SwiftUI app via `@UIApplicationDelegateAdaptor`:
/// ```swift
/// @main
/// struct bareApp: App {
///     @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
///     // ...
/// }
/// ```
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // OneSignal handles its own setup via swizzling
        // No additional code needed here
        return true
    }
}
