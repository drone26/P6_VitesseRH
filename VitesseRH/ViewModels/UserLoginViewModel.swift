//
//  UserLoginViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import Foundation
import Observation

/// ViewModel for managing user login
@Observable
final class UserLoginViewModel {
    // MARK: - Properties
    
    /// Email input
    var email: String = ""
    
    /// Password input
    var password: String = ""
    
    /// Loading state
    private(set) var isLoading: Bool = false
    
    /// Error state
    private(set) var errorMessage: String?
    
    /// Success flag - indicates successful login
    private(set) var isLoggedIn: Bool = false
    
    /// Admin status of logged-in user
    private(set) var isAdmin: Bool = false
    
    /// Backend service for API calls
    private let backendService: CandidateBackendService
    
    // MARK: - Init
    
    init(backendService: CandidateBackendService = CandidateBackendService()) {
        self.backendService = backendService
    }
    
    // MARK: - Computed Properties
    
    /// Checks if email is in valid format
    var isEmailValid: Bool {
        isValidEmailFormat(email)
    }
    
    /// Checks if password meets minimum requirements
    var isPasswordValid: Bool {
        isValidPassword(password)
    }
    
    /// Checks if login button should be enabled
    var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    // MARK: - Public Methods
    
    /// Perform user login
    /// - Throws: APIError if login fails
    func login() async throws {
        isLoading = true
        errorMessage = nil
        isLoggedIn = false
        
        do {
            try await backendService.userAuthenticate(email: email, password: password)
            
            // Set admin status if available
            if let isAdmin = await backendService.isAdmin {
                self.isAdmin = isAdmin
            }
            
            isLoggedIn = true
            isLoading = false  // Set to false on success
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isLoggedIn = false
            isLoading = false  // Set to false on error
            throw error
        } catch {
            errorMessage = "An unexpected error occurred during login"
            isLoggedIn = false
            isLoading = false  // Set to false on error
            throw error
        }
    }
    
    /// Perform user login with automatic error handling
    func loginWithErrorHandling() async {
        do {
            try await login()
        } catch {
            // Error is already handled and set in errorMessage
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clear all fields
    func clearForm() {
        email = ""
        password = ""
        errorMessage = nil
    }
    
    /// Reset login state
    func resetLoginState() {
        isLoggedIn = false
        isAdmin = false
    }
}
