//
//  KeychainService.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 10/02/2026.
//

import Foundation

/// Protocol for Keychain operations
protocol KeychainServiceProtocol: Actor {
    func saveToken(_ token: String) async throws
    func getToken() async throws -> String?
}

/// Service for managing secure storage in the Keychain
actor KeychainService: KeychainServiceProtocol {
    private enum KeychainKey {
        static let token = "vitesse_auth_token"
    }
    
    // MARK: - Token Storage
    
    /// Saves authentication token to Keychain
    func saveToken(_ token: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: KeychainKey.token,
            kSecValueData as String: token.data(using: .utf8) ?? Data()
        ]
        
        // Delete existing token first
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
    
    /// Retrieves authentication token from Keychain
    func getToken() async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: KeychainKey.token,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status: status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        
        return token
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case retrieveFailed(status: OSStatus)
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve from Keychain (status: \(status))"
        case .decodingFailed:
            return "Failed to decode Keychain data"
        }
    }
}
