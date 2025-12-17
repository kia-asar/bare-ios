//
//  SupabaseClientProvider.swift
//  BareKit
//
//  Provides configured Supabase client with shared Keychain storage
//

import Foundation
import Supabase
import KeychainAccess

/// Provides a configured Supabase client with Keychain-based session storage
public actor SupabaseClientProvider {
    public static let shared = SupabaseClientProvider()

    private var clientInstance: SupabaseClient?

    private init() {}

    /// Get or create a configured Supabase client
    /// - Parameter config: Supabase configuration
    /// - Returns: Configured SupabaseClient
    public func client(config: SupabaseConfig) -> SupabaseClient {
        if let existing = clientInstance {
            return existing
        }

        // Create keychain-backed session storage
        // Uses default keychain access group from entitlements for share extension compatibility
        let storage = KeychainSessionStorage()

        let client = SupabaseClient(
            supabaseURL: config.url,
            supabaseKey: config.anonKey,
            options: .init(
                auth: .init(
                    storage: storage,
                    flowType: .pkce,  // PKCE flow required for magic link auth with refresh tokens
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        clientInstance = client
        return client
    }
}

/// Keychain-backed session storage for Supabase Auth
/// Uses KeychainAccess library for secure storage
/// Shares auth sessions between main app and share extension via default keychain access group
final class KeychainSessionStorage: AuthLocalStorage, @unchecked Sendable {
    private let keychain: Keychain

    init() {
        // Use default keychain access group from entitlements
        // iOS automatically uses the first keychain-access-group defined in entitlements
        // This enables sharing between main app and share extension without hardcoding team ID
        self.keychain = Keychain(service: AppConfig.keychainServiceID)
            .accessibility(.afterFirstUnlock)
    }

    func store(key: String, value: Data) throws {
        try keychain.set(value, key: key)
    }

    func retrieve(key: String) throws -> Data? {
        try keychain.getData(key)
    }

    func remove(key: String) throws {
        try keychain.remove(key)
    }
}


