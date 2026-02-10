//
//  CandidateViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

/// ViewModel for managing a single candidate
@Observable
final class CandidateViewModel {
    // MARK: - Properties
    
    /// The candidate being viewed
    private(set) var candidate: Candidate
    
    /// Loading state
    private(set) var isLoading: Bool = false
    
    /// Error state
    private(set) var errorMessage: String?
    
    /// Backend service for API calls
    private let backendService: CandidateBackendService
    
    // MARK: - Init
    
    init(candidate: Candidate, backendService: CandidateBackendService = CandidateBackendService()) {
        self.candidate = candidate
        self.backendService = backendService
    }
    
    // MARK: - Public Methods
    
    /// Refresh candidate details from backend
    func refreshCandidate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let refreshedCandidate = try await backendService.fetchCandidate(candidateId: candidate.id)
            self.candidate = refreshedCandidate
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    /// Toggle favorite status
    func toggleFavorite() async {
        // We do not set global isLoading to avoid blocking the UI for a star toggle
        errorMessage = nil
        
        do {
            let updatedCandidate = try await backendService.toogleCandidateFavoriteStatus(candidateId: candidate.id)
            self.candidate = updatedCandidate
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
    }
}
