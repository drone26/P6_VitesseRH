//
//  CandidateEditViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

@Observable
@MainActor final class CandidateEditViewModel {
    // MARK: - Properties
    
    private(set) var candidates: [Candidate] = []
    var selectedIds: Set<UUID> = []
    
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    
    private let backendService: CandidateBackendService
    
    // MARK: - Init
    
    init(backendService: CandidateBackendService) {
        self.backendService = backendService
    }
    
    // MARK: - Computed Properties
    
    var hasSelection: Bool {
        !selectedIds.isEmpty
    }
    
    // MARK: - Public Methods
    
    /// Fetches candidates to populate the list
    func fetchCandidates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.candidates = try await backendService.fetchAllCandidates()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    /// Toggles selection of a candidate
    func toggleSelection(for candidateId: UUID) {
        if selectedIds.contains(candidateId) {
            selectedIds.remove(candidateId)
        } else {
            selectedIds.insert(candidateId)
        }
    }
    
    /// Deletes the selected candidates
    func deleteSelectedCandidates() async {
        isLoading = true
        errorMessage = nil
        
        // We iterate through selected IDs and delete them one by one
        // In a real production app, a bulk delete endpoint would be better
        for id in selectedIds {
            do {
                try await backendService.deleteCandidate(candidateId: id)
                // Remove from local list upon success
                if let index = candidates.firstIndex(where: { $0.id == id }) {
                    candidates.remove(at: index)
                }
            } catch {
                print("Failed to delete candidate \(id)")
                // We continue trying to delete others even if one fails
            }
        }
        
        // Clear selection after deletion loop
        selectedIds.removeAll()
        isLoading = false
    }
}
