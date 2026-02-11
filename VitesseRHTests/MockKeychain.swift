//
//  MockKeychain.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 10/02/2026.
//

import Foundation
import XCTest
@testable import VitesseRH


// MARK: - Mock Keychain Service

actor MockKeychainService: KeychainServiceProtocol {
    var savedToken: String?
    
    func saveToken(_ token: String) throws {
        self.savedToken = token
    }
    
    func getToken() throws -> String? {
        return savedToken
    }
    
    // Helper methods for testing
    func setToken(_ token: String) {
        self.savedToken = token
    }
    
    func clearToken() {
        self.savedToken = nil
    }
}
