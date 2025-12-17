//
//  ContentViewModel.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/3/25.
//

import Foundation
import Observation
import CStudioKit

/// View model managing the content items and their state
@Observable
@MainActor
final class ContentViewModel {
    var items: [ContentItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let postRepository: PostRepositoryProtocol
    private var hasLoaded = false
    nonisolated(unsafe) private var loadTask: Task<Void, Never>?

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
        // Don't auto-load on init - let the view trigger initial load
        // This prevents unnecessary network calls if view doesn't appear
    }

    deinit {
        // Cancel load task on deinit to prevent memory leaks
        // Note: Task cancellation is thread-safe and can be called from any context
        loadTask?.cancel()

        // Note: Avoid creating new Tasks in deinit as they may outlive the object
        // ImageConfiguration.stopPrefetching() will be called when the view disappears
    }
    
    /// Loads content items (only once unless explicitly refreshed)
    func loadContent() {
        // Only load once to prevent duplicate network calls
        guard !hasLoaded else { return }
        hasLoaded = true

        isLoading = true
        errorMessage = nil

        // Cancel any existing load task
        loadTask?.cancel()

        loadTask = Task {
            await performLoad()
        }
    }

    /// Refreshes the content
    func refresh() async {
        // Reset hasLoaded flag to allow refresh
        hasLoaded = false

        // Cancel any existing load task
        loadTask?.cancel()

        isLoading = true
        errorMessage = nil

        loadTask = Task {
            await performLoad()
        }
    }

    /// Performs the actual loading of posts from repository
    ///
    /// Centralized loading logic used by both initial load and refresh.
    /// Converts Post models to ContentItem for display and triggers image prefetching.
    private func performLoad() async {
        do {
            let posts = try await postRepository.listRecent(limit: 50)

            // Use Post's toContentItem() method - no detailed fields needed for list view
            self.items = posts.map { $0.toContentItem(includeDetailedFields: false) }
            self.isLoading = false

            // Prefetch images after items are loaded
            prefetchImages()
        } catch {
            self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Retrieves a specific item by ID
    func item(withId id: UUID) -> ContentItem? {
        items.first { $0.id == id }
    }

    /// Prefetch images for smooth scrolling
    private func prefetchImages() {
        let imageUrls = items.compactMap { item -> URL? in
            guard let urlString = item.imageUrl else { return nil }
            return URL(string: urlString)
        }

        if !imageUrls.isEmpty {
            ImageConfiguration.configurePrefetching(for: imageUrls)
        }
    }
}
