//
//  CandidateListViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

/// ViewModel for managing candidate list (simplified version without filters or modifications)
@Observable
final class CandidateListViewModel {
    // MARK: - Properties
    
    /// List of all candidates fetched from backend
    private(set) var candidates: [Candidate] = []
    
    /// Loading state
    private(set) var isLoading: Bool = false
    
    /// Error state
    private(set) var errorMessage: String?
    
    /// Backend service for API calls
    private let backendService: CandidateBackendService
    
    // MARK: - Init
    
    init(backendService: CandidateBackendService = CandidateBackendService()) {
        self.backendService = backendService
    }
    
    // MARK: - Computed Properties
    
    /// Number of candidates
    var candidateCount: Int {
        candidates.count
    }
    
    // MARK: - Public Methods
    
    /// Fetch all candidates from backend
    func fetchAllCandidates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedCandidates = try await backendService.fetchAllCandidates()
            self.candidates = fetchedCandidates
        } catch let error as APIError {
            errorMessage = error.errorDescription
            candidates = []
        } catch {
            errorMessage = "An unexpected error occurred"
            candidates = []
        }
        
        isLoading = false
    }
}
