//
//  UserRegisterViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

/// ViewModel for managing user registration
@Observable
final class UserRegisterViewModel {
    // MARK: - Properties
    
    /// First name input
    var firstName: String = ""
    
    /// Last name input
    var lastName: String = ""
    
    /// Email input
    var email: String = ""
    
    /// Password input
    var password: String = ""
    
    /// Confirm password input
    var confirmPassword: String = ""
    
    /// Loading state
    private(set) var isLoading: Bool = false
    
    /// Error state
    private(set) var errorMessage: String?
    
    /// Success flag - indicates successful registration
    private(set) var isRegistered: Bool = false
    
    /// Backend service for API calls
    private let backendService: CandidateBackendService
    
    // MARK: - Init
    
    init(backendService: CandidateBackendService = CandidateBackendService()) {
        self.backendService = backendService
    }
    
    // MARK: - Computed Properties
    
    /// Checks if first name is valid (not empty)
    var isFirstNameValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Checks if last name is valid (not empty)
    var isLastNameValid: Bool {
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Checks if email is in valid format
    var isEmailValid: Bool {
        isValidEmailFormat(email)
    }
    
    /// Checks if password meets minimum requirements
    var isPasswordValid: Bool {
        isValidPassword(password)
    }
    
    /// Checks if passwords match
    var isPasswordConfirmValid: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }
    
    /// Checks if the entire form is valid
    var isFormValid: Bool {
        isFirstNameValid && isLastNameValid && isEmailValid && isPasswordValid && isPasswordConfirmValid
    }
    
    // MARK: - Public Methods
    
    /// Perform user registration
    /// - Throws: APIError if registration fails
    func register() async throws {
        isLoading = true
        errorMessage = nil
        isRegistered = false
        
        do {
            try await backendService.userRegister(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
            
            isRegistered = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isRegistered = false
            throw error
        } catch {
            errorMessage = "An unexpected error occurred during registration"
            isRegistered = false
            throw error
        }
    }
    
    /// Perform user registration with automatic error handling
    func registerWithErrorHandling() async {
        do {
            try await register()
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
        firstName = ""
        lastName = ""
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }
    
    /// Reset registration state
    func resetRegistrationState() {
        isRegistered = false
    }
}
