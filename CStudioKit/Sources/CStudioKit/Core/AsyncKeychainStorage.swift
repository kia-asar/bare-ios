//
//  AsyncKeychainStorage.swift
//  CStudioKit
//
//  Async/await wrapper around KeychainAccess for thread-safe keychain operations
//

import Foundation
import KeychainAccess

/// Actor-based async wrapper for keychain storage
/// Provides thread-safe, non-blocking access to keychain with access group support for app/extension sharing
public actor AsyncKeychainStorage {
    private let keychain: Keychain

    /// Initialize async keychain storage
    /// - Parameters:
    ///   - service: Service identifier (defaults to bundle identifier)
    ///   - accessGroup: Keychain access group for sharing between app and extensions (optional)
    public init(service: String? = nil, accessGroup: String? = nil) {
        let serviceIdentifier = service ?? Bundle.main.bundleIdentifier ?? AppConfig.mainAppBundleID

        if let accessGroup = accessGroup {
            self.keychain = Keychain(service: serviceIdentifier, accessGroup: accessGroup)
                .accessibility(.afterFirstUnlock)
        } else {
            self.keychain = Keychain(service: serviceIdentifier)
                .accessibility(.afterFirstUnlock)
        }
    }

    /// Store data in keychain
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Key to store under
    public func store(_ data: Data, forKey key: String) async throws {
        try keychain.set(data, key: key)
    }

    /// Retrieve data from keychain
    /// - Parameter key: Key to retrieve
    /// - Returns: Data if found, nil otherwise
    public func retrieve(forKey key: String) async throws -> Data? {
        try keychain.getData(key)
    }

    /// Delete data from keychain
    /// - Parameter key: Key to delete
    public func delete(key: String) async throws {
        try keychain.remove(key)
    }
}
