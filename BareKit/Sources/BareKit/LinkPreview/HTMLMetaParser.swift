//
//  HTMLMetaParser.swift
//  BareKit
//
//  Utility for parsing HTML meta tags and structured data
//

import Foundation

/// Utility for parsing HTML meta tags and JSON-LD structured data
struct HTMLMetaParser {

    // MARK: - Cached Regex Patterns

    private static let metaTagRegex = try? NSRegularExpression(
        pattern: "<meta\\s+([^>]+)>",
        options: [.caseInsensitive]
    )
    private static let titleTagRegex = try? NSRegularExpression(
        pattern: "<title>([^<]+)</title>",
        options: [.caseInsensitive]
    )
    private static let jsonLDRegex = try? NSRegularExpression(
        pattern: "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>([\\s\\S]*?)</script>",
        options: [.caseInsensitive]
    )
    private static let metaKeyRegex = try? NSRegularExpression(
        pattern: "(?:property|name)\\s*=\\s*[\"']([^\"']+)[\"']",
        options: [.caseInsensitive]
    )
    private static let metaValueRegex = try? NSRegularExpression(
        pattern: "content\\s*=\\s*[\"']([^\"']+)[\"']",
        options: [.caseInsensitive]
    )

    // MARK: - Public Methods

    /// Extracts all meta tags from HTML into a dictionary
    /// - Parameter html: The HTML content
    /// - Returns: Dictionary mapping meta tag names/properties to their content
    static func extractAllMetaTags(from html: String) -> [String: String] {
        guard let regex = metaTagRegex else { return [:] }

        var metaTags: [String: String] = [:]
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)

        for match in matches {
            guard match.numberOfRanges > 1,
                  let attributesRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let attributes = String(html[attributesRange])

            // Extract property/name and content from attributes
            if let (key, value) = parseMetaAttributes(attributes) {
                metaTags[key] = HTMLEntityDecoder.decode(value)
            }
        }

        return metaTags
    }

    /// Extracts the title tag content from HTML
    /// - Parameter html: The HTML content
    /// - Returns: The title content, if found
    static func extractTitleTag(from html: String) -> String? {
        guard let regex = titleTagRegex else { return nil }

        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        let captured = String(html[captureRange])
        return HTMLEntityDecoder.decode(captured)
    }

    /// Extracts JSON-LD structured data from HTML
    /// - Parameters:
    ///   - html: The HTML content
    ///   - url: The base URL for resolving relative URLs
    /// - Returns: A LinkPreview if JSON-LD data was found and parsed successfully
    static func extractJSONLDData(from html: String, url: URL) -> LinkPreview? {
        guard let regex = jsonLDRegex else { return nil }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)

        for match in matches {
            guard match.numberOfRanges > 1,
                  let jsonRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let jsonString = String(html[jsonRange])

            // Try to parse JSON
            guard let jsonData = jsonString.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) else {
                continue
            }

            // Handle array of JSON-LD objects
            if let jsonArray = jsonObject as? [[String: Any]] {
                for object in jsonArray {
                    if let preview = parseJSONLDObject(object, url: url) {
                        return preview
                    }
                }
            }
            // Handle single JSON-LD object
            else if let singleObject = jsonObject as? [String: Any] {
                if let preview = parseJSONLDObject(singleObject, url: url) {
                    return preview
                }
            }
        }

        return nil
    }

    /// Resolves an image URL (handles relative URLs)
    /// - Parameters:
    ///   - imageURLString: The image URL string (may be relative)
    ///   - baseURL: The base URL to resolve against
    /// - Returns: Absolute URL if resolution succeeded
    static func resolveImageURL(_ imageURLString: String?, baseURL: URL) -> URL? {
        guard let imageURLString = imageURLString else { return nil }

        if let absoluteURL = URL(string: imageURLString), absoluteURL.scheme != nil {
            return absoluteURL
        } else if let base = URL(string: "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")") {
            return URL(string: imageURLString, relativeTo: base)?.absoluteURL
        }

        return nil
    }

    // MARK: - Private Methods

    /// Parses meta tag attributes to extract key-value pair
    private static func parseMetaAttributes(_ attributes: String) -> (String, String)? {
        guard let keyRegex = metaKeyRegex,
              let valueRegex = metaValueRegex else {
            return nil
        }

        var key: String?
        var value: String?

        let range = NSRange(attributes.startIndex..., in: attributes)

        if let keyMatch = keyRegex.firstMatch(in: attributes, range: range),
           let keyRange = Range(keyMatch.range(at: 1), in: attributes) {
            key = String(attributes[keyRange])
        }

        if let valueMatch = valueRegex.firstMatch(in: attributes, range: range),
           let valueRange = Range(valueMatch.range(at: 1), in: attributes) {
            value = String(attributes[valueRange])
        }

        guard let k = key, let v = value else { return nil }
        return (k, v)
    }

    /// Parses a single JSON-LD object into a LinkPreview
    private static func parseJSONLDObject(_ object: [String: Any], url: URL) -> LinkPreview? {
        guard let type = object["@type"] as? String,
              (type == "VideoObject" || type == "SocialMediaPosting" || type == "WebPage") else {
            return nil
        }

        let name = object["name"] as? String ?? object["headline"] as? String
        let description = object["description"] as? String
        let imageURLString = (object["image"] as? [String: Any])?["url"] as? String
            ?? (object["image"] as? String)
            ?? (object["thumbnailUrl"] as? String)

        let imageURL = resolveImageURL(imageURLString, baseURL: url)

        // Only return if we have meaningful data
        guard name != nil || description != nil || imageURL != nil else {
            return nil
        }

        return LinkPreview(
            url: url,
            title: name?.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: imageURL,
            siteName: nil
        )
    }
}
