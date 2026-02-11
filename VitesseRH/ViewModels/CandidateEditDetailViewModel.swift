//
//  CandidateEditDetailViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

@Observable
final class CandidateEditDetailViewModel {
    // MARK: - Properties
    
    // Form fields
    var email: String = ""
    var phone: String = ""
    var linkedinURL: String = ""
    var note: String = ""
    
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    
    private let candidateId: UUID
    private let firstName: String
    private let lastName: String
    private let backendService: CandidateBackendService
    
    // MARK: - Init
    
    init(candidate: Candidate, backendService: CandidateBackendService) {
        self.candidateId = candidate.id
        self.firstName = candidate.firstName
        self.lastName = candidate.lastName
        self.backendService = backendService
        
        // Initialize state with current data
        self.email = candidate.email
        self.phone = candidate.phone ?? ""
        self.linkedinURL = candidate.linkedinURL ?? ""
        self.note = candidate.note ?? ""
    }
    
    // MARK: - Public Methods
    
    /// Updates the candidate on the backend
    /// - Returns: The updated Candidate object if successful
    func updateCandidate() async throws -> Candidate? {
        isLoading = true
        errorMessage = nil
        
        let request = CandidateRequest(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            linkedinURL: linkedinURL.isEmpty ? nil : linkedinURL,
            note: note.isEmpty ? nil : note
        )
        
        do {
            let updatedCandidate = try await backendService.updateCandidate(
                candidateId: candidateId,
                candidateRequest: request
            )
            isLoading = false
            return updatedCandidate
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isLoading = false
            throw error
        } catch {
            errorMessage = "An unexpected error occurred"
            isLoading = false
            throw error
        }
    }
}
