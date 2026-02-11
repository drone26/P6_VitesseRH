//
//  CandidateBackendServiceTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 10/02/2026.
//

import XCTest
@testable import VitesseRH

final class CandidateBackendServiceTests: XCTestCase {
    
    var service: CandidateBackendService!
    var mockSession: MockURLSession!
    var mockKeychainService: MockKeychainService!
    var mockApiService: APIService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        mockApiService = APIService(session: mockSession)
        mockKeychainService = MockKeychainService()
        service = CandidateBackendService(
            apiService: mockApiService,
            keychainService: mockKeychainService
        )
    }
    
    override func tearDown() {
        service = nil
        mockSession = nil
        mockApiService = nil
        mockKeychainService = nil
        super.tearDown()
    }
    
    // MARK: - User Authentication Tests
    
    func test_userAuthenticate_saves_token_to_keychain() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"
        let expectedToken = "auth_token_12345"
        
        let responseData = try JSONEncoder().encode(
            UserAuthenticationResponse(token: expectedToken, isAdmin: true)
        )
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/user/auth")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        try await service.userAuthenticate(email: email, password: password)
        
        // Then
        let savedToken = try await mockKeychainService.getToken()
        let isAdmin = await service.isAdmin
        XCTAssertEqual(savedToken, expectedToken)
        XCTAssertEqual(isAdmin, true)
    }
    
    func test_userAuthenticate_with_non_admin_user() async throws {
        // Given
        let email = "user@example.com"
        let password = "password123"
        let expectedToken = "user_token_xyz"
        
        let responseData = try JSONEncoder().encode(
            UserAuthenticationResponse(token: expectedToken, isAdmin: false)
        )
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/user/auth")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        try await service.userAuthenticate(email: email, password: password)
        
        // Then
        let savedToken = try await mockKeychainService.getToken()
        let isAdmin = await service.isAdmin
        XCTAssertEqual(savedToken, expectedToken)
        XCTAssertEqual(isAdmin, false)
    }
    
    func test_userAuthenticate_failure_does_not_save_token() async throws {
        // Given
        let email = "wrong@example.com"
        let password = "wrongpassword"
        
        let errorResponse = """
        { "error": true, "reason": "Invalid credentials" }
        """.data(using: .utf8)!
        
        mockSession.data = errorResponse
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/user/auth")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When / Then
        do {
            try await service.userAuthenticate(email: email, password: password)
            XCTFail("Should throw error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unAuthorized(reason: "Invalid credentials"))
            let savedToken = try await mockKeychainService.getToken()
            XCTAssertNil(savedToken)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Fetch All Candidates Tests
    
    func test_fetchAllCandidates_retrieves_token_from_keychain() async throws {
        // Given
        let token = "test_token_123"
        await mockKeychainService.setToken(token)
        
        let candidates = [
            Candidate(id: UUID(), firstName: "John", lastName: "Doe", email: "john@example.com", isFavorite: false),
            Candidate(id: UUID(), firstName: "Jane", lastName: "Smith", email: "jane@example.com", isFavorite: true)
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
        let result = try await service.fetchAllCandidates()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].firstName, "John")
        XCTAssertEqual(result[1].firstName, "Jane")
        
        // Verify token was used in request
        let request = mockSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
    }
    
    func test_fetchAllCandidates_fails_when_not_logged_in() async {
        // Given - no token in keychain (not logged in)
        await mockKeychainService.clearToken()
        
        // When / Then
        do {
            _ = try await service.fetchAllCandidates()
            XCTFail("Should throw error when not logged in")
        } catch let error as APIError {
            XCTAssertEqual(error, .unAuthorized(reason: "No authentication token available"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Fetch Single Candidate Tests
    
    func test_fetchCandidate_retrieves_token_from_keychain() async throws {
        // Given
        let token = "test_token_456"
        await mockKeychainService.setToken(token)
        
        let candidateId = UUID()
        let candidate = Candidate(
            id: candidateId,
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            isFavorite: false
        )
        
        let responseData = try JSONEncoder().encode(candidate)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(candidateId.uuidString)")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await service.fetchCandidate(candidateId: candidateId)
        
        // Then
        XCTAssertEqual(result.id, candidateId)
        XCTAssertEqual(result.firstName, "John")
        
        // Verify token was used
        let request = mockSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
    }
    
    func test_fetchCandidate_fails_when_no_token() async {
        // Given
        await mockKeychainService.clearToken()
        let candidateId = UUID()
        
        // When / Then
        do {
            _ = try await service.fetchCandidate(candidateId: candidateId)
            XCTFail("Should throw error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unAuthorized(reason: "No authentication token available"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Create Candidate Tests
    
    func test_createCandidate_retrieves_token_from_keychain() async throws {
        // Given
        let token = "test_token_789"
        await mockKeychainService.setToken(token)
        
        let candidateRequest = CandidateRequest(
            firstName: "Bob",
            lastName: "Johnson",
            email: "bob@example.com",
            phone: "123-456-7890",
            linkedinURL: nil,
            note: nil
        )
        
        let createdCandidate = Candidate(
            id: UUID(),
            firstName: "Bob",
            lastName: "Johnson",
            email: "bob@example.com",
            isFavorite: false
        )
        
        let responseData = try JSONEncoder().encode(createdCandidate)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await service.createCandidate(candidateRequest: candidateRequest)
        
        // Then
        XCTAssertEqual(result.firstName, "Bob")
        XCTAssertEqual(result.lastName, "Johnson")
        
        // Verify token was used
        let request = mockSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
    }
    
    func test_createCandidate_fails_when_no_token() async {
        // Given
        await mockKeychainService.clearToken()
        
        let candidateRequest = CandidateRequest(
            firstName: "Bob",
            lastName: "Johnson",
            email: "bob@example.com",
            phone: nil,
            linkedinURL: nil,
            note: nil
        )
        
        // When / Then
        do {
            _ = try await service.createCandidate(candidateRequest: candidateRequest)
            XCTFail("Should throw error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unAuthorized(reason: "No authentication token available"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Update Candidate Tests
    
    func test_updateCandidate_retrieves_token_from_keychain() async throws {
        // Given
        let token = "test_token_update"
        await mockKeychainService.setToken(token)
        
        let candidateId = UUID()
        let candidateRequest = CandidateRequest(
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            phone: "987-654-3210",
            linkedinURL: "https://linkedin.com/in/johndoe",
            note: "Updated note"
        )
        
        let updatedCandidate = Candidate(
            id: candidateId,
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            phone: "987-654-3210",
            linkedinURL: "https://linkedin.com/in/johndoe",
            note: "Updated note",
            isFavorite: false
        )
        
        let responseData = try JSONEncoder().encode(updatedCandidate)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(candidateId.uuidString)")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await service.updateCandidate(candidateId: candidateId, candidateRequest: candidateRequest)
        
        // Then
        XCTAssertEqual(result.phone, "987-654-3210")
        XCTAssertEqual(result.note, "Updated note")
        
        // Verify token was used
        let request = mockSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
    }
    
    func test_updateCandidate_fails_when_no_token() async {
        // Given
        await mockKeychainService.clearToken()
        
        let candidateId = UUID()
        let candidateRequest = CandidateRequest(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            phone: nil,
            linkedinURL: nil,
            note: nil
        )
        
        // When / Then
        do {
            _ = try await service.updateCandidate(candidateId: candidateId, candidateRequest: candidateRequest)
            XCTFail("Should throw error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unAuthorized(reason: "No authentication token available"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Delete Candidate Tests
    
    func test_deleteCandidate_retrieves_token_from_keychain() async throws {
        // Given
        let token = "test_token_delete"
        await mockKeychainService.setToken(token)
        
        let candidateId = UUID()
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(candidateId.uuidString)")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        try await service.deleteCandidate(candidateId: candidateId)
        
        // Then
        // Verify token was used
        let request = mockSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
    }
    
    func test_deleteCandidate_fails_when_no_token() async {
        // Given
        await mockKeychainService.clearToken()
        let candidateId = UUID()
        
        // When / Then
        do {
            try await service.deleteCandidate(candidateId: candidateId)
            XCTFail("Should throw error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unAuthorized(reason: "No authentication token available"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Toggle Favorite Tests
    
    func test_toogleCandidateFavoriteStatus_retrieves_token_from_keychain() async throws {
        // Given
        let token = "test_token_favorite"
        await mockKeychainService.setToken(token)
        
        let candidateId = UUID()
        let favoriteCandidate = Candidate(
            id: candidateId,
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@example.com",
            isFavorite: true
        )
        
        let responseData = try JSONEncoder().encode(favoriteCandidate)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com/candidate/\(candidateId.uuidString)/favorite")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await service.toogleCandidateFavoriteStatus(candidateId: candidateId)
        
        // Then
        XCTAssertEqual(result.isFavorite, true)
        
        // Verify token was used
        let request = mockSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
    }
    
    func test_toogleCandidateFavoriteStatus_fails_when_no_token() async {
        // Given
        await mockKeychainService.clearToken()
        let candidateId = UUID()
        
        // When / Then
        do {
            _ = try await service.toogleCandidateFavoriteStatus(candidateId: candidateId)
            XCTFail("Should throw error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unAuthorized(reason: "No authentication token available"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}


