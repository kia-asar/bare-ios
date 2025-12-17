//
//  AIChatService.swift
//  CStudioKit
//
//  AI chat service for conversing about post content (placeholder for future implementation)
//

import Foundation

/// Protocol for AI chat operations on posts
public protocol AIChatServiceProtocol: Sendable {
    /// Start a new conversation about a post
    func startConversation(for postId: UUID) async throws -> UUID
    
    /// Send a message in a conversation
    func sendMessage(conversationId: UUID, text: String) async throws -> [AIMessage]
    
    /// Get conversation history
    func getConversationHistory(conversationId: UUID) async throws -> [AIMessage]
}

/// AI message in a conversation
public struct AIMessage: Codable, Hashable, Sendable {
    public let id: UUID
    public let role: MessageRole
    public let content: String
    public let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
    }
    
    public init(id: UUID = UUID(), role: MessageRole, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

/// Role of a message in a conversation
public enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

/// No-op implementation for AI chat (placeholder until feature is implemented)
public actor NoopAIChatService: AIChatServiceProtocol {
    public init() {}
    
    public func startConversation(for postId: UUID) async throws -> UUID {
        throw AIServiceError.notImplemented
    }
    
    public func sendMessage(conversationId: UUID, text: String) async throws -> [AIMessage] {
        throw AIServiceError.notImplemented
    }
    
    public func getConversationHistory(conversationId: UUID) async throws -> [AIMessage] {
        throw AIServiceError.notImplemented
    }
}

/// Errors that can occur in AI service operations
public enum AIServiceError: Error, LocalizedError {
    case notImplemented
    case conversationNotFound
    case invalidRequest
    
    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "AI chat feature not yet implemented"
        case .conversationNotFound:
            return "Conversation not found"
        case .invalidRequest:
            return "Invalid request"
        }
    }
}


