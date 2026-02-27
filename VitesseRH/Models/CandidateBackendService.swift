//
//  CandidateBackendService.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import Foundation

/// Service layer for interacting with the Candidate API backend
actor CandidateBackendService {
    private let apiService: APIService
    private let keychainService: KeychainServiceProtocol
    private(set) var isAdmin: Bool?
    
    init(apiService: APIService = APIService(), keychainService: KeychainServiceProtocol = KeychainService()) {
        self.apiService = apiService
        self.keychainService = keychainService
    }
    
    // MARK: - Endpoint Definitions
    
    /// API Candidate backend Endpoint definitions
    private enum Endpoint: APIEndpoint, Sendable {
        case userAuthenticate(userAuthenticationRequest: UserAuthenticationRequest)
        case userRegister(userRegisterRequest: UserRegisterRequest)
        case fetchCandidates(token: String)
        case fetchCandidate(candidateId: UUID, token: String)
        case createCandidate(candidate: CandidateRequest, token: String)
        case updateCandidate(candidateId: UUID, candidate: CandidateRequest, token: String)
        case deleteCandidate(candidateId: UUID, token: String)
        case toogleCandidateFavoriteStatus(candidateId: UUID, token: String)
        
        var baseURL: URL? {
            return CandidateAPIURL
        }
        
        var path: String {
            switch self {
            case .userAuthenticate:
                return "/user/auth"
            case .userRegister:
                return "/user/register"
            case .fetchCandidates, .createCandidate:
                return "/candidate"
            case .fetchCandidate(let candidateId, _), .updateCandidate(let candidateId, _, _), .deleteCandidate(let candidateId, _):
                return "/candidate/\(candidateId.uuidString)"
            case .toogleCandidateFavoriteStatus(let candidateId, _):
                return "/candidate/\(candidateId.uuidString)/favorite"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .userAuthenticate, .userRegister, .createCandidate, .toogleCandidateFavoriteStatus:
                return .post
            case .fetchCandidates, .fetchCandidate:
                return .get
            case .updateCandidate:
                return .put
            case .deleteCandidate:
                return .delete
            }
        }
        
        var headers: [String: String]? {
            var headers = ["Accept": "application/json"]
            
            switch self {
            case .userAuthenticate, .userRegister:
                break
            case .fetchCandidates(let token), .fetchCandidate(_, let token), .createCandidate(_, let token), .updateCandidate(_ , _, let token), .deleteCandidate(_ , let token), .toogleCandidateFavoriteStatus(_, let token):
                headers["Authorization"] = "Bearer \(token)"
            }
            return headers
        }
        
        var body: (any Encodable & Sendable)? {
            switch self {
            case .userAuthenticate(let userAuthenticationRequest):
                return userAuthenticationRequest
            case .userRegister(let userRegisterRequest):
                return userRegisterRequest
            case .fetchCandidates, .fetchCandidate, .deleteCandidate(_ ,  _), .toogleCandidateFavoriteStatus(_, _):
                return nil
            case .createCandidate(let candidate, _), .updateCandidate(_, let candidate, _):
                return candidate
            }
        }
    }
    
    // MARK: - User Authentication
    
    /// API authentification to get an access Token and a boolean if user is admin or not.
    /// - Parameters:
    ///   - email: email
    ///   - password: password
    ///
    func userAuthenticate(email: String, password: String) async throws {
        let userAuthenticationRequest = UserAuthenticationRequest(email: email, password: password)
        let endpoint = Endpoint.userAuthenticate(userAuthenticationRequest: userAuthenticationRequest)
        
        do {
            let response: UserAuthenticationResponse = try await apiService.request(endpoint)
            self.isAdmin = response.isAdmin
            
            // Save token to Keychain
            try await keychainService.saveToken(response.token)
        } catch let error as APIError {
            throw error
        }
    }
    
    // MARK: - User Register
    
    /// User Register
    func userRegister(firstName: String, lastName: String, email: String, password: String) async throws {
        let userRegisterRequest = UserRegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName)
        let endpoint = Endpoint.userRegister(userRegisterRequest: userRegisterRequest)
        
        do {
            try await apiService.requestVoid(endpoint)
        } catch let error as APIError {
            throw error
        }
    }
    
    // MARK: - Fetch all candidates
    
    /// Fetch all candidates
    func fetchAllCandidates() async throws -> [Candidate] {
        guard let token = try await keychainService.getToken() else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        let endpoint = Endpoint.fetchCandidates(token: token)
        
        return try await apiService.request(endpoint)
    }
    
    // MARK: - Fetch Candidate Detail
    
    /// Fetches details for a single candidate by ID
    func fetchCandidate(candidateId: UUID) async throws -> Candidate {
        guard let token = try await keychainService.getToken() else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        
        let endpoint = Endpoint.fetchCandidate(candidateId: candidateId, token: token)
        
        return try await apiService.request(endpoint)
    }
    
    // MARK: - Create Candidate
    
    /// Creates a new candidate
    /// - Parameter candidateRequest: The candidate details
    /// - Returns: The newly created Candidate object
    func createCandidate(candidateRequest: CandidateRequest) async throws -> Candidate {
        guard let token = try await keychainService.getToken() else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        
        let endpoint = Endpoint.createCandidate(candidate: candidateRequest, token: token)
        
        return try await apiService.request(endpoint)
    }
    
    // MARK: - Update Candidate
    
    /// Updates a candidate
    /// - Parameters:
    ///     candidateId: The candidate uuid
    ///     candidateRequest: The candidate details
    /// - Returns: The updated Candidate object
    func updateCandidate(candidateId: UUID, candidateRequest: CandidateRequest) async throws -> Candidate {
        guard let token = try await keychainService.getToken() else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        
        let endpoint = Endpoint.updateCandidate(candidateId: candidateId, candidate: candidateRequest, token: token)
        
        return try await apiService.request(endpoint)
    }
    
    // MARK: - Delete Candidate
    
    /// Delete a candidate
    /// - Parameter:
    ///     candidateId: The candidate uuid to delete
    func deleteCandidate(candidateId: UUID) async throws {
        guard let token = try await keychainService.getToken() else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        
        let endpoint = Endpoint.deleteCandidate(candidateId: candidateId, token: token)
        
        try await apiService.requestVoid(endpoint)
    }
    
    // MARK: - Toggle favorite status for a Candidate
    
    /// Toggle favorite status for a candidate
    /// - Parameter:
    ///     candidateId: The candidate uuid to have favorite status toggled
    func toogleCandidateFavoriteStatus(candidateId: UUID) async throws -> Candidate {
        guard let token = try await keychainService.getToken() else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        
        let endpoint = Endpoint.toogleCandidateFavoriteStatus(candidateId: candidateId, token: token)
        
        return try await apiService.request(endpoint)
    }
}
