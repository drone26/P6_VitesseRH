//
//  AppViewModelTests.swift
//  VitesseRHTests
//
//  Created by Mathieu ARRIO on 09/02/2026.
//

import XCTest
@testable import VitesseRH

final class AppViewModelTests: XCTestCase {
    
    var viewModel: AppViewModel!
    var mockSession: MockURLSession!
    var backendService: CandidateBackendService!
    
    override func setUp() {
        super.setUp()
        // 1. Setup Mock Session
        mockSession = MockURLSession()
        
        // 2. Setup Service
        let apiService = APIService(session: mockSession)
        backendService = CandidateBackendService(apiService: apiService)
        
        // 3. Init ViewModel with injected service
        viewModel = AppViewModel(backendService: backendService)
    }
    
    override func tearDown() {
        viewModel = nil
        backendService = nil
        mockSession = nil
        super.tearDown()
    }
        
    // MARK: - ViewModel Provider Tests
    
    func test_provides_candidateViewModel() {
        // When
        let candidate = Candidate(id: UUID(), firstName: "Test", lastName: "User", email: "test@user.com", phone: nil, linkedinURL: nil, note: nil, isFavorite: false)
        
        // Given
        let candidateVM = viewModel.candidateViewModel(candidate: candidate)
        
        // Then
        XCTAssertNotNil(candidateVM)
        XCTAssertEqual(candidateVM.candidate.id, candidate.id)
    }
    
    func test_provides_candidateEditDetailViewModel() {
        // When
        let candidate = Candidate(id: UUID(), firstName: "Edit", lastName: "Me", email: "edit@me.com", phone: "123", linkedinURL: nil, note: nil, isFavorite: true)
        
        // Given
        let editDetailVM = viewModel.candidateEditDetailViewModel(candidate: candidate)
        
        // Then
        XCTAssertNotNil(editDetailVM)
        XCTAssertEqual(editDetailVM.email, "edit@me.com")
        XCTAssertEqual(editDetailVM.phone, "123")
    }
}
