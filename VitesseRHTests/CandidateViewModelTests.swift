//
//  CandidateViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

final class CandidateViewModelTests: XCTestCase {
    
    var viewModel: CandidateViewModel!
    var mockSession: MockURLSession!
    var backendService: CandidateBackendService!
    var initialCandidate: Candidate!
    
    override func setUp() {
        super.setUp()
        
        // 1. Setup Mock Session
        mockSession = MockURLSession()
        
        // 2. Setup Service Chain
        let apiService = APIService(session: mockSession)
        backendService = CandidateBackendService(apiService: apiService)
        
        // 3. Setup Initial Data
        initialCandidate = Candidate(
            id: UUID(),
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            phone: "123456789",
            linkedinURL: nil,
            note: "Initial note",
            isFavorite: false
        )
        
        // 4. Init ViewModel
        viewModel = CandidateViewModel(candidate: initialCandidate, backendService: backendService)
    }
    
    override func tearDown() {
        viewModel = nil
        backendService = nil
        mockSession = nil
        initialCandidate = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    /// Helper to simulate a logged-in state in the BackendService
    private func authenticateService() async throws {
        let authResponse = UserAuthenticationResponse(token: "mock_valid_token", isAdmin: false)
        let data = try JSONEncoder().encode(authResponse)
        
        mockSession.data = data
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/user/auth")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        try await backendService.userAuthenticate(email: "test", password: "password")
    }
    
    // MARK: - refreshCandidate Tests
    
    func test_refreshCandidate_success_updates_candidate() async throws {
        // When
        try await authenticateService() // Must be logged in
        
        let updatedCandidate = Candidate(
            id: initialCandidate.id,
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            phone: "987654321", // Changed
            linkedinURL: "https://linkedin.com/in/johndoe", // Changed
            note: "Updated note", // Changed
            isFavorite: true // Changed
        )
        
        mockSession.data = try JSONEncoder().encode(updatedCandidate)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/candidate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        await viewModel.refreshCandidate()
        
        // Then
        XCTAssertEqual(viewModel.candidate.phone, "987654321")
        XCTAssertEqual(viewModel.candidate.note, "Updated note")
        XCTAssertTrue(viewModel.candidate.isFavorite)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_refreshCandidate_without_token_sets_unauthorized_error() async {
        // When (Do not call authenticateService())
        
        // Given
        await viewModel.refreshCandidate()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("token") == true || viewModel.errorMessage?.contains("Unauthorized") == true)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_refreshCandidate_api_error_sets_errorMessage() async throws {
        // When
        try await authenticateService()
        
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 404, // Not Found
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        await viewModel.refreshCandidate()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage) // Expecting "Not found"
        XCTAssertFalse(viewModel.isLoading)
        // Candidate data should remain unchanged on failure
        XCTAssertEqual(viewModel.candidate.phone, "123456789")
    }
    
    func test_refreshCandidate_generic_error_sets_default_message() async throws {
        // When
        try await authenticateService()
        
        // Simulate a network error (no response/data logic in MockSession for error)
        mockSession.error = NSError(domain: "Test", code: -1, userInfo: nil)
        
        // Given
        await viewModel.refreshCandidate()
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "An unexpected error occurred")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - toggleFavorite Tests
    
    func test_toggleFavorite_success_flips_value() async throws {
        // When
        try await authenticateService()
        
        var favoritedCandidate = initialCandidate!
        favoritedCandidate.isFavorite = true
        
        mockSession.data = try JSONEncoder().encode(favoritedCandidate)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        await viewModel.toggleFavorite()
        
        // Then
        XCTAssertTrue(viewModel.candidate.isFavorite)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_toggleFavorite_failure_does_not_update_candidate() async throws {
        // When
        try await authenticateService()
        
        // Simulate Server Error
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        await viewModel.toggleFavorite()
        
        // Then
        XCTAssertFalse(viewModel.candidate.isFavorite) // Should remain false
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
