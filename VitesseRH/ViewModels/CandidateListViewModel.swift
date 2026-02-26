//
//  CandidateListViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

/// ViewModel for managing candidate list
@Observable
@MainActor final class CandidateListViewModel {
    // MARK: - Properties
    
    /// List of all candidates fetched from backend
    private(set) var candidates: [Candidate] = []
    
    /// Search text filter
    var searchText: String = ""
    
    /// Show favorites only filter
    var showFavoritesOnly: Bool = false
    
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
    
    /// Filtered candidates based on search text and favorites filter
    var filteredCandidates: [Candidate] {
        candidates.filter {
            (searchText.isEmpty ||
             $0.firstName.localizedCaseInsensitiveContains(searchText) ||
             $0.lastName.localizedCaseInsensitiveContains(searchText)) &&
            (!showFavoritesOnly || $0.isFavorite)
        }
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
