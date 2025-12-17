//
//  cstudioApp.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/3/25.
//

import SwiftUI
import CStudioKit
import OSLog
import Auth

@main
struct cstudioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var initState: InitializationState = .loading
    @State private var killSwitchState: KillSwitchState = .none

    var body: some Scene {
        WindowGroup {
            switch initState {
            case .loading:
                ProgressView("Loading...")
                    .task {
                        await initializeDependencies()
                    }
            case .ready:
                contentView
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .remoteConfigUpdated)) { _ in
                        checkKillSwitch()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        Task {
                            await refreshDynamicContext()
                        }
                    }
            case .failed(let error):
                ErrorView(error: error) {
                    initState = .loading
                    Task {
                        await initializeDependencies()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch killSwitchState {
        case .none:
            ContentView()
        case .soft(let message):
            ContentView()
                .softKillSwitchAlert(message: message)
        case .maintenance(let message, let endTime):
            MaintenanceView(message: message, endTime: endTime)
        case .hard(let message):
            HardKillSwitchView(message: message)
        case .emergency(let message):
            EmergencyKillSwitchView(message: message)
        }
    }

    private func initializeDependencies() async {
        #if DEBUG
        AppConfig.validate()
        #endif

        do {
            // Configure image loading pipeline
            ImageConfiguration.configure()

            // Initialize observability first (never fails, falls back to noop)
            let observability = await ObservabilityInitializer.initialize()

            // Initialize push notification service (required - will throw if not configured)
            let pushService = try await initializePushNotificationService(observability: observability)

            // Initialize Supabase and other dependencies with auth callback
            let config = try await SupabaseConfig.fromBundle()
            await DependencyContainer.shared.initialize(
                config: config,
                observability: observability,
                pushNotificationService: pushService,
                setupAuthCallback: { authManager in
                    // Setup auth integration for analytics
                    ObservabilityInitializer.setupAuthIntegration(
                        authManager: authManager,
                        analytics: observability.analytics
                    )

                    // Setup push notification user ID sync
                    setupPushNotificationAuthSync(
                        authManager: authManager,
                        pushService: pushService
                    )
                }
            )

            // Setup notification opened handler for navigation
            await setupPushNotificationNavigation(pushService: pushService)

            // Setup permission observer for tracking
            setupPushPermissionObserver(pushService: pushService, observability: observability)

            // Check and track initial permission state
            await trackInitialPermissionState(pushService: pushService, observability: observability)

            // Log successful initialization
            await observability.analytics.track(event: "app_launched", parameters: nil)

            // Check kill switches before showing main content
            checkKillSwitch()

            initState = .ready
        } catch {
            AppLogger.app.error("Failed to initialize dependencies: \(error.localizedDescription)")
            initState = .failed(error.localizedDescription)
        }
    }

    private func checkKillSwitch() {
        let checker = KillSwitchChecker(flags: FeatureFlags.raw)
        killSwitchState = checker.check()

        if killSwitchState.isBlocking {
            AppLogger.app.warning("Kill switch activated: \(killSwitchState)")
        }
    }

    enum InitializationState {
        case loading
        case ready
        case failed(String)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == AppConfig.urlScheme, url.host == "auth-callback" else {
            return
        }

        Task {
            do {
                let authManager = try await DependencyContainer.shared.getAuthManager()
                try await authManager.handleDeepLink(url)
            } catch {
                AppLogger.app.error("Failed to handle deep link: \(error)")
            }
        }
    }

    private func refreshDynamicContext() async {
        await ObservabilityInitializer.refreshDynamicContext()
    }

    // MARK: - Push Notification Setup

    /// Initialize push notification service with OneSignal (required)
    @MainActor
    private func initializePushNotificationService(observability: Observability) async throws -> PushNotificationService {
        let config = try ObservabilityConfig.load()

        guard let appId = config.oneSignalAppId else {
            let errorMessage = """
            ONESIGNAL_APP_ID is not configured!

            Add to your .xcconfig files (Dev.xcconfig and Prod.xcconfig):
            ONESIGNAL_APP_ID = your-onesignal-app-id

            Get your App ID from: https://app.onesignal.com/
            """
            AppLogger.app.error("OneSignal App ID missing - push notifications are required")
            throw PushNotificationError.invalidConfiguration
        }

        // Initialize OneSignal
        let service = OneSignalPushNotificationService()
        await service.initialize(appId: appId)

        // Track initialization
        await observability.analytics.track(
            event: "push_notification_initialized",
            parameters: ["service": "onesignal"]
        )

        return service
    }

    /// Setup auth state sync with push notification service
    @MainActor
    private func setupPushNotificationAuthSync(
        authManager: AuthManager,
        pushService: PushNotificationService
    ) {
        // Sync current user if authenticated AND push permission is authorized
        // Only set external user ID after user has granted push permissions
        if authManager.isAuthenticated, let userId = authManager.userId {
            Task {
                let permissionStatus = await pushService.getPermissionStatus()
                if permissionStatus == .authorized {
                    await pushService.setExternalUserId(userId.uuidString)
                    AppLogger.app.info("Synced push notification user ID on init")
                } else {
                    AppLogger.app.info("Skipping push notification user ID sync - permission not granted (status: \(permissionStatus.rawValue))")
                }
            }
        }

        // Capture existing callback to compose with it
        let existingCallback = authManager.onAuthStateChange

        // Observe auth state changes (composing with existing callback)
        authManager.onAuthStateChange = { @MainActor event, session in
            // Call existing callback first (e.g., observability)
            existingCallback?(event, session)

            // Then handle push notification sync
            Task {
                if let session = session {
                    // Only sync user ID if push permission is authorized
                    let permissionStatus = await pushService.getPermissionStatus()
                    if permissionStatus == .authorized {
                        let userId = session.user.id
                        await pushService.setExternalUserId(userId.uuidString)
                        AppLogger.app.info("Synced push notification user ID: \(userId, privacy: .private(mask: .hash))")
                    } else {
                        AppLogger.app.info("Skipping push notification user ID sync - permission not granted (status: \(permissionStatus.rawValue))")
                    }
                } else {
                    await pushService.removeExternalUserId()
                    AppLogger.app.info("Removed push notification user ID")
                }
            }
        }
    }

    /// Setup push notification opened handler for navigation
    @MainActor
    private func setupPushNotificationNavigation(pushService: PushNotificationService) async {
        pushService.setNotificationOpenedHandler { notificationData in
            AppLogger.app.info("Push notification opened: \(notificationData.notificationId)")

            // Post navigation notification on main actor (UI updates require main thread)
            Task { @MainActor in
                if let routeURL = notificationData.routeURL {
                    NotificationCenter.default.post(
                        name: .navigateToRoute,
                        object: nil,
                        userInfo: ["routeURL": routeURL]
                    )
                }
            }

            // Track analytics (non-blocking)
            Task {
                do {
                    let deps = try await DependencyContainer.shared.getCurrent()
                    await deps.observability.analytics.track(
                        event: "push_notification_opened",
                        parameters: [
                            "notification_id": notificationData.notificationId,
                            "has_route": notificationData.routeURL != nil ? "true" : "false"
                        ]
                    )
                } catch {
                    AppLogger.app.error("Failed to track push notification analytics: \(error)")
                }
            }
        }
    }

    /// Setup push notification permission observer for tracking state changes
    @MainActor
    private func setupPushPermissionObserver(
        pushService: PushNotificationService,
        observability: Observability
    ) {
        pushService.addPermissionObserver { granted in
            AppLogger.app.info("Push permission state changed: \(granted ? "granted" : "denied")")

            // Track permission state changes in analytics
            // This catches both initial grants and revocations from Settings
            Task {
                await observability.analytics.track(
                    event: "push_permission_state_changed",
                    parameters: ["granted": granted ? "true" : "false"]
                )

                // Sync user ID when permission is granted
                if granted {
                    do {
                        let authManager = try await DependencyContainer.shared.getAuthManager()

                        // Access MainActor-isolated properties within MainActor context
                        let (isAuthenticated, userId) = await MainActor.run {
                            (authManager.isAuthenticated, authManager.userId)
                        }

                        if isAuthenticated, let userId = userId {
                            await pushService.setExternalUserId(userId.uuidString)
                            AppLogger.app.info("Synced push notification user ID after permission granted: \(userId, privacy: .private(mask: .hash))")
                        }
                    } catch {
                        AppLogger.app.error("Failed to sync push notification user ID after permission granted: \(error)")
                    }
                }
            }
        }
    }

    /// Track initial permission state on app launch
    @MainActor
    private func trackInitialPermissionState(
        pushService: PushNotificationService,
        observability: Observability
    ) async {
        let status = await pushService.getPermissionStatus()
        AppLogger.app.info("Initial push permission status: \(status.rawValue)")

        await observability.analytics.track(
            event: "push_permission_initial_state",
            parameters: ["status": status.rawValue]
        )
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let error: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Initialization Failed")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .padding()
    }
}
