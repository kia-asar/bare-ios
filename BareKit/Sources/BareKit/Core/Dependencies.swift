//
//  Dependencies.swift
//  BareKit
//
//  Dependency injection container for services
//

import Foundation
import Supabase
import SwiftUI

/// Protocol defining all dependencies needed by the app
public protocol Dependencies: Sendable {
    var supabase: SupabaseClient { get }
    var postRepository: PostRepositoryProtocol { get }
    var aiChatService: AIChatServiceProtocol { get }
    var observability: Observability { get }
    var pushNotificationService: PushNotificationService { get }
}

/// Live implementation of dependencies
public struct LiveDependencies: Dependencies {
    public let supabase: SupabaseClient
    public let postRepository: PostRepositoryProtocol
    public let aiChatService: AIChatServiceProtocol
    public let observability: Observability
    public let pushNotificationService: PushNotificationService

    public init(
        config: SupabaseConfig,
        observability: Observability = .noop,
        pushNotificationService: PushNotificationService
    ) async {
        // Initialize Supabase client on background thread to prevent keychain I/O from blocking
        // The keychain access (triggered by emitLocalSessionAsInitialSession) happens synchronously
        // but by doing it on a background thread, we don't freeze the main thread
        self.supabase = await Task.detached(priority: .userInitiated) {
            await SupabaseClientProvider.shared.client(config: config)
        }.value

        self.postRepository = PostRepository(client: supabase)
        self.aiChatService = NoopAIChatService()
        self.observability = observability
        self.pushNotificationService = pushNotificationService
    }
}

/// Errors that can occur when accessing dependencies
public enum DependencyError: Error, LocalizedError {
    case notInitialized
    case authManagerNotInitialized

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Dependencies have not been initialized. Please call DependencyContainer.initialize() first."
        case .authManagerNotInitialized:
            return "AuthManager has not been initialized. Please ensure DependencyContainer.initialize() completes successfully."
        }
    }
}

/// Global dependency container
public actor DependencyContainer {
    public static let shared = DependencyContainer()

    private var _current: Dependencies?
    private var _authManager: AuthManager?

    private init() {}

    /// Access current dependencies
    ///
    /// **Important**: This property uses fatalError if dependencies aren't initialized.
    /// Prefer using `getCurrent()` for graceful error handling.
    public var current: Dependencies {
        get {
            guard let deps = _current else {
                fatalError("DependencyContainer.current accessed before being initialized. Call DependencyContainer.initialize() first.")
            }
            return deps
        }
    }

    /// Get current dependencies with error handling
    ///
    /// Use this method instead of the `current` property for graceful error handling.
    ///
    /// - Throws: `DependencyError.notInitialized` if container hasn't been initialized
    /// - Returns: The initialized dependencies
    public func getCurrent() throws -> Dependencies {
        guard let deps = _current else {
            throw DependencyError.notInitialized
        }
        return deps
    }

    /// Get the auth manager with error handling
    ///
    /// - Throws: `DependencyError.authManagerNotInitialized` if auth manager hasn't been initialized
    /// - Returns: The initialized auth manager
    public func getAuthManager() throws -> AuthManager {
        guard let manager = _authManager else {
            throw DependencyError.authManagerNotInitialized
        }
        return manager
    }

    /// Initialize the dependency container
    /// - Parameters:
    ///   - config: Supabase configuration
    ///   - observability: Observability services (optional, defaults to noop)
    ///   - pushNotificationService: Push notification service implementation
    ///   - setupAuthCallback: Optional callback to setup auth integration (e.g., with observability)
    public func initialize(
        config: SupabaseConfig,
        observability: Observability = .noop,
        pushNotificationService: PushNotificationService,
        setupAuthCallback: (@MainActor (AuthManager) -> Void)? = nil
    ) async {
        let deps = await LiveDependencies(
            config: config,
            observability: observability,
            pushNotificationService: pushNotificationService
        )
        _current = deps

        // Create auth manager on MainActor and store reference
        let authManager = await MainActor.run {
            AuthManager(client: deps.supabase)
        }
        _authManager = authManager

        // Setup auth callback if provided (e.g., for observability integration)
        if let setupAuthCallback = setupAuthCallback {
            await MainActor.run {
                setupAuthCallback(authManager)
            }
        }

        // Start listening on MainActor
        await MainActor.run {
            authManager.startListening()
        }
    }

    /// Check if container is fully initialized (both dependencies and auth manager)
    public var isInitialized: Bool {
        _current != nil && _authManager != nil
    }
}

// MARK: - SwiftUI Environment

/// Environment key for dependencies
///
/// **Note**: Accessing deps from environment without initialization will cause a runtime error.
/// Always ensure dependencies are injected via `.environment(\.deps, dependencies)` modifier.
public struct DependenciesKey: EnvironmentKey {
    public static var defaultValue: Dependencies {
        // Using NoopDependencies as fallback instead of fatalError for better testability
        // In production, dependencies should always be properly injected
        NoopDependencies()
    }
}

extension EnvironmentValues {
    public var deps: Dependencies {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}

// MARK: - Noop Dependencies for Testing

/// Noop implementation of dependencies for testing and fallback
private struct NoopDependencies: Dependencies {
    var supabase: SupabaseClient {
        // This should never be called in production
        fatalError("NoopDependencies.supabase accessed. Ensure dependencies are properly initialized.")
    }

    var postRepository: PostRepositoryProtocol {
        NoopPostRepository()
    }

    var aiChatService: AIChatServiceProtocol {
        NoopAIChatService()
    }

    var observability: Observability {
        .noop
    }

    var pushNotificationService: PushNotificationService {
        NoopPushNotificationService()
    }
}

/// Noop post repository for testing
private struct NoopPostRepository: PostRepositoryProtocol {
    func create(_ input: PostInput) async throws -> CreatePostResponse {
        throw DependencyError.notInitialized
    }

    func get(id: UUID) async throws -> Post? {
        throw DependencyError.notInitialized
    }

    func listRecent(limit: Int) async throws -> [Post] {
        throw DependencyError.notInitialized
    }

    func update(_ id: UUID, with update: PostUpdate) async throws -> Post {
        throw DependencyError.notInitialized
    }

    func delete(_ id: UUID) async throws {
        throw DependencyError.notInitialized
    }

    func canonicalizeAndCheck(originalURL: URL) async throws -> CanonicalizeCheckResponse {
        throw DependencyError.notInitialized
    }
}


