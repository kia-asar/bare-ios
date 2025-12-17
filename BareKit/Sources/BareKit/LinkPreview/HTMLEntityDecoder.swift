//
//  HTMLEntityDecoder.swift
//  BareKit
//
//  Utility for decoding HTML entities in text
//

import Foundation

/// Utility for decoding HTML entities
struct HTMLEntityDecoder {

    // Cached regex patterns for entity decoding
    private static let numericEntityRegex = try? NSRegularExpression(
        pattern: "&#(\\d+);",
        options: []
    )
    private static let hexEntityRegex = try? NSRegularExpression(
        pattern: "&#x([0-9a-fA-F]+);",
        options: []
    )

    /// Decodes HTML entities in a string
    /// - Parameter string: The string with HTML entities
    /// - Returns: Decoded string
    static func decode(_ string: String) -> String {
        var result = string

        // Common HTML entities (decode in order of specificity)
        // Must decode &amp; last to avoid double-decoding
        let entities: [(entity: String, character: String)] = [
            ("&nbsp;", " "),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&amp;", "&")  // Decode last to avoid double-decoding
        ]

        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        // Decode numeric entities (&#123;)
        result = decodeNumericEntities(result)

        // Decode hex entities (&#x1a;)
        result = decodeHexEntities(result)

        return result
    }

    // MARK: - Private Methods

    private static func decodeNumericEntities(_ string: String) -> String {
        guard let regex = numericEntityRegex else { return string }

        var result = string
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        // Process in reverse to maintain correct ranges
        for match in matches.reversed() {
            if let range = Range(match.range, in: result),
               let numRange = Range(match.range(at: 1), in: result),
               let code = Int(result[numRange]),
               let scalar = UnicodeScalar(code) {
                result.replaceSubrange(range, with: String(Character(scalar)))
            }
        }

        return result
    }

    private static func decodeHexEntities(_ string: String) -> String {
        guard let regex = hexEntityRegex else { return string }

        var result = string
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        // Process in reverse to maintain correct ranges
        for match in matches.reversed() {
            if let range = Range(match.range, in: result),
               let hexRange = Range(match.range(at: 1), in: result),
               let code = Int(result[hexRange], radix: 16),
               let scalar = UnicodeScalar(code) {
                result.replaceSubrange(range, with: String(Character(scalar)))
            }
        }

        return result
    }
}
