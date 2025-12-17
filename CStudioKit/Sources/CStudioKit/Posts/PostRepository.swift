//
//  PostRepository.swift
//  CStudioKit
//
//  Repository for post CRUD operations
//

import Foundation
import Supabase
import OSLog

/// Protocol for post repository operations
public protocol PostRepositoryProtocol: Sendable {
    /// List recent posts
    func listRecent(limit: Int) async throws -> [Post]
    
    /// Get a specific post by ID
    func get(id: UUID) async throws -> Post?
    
    /// Check if a URL exists and get canonical form
    func canonicalizeAndCheck(originalURL: URL) async throws -> CanonicalizeCheckResponse
    
    /// Create a new post (calls Edge Function for canonicalization)
    func create(_ input: PostInput) async throws -> CreatePostResponse
    
    /// Update an existing post
    func update(_ id: UUID, with update: PostUpdate) async throws -> Post
    
    /// Delete a post
    func delete(_ id: UUID) async throws
}

/// Post repository implementation
public actor PostRepository: PostRepositoryProtocol {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func listRecent(limit: Int = 50) async throws -> [Post] {
        let signpost = AppLogger.signpost(logger: AppLogger.network, name: "fetch_posts")
        signpost.begin()
        defer { signpost.end("fetched \(limit) posts") }
        
        AppLogger.network.debug("Fetching recent posts (limit: \(limit))")
        let response: [Post] = try await client
            .from("studio_posts")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        AppLogger.network.info("Fetched \(response.count) posts")
        return response
    }
    
    public func get(id: UUID) async throws -> Post? {
        let response: [Post] = try await client
            .from("studio_posts")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        return response.first
    }
    
    public func canonicalizeAndCheck(originalURL: URL) async throws -> CanonicalizeCheckResponse {
        let signpost = AppLogger.signpost(logger: AppLogger.network, name: "canonicalize_url")
        signpost.begin()
        defer { signpost.end() }
        
        AppLogger.network.debug("Canonicalizing URL")
        
        struct Request: Encodable {
            let original_url: String
        }
        
        let request = Request(original_url: originalURL.absoluteString)
        
        let response: CanonicalizeCheckResponse = try await invokeFunction(
            "studio_canonicalize_and_check",
            body: request
        )
        
        AppLogger.network.info("URL canonicalized successfully")
        return response
    }
    
    public func create(_ input: PostInput) async throws -> CreatePostResponse {
        let signpost = AppLogger.signpost(logger: AppLogger.network, name: "create_post")
        signpost.begin()
        defer { signpost.end() }
        
        AppLogger.network.info("Creating post")
        let response: CreatePostResponse = try await invokeFunction(
            "studio_create_post_with_canonicalization",
            body: input
        )
        
        AppLogger.network.info("Post created successfully")
        return response
    }
    
    public func update(_ id: UUID, with update: PostUpdate) async throws -> Post {
        let response: [Post] = try await client
            .from("studio_posts")
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .execute()
            .value
        
        guard let post = response.first else {
            throw RepositoryError.notFound
        }
        
        return post
    }
    
    public func delete(_ id: UUID) async throws {
        try await client
            .from("studio_posts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Helpers

    private func invokeFunction<Response: Decodable, Body: Encodable>(
        _ name: String,
        body: Body
    ) async throws -> Response {
        if let payload = body.asJSONString(sortedKeys: true) {
            AppLogger.network.logPrivate(level: .debug, "[\(name)] payload: \(payload)")
        }

        let decoder = SupabaseJSONCoding.makeDecoder()

        do {
            return try await client.functions.invoke(
                name,
                options: FunctionInvokeOptions(body: body),
                decode: { data, response in
                    do {
                        return try decoder.decode(Response.self, from: data)
                    } catch {
                        let responseBody = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
                        AppLogger.network.logPrivate(
                            level: .error,
                            "[\(name)] decode failed (status \(response.statusCode)): \(error). Body: \(responseBody)"
                        )
                        throw error
                    }
                }
            )
        } catch let functionsError as FunctionsError {
            switch functionsError {
            case .relayError:
                AppLogger.network.error("[\(name)] relay error while invoking function.")
            case let .httpError(code, data):
                let responseBody = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
                AppLogger.network.logPrivate(
                    level: .error,
                    "[\(name)] HTTP \(code) response: \(responseBody)"
                )
            }
            throw functionsError
        }
    }
}

/// Errors that can occur in repository operations
public enum RepositoryError: Error, LocalizedError {
    case notFound
    case invalidResponse
    case unauthorized
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Post not found"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

