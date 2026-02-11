//
//  CandidateEditViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

final class CandidateEditViewModelTests: XCTestCase {
    
    var viewModel: CandidateEditViewModel!
    var mockSession: MockURLSession!
    var backendService: CandidateBackendService!
    
    override func setUp() async throws {
        // 1. Setup Mock Session
        mockSession = MockURLSession()
        
        // 2. Setup Service Chain
        let apiService = APIService(session: mockSession)
        backendService = CandidateBackendService(apiService: apiService)
        
        // 3. Authenticate to ensure the service has a token
        let authResponse = UserAuthenticationResponse(token: "mock-token", isAdmin: false)
        mockSession.data = try JSONEncoder().encode(authResponse)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        try await backendService.userAuthenticate(email: "a", password: "b")
        
        // 4. Init ViewModel
        viewModel = CandidateEditViewModel(backendService: backendService)
    }
    
    override func tearDown() {
        viewModel = nil
        backendService = nil
        mockSession = nil
    }

    // MARK: - Selection Logic Tests
    
    func test_toggleSelection_manages_ids_and_computed_property() {
        let id1 = UUID()
        let id2 = UUID()
        
        // 1. Select first ID
        viewModel.toggleSelection(for: id1)
        XCTAssertTrue(viewModel.selectedIds.contains(id1))
        XCTAssertEqual(viewModel.selectedIds.count, 1)
        XCTAssertTrue(viewModel.hasSelection)
        
        // 2. Select second ID
        viewModel.toggleSelection(for: id2)
        XCTAssertTrue(viewModel.selectedIds.contains(id2))
        XCTAssertEqual(viewModel.selectedIds.count, 2)
        
        // 3. Toggle first ID (Deselect)
        viewModel.toggleSelection(for: id1)
        XCTAssertFalse(viewModel.selectedIds.contains(id1))
        XCTAssertTrue(viewModel.selectedIds.contains(id2))
        XCTAssertEqual(viewModel.selectedIds.count, 1)
        XCTAssertTrue(viewModel.hasSelection)
        
        // 4. Toggle second ID (Deselect all)
        viewModel.toggleSelection(for: id2)
        XCTAssertTrue(viewModel.selectedIds.isEmpty)
        XCTAssertFalse(viewModel.hasSelection)
    }
    
    // MARK: - Fetch Candidates Tests
    
    func test_fetchCandidates_success_populates_list() async throws {
        // When
        let candidates = [
            Candidate(id: UUID(), firstName: "A", lastName: "B", email: "a@b.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        ]
        mockSession.data = try JSONEncoder().encode(candidates)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        await viewModel.fetchCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 1)
        XCTAssertEqual(viewModel.candidates.first?.firstName, "A")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_fetchCandidates_api_error_sets_errorMessage() async throws {
        // When (Error http code 500)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        // Given
        await viewModel.fetchCandidates()
        
        // Then
        XCTAssertTrue(viewModel.candidates.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage) // "Server error: 500"
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_fetchCandidates_generic_error_sets_default_message() async throws {
        // When (Network Error)
        mockSession.error = NSError(domain: "Test", code: -1, userInfo: nil)
        
        // Given
        await viewModel.fetchCandidates()
        
        // Then
        XCTAssertTrue(viewModel.candidates.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "An unexpected error occurred")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Delete Logic Tests
    
    func test_deleteSelectedCandidates_success_removes_items() async throws {
        // When
        let idToKeep = UUID()
        let idToDelete = UUID()
        let candidates = [
            Candidate(id: idToKeep, firstName: "Keep", lastName: "Me", email: "k@m.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false),
            Candidate(id: idToDelete, firstName: "Delete", lastName: "Me", email: "d@m.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        ]
        
        // Load data into ViewModel
        mockSession.data = try JSONEncoder().encode(candidates)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        await viewModel.fetchCandidates()
        
        // Select Item
        viewModel.toggleSelection(for: idToDelete)
        
        // Prepare Delete Response (Success Void)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        await viewModel.deleteSelectedCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 1)
        XCTAssertEqual(viewModel.candidates.first?.id, idToKeep)
        XCTAssertTrue(viewModel.selectedIds.isEmpty) // Selection should be cleared
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_deleteSelectedCandidates_failure_keeps_item_in_list() async throws {
        // When : Setup Data
        let idToDelete = UUID()
        let candidates = [
            Candidate(id: idToDelete, firstName: "Delete", lastName: "Me", email: "d@m.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        ]
        
        mockSession.data = try JSONEncoder().encode(candidates)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        await viewModel.fetchCandidates()
        
        // When : Select Item
        viewModel.toggleSelection(for: idToDelete)
        
        // When : Prepare Delete Response (Failure 500)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        // Given
        await viewModel.deleteSelectedCandidates()
        
        // Then
        XCTAssertEqual(viewModel.candidates.count, 1, "Candidate should remain in list on failure")
        XCTAssertTrue(viewModel.candidates.contains(where: { $0.id == idToDelete }))
        XCTAssertTrue(viewModel.selectedIds.isEmpty, "Selection is cleared even if operation fails (per current implementation)")
        XCTAssertFalse(viewModel.isLoading)
    }
}
