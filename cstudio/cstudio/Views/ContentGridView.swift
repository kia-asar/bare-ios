//
//  ContentGridView.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/3/25.
//

import SwiftUI
import CStudioKit
import OSLog

/// Main grid view displaying content items in an Instagram-like layout
struct ContentGridView: View {
    @State private var viewModel: ContentViewModel?
    @State private var navigator = Navigator()
    @State private var isInitializing = true
    @State private var addPostConfig: AddPostConfig?
    @State private var showPermissionPrimer = false
    @State private var permissionStatus: PushPermissionStatus = .notDetermined

    // First launch tracking for push permission prompt
    @AppStorage("hasPromptedForPushPermission") private var hasPromptedForPushPermission = false

    struct AddPostConfig: Identifiable {
        let id = UUID()
        let initialURL: URL?
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            Group {
                if isInitializing || viewModel == nil {
                    ProgressView("Initializing...")
                } else if let vm = viewModel {
                    if vm.isLoading && vm.items.isEmpty {
                        loadingView
                    } else if let error = vm.errorMessage {
                        errorView(error)
                    } else {
                        gridContent(vm: vm)
                    }
                }
            }
            .navigationTitle("cstudio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel?.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel?.isLoading ?? true)
                }
            }
            .withAppRouteDestinations() // Add navigation destination handling
        }
        .task {
            await initializeViewModel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToRoute)) { notification in
            handleNavigationFromNotification(notification)
        }
        .overlay {
            if showPermissionPrimer {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    PushPermissionPrimer(
                        status: permissionStatus,
                        onAllow: {
                            handlePermissionAllow()
                        },
                        onDismiss: {
                            handlePermissionDismiss()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showPermissionPrimer)
            }
        }
        .sheet(item: $addPostConfig) { config in
            AddPostView(
                initialURL: config.initialURL,
                onSave: { _ in
                    addPostConfig = nil
                    // Refresh grid after adding post
                    viewModel?.loadContent()
                },
                onCancel: {
                    addPostConfig = nil
                }
            )
        }
    }
    
    private func initializeViewModel() async {
        let deps = await DependencyContainer.shared.current
        await MainActor.run {
            let vm = ContentViewModel(postRepository: deps.postRepository)
            viewModel = vm
            isInitializing = false
            // Trigger initial load after view model is ready
            vm.loadContent()

            // Check permission status and show appropriate prompt
            Task {
                let status = await deps.pushNotificationService.getPermissionStatus()

                await MainActor.run {
                    permissionStatus = status
                }

                // Show prompt on first launch or if denied (to offer Settings link)
                // Skip if already authorized
                let shouldShowPrompt = status == .notDetermined || status == .denied

                if shouldShowPrompt && (!hasPromptedForPushPermission || status == .denied) {
                    try? await Task.sleep(for: .seconds(1))
                    await MainActor.run {
                        showPermissionPrimer = true
                    }
                }
            }
        }
    }
    
    private func gridContent(vm: ContentViewModel) -> some View {
        ZStack(alignment: .bottomTrailing) {
            gridScrollView(vm: vm)
            floatingAddButton
        }
    }

    /// Scrollable grid of content items
    private func gridScrollView(vm: ContentViewModel) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(vm.items) { item in
                    NavigationLink(value: AppRoute.contentDetail(postId: item.id)) {
                        ThumbnailCell(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 80) // Add padding to avoid button overlap
        }
        .refreshable {
            await vm.refresh()
        }
    }

    /// Floating button for adding posts
    private var floatingAddButton: some View {
        Menu {
            Button {
                addPostConfig = AddPostConfig(initialURL: nil)
            } label: {
                Label("Text", systemImage: "text.quote")
            }

            Button {
                handlePasteFromClipboard()
            } label: {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .tint(.accentColor)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading content...")
                .foregroundStyle(.secondary)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                viewModel?.loadContent()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func handlePasteFromClipboard() {
        #if os(iOS)
        if let pastedString = UIPasteboard.general.string {
            AppLogger.app.debug("📋 Clipboard content: '\(pastedString)'")

            let trimmed = pastedString.trimmingCharacters(in: .whitespacesAndNewlines)
            AppLogger.app.debug("📋 Trimmed content: '\(trimmed)'")

            if let url = URL(string: trimmed), url.scheme != nil {
                AppLogger.app.debug("✅ Valid URL created: \(url.absoluteString)")
                addPostConfig = AddPostConfig(initialURL: url)
            } else {
                AppLogger.app.debug("❌ Failed to create valid URL from string")
                addPostConfig = AddPostConfig(initialURL: nil)
            }
        } else {
            AppLogger.app.debug("⚠️ No string found in clipboard")
        }
        #endif
    }

    /// Handle navigation from push notification
    private func handleNavigationFromNotification(_ notification: Notification) {
        guard let routeURL = notification.userInfo?["routeURL"] as? URL else {
            AppLogger.app.warning("Navigation notification missing routeURL")
            return
        }

        // Parse URL into AppRoute
        guard let route = AppRoute.from(url: routeURL) else {
            AppLogger.app.warning("Failed to parse route from URL: \(routeURL)")
            return
        }

        AppLogger.app.info("Navigating to route from push notification: \(routeURL)")
        navigator.navigate(to: route)
    }

    // MARK: - Push Permission Flow

    /// Handle user tapping "Enable Notifications" or "Open Settings"
    private func handlePermissionAllow() {
        // If previously denied, open Settings
        if permissionStatus == .denied {
            AppLogger.app.info("Opening Settings to enable notifications")

            Task {
                // Track analytics before opening Settings to ensure event is captured
                let deps = try await DependencyContainer.shared.getCurrent()
                await deps.observability.analytics.track(
                    event: "push_permission_settings_opened",
                    parameters: nil
                )

                // Open Settings after tracking completes
                await MainActor.run {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                    showPermissionPrimer = false
                }
            }
            return
        }

        // Otherwise, request permission for first time
        AppLogger.app.info("User tapped 'Enable Notifications' on pre-prompt")

        Task {
            let deps = try await DependencyContainer.shared.getCurrent()
            await deps.observability.analytics.track(
                event: "push_permission_pre_prompt_accepted",
                parameters: nil
            )

            // Request system permission
            let granted = await deps.pushNotificationService.requestPermission()

            // Track system permission result
            await deps.observability.analytics.track(
                event: "push_permission_system_prompt_result",
                parameters: ["granted": granted ? "true" : "false"]
            )

            AppLogger.app.info("System permission prompt result: \(granted ? "granted" : "denied")")

            // Mark as prompted (don't show pre-prompt again)
            await MainActor.run {
                hasPromptedForPushPermission = true
                showPermissionPrimer = false
            }
        }
    }

    /// Handle user tapping "Not Now" on pre-prompt
    private func handlePermissionDismiss() {
        AppLogger.app.info("User dismissed permission pre-prompt")

        // Track pre-prompt dismissal
        Task {
            let deps = try await DependencyContainer.shared.getCurrent()
            await deps.observability.analytics.track(
                event: "push_permission_pre_prompt_dismissed",
                parameters: nil
            )

            // Mark as prompted (don't show again this session, but allow re-prompt in future)
            // Note: We're setting this to true to avoid annoying users. In the future,
            // you could implement a more sophisticated re-prompting strategy
            await MainActor.run {
                hasPromptedForPushPermission = true
                showPermissionPrimer = false
            }
        }
    }
}

#Preview {
    ContentGridView()
}

