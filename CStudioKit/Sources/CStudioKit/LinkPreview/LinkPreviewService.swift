//
//  LinkPreviewService.swift
//  CStudioKit
//
//  Service for fetching and caching link previews
//

import Foundation

/// Errors that can occur during link preview fetching
public enum LinkPreviewError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError
    case noContent

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError:
            return "Failed to parse link preview"
        case .noContent:
            return "No preview content available"
        }
    }
}

/// Service for fetching link previews using Open Graph meta tags
public final class LinkPreviewService: @unchecked Sendable {

    /// Shared singleton instance
    public static let shared = LinkPreviewService()

    private let urlSession: URLSession
    private nonisolated(unsafe) let cache = NSCache<NSURL, CachedPreview>()

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: configuration)

        // Configure cache
        cache.countLimit = 50
    }

    /// Fetches link preview for the given URL
    /// - Parameter url: The URL to fetch preview for
    /// - Returns: LinkPreview with OG meta tag data
    public func fetchPreview(for url: URL) async throws -> LinkPreview {
        // Check cache first
        if let cached = cache.object(forKey: url as NSURL) {
            if Date().timeIntervalSince(cached.timestamp) < 300 { // 5 min cache
                return cached.preview
            }
            // Remove expired entry
            cache.removeObject(forKey: url as NSURL)
        }

        // Fetch HTML content
        let html = try await fetchHTML(from: url)

        // Parse OG meta tags
        let preview = parseOpenGraphTags(from: html, url: url)

        // Cache the result
        cache.setObject(CachedPreview(preview: preview, timestamp: Date()), forKey: url as NSURL)

        return preview
    }

    // MARK: - Private Methods

    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)

        // Use crawler User-Agent for TikTok and other social media sites
        // These sites serve OG meta tags only to crawlers, not regular browsers
        let userAgent = getUserAgent(for: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // Some sites require Accept header for proper content
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw LinkPreviewError.networkError(URLError(.badServerResponse))
            }

            guard let html = String(data: data, encoding: .utf8) else {
                throw LinkPreviewError.parsingError
            }

            return html
        } catch {
            throw LinkPreviewError.networkError(error)
        }
    }

    /// Returns appropriate User-Agent based on the URL domain
    /// TikTok and other social platforms serve OG tags only to crawlers
    private func getUserAgent(for url: URL) -> String {
        guard let host = url.host?.lowercased() else {
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        }

        // TikTok requires a crawler-like User-Agent to serve OG meta tags
        if host.contains("tiktok.com") {
            // Facebook's crawler User-Agent (similar to what TikTok expects)
            return "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)"
        }

        // Instagram also benefits from crawler User-Agent
        if host.contains("instagram.com") {
            return "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)"
        }

        // Default mobile User-Agent for other sites
        return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
    }

    private func parseOpenGraphTags(from html: String, url: URL) -> LinkPreview {
        // Try to extract JSON-LD structured data first (for TikTok and other modern sites)
        if let jsonLDData = HTMLMetaParser.extractJSONLDData(from: html, url: url) {
            return jsonLDData
        }

        // Scan HTML once and extract all meta tags
        let metaTags = HTMLMetaParser.extractAllMetaTags(from: html)

        // Extract values with fallback priority
        let ogTitle = metaTags["og:title"]
            ?? metaTags["twitter:title"]
            ?? HTMLMetaParser.extractTitleTag(from: html)

        let ogDescription = metaTags["og:description"]
            ?? metaTags["twitter:description"]
            ?? metaTags["description"]

        let ogImageURLString = metaTags["og:image"]
            ?? metaTags["og:image:url"]
            ?? metaTags["twitter:image"]
            ?? metaTags["twitter:image:src"]

        let ogSiteName = metaTags["og:site_name"]

        // Convert relative image URL to absolute
        let ogImageURL = HTMLMetaParser.resolveImageURL(ogImageURLString, baseURL: url)

        return LinkPreview(
            url: url,
            title: ogTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
            description: ogDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: ogImageURL,
            siteName: ogSiteName?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

// MARK: - Cache Helper

private final class CachedPreview: @unchecked Sendable {
    let preview: LinkPreview
    let timestamp: Date

    init(preview: LinkPreview, timestamp: Date) {
        self.preview = preview
        self.timestamp = timestamp
    }
}
