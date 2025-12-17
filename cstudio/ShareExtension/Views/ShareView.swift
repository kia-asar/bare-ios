//
//  ShareView.swift
//  cstudio Share Extension
//
//  Created by Kiarash Asar on 11/4/25.
//
//  Wrapper for share extension - extracts URL and uses AddPostView
//

import SwiftUI
import UniformTypeIdentifiers
import CStudioKit
import OSLog

struct ShareView: View {
    let extensionContext: NSExtensionContext?

    @State private var opacity: Double = 0.0
    @State private var sharedURL: URL?
    @State private var errorMessage: String?
    @State private var isDismissing = false
    @State private var loadingTask: Task<Void, Never>?
    @State private var isExtractingURL = true
    
    var body: some View {
        ZStack {
            if isExtractingURL {
                // Show loading state while extracting URL
                DesignTokens.Colors.backgroundOverlay
                    .ignoresSafeArea()

                VStack(spacing: DesignTokens.Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.accentColor)

                    Text("Extracting URL...")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .padding(DesignTokens.Spacing.xxxl)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            } else if let url = sharedURL {
                // Use AddPostView with the extracted URL
                AddPostView(
                    initialURL: url,
                    onSave: { _ in
                        dismissExtension()
                    },
                    onCancel: {
                        cancelExtension()
                    }
                )
                .opacity(opacity)
            } else if let error = errorMessage {
                // Show error state
                DesignTokens.Colors.backgroundOverlay
                    .ignoresSafeArea()

                VStack(spacing: DesignTokens.Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)

                    Text("Unable to Extract URL")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                    Button("Cancel") {
                        cancelExtension()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(DesignTokens.Spacing.xxxl)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .opacity(opacity)
            }
        }
        .task {
            // Store task reference for cancellation
            loadingTask = Task {
                await handleShareExtension()
            }
            await loadingTask?.value
        }
    }
    
    // MARK: - Share Extension Logic

    private func handleShareExtension() async {
        let signpost = AppLogger.signpost(logger: AppLogger.shareExt, name: "share_extension_flow")
        signpost.begin()

        // Track extension opened
        await bufferAnalyticsEvent("share_extension_opened")

        // Extract shared URL
        await extractSharedURL()

        // Update UI
        await MainActor.run {
            isExtractingURL = false
        }

        // Fade in animation
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 1.0
        }

        signpost.end()
    }
    
    private func extractSharedURL() async {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            errorMessage = "No content to share"
            await bufferAnalyticsEvent("share_extension_error", parameters: ["error": "no_content"])
            return
        }

        do {
            // Try loading as URL first (modern async API)
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                if let url = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                    sharedURL = url
                    return
                }

                // Try as data representation
                if let data = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    sharedURL = url
                    return
                }
            }

            // Try loading as text
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                if let urlString = try await itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier) as? String,
                   let url = URL(string: urlString) {
                    sharedURL = url
                    return
                }
            }

            errorMessage = "Could not extract URL from shared content"
            await bufferAnalyticsEvent("share_extension_error", parameters: ["error": "url_extraction_failed"])
        } catch {
            errorMessage = "Error loading shared content: \(error.localizedDescription)"
            await bufferAnalyticsEvent("share_extension_error", parameters: ["error": error.localizedDescription])
        }
    }
    
    private func dismissExtension() {
        // Prevent multiple dismissals
        guard !isDismissing else { return }
        isDismissing = true

        // Cancel any in-flight network requests
        loadingTask?.cancel()

        // Track success
        Task {
            await bufferAnalyticsEvent("share_extension_completed")
        }

        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0.0
        }

        // Delay dismissal slightly for smooth animation
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func cancelExtension() {
        // Prevent multiple dismissals
        guard !isDismissing else { return }
        isDismissing = true

        // Track cancellation
        Task {
            await bufferAnalyticsEvent("share_extension_cancelled")
        }

        // Cancel any in-flight network requests
        loadingTask?.cancel()

        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0.0
        }

        // Delay dismissal slightly for smooth animation
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            extensionContext?.cancelRequest(withError: NSError(
                domain: AppConfig.shareExtensionErrorDomain,
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
            ))
        }
    }

    // MARK: - Observability Helpers

    /// Buffer analytics event for relay by main app
    private func bufferAnalyticsEvent(_ name: String, parameters: [String: String]? = nil) async {
        let event = BufferedAnalyticsEvent(
            name: name,
            parameters: parameters,
            source: "share_extension"
        )
        await AppGroupEventBuffer.shared.appendIfConsented(event)
        AppLogger.shareExt.debug("📊 Buffered event: \(name)")
    }
}

#Preview {
    ShareView(extensionContext: nil)
}

