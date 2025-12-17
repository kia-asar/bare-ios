//
//  SemanticVersion.swift
//  BareKit
//
//  Semantic version comparison utility
//

import Foundation

/// Represents a semantic version (major.minor.patch)
public struct SemanticVersion: Comparable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    /// Initialize from version components
    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parse semantic version from string (e.g., "1.2.3")
    /// Returns nil if string is not a valid semantic version
    public init?(string: String) {
        let components = string.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 1 else { return nil }

        self.major = components[0]
        self.minor = components.count > 1 ? components[1] : 0
        self.patch = components.count > 2 ? components[2] : 0
    }

    // MARK: - Comparable

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }

    public static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
}

// MARK: - String Conversion

extension SemanticVersion: CustomStringConvertible {
    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}
