//
//  CandidateListViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

final class CandidateListViewModelTests: XCTestCase {
    
    var viewModel: CandidateListViewModel!
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
        viewModel = CandidateListViewModel(backendService: backendService)
    }
    
    override func tearDown() {
        viewModel = nil
        backendService = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    /// Helper to simulate a logged-in state in the BackendService.
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
    
    // MARK: - Fetch Candidates Tests
    
    func test_fetchAllCandidates_success_populates_list() async throws {
        // When
        try await authenticateService()
        
        let candidates = [
            Candidate(id: UUID(), firstName: "Alice", lastName: "Smith", email: "alice@test.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false),
            Candidate(id: UUID(), firstName: "Bob", lastName: "Jones", email: "bob@test.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: true)
        ]
        
        mockSession.data = try JSONEncoder().encode(candidates)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/candidate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 2)
        XCTAssertEqual(viewModel.candidateCount, 2)
        XCTAssertEqual(viewModel.candidates.first?.firstName, "Alice")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_fetchAllCandidates_fails_when_not_logged_in() async {
        // When (Skip authenticateService() call)
        
        // Given
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertTrue(viewModel.candidates.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        // BackendService throws APIError.unAuthorized("No authentication token available")
        XCTAssertTrue(viewModel.errorMessage?.contains("token") == true || viewModel.errorMessage?.contains("Unauthorized") == true)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_fetchAllCandidates_api_error_sets_errorMessage() async throws {
        // When
        try await authenticateService()
        
        // Simulate Server Error (500)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertTrue(viewModel.candidates.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage) // Should be "Server error: 500" or similar
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_fetchAllCandidates_decoding_error_resets_list() async throws {
        // When
        try await authenticateService()
        
        // Simulate malformed JSON
        mockSession.data = "Invalid JSON".data(using: .utf8)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Given
        await viewModel.fetchAllCandidates()
        
        // When
        XCTAssertTrue(viewModel.candidates.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, APIError.decodingFailed.errorDescription)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_fetchAllCandidates_generic_error_sets_default_message() async throws {
        // When
        try await authenticateService()
        
        // Simulate a network failure (NSError) not handled by APIError
        mockSession.error = NSError(domain: "TestDomain", code: -1, userInfo: nil)
        
        // Given
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertTrue(viewModel.candidates.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "An unexpected error occurred")
        XCTAssertFalse(viewModel.isLoading)
    }
}
