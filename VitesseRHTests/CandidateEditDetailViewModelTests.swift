//
//  CandidateEditDetailViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

@MainActor
final class CandidateEditDetailViewModelTests: XCTestCase {
    
    var viewModel: CandidateEditDetailViewModel!
    var mockSession: MockURLSession!
    var backendService: CandidateBackendService!
    var sampleCandidate: Candidate!

    override func setUp() async throws {
        // 1. Setup Mock Session
        mockSession = MockURLSession()
        
        // 2. Setup Service Chain
        let apiService = APIService(session: mockSession)
        backendService = CandidateBackendService(apiService: apiService)
        
        // 3. Authenticate (Required by BackendService)
        let authResponse = UserAuthenticationResponse(token: "mock-token", isAdmin: false)
        mockSession.data = try JSONEncoder().encode(authResponse)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        try await backendService.userAuthenticate(email: "a", password: "b")
        
        // 4. Default Candidate
        sampleCandidate = Candidate(id: UUID(), firstName: "Original", lastName: "Name", email: "orig@test.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        viewModel = CandidateEditDetailViewModel(candidate: sampleCandidate, backendService: backendService)
    }
    
    override func tearDown() {
        viewModel = nil
        backendService = nil
        mockSession = nil
        sampleCandidate = nil
    }

    // MARK: - Update Logic Tests

    func testUpdateCandidateSuccess() async throws {
        // When
        viewModel.phone = "123456789"
        
        var updatedCandidate = sampleCandidate!
        updatedCandidate.phone = "123456789"
        
        mockSession.data = try JSONEncoder().encode(updatedCandidate)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        // Given
        let result = try await viewModel.updateCandidate()

        // Then
        XCTAssertEqual(result?.phone, "123456789")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testUpdateCandidate_converts_empty_strings_to_nil_in_request() async throws {
        // When
        viewModel.phone = ""
        viewModel.linkedinURL = ""
        viewModel.note = ""
        
        // Mock Response Success
        mockSession.data = try JSONEncoder().encode(sampleCandidate)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        _ = try await viewModel.updateCandidate()
        
        // Then (Inspect the json body sent to the server)
        guard let requestData = mockSession.lastRequest?.httpBody else {
            XCTFail("No request body sent")
            return
        }
        
        let sentRequest = try JSONDecoder().decode(CandidateRequest.self, from: requestData)
        
        // Verify that empty strings in ViewModel became nil in json
        XCTAssertNil(sentRequest.phone)
        XCTAssertNil(sentRequest.linkedinURL)
        XCTAssertNil(sentRequest.note)
    }
    
    // MARK: - Error Handling Tests
    
    func testUpdateCandidate_api_error_sets_errorMessage() async {
        // When (Simulate Server Error (500))
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            _ = try await viewModel.updateCandidate()
            XCTFail("Should fail with APIError")
        } catch {
            XCTAssertNotNil(viewModel.errorMessage)
            XCTAssertTrue(viewModel.errorMessage?.contains("Server error") ?? false)
            XCTAssertFalse(viewModel.isLoading)
        }
    }
    
    func testUpdateCandidate_generic_error_sets_default_message() async {
        // When (Simulate Network Error (NSError))
        mockSession.error = NSError(domain: "Test", code: -1, userInfo: nil)
        
        // Given / Then
        do {
            _ = try await viewModel.updateCandidate()
            XCTFail("Should fail with generic error")
        } catch {
            XCTAssertEqual(viewModel.errorMessage, "An unexpected error occurred")
            XCTAssertFalse(viewModel.isLoading)
        }
    }
}
