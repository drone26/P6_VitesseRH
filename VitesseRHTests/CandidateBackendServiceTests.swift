//
//  CandidateBackendServiceTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

final class CandidateBackendServiceTests: XCTestCase {
    
    var service: CandidateBackendService!
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        // 1. Setup Mock Session
        mockSession = MockURLSession()
        
        // 2. Inject into APIService
        let apiService = APIService(session: mockSession)
        
        // 3. Inject into BackendService
        service = CandidateBackendService(apiService: apiService)
    }
    
    override func tearDown() {
        service = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func performLogin() async throws {
        let authResponse = UserAuthenticationResponse(token: "test_token_123", isAdmin: true)
        let data = try JSONEncoder().encode(authResponse)
        
        mockSession.data = data
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/user/auth")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        try await service.userAuthenticate(email: "admin@test.com", password: "password")
    }
    
    // MARK: - Authentication Tests
    
    func test_userAuthenticate_success_sets_token_and_admin() async throws {
        // When
        let expectedToken = "token_abc"
        let expectedAdmin = true
        let responseObj = UserAuthenticationResponse(token: expectedToken, isAdmin: expectedAdmin)
        mockSession.data = try JSONEncoder().encode(responseObj)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        try await service.userAuthenticate(email: "test@test.com", password: "123")
        
        // Then
        let token = await service.token
        let isAdmin = await service.isAdmin
        XCTAssertEqual(token, expectedToken)
        XCTAssertEqual(isAdmin, expectedAdmin)
        
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/user/auth")
    }
    
    func test_userAuthenticate_failure_throws_error() async {
        // When (401 Unauthorized)
        let errorBody = BackendErrorResponse(error: true, reason: "Bad credentials")
        mockSession.data = try! JSONEncoder().encode(errorBody)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.userAuthenticate(email: "bad", password: "bad")
            XCTFail("Should throw error")
        } catch let error as APIError {
            // APIService maps 401 to .unAuthorized containing the reason
            XCTAssertEqual(error.errorDescription, "Bad credentials")
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    // MARK: - Registration Tests
    
    func test_userRegister_success() async throws {
        // When
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        try await service.userRegister(firstName: "John", lastName: "Doe", email: "j@d.com", password: "pass")
        
        // Then
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/user/register")
        
        let bodyData = mockSession.lastRequest?.httpBody
        let decodedBody = try JSONDecoder().decode(UserRegisterRequest.self, from: bodyData!)
        XCTAssertEqual(decodedBody.firstName, "John")
    }
    
    func test_userRegister_failure() async {
        // When (400 Bad Request)
        mockSession.data = try! JSONEncoder().encode(BackendErrorResponse(error: true, reason: "Email exists"))
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.userRegister(firstName: "J", lastName: "D", email: "e", password: "p")
            XCTFail("Should fail")
        } catch let error as APIError {
            XCTAssertEqual(error.errorDescription, "Email exists") // mapped to .badRequest
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    // MARK: - Fetch All Candidates Tests
    
    func test_fetchAllCandidates_no_token_throws_unauthorized() async {
        // When / Given / Then (Skip login)
        do {
            _ = try await service.fetchAllCandidates()
            XCTFail("Should fail without token")
        } catch let error as APIError {
            XCTAssertEqual(error.errorDescription, "No authentication token available")
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func test_fetchAllCandidates_success() async throws {
        // When
        try await performLogin()
        
        let candidates = [
            Candidate(id: UUID(), firstName: "A", lastName: "B", email: "a@b.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        ]
        mockSession.data = try JSONEncoder().encode(candidates)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        let result = try await service.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "GET")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test_token_123")
    }
    
    // MARK: - Fetch Single Candidate Tests
    
    func test_fetchCandidate_success() async throws {
        // When
        try await performLogin()
        let id = UUID()
        let candidate = Candidate(id: id, firstName: "A", lastName: "B", email: "a@b.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        
        mockSession.data = try JSONEncoder().encode(candidate)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        let result = try await service.fetchCandidate(candidateId: id)
        
        // Then
        XCTAssertEqual(result.id, id)
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/candidate/\(id.uuidString)")
    }
    
    // MARK: - Create Candidate Tests
    
    func test_createCandidate_success() async throws {
        // When
        try await performLogin()
        let request = CandidateRequest(firstName: "New", lastName: "Guy", email: "new@guy.com", phone: nil, linkedinURL: nil, note: nil)
        let responseCand = Candidate(id: UUID(), firstName: "New", lastName: "Guy", email: "new@guy.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        
        mockSession.data = try JSONEncoder().encode(responseCand)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 201, httpVersion: nil, headerFields: nil)
        
        // Given
        let result = try await service.createCandidate(candidateRequest: request)
        
        // Then
        XCTAssertEqual(result.firstName, "New")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        
        let sentData = mockSession.lastRequest?.httpBody
        let decoded = try JSONDecoder().decode(CandidateRequest.self, from: sentData!)
        XCTAssertEqual(decoded.email, "new@guy.com")
    }
    
    func test_createCandidate_no_token_throws_unauthorized() async {
        // When (skip login)
        let request = CandidateRequest(
            firstName: "John",
            lastName: "Doe",
            email: "john@test.com",
            phone: nil,
            linkedinURL: nil,
            note: nil
        )
        
        // Given / Then
        do {
            _ = try await service.createCandidate(candidateRequest: request)
            XCTFail("Should have thrown unAuthorized error because token is nil")
        } catch let error as APIError {
            // Assert
            // This verifies the specific error thrown when token is nil
            XCTAssertEqual(error.errorDescription, "No authentication token available")
            
            // Verify it is the correct enum case
            if case .unAuthorized(let reason) = error {
                XCTAssertEqual(reason, "No authentication token available")
            } else {
                XCTFail("Error should be .unAuthorized")
            }
        } catch {
            XCTFail("Thrown error was not an APIError: \(error)")
        }
    }
    
    // MARK: - Update Candidate Tests
    
    func test_updateCandidate_success() async throws {
        // When
        try await performLogin()
        let id = UUID()
        let request = CandidateRequest(firstName: "Updated", lastName: "Guy", email: "u@g.com", phone: "123", linkedinURL: nil, note: nil)
        let responseCand = Candidate(id: id, firstName: "Updated", lastName: "Guy", email: "u@g.com", phone: "123", linkedinURL: nil, note: nil, isFavorite: false)
        
        mockSession.data = try JSONEncoder().encode(responseCand)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        let result = try await service.updateCandidate(candidateId: id, candidateRequest: request)
        
        // Then
        XCTAssertEqual(result.phone, "123")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "PUT")
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/candidate/\(id.uuidString)")
    }
    
    func test_updateCandidate_no_token_throws_unauthorized() async {
        // When (skip login)
        let id = UUID()
        let request = CandidateRequest(
            firstName: "Updated",
            lastName: "Name",
            email: "updated@test.com",
            phone: nil,
            linkedinURL: nil,
            note: nil
        )
        
        // Given / Then
        do {
            _ = try await service.updateCandidate(candidateId: id, candidateRequest: request)
            XCTFail("Should have thrown unAuthorized error because token is nil")
        } catch let error as APIError {
            // Assert
            XCTAssertEqual(error.errorDescription, "No authentication token available")
            
            // Verify it is the correct enum case
            if case .unAuthorized(let reason) = error {
                XCTAssertEqual(reason, "No authentication token available")
            } else {
                XCTFail("Error should be .unAuthorized")
            }
        } catch {
            XCTFail("Thrown error was not an APIError: \(error)")
        }
    }
    
    // MARK: - Delete Candidate Tests
    
    func test_deleteCandidate_success() async throws {
        // When
        try await performLogin()
        let id = UUID()
        
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        try await service.deleteCandidate(candidateId: id)
        
        // Then
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "DELETE")
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/candidate/\(id.uuidString)")
    }
    
    func test_deleteCandidate_no_token_throws_unauthorized() async {
        // When
        let id = UUID()
        // No login performed
        
        // Given / Then
        do {
            try await service.deleteCandidate(candidateId: id)
            XCTFail("Should have thrown unAuthorized error because token is nil")
        } catch let error as APIError {
            // Assert
            XCTAssertEqual(error.errorDescription, "No authentication token available")
            
            if case .unAuthorized(let reason) = error {
                XCTAssertEqual(reason, "No authentication token available")
            } else {
                XCTFail("Error should be .unAuthorized")
            }
        } catch {
            XCTFail("Thrown error was not an APIError: \(error)")
        }
    }
    
    // MARK: - Toggle Favorite Tests
    
    func test_toggleCandidateFavoriteStatus_success() async throws {
        // When
        try await performLogin()
        let id = UUID()
        // Simulate toggled state in response
        let responseCand = Candidate(id: id, firstName: "Fave", lastName: "Guy", email: "f@g.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: true)
        
        mockSession.data = try JSONEncoder().encode(responseCand)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        let result = try await service.toogleCandidateFavoriteStatus(candidateId: id)
        
        // Then
        XCTAssertTrue(result.isFavorite)
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertTrue(mockSession.lastRequest?.url?.path.hasSuffix("/favorite") ?? false)
    }
    
    func test_toggleCandidateFavoriteStatus_no_token() async {
        // When / Given / Then (Skip login)
        do {
            _ = try await service.toogleCandidateFavoriteStatus(candidateId: UUID())
            XCTFail("Should fail")
        } catch let error as APIError {
            XCTAssertEqual(error.errorDescription, "No authentication token available")
        } catch {
            XCTFail("Wrong error")
        }
    }
}
