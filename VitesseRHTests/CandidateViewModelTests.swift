//
//  CandidateViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 10/02/2026.
//

import XCTest
@testable import VitesseRH

final class CandidateViewModelTests: XCTestCase {
    
    var viewModel: CandidateViewModel!
    var mockSession: MockURLSession!
    var mockKeychainService: MockKeychainService!
    var mockApiService: APIService!
    var mockBackendService: CandidateBackendService!
    var sampleCandidate: Candidate!
    
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
        
        sampleCandidate = Candidate(
            id: UUID(),
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            phone: "0601020304",
            linkedinURL: "https://linkedin.com/in/johndoe",
            note: "Great candidate",
            isFavorite: false
        )
        
        viewModel = CandidateViewModel(candidate: sampleCandidate, backendService: mockBackendService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockSession = nil
        mockApiService = nil
        mockKeychainService = nil
        mockBackendService = nil
        sampleCandidate = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initial_state() {
        // Then
        XCTAssertEqual(viewModel.candidate.firstName, "John")
        XCTAssertEqual(viewModel.candidate.lastName, "Doe")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Refresh Candidate Tests
    
    func test_refreshCandidate_success() async throws {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let updatedCandidate = Candidate(
            id: sampleCandidate.id,
            firstName: "John",
            lastName: "Doe",
            email: "john.updated@example.com",
            phone: "0602020304",
            linkedinURL: "https://linkedin.com/in/johndoe",
            note: "Updated note",
            isFavorite: true
        )
        
        let responseData = try JSONEncoder().encode(updatedCandidate)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(sampleCandidate.id.uuidString)")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.refreshCandidate()
        
        // Then
        XCTAssertEqual(viewModel.candidate.email, "john.updated@example.com")
        XCTAssertEqual(viewModel.candidate.phone, "0602020304")
        XCTAssertEqual(viewModel.candidate.note, "Updated note")
        XCTAssertTrue(viewModel.candidate.isFavorite)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_refreshCandidate_without_token_sets_unauthorized_error() async {
        // Given - no token in keychain
        await mockKeychainService.clearToken()
        
        // When
        await viewModel.refreshCandidate()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(
                errorMessage.lowercased().contains("token") ||
                errorMessage.lowercased().contains("unauthorized") ||
                errorMessage.contains("No authentication token available")
            )
        }
    }
    
    func test_refreshCandidate_handles_api_error() async {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let errorResponse = """
        { "error": true, "reason": "Candidate not found" }
        """.data(using: .utf8)!
        
        mockSession.data = errorResponse
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(sampleCandidate.id.uuidString)")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.refreshCandidate()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(
                errorMessage.contains("Candidate not found") ||
                errorMessage.lowercased().contains("not found")
            )
        }
    }
    
    // MARK: - Toggle Favorite Tests
    
    func test_toggleFavorite_success() async throws {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let initialFavoriteStatus = viewModel.candidate.isFavorite
        
        let updatedCandidate = Candidate(
            id: sampleCandidate.id,
            firstName: sampleCandidate.firstName,
            lastName: sampleCandidate.lastName,
            email: sampleCandidate.email,
            phone: sampleCandidate.phone,
            linkedinURL: sampleCandidate.linkedinURL,
            note: sampleCandidate.note,
            isFavorite: !initialFavoriteStatus
        )
        
        let responseData = try JSONEncoder().encode(updatedCandidate)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(sampleCandidate.id.uuidString)/favorite")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.toggleFavorite()
        
        // Then
        XCTAssertEqual(viewModel.candidate.isFavorite, !initialFavoriteStatus)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_toggleFavorite_without_token_sets_error() async {
        // Given - no token
        await mockKeychainService.clearToken()
        
        // When
        await viewModel.toggleFavorite()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(
                errorMessage.lowercased().contains("token") ||
                errorMessage.lowercased().contains("unauthorized")
            )
        }
    }
    
    func test_toggleFavorite_handles_api_error() async {
        // Given
        let token = "test_token"
        await mockKeychainService.setToken(token)
        
        let errorResponse = """
        { "error": true, "reason": "Server error" }
        """.data(using: .utf8)!
        
        mockSession.data = errorResponse
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(sampleCandidate.id.uuidString)/favorite")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await viewModel.toggleFavorite()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        
        if let errorMessage = viewModel.errorMessage {
            XCTAssertTrue(
                errorMessage.lowercased().contains("server error") ||
                errorMessage.lowercased().contains("error")
            )
        }
    }
}
