//
//  View+Navigation.swift
//  bare
//
//  Created by Kiarash Asar on 11/13/25.
//

import SwiftUI
import BareKit

/// SwiftUI View extension for handling AppRoute navigation destinations
extension View {
    /// Adds navigation destination handling for AppRoute
    ///
    /// This is a convenience method that centralizes all route → view mappings.
    /// Use this instead of manually handling each route type.
    ///
    /// ## Usage
    /// ```swift
    /// NavigationStack(path: $navigator.path) {
    ///     ContentGridView()
    ///         .withAppRouteDestinations()
    /// }
    /// ```
    ///
    /// - Returns: A view that handles AppRoute navigation
    func withAppRouteDestinations() -> some View {
        self.navigationDestination(for: AppRoute.self) { route in
            route.destination()
        }
    }
}

// MARK: - AppRoute Destination Views

extension AppRoute {
    /// Returns the SwiftUI view for this route
    ///
    /// This centralized approach ensures all navigation destinations are defined in one place,
    /// making it easy to maintain and test navigation flows.
    ///
    /// **Note**: This extension is in the main app target because it references
    /// app-specific views (ContentDetailView, etc.). The AppRoute enum itself lives
    /// in BareKit for sharing across all targets.
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .contentDetail(let postId):
            ContentDetailLoadingView(postId: postId)
        }
    }
}

// MARK: - Detail Loading View

/// Loading wrapper that fetches a ContentItem by ID and displays the detail view
private struct ContentDetailLoadingView: View {
    let postId: UUID
    @State private var item: ContentItem?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error {
                errorView(error)
            } else if let item {
                ContentDetailView(item: item)
            }
        }
        .task {
            await loadItem()
        }
    }

    private func loadItem() async {
        do {
            let deps = await DependencyContainer.shared.current

            // Fetch single post by ID - efficient and direct
            guard let post = try await deps.postRepository.get(id: postId) else {
                await MainActor.run {
                    error = "Content not found"
                    isLoading = false
                }
                return
            }

            // Convert Post to ContentItem - include all detailed fields for detail view
            let contentItem = post.toContentItem(includeDetailedFields: true)

            await MainActor.run {
                item = contentItem
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load post: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
