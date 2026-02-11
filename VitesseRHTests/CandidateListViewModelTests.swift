//
//  CandidateListViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 10/02/2026.
//

import XCTest
@testable import VitesseRH

final class CandidateListViewModelTests: XCTestCase {
    
    var viewModel: CandidateListViewModel!
    var mockSession: MockURLSession!
    var mockKeychainService: MockKeychainService!
    var mockApiService: APIService!
    var mockBackendService: CandidateBackendService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        mockApiService = APIService(session: mockSession)
        mockKeychainService = MockKeychainService()
        mockBackendService = CandidateBackendService(
            apiService: mockApiService,
            keychainService: mockKeychainService
        )
        viewModel = CandidateListViewModel(backendService: mockBackendService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockSession = nil
        mockApiService = nil
        mockKeychainService = nil
        mockBackendService = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initial_state() {
        // Then
        XCTAssertEqual(viewModel.candidates.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.candidateCount, 0)
    }
    
    // MARK: - Fetch All Candidates Tests
    
    func test_fetchAllCandidates_success() async throws {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let candidates = [
            Candidate(id: UUID(), firstName: "John", lastName: "Doe", email: "john@example.com", isFavorite: false),
            Candidate(id: UUID(), firstName: "Jane", lastName: "Smith", email: "jane@example.com", isFavorite: true),
            Candidate(id: UUID(), firstName: "Bob", lastName: "Johnson", email: "bob@example.com", isFavorite: false)
        ]
        
        let responseData = try JSONEncoder().encode(candidates)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 3)
        XCTAssertEqual(viewModel.candidateCount, 3)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.candidates[0].firstName, "John")
        XCTAssertEqual(viewModel.candidates[1].firstName, "Jane")
        XCTAssertEqual(viewModel.candidates[2].firstName, "Bob")
    }
    
    func test_fetchAllCandidates_fails_when_not_logged_in() async {
        // Given - no token in keychain (not logged in)
        await mockKeychainService.clearToken()
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(errorMessage.contains("No authentication token"))
        }
    }
    
    func test_fetchAllCandidates_handles_empty_list() async throws {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let candidates: [Candidate] = []
        let responseData = try JSONEncoder().encode(candidates)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 0)
        XCTAssertEqual(viewModel.candidateCount, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_fetchAllCandidates_handles_api_error() async {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let errorResponse = """
        { "error": true, "reason": "Internal Server Error" }
        """.data(using: .utf8)!
        
        mockSession.data = errorResponse
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(
                errorMessage.lowercased().contains("server error") ||
                errorMessage.contains("Internal Server Error")
            )
        }
    }
    
    func test_fetchAllCandidates_handles_400_bad_request() async {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let errorResponse = """
        { "error": true, "reason": "Invalid request parameters" }
        """.data(using: .utf8)!
        
        mockSession.data = errorResponse
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(
                errorMessage.contains("Invalid request parameters") ||
                errorMessage.lowercased().contains("bad request")
            )
        }
    }
    
    func test_fetchAllCandidates_handles_404_not_found() async {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let errorResponse = """
        { "error": true, "reason": "Candidates endpoint not found" }
        """.data(using: .utf8)!
        
        mockSession.data = errorResponse
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(
                errorMessage.lowercased().contains("not found") ||
                errorMessage.contains("Candidates endpoint not found")
            )
        }
    }
    
    func test_fetchAllCandidates_handles_network_error() async {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        // Simulate network error by providing no response
        mockSession.response = nil
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func test_fetchAllCandidates_sets_loading_state() async throws {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let candidates = [
            Candidate(id: UUID(), firstName: "John", lastName: "Doe", email: "john@example.com", isFavorite: false)
        ]
        
        let responseData = try JSONEncoder().encode(candidates)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let fetchTask = Task {
            await viewModel.fetchAllCandidates()
        }
        
        // Give it a moment to set loading state
        try await Task.sleep(nanoseconds: 1_000)
        
        // Then (while loading, isLoading should be true or false depending on timing)
        await fetchTask.value
        
        // After fetch, isLoading should be false
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.candidates.count, 1)
    }
    
    func test_candidateCount_computed_property() async throws {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let candidates = [
            Candidate(id: UUID(), firstName: "John", lastName: "Doe", email: "john@example.com", isFavorite: false),
            Candidate(id: UUID(), firstName: "Jane", lastName: "Smith", email: "jane@example.com", isFavorite: false),
            Candidate(id: UUID(), firstName: "Bob", lastName: "Johnson", email: "bob@example.com", isFavorite: false)
        ]
        
        let responseData = try JSONEncoder().encode(candidates)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidateCount, 3)
    }
    
    func test_fetchAllCandidates_clears_previous_error() async throws {
        // Given - first call with error
        await mockKeychainService.clearToken()
        await viewModel.fetchAllCandidates()
        XCTAssertNotNil(viewModel.errorMessage)
        
        // Given - second call with valid token and success
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let candidates = [
            Candidate(id: UUID(), firstName: "John", lastName: "Doe", email: "john@example.com", isFavorite: false)
        ]
        
        let responseData = try JSONEncoder().encode(candidates)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.fetchAllCandidates()
        
        // Then - error should be cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.candidates.count, 1)
    }
}
