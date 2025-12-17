//
//  LinkPreview.swift
//  BareKit
//
//  Link preview model for OG meta tag data
//

import Foundation

/// Represents link preview data extracted from Open Graph meta tags
public struct LinkPreview: Identifiable, Sendable {
    public let id = UUID()
    public let url: URL
    public let title: String?
    public let description: String?
    public let imageURL: URL?
    public let siteName: String?

    public init(
        url: URL,
        title: String?,
        description: String?,
        imageURL: URL?,
        siteName: String?
    ) {
        self.url = url
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.siteName = siteName
    }

    /// Indicates if the preview has meaningful content to display
    public var hasContent: Bool {
        title != nil || description != nil || imageURL != nil
    }

    /// Returns a display-ready title (falls back to URL host if no title)
    public var displayTitle: String {
        title ?? url.host ?? url.absoluteString
    }

    /// Returns a truncated description suitable for preview display
    public var displayDescription: String? {
        guard let description = description, !description.isEmpty else {
            return nil
        }

        // Truncate long descriptions using prefix for cleaner code
        let maxLength = 150
        if description.count > maxLength {
            return String(description.prefix(maxLength)) + "..."
        }
        return description
    }
}
