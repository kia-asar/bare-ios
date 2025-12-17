//
//  ImageConfiguration.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/13/25.
//

import Foundation
import Nuke

/// Centralized configuration for image loading and caching using Nuke
///
/// Nuke automatically provides intelligent defaults for memory and disk caching based on device capabilities.
/// This enum provides convenience methods for prefetching images to improve scroll performance.
enum ImageConfiguration {
    @MainActor
    private static var activePrefetcher: ImagePrefetcher?

    /// Configure the Nuke image pipeline
    ///
    /// Nuke uses intelligent defaults, so no explicit configuration is needed.
    /// This method exists for future customization if needed.
    static func configure() {
        // Nuke's default pipeline provides:
        // - Automatic memory cache (based on device RAM)
        // - Automatic disk cache (URLCache with ~150MB default)
        // - Progressive decoding
        // - Task coalescing
        // - Request deduplication
        //
        // No custom configuration needed for now.
    }

    /// Configure image prefetching for grids
    ///
    /// Prefetches images for smooth scrolling
    /// Call this when grid data loads
    @MainActor
    static func configurePrefetching(for urls: [URL]) {
        // Stop any previous prefetch operation
        activePrefetcher?.stopPrefetching()

        // Start new prefetch
        let prefetcher = ImagePrefetcher()
        prefetcher.priority = .low // Don't interfere with visible images
        prefetcher.startPrefetching(with: urls)
        activePrefetcher = prefetcher
    }

    /// Stop prefetching (cleanup)
    @MainActor
    static func stopPrefetching() {
        activePrefetcher?.stopPrefetching()
        activePrefetcher = nil
    }
}
