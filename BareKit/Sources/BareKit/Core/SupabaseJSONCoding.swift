//
//  SupabaseJSONCoding.swift
//  BareKit
//
//  Helpers for encoding/decoding Supabase payloads with ISO8601 timestamps.
//

import Foundation

enum SupabaseJSONCoding {
    /// Create a decoder that matches Supabase's default (fractional ISO 8601 timestamps).
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            if let stringValue = try? container.decode(String.self),
               let parsed = ISO8601DateParsers.parse(stringValue) {
                return parsed
            }

            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date format in Supabase response."
            )
        }
        return decoder
    }
}

private enum ISO8601DateParsers {
    static func parse(_ value: String) -> Date? {
        if let fractional = fractionalSeconds.date(from: value) {
            return fractional
        }
        return wholeSeconds.date(from: value)
    }

    nonisolated(unsafe) private static let fractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    nonisolated(unsafe) private static let wholeSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension Encodable {
    /// Encode the value into a JSON string (best effort, used for debug logs).
    func asJSONString(sortedKeys: Bool = false) -> String? {
        let encoder = JSONEncoder()
        if sortedKeys {
            encoder.outputFormatting.insert(.sortedKeys)
        }

        guard let data = try? encoder.encode(self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
