//
//  UserLoginViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

final class UserLoginViewModelTests: XCTestCase {
    
    var viewModel: UserLoginViewModel!
    var mockSession: MockURLSession!
    var backendService: CandidateBackendService!
    
    override func setUp() {
        super.setUp()
        // Setup the dependency chain: MockSession -> APIService -> BackendService -> ViewModel
        mockSession = MockURLSession()
        let apiService = APIService(session: mockSession)
        backendService = CandidateBackendService(apiService: apiService)
        viewModel = UserLoginViewModel(backendService: backendService)
    }
    
    override func tearDown() {
        viewModel = nil
        backendService = nil
        mockSession = nil
        super.tearDown()
    }
       
    // MARK: - Form Validation Tests
    
    func test_isEmailValid_with_valid_email_returns_true() {
        // When
        viewModel.email = "test@example.com"
        
        // Given / Then
        XCTAssertTrue(viewModel.isEmailValid)
    }

    func test_isEmailValid_with_invalid_email_returns_false() {
        // When
        viewModel.email = "invalid-email"
        // Given / Then
        XCTAssertFalse(viewModel.isEmailValid)
        
        // When
        viewModel.email = ""
        // Given / Then
        XCTAssertFalse(viewModel.isEmailValid)
        
        // Testing specific edge case: domain length < 2
        // When
        viewModel.email = "user@domain.c"
        // Given / Then
        XCTAssertFalse(viewModel.isEmailValid)
    }

    func test_isPasswordValid_checks_length_greater_than_4() {
        // When
        viewModel.password = "1234"
        // Given / Then
        XCTAssertFalse(viewModel.isPasswordValid)
        
        // When
        viewModel.password = "12345"
        // Given / Then
        XCTAssertTrue(viewModel.isPasswordValid)
    }

    func test_isFormValid_requires_both_email_and_password_valid() {
        // When
        // Both invalid
        viewModel.email = "bad"
        viewModel.password = "123"
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
        
        // When
        // Email valid, password invalid
        viewModel.email = "test@example.com"
        viewModel.password = "123"
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
        
        // When
        // Email invalid, password valid
        viewModel.email = "bad"
        viewModel.password = "12345"
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
        
        // When
        // Both valid
        viewModel.email = "test@example.com"
        viewModel.password = "12345"
        // Given / Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    // MARK: - Login Functionality Tests
    
    func test_login_success_sets_loggedIn_state_and_admin_status() async throws {
        // When
        let expectedToken = "mock_token_123"
        let response = UserAuthenticationResponse(token: expectedToken, isAdmin: true)
        let data = try JSONEncoder().encode(response)
        
        mockSession.data = data
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/api/user/auth")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        viewModel.email = "admin@example.com"
        viewModel.password = "password123"
        
        // Given
        try await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.isLoggedIn)
        XCTAssertTrue(viewModel.isAdmin)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
 
    func test_login_success_for_non_admin_sets_isAdmin_false() async throws {
        // When
        let response = UserAuthenticationResponse(token: "token", isAdmin: false)
        mockSession.data = try JSONEncoder().encode(response)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        try await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.isLoggedIn)
        XCTAssertFalse(viewModel.isAdmin)
    }
   
    func test_login_failure_with_APIError_sets_errorMessage() async {
        // When (Mock a 401 Unauthorized response)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        viewModel.email = "user@example.com"
        viewModel.password = "wrongpassword"
        
        // Given / Then
        do {
            try await viewModel.login()
            XCTFail("Login should have thrown an error")
        } catch {
            XCTAssertFalse(viewModel.isLoggedIn)
            XCTAssertFalse(viewModel.isLoading)
            XCTAssertNotNil(viewModel.errorMessage)
        }
    }
 
    func test_login_failure_with_decoding_error() async {
        // When (Return valid 200 status but invalid json data)
        mockSession.data = "Invalid JSON".data(using: .utf8)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given / Then
        do {
            try await viewModel.login()
            XCTFail("Login should fail due to decoding error")
        } catch {
            XCTAssertFalse(viewModel.isLoggedIn)
            XCTAssertFalse(viewModel.isLoading)
            XCTAssertEqual(viewModel.errorMessage, APIError.decodingFailed.errorDescription)
        }
    }
  
    func test_login_failure_with_generic_error_sets_default_message() async {
        // When (Mock the session to throw a generic NSError)
        mockSession.error = NSError(domain: "TestDomain", code: -1, userInfo: nil)
        
        // Given / Then
        do {
            try await viewModel.login()
            XCTFail("Login should throw error")
        } catch {
            XCTAssertFalse(viewModel.isLoggedIn)
            XCTAssertFalse(viewModel.isLoading)
            XCTAssertEqual(viewModel.errorMessage, "An unexpected error occurred during login")
        }
    }
}
