//
//  Post.swift
//  CStudioKit
//
//  Core post model mirroring studio_posts table
//

import Foundation

/// A post saved by the user
public struct Post: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let originalURL: URL
    public let canonicalURL: URL
    public var thumbnailURL: URL?
    public var userInstructions: String?
    public var payload: [String: JSONValue]
    public var ingestionStatus: IngestionStatus
    public var ingestionError: String?
    public var ingestedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case originalURL = "original_url"
        case canonicalURL = "canonical_url"
        case thumbnailURL = "thumbnail_url"
        case userInstructions = "user_instructions"
        case payload
        case ingestionStatus = "ingestion_status"
        case ingestionError = "ingestion_error"
        case ingestedAt = "ingested_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        originalURL: URL,
        canonicalURL: URL,
        thumbnailURL: URL? = nil,
        userInstructions: String? = nil,
        payload: [String: JSONValue] = [:],
        ingestionStatus: IngestionStatus = .pending,
        ingestionError: String? = nil,
        ingestedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.originalURL = originalURL
        self.canonicalURL = canonicalURL
        self.thumbnailURL = thumbnailURL
        self.userInstructions = userInstructions
        self.payload = payload
        self.ingestionStatus = ingestionStatus
        self.ingestionError = ingestionError
        self.ingestedAt = ingestedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Status of content ingestion for a post
public enum IngestionStatus: String, Codable, Sendable {
    case pending
    case processing
    case completed
    case failed
}

/// Input for creating a new post
public struct PostInput: Codable, Sendable {
    public let originalURL: URL
    public var userInstructions: String?
    public var thumbnailURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case originalURL = "original_url"
        case userInstructions = "user_instructions"
        case thumbnailURL = "thumbnail_url"
    }
    
    public init(
        originalURL: URL,
        userInstructions: String? = nil,
        thumbnailURL: URL? = nil
    ) {
        self.originalURL = originalURL
        self.userInstructions = userInstructions
        self.thumbnailURL = thumbnailURL
    }
}

/// Update data for an existing post
public struct PostUpdate: Codable, Sendable {
    public var thumbnailURL: URL?
    public var userInstructions: String?
    public var payload: [String: JSONValue]?
    public var ingestionStatus: IngestionStatus?
    public var ingestionError: String?
    public var ingestedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case thumbnailURL = "thumbnail_url"
        case userInstructions = "user_instructions"
        case payload
        case ingestionStatus = "ingestion_status"
        case ingestionError = "ingestion_error"
        case ingestedAt = "ingested_at"
    }
    
    public init(
        thumbnailURL: URL? = nil,
        userInstructions: String? = nil,
        payload: [String: JSONValue]? = nil,
        ingestionStatus: IngestionStatus? = nil,
        ingestionError: String? = nil,
        ingestedAt: Date? = nil
    ) {
        self.thumbnailURL = thumbnailURL
        self.userInstructions = userInstructions
        self.payload = payload
        self.ingestionStatus = ingestionStatus
        self.ingestionError = ingestionError
        self.ingestedAt = ingestedAt
    }
}

/// Response from canonicalize and check endpoint
public struct CanonicalizeCheckResponse: Codable, Sendable {
    public let canonicalURL: URL
    public let exists: Bool
    public let postId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case canonicalURL = "canonical_url"
        case exists
        case postId = "post_id"
    }
    
    public init(canonicalURL: URL, exists: Bool, postId: UUID? = nil) {
        self.canonicalURL = canonicalURL
        self.exists = exists
        self.postId = postId
    }
}

/// Response from create post endpoint
public struct CreatePostResponse: Codable, Sendable {
    public let created: Bool
    public let post: Post
    
    public init(created: Bool, post: Post) {
        self.created = created
        self.post = post
    }
}

// MARK: - Post Convenience Extensions

extension Post {
    /// Extract display title from post payload or URL
    ///
    /// Attempts to get the title from the payload first, falling back to the canonical URL's host.
    /// This ensures every post has a meaningful display title.
    ///
    /// - Returns: A non-empty title string
    public func extractTitle() -> String {
        if let title = payload["title"]?.stringValue, !title.isEmpty {
            return title
        }
        if let topic = payload["topic"]?.stringValue, !topic.isEmpty {
            return topic
        }
        return canonicalURL.host ?? canonicalURL.absoluteString
    }
    
    /// Extract engagement metrics from post payload
    ///
    /// Parses views, likes, and comments from the payload and formats them for display.
    ///
    /// - Returns: Array of MetricItems, or nil if metrics are not available
    public func extractEngagementMetrics() -> [MetricItem]? {
        guard let views = payload["views"]?.numberValue,
              let likes = payload["likes"]?.numberValue,
              let comments = payload["comments"]?.numberValue else {
            return nil
        }
        
        return [
            MetricItem(count: formatEngagementNumber(views), iconName: "eye.fill"),
            MetricItem(count: formatEngagementNumber(likes), iconName: "heart.fill"),
            MetricItem(count: formatEngagementNumber(comments), iconName: "bubble.left.fill")
        ]
    }
    
    /// Format a number for engagement metrics display
    ///
    /// Formats large numbers with k/m suffixes (e.g., 1500 -> "1.5k", 2,300,000 -> "2.3m")
    ///
    /// - Parameter value: The numeric value to format
    /// - Returns: Formatted string representation
    private func formatEngagementNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fm", value / 1_000_000)
        } else if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    /// Convert Post to ContentItem for display
    ///
    /// Creates a ContentItem with all available fields from the Post.
    /// This centralizes the conversion logic and ensures consistency across the app.
    ///
    /// - Parameter includeDetailedFields: Whether to include detailed payload fields (default: true)
    /// - Returns: ContentItem ready for display
    public func toContentItem(includeDetailedFields: Bool = true) -> ContentItem {
        let baseItem = ContentItem(
            id: self.id,
            thumbnailName: "photo",
            title: self.extractTitle(),
            createdDate: self.createdAt,
            originalURL: self.originalURL,
            imageUrl: self.thumbnailURL?.absoluteString,
            engagementMetrics: self.extractEngagementMetrics()
        )

        // Return minimal version if detailed fields not requested
        guard includeDetailedFields else {
            return baseItem
        }

        // Return full version with all payload fields
        return ContentItem(
            id: baseItem.id,
            thumbnailName: baseItem.thumbnailName,
            title: baseItem.title,
            createdDate: baseItem.createdDate,
            originalURL: baseItem.originalURL,
            imageUrl: baseItem.imageUrl,
            engagementMetrics: baseItem.engagementMetrics,
            viralStatus: self.payload["viral_status"]?.stringValue,
            authorHandle: self.payload["author_handle"]?.stringValue,
            summary: self.payload["summary"]?.stringValue,
            audioTranscription: self.payload["audio_transcription"]?.stringValue,
            visualTranscription: self.payload["visual_transcription"]?.stringValue,
            userResearchAnswer: self.payload["user_research_answer"]?.stringValue,
            commentsAnalysis: self.payload["comments_analysis"]?.stringValue
        )
    }
}

