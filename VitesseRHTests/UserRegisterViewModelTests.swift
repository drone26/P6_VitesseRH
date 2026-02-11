//
//  UserRegisterViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

//
//  UserRegisterViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

final class UserRegisterViewModelTests: XCTestCase {
    
    var viewModel: UserRegisterViewModel!
    var mockSession: MockURLSession!
    var backendService: CandidateBackendService!
    
    override func setUp() {
        super.setUp()
        
        // 1. Setup Mock Session
        mockSession = MockURLSession()
        
        // 2. Setup Service Chain
        let apiService = APIService(session: mockSession)
        backendService = CandidateBackendService(apiService: apiService)
        
        // 3. Init ViewModel
        viewModel = UserRegisterViewModel(backendService: backendService)
    }
    
    override func tearDown() {
        viewModel = nil
        backendService = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - Validation Tests
    
    func test_isFirstNameValid() {
        // When
        viewModel.firstName = ""
        // Given / Then
        XCTAssertFalse(viewModel.isFirstNameValid)
        
        // When
        viewModel.firstName = "   "
        // Given / Then
        XCTAssertFalse(viewModel.isFirstNameValid)
        
        // When
        viewModel.firstName = "John"
        // Given / Then
        XCTAssertTrue(viewModel.isFirstNameValid)
    }
    
    func test_isLastNameValid() {
        // When
        viewModel.lastName = ""
        // Given / Then
        XCTAssertFalse(viewModel.isLastNameValid)
        
        // When
        viewModel.lastName = "   "
        // Given / Then
        XCTAssertFalse(viewModel.isLastNameValid)
        
        // When
        viewModel.lastName = "Doe"
        // Given / Then
        XCTAssertTrue(viewModel.isLastNameValid)
    }
    
    func test_isEmailValid() {
        // When
        viewModel.email = "invalid"
        // Given / Then
        XCTAssertFalse(viewModel.isEmailValid)
        
        // When
        viewModel.email = "test@example.com"
        // Given / Then
        XCTAssertTrue(viewModel.isEmailValid)
    }
    
    func test_isPasswordValid() {
        // When
        viewModel.password = "123"
        // Given / Then
        XCTAssertFalse(viewModel.isPasswordValid)
        
        // When
        viewModel.password = "123456"
        // Given / Then
        XCTAssertTrue(viewModel.isPasswordValid)
    }
    
    func test_isPasswordConfirmValid() {
        // When
        // Empty confirm
        viewModel.password = "password"
        viewModel.confirmPassword = ""
        // Given / Then
        XCTAssertFalse(viewModel.isPasswordConfirmValid)
        
        // Mismatch
        viewModel.confirmPassword = "mismatch"
        // Given / Then
        XCTAssertFalse(viewModel.isPasswordConfirmValid)
        
        // Match
        viewModel.confirmPassword = "password"
        // Given / Then
        XCTAssertTrue(viewModel.isPasswordConfirmValid)
    }
    
    func test_isFormValid_requires_all_fields_valid() {
        // When
        // Set all valid first
        viewModel.firstName = "John"
        viewModel.lastName = "Doe"
        viewModel.email = "john@example.com"
        viewModel.password = "password"
        viewModel.confirmPassword = "password"
        // Given / Then
        XCTAssertTrue(viewModel.isFormValid)
        
        // When
        // Invalidate one by one
        viewModel.firstName = ""
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
        
        // When
        viewModel.firstName = "John" // reset
        viewModel.lastName = ""
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
        
        // When
        viewModel.lastName = "Doe" // reset
        viewModel.email = "bad-email"
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
        
        // When
        viewModel.email = "john@example.com" // reset
        viewModel.password = "short"
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
        
        // When
        viewModel.password = "password" // reset
        viewModel.confirmPassword = "mismatch"
        // Given / Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    // MARK: - Registration Functionality Tests
    
    func test_register_success_sets_isRegistered_true() async throws {
        // When
        // Mock success response (empty body or minimal success json)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/register")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        viewModel.firstName = "John"
        viewModel.lastName = "Doe"
        viewModel.email = "john@example.com"
        viewModel.password = "password"
        
        // Given
        try await viewModel.register()
        
        // Then
        XCTAssertTrue(viewModel.isRegistered)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_register_failure_with_APIError_sets_errorMessage() async {
        // When (Mock a 400 Bad Request which throws APIError.badRequest)
        mockSession.data = Data() // No error body
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/register")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given / Then
        do {
            try await viewModel.register()
            XCTFail("Register should fail with APIError")
        } catch _ as APIError {
            // Assert
            XCTAssertFalse(viewModel.isRegistered)
            // 400 maps to APIError.badRequest. Without a reason body, it defaults to "Bad request"
            XCTAssertEqual(viewModel.errorMessage, "Bad request")
        } catch {
            XCTFail("Wrong error type thrown: \(error)")
        }
    }
    
    func test_register_failure_with_generic_error_sets_default_message() async {
        // When (Mock network error (NSError))
        mockSession.error = NSError(domain: "Test", code: -1, userInfo: nil)
        
        // Given / Then
        do {
            try await viewModel.register()
            XCTFail("Register should fail")
        } catch {
            // Assert
            XCTAssertFalse(viewModel.isRegistered)
            XCTAssertEqual(viewModel.errorMessage, "An unexpected error occurred during registration")
        }
    }
       
    func test_resetRegistrationState_resets_flag() async throws {
        // When (Register successfully first)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        try await viewModel.register()
        
        XCTAssertTrue(viewModel.isRegistered)
        
        // Given
        viewModel.resetRegistrationState()
        
        // Then
        XCTAssertFalse(viewModel.isRegistered)
    }
}
