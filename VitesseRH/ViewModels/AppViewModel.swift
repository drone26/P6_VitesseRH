//
//  AppViewModel.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import Foundation
import Observation

/// Root ViewModel managing app state and shared services
@Observable
final class AppViewModel {
    // MARK: - Properties
    
    /// Indicates if user is logged in
    var isLogged: Bool = false
    
    /// Shared backend service instance - contains authentication token
    private let sharedBackendService: CandidateBackendService
    
    // MARK: - Init
    
    init(backendService: CandidateBackendService = CandidateBackendService()) {
        self.sharedBackendService = backendService
    }
    
    // MARK: - ViewModel Providers
    
    /// Provides LoginViewModel with shared backend service
    var loginViewModel: UserLoginViewModel {
        UserLoginViewModel(backendService: sharedBackendService)
    }
    
    /// Provides RegisterViewModel with shared backend service
    var userRegisterViewModel: UserRegisterViewModel {
        UserRegisterViewModel(backendService: sharedBackendService)
    }
    
    /// Provides CandidateListViewModel with shared backend service
    var candidateListViewModel: CandidateListViewModel {
        CandidateListViewModel(backendService: sharedBackendService)
    }
    
    /// Provides CandidateViewModel with shared backend service
    func candidateViewModel(candidate: Candidate) -> CandidateViewModel {
        CandidateViewModel(candidate: candidate, backendService: sharedBackendService)
    }
    
    /// Provides CandidateEditDetailViewModel with shared backend service
    func candidateEditDetailViewModel(candidate: Candidate) -> CandidateEditDetailViewModel {
        CandidateEditDetailViewModel(candidate: candidate, backendService: sharedBackendService)
    }
}
