//
//  AddPostViewModel.swift
//  bare
//
//  ViewModel for AddPostView - handles business logic and state management
//

import Foundation
import SwiftUI
import BareKit
import OSLog

@MainActor
@Observable
final class AddPostViewModel {
    // MARK: - State

    var urlText: String
    var analysisText: String = ""
    var linkPreview: LinkPreview?
    var isLoadingPreview = false
    var isSavingPost = false
    var errorMessage: String?
    var urlValidationError: String?

    // MARK: - Properties

    private let initialURL: URL?

    // MARK: - Initialization

    init(initialURL: URL? = nil) {
        self.initialURL = initialURL
        self.urlText = initialURL?.absoluteString ?? ""
    }

    // MARK: - Public Methods

    /// Load initial preview if URL was provided
    func loadInitialPreview() async {
        guard let url = initialURL else { return }
        await fetchLinkPreview(for: url)
    }

    /// Validate URL and load preview
    func validateAndLoadURL() {
        // Clear previous errors
        urlValidationError = nil
        errorMessage = nil

        // Trim whitespace
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate URL
        guard !trimmed.isEmpty else {
            urlValidationError = "Please enter a URL"
            return
        }

        guard let url = URL(string: trimmed), url.scheme != nil, url.host != nil else {
            urlValidationError = "Please enter a valid URL (e.g., https://example.com)"
            return
        }

        // Fetch preview
        Task {
            await fetchLinkPreview(for: url)
        }
    }

    /// Save post with current preview and analysis
    func savePost(onSuccess: @escaping (Post) -> Void) {
        guard let preview = linkPreview else { return }

        // Clear any previous state
        errorMessage = nil
        isSavingPost = true

        Task {
            let signpost = AppLogger.signpost(logger: AppLogger.app, name: "save_post")
            signpost.begin()

            do {
                // Check if dependencies are initialized
                let container = DependencyContainer.shared
                if !(await container.isInitialized) {
                    // Initialize dependencies if not already done (e.g., Share Extension)
                    let config = try await SupabaseConfig.fromBundle()
                    await container.initialize(
                        config: config,
                        pushNotificationService: NoopPushNotificationService()
                    )
                }

                let deps = await container.current
                let postRepository = deps.postRepository
                let authManager = try await container.getAuthManager()

                // Check if user is authenticated
                guard authManager.isAuthenticated else {
                    isSavingPost = false
                    errorMessage = "Please sign in to save posts"
                    signpost.end("not_authenticated")

                    // Track authentication failure
                    await deps.observability.analytics.track(
                        event: "post_save_failed",
                        parameters: ["reason": "not_authenticated"]
                    )
                    return
                }

                // Create post input
                let input = PostInput(
                    originalURL: preview.url,
                    userInstructions: analysisText.isEmpty ? nil : analysisText,
                    thumbnailURL: preview.imageURL
                )

                AppLogger.app.logPrivate(level: .debug, "Saving post with URL: \(preview.url.absoluteString)")

                // Save post via edge function
                let response = try await postRepository.create(input)

                signpost.end("success")

                // Track successful post creation
                await deps.observability.analytics.track(
                    event: "post_created",
                    parameters: [
                        "created": response.created,
                        "has_instructions": input.userInstructions != nil,
                        "has_thumbnail": input.thumbnailURL != nil
                    ]
                )

                // Update state and call success handler
                isSavingPost = false
                onSuccess(response.post)

            } catch {
                // Log detailed error information
                AppLogger.app.error("Failed to save post: \(error.localizedDescription)")
                AppLogger.app.logPrivate(level: .error, "Save post error: \(String(describing: error))")
                if let decodingError = error as? DecodingError {
                    AppLogger.app.logPrivate(
                        level: .error,
                        "Decoding details: \(decodingError.detailedDescription)"
                    )
                }

                let errorDescription = userFriendlyError(from: error)

                withAnimation {
                    isSavingPost = false
                    errorMessage = errorDescription
                }

                signpost.end("error")

                // Track error with non-PII details
                let deps = await DependencyContainer.shared.current
                await deps.observability.analytics.track(
                    event: "post_save_failed",
                    parameters: ["reason": "api_error"]
                )
            }
        }
    }

    /// Clear error message
    func clearError() {
        withAnimation {
            errorMessage = nil
        }
    }

    // MARK: - Private Methods

    private func fetchLinkPreview(for url: URL) async {
        let signpost = AppLogger.signpost(logger: AppLogger.app, name: "fetch_link_preview")
        signpost.begin()

        isLoadingPreview = true

        do {
            let preview = try await LinkPreviewService.shared.fetchPreview(for: url)
            linkPreview = preview
            errorMessage = nil
            isLoadingPreview = false
            signpost.end("success")
        } catch {
            // Still show something even if preview fails
            let fallbackPreview = LinkPreview(
                url: url,
                title: url.host,
                description: "Preview not available",
                imageURL: nil,
                siteName: nil
            )

            linkPreview = fallbackPreview
            isLoadingPreview = false

            AppLogger.app.error("Preview error: \(error.localizedDescription)")
            signpost.end("error")
        }
    }

    /// Convert technical errors to user-friendly messages
    private func userFriendlyError(from error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        // Check for specific error types
        if error is DecodingError {
            return "Server returned an unexpected response. Please try again."
        } else if errorString.contains("network") || errorString.contains("connection") {
            return "Unable to connect. Please check your internet connection."
        } else if errorString.contains("unauthorized") || errorString.contains("auth") {
            return "Authentication failed. Please sign in again."
        } else if errorString.contains("timeout") {
            return "Request timed out. Please try again."
        } else if errorString.contains("couldn't be read") || errorString.contains("correct format") {
            return "Server error occurred. Please try again."
        } else {
            return "Failed to save post. Please try again."
        }
    }
}

// MARK: - Helper Extensions

private extension DecodingError {
    var detailedDescription: String {
        switch self {
        case let .dataCorrupted(context):
            return "Data corrupted at \(context.codingPath.readablePath): \(context.debugDescription)"
        case let .keyNotFound(key, context):
            return "Key '\(key.stringValue)' not found at \(context.codingPath.readablePath): \(context.debugDescription)"
        case let .valueNotFound(type, context):
            return "Value of type \(type) missing at \(context.codingPath.readablePath): \(context.debugDescription)"
        case let .typeMismatch(type, context):
            return "Type \(type) mismatch at \(context.codingPath.readablePath): \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error: \(localizedDescription)"
        }
    }
}

private extension Array where Element == CodingKey {
    nonisolated var readablePath: String {
        guard !isEmpty else { return "<root>" }
        return reduce(into: "") { result, key in
            if let index = key.intValue {
                result += "[\(index)]"
            } else {
                if !result.isEmpty {
                    result += "."
                }
                result += key.stringValue
            }
        }
    }
}
