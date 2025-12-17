//
//  AuthManager.swift
//  BareKit
//
//  Unified authentication manager combining state and operations
//  Single source of truth for authentication using modern Swift patterns
//

import Foundation
import Supabase
import Observation
import OSLog

/// Unified authentication manager handling both state and operations
/// Uses Swift's @Observable for reactive UI updates
@Observable
@MainActor
public final class AuthManager {
    // MARK: - Observable State

    /// Current authentication status
    public private(set) var isAuthenticated = false

    /// Current user session
    public private(set) var session: Session?

    /// Current user if authenticated
    public var currentUser: User? {
        session?.user
    }

    /// Current user ID if authenticated
    public var userId: UUID? {
        session?.user.id
    }

    // MARK: - Private Properties

    private let client: SupabaseClient
    private let redirectURL = AppConfig.authCallbackURL
    private var authStateTask: Task<Void, Never>?

    /// Optional callback invoked when authentication state changes
    /// Allows external systems (like observability) to react to auth changes
    public var onAuthStateChange: (@MainActor (AuthChangeEvent, Session?) -> Void)?

    // MARK: - Initialization

    public init(client: SupabaseClient) {
        self.client = client
    }

    /// Start listening to authentication state changes
    /// Should be called once when the app initializes
    public func startListening() {
        authStateTask?.cancel()

        // Immediately restore any cached session (e.g., from the keychain) so UI
        // consumers see the correct state before the async listener fires.
        restoreCachedSessionIfAvailable()

        authStateTask = Task { @MainActor in
            for await (event, session) in await client.auth.authStateChanges {
                handleAuthStateChange(event: event, session: session)
            }
        }
    }

    /// Stop listening to authentication state changes
    public func stopListening() {
        authStateTask?.cancel()
        authStateTask = nil
    }

    // MARK: - Authentication Operations

    /// Send a magic link to the provided email address
    /// - Parameter email: User's email address
    /// - Throws: Authentication errors from Supabase
    public func sendMagicLink(to email: String) async throws {
        let signpost = AppLogger.signpost(logger: AppLogger.auth, name: "send_magic_link")
        signpost.begin()
        defer { signpost.end() }
        
        AppLogger.auth.info("Sending magic link")
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: redirectURL
        )
        AppLogger.auth.info("Magic link sent successfully")
    }

    /// Handle deep link callback from magic link
    /// - Parameter url: Deep link URL from the magic link email
    /// - Throws: Authentication errors if session extraction fails
    public func handleDeepLink(_ url: URL) async throws {
        let signpost = AppLogger.signpost(logger: AppLogger.auth, name: "handle_deep_link")
        signpost.begin()
        defer { signpost.end() }
        
        AppLogger.auth.info("Handling auth deep link")
        try await client.auth.session(from: url)
        AppLogger.auth.info("Deep link handled successfully")
        // State will be updated automatically via authStateChanges listener
    }

    /// Sign out the current user
    /// - Throws: Sign out errors from Supabase
    public func signOut() async throws {
        let signpost = AppLogger.signpost(logger: AppLogger.auth, name: "sign_out")
        signpost.begin()
        defer { signpost.end() }
        
        AppLogger.auth.info("Signing out user")
        try await client.auth.signOut()
        AppLogger.auth.info("User signed out successfully")
        // State will be updated automatically via authStateChanges listener
    }

    // MARK: - Private Methods

    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        switch event {
        case .initialSession, .signedIn, .tokenRefreshed, .mfaChallengeVerified:
            updateSession(session)

        case .signedOut, .userDeleted:
            clearSession()

        case .userUpdated:
            updateSession(session)

        case .passwordRecovery:
            updateSession(session)
        }

        // Notify external observers (e.g., observability)
        onAuthStateChange?(event, session)
    }

    private func updateSession(_ session: Session?) {
        self.session = session
        self.isAuthenticated = session?.isValid ?? false
    }

    private func clearSession() {
        self.session = nil
        self.isAuthenticated = false
    }

    /// Restore existing session from local storage (used by share extension)
    private func restoreCachedSessionIfAvailable() {
        guard session == nil else { return }

        if let cachedSession = client.auth.currentSession {
            // Only restore if session is still valid
            if cachedSession.isValid {
                AppLogger.auth.info("Restored cached Supabase session from local storage")
                updateSession(cachedSession)
            } else {
                AppLogger.auth.info("Cached session found but expired, waiting for auth stream")
            }
        }
    }
}

// MARK: - Session Validation

extension Session {
    /// Check if the session is still valid (not expired)
    var isValid: Bool {
        let expiryDate = Date(timeIntervalSince1970: expiresAt)
        return expiryDate > Date()
    }
}
