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
    private(set) var token: String?
    private(set) var isAdmin: Bool?
    
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    // MARK: - Endpoint Definitions
    
    /// API Candidate backend Endpoint definitions
    private enum Endpoint: APIEndpoint {
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
        
        var body: Encodable? {
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
            self.token = response.token
            self.isAdmin = response.isAdmin
            print("TOKEN: \(self.token!)")
            print("ISADMIN: \(self.isAdmin!)")            
        } catch let error as APIError {
            // Error messages from backend are now captured in the error itself
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
            // Error messages from backend are now captured in the error itself
            throw error
        }
    }
    
    // MARK: - Fetch all candidates
    
    /// Fetch all candidates
    func fetchAllCandidates() async throws -> [Candidate] {
        guard let token = token else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        let endpoint = Endpoint.fetchCandidates(token: token)
        
        return try await apiService.request(endpoint)
    }
    
    // MARK: - Fetch Candidate Detail
    
    /// Fetches details for a single candidate by ID
    func fetchCandidate(candidateId: UUID) async throws -> Candidate {
        guard let token = token else {
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
        guard let token = self.token else {
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
        guard let token = self.token else {
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
        guard let token = self.token else {
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
        guard let token = self.token else {
            throw APIError.unAuthorized(reason: "No authentication token available")
        }
        
        let endpoint = Endpoint.toogleCandidateFavoriteStatus(candidateId: candidateId, token: token)
        
        return try await apiService.request(endpoint)
    }
}

import Playgrounds

#Playground {
    let sharedBackendService: CandidateBackendService
    
    sharedBackendService = CandidateBackendService()
    
    // Test login with bad credentials
    do {
        try await sharedBackendService.userAuthenticate(email: "bob@bob.fr", password: "1234")
        
    } catch let apiError as APIError {
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test login with good credentials
    do {
        try await sharedBackendService.userAuthenticate(email: "admin@vitesse.com", password: "test123")
        
    } catch let apiError as APIError {
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test user register
    do {
        try await sharedBackendService.userRegister(firstName: "Mathieu", lastName: "ARRIO", email: "mathieu@vitesse.com", password: "test1234")
    }
    catch let apiError as APIError {
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test login with good credentials
    do {
        try await sharedBackendService.userAuthenticate(email: "mathieu@vitesse.com", password: "test1234")
    } catch let apiError as APIError {
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test fetch all candidates
    do {
        let candidatesResponse = try await sharedBackendService.fetchAllCandidates()
        print(candidatesResponse)
    } catch let apiError as APIError {
        print("FETCHALLCANDIDATES ERROR")
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test fetch a candidate
    do {
        let candidateResponse = try await sharedBackendService.fetchCandidate(candidateId: UUID(uuidString: "C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2")!)
        print("CANDIDATE (C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2) : \(candidateResponse)")
    } catch let apiError as APIError {
        print("FETCHCANDIDATE ERROR")
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test create a candidate
    var candidateToCreate = CandidateRequest(firstName: "Bob", lastName: "LEPONGE", email: "bob@leponge.fr", phone: nil, linkedinURL: nil, note: nil)
    do {
        let candidateResponse = try await sharedBackendService.createCandidate(candidateRequest: candidateToCreate)
        print(candidateResponse)
    } catch let apiError as APIError {
        print("CREATECANDIDATE ERROR")
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test update a candidate
    candidateToCreate = CandidateRequest(firstName: "Bob", lastName: "LEPONGE", email: "bob@leponge.fr", phone: "0622222222", linkedinURL: nil, note: nil)
    do {
        let candidateResponse = try await sharedBackendService.updateCandidate(candidateId: UUID(uuidString: "469BCC2B-66EA-4991-A00E-6715422624EA")!, candidateRequest: candidateToCreate)
        print(candidateResponse)
    } catch let apiError as APIError {
        print("UPDATECANDIDATE ERROR")
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test delete a candidate
    do {
        try await sharedBackendService.deleteCandidate(candidateId: UUID(uuidString: "F44F4769-BD46-49EE-8F1F-EC3CA619F63C")!)
        
    } catch let apiError as APIError {
        print("DELETECANDIDATE ERROR")
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test toggle favorite status for a candidate (Authentiacted user is not admin)
    do {
        let candidateResponse = try await sharedBackendService.toogleCandidateFavoriteStatus(candidateId: UUID(uuidString: "C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2")!)
        print(candidateResponse)
    } catch let apiError as APIError {
        print("TOGGLE FAVORITE STATUS CANDIDATE ERROR")
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test login with good credentials with an admin user
    do {
        try await sharedBackendService.userAuthenticate(email: "admin@vitesse.com", password: "test123")
    } catch let apiError as APIError {
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }
    
    // Test toggle favorite status for a candidate (Authentiacted user is admin)
    do {
        let candidateResponse = try await sharedBackendService.toogleCandidateFavoriteStatus(candidateId: UUID(uuidString: "C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2")!)
        print(candidateResponse)
    } catch let apiError as APIError {
        print("TOGGLE FAVORITE STATUS CANDIDATE ERROR")
        print(apiError.errorDescription!)
        print(getReadableErrorMessage(apiError))

    }

}

// ============================================================
// HELPER FUNCTION: Convert error to user-friendly message
// ============================================================
func getReadableErrorMessage(_ error: APIError) -> String {
    switch error {
    case .badCredentials(let reason):
        return "❌ Login Failed: \(reason ?? "Invalid credentials")"
    case .unAuthorized(let reason):
        return "🔐 Unauthorized: \(reason ?? "Invalid or expired token")"
    case .badRequest(let reason):
        return "⚠️ Invalid Request: \(reason ?? "Please check your input")"
    case .notFound(let reason):
        return "🔍 Not Found: \(reason ?? "The requested resource doesn't exist")"
    case .serverError(let code, let reason):
        return "⚠️ Server Error (\(code)): \(reason ?? "Please try again later")"
    case .networkError:
        return "📡 Network Error: Check your internet connection"
    case .invalidURL:
        return "🔗 Invalid URL"
    case .decodingFailed:
        return "📦 Failed to process response"
    case .unknown:
        return "❓ Unknown error occurred"
    }
    
}

/*
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
 private(set) var token: String?
 private(set) var isAdmin: Bool?
 
 init(apiService: APIService = APIService()) {
 self.apiService = apiService
 }
 
 // MARK: - Endpoint Definitions
 
 /// API Candidate backend Endpoint definitions
 private enum Endpoint: APIEndpoint {
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
 
 var body: Encodable? {
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
 self.token = response.token
 self.isAdmin = response.isAdmin
 
 print("ISADMIN: \(String(describing: self.isAdmin))")
 } catch let error as APIError {
 // Map HTTP status codes to specific errors
 switch error {
 case .serverError(let statusCode):
 switch statusCode {
 case 400:
 throw APIError.badCredentials
 case 401, 403:
 throw APIError.unAuthorized
 case 500...599:
 throw APIError.serverError(statusCode: statusCode)
 default:
 throw APIError.serverError(statusCode: statusCode)
 }
 case .invalidURL:
 throw APIError.invalidURL
 case .networkError:
 throw APIError.networkError
 case .decodingFailed:
 throw APIError.decodingFailed
 default:
 throw error
 }
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
 // Map HTTP status codes to specific errors
 switch error {
 case .serverError(let statusCode):
 switch statusCode {
 case 400:
 throw APIError.badCredentials
 case 401, 403:
 throw APIError.unAuthorized
 case 500...599:
 throw APIError.serverError(statusCode: statusCode)
 default:
 throw APIError.serverError(statusCode: statusCode)
 }
 case .invalidURL:
 throw APIError.invalidURL
 case .networkError:
 throw APIError.networkError
 case .decodingFailed:
 throw APIError.decodingFailed
 default:
 throw error
 }
 }
 }
 
 // MARK: - Fetch all candidates
 
 /// Fetch all candidates
 func fetchAllCandidates() async throws -> [Candidate] {
 guard let token = token else {
 throw APIError.unknown
 }
 let endpoint = Endpoint.fetchCandidates(token: token)
 
 return try await apiService.request(endpoint)
 }
 
 // MARK: - Fetch Candidate Detail
 
 /// Fetches details for a single candidate by ID
 func fetchCandidate(candidateId: UUID) async throws -> Candidate {
 guard let token = token else {
 throw APIError.unAuthorized
 }
 
 let endpoint = Endpoint.fetchCandidate(candidateId: candidateId, token: token)
 
 do {
 // The response matches the Candidate struct in APIDataModel.swift
 return try await apiService.request(endpoint)
 } catch let error as APIError {
 // Standard error mapping used in your other methods
 switch error {
 case .serverError(let statusCode):
 if statusCode == 401 || statusCode == 403 { throw APIError.unAuthorized }
 throw APIError.serverError(statusCode: statusCode)
 default:
 throw error
 }
 }
 }
 
 // MARK: - Create Candidate
 
 /// Creates a new candidate
 /// - Parameter candidateRequest: The candidate details
 /// - Returns: The newly created Candidate object
 func createCandidate(candidateRequest: CandidateRequest) async throws -> Candidate {
 guard let token = self.token else {
 throw APIError.unAuthorized
 }
 
 let endpoint = Endpoint.createCandidate(candidate: candidateRequest, token: token)
 
 do {
 // The API returns the full Candidate object upon success
 return try await apiService.request(endpoint)
 } catch let error as APIError {
 throw error
 }
 }
 
 // MARK: - Update Candidate
 
 /// Updates a candidate
 /// - Parameters:
 ///     candidateId: The candidate uuid
 ///     candidateRequest: The candidate details
 /// - Returns: The updated Candidate object
 func updateCandidate(candidateId: UUID, candidateRequest: CandidateRequest) async throws -> Candidate {
 guard let token = self.token else {
 throw APIError.unAuthorized
 }
 
 let endpoint = Endpoint.updateCandidate(candidateId: candidateId, candidate: candidateRequest, token: token)
 
 do {
 // The API returns the full Candidate object upon success
 return try await apiService.request(endpoint)
 } catch let error as APIError {
 throw error
 }
 }
 
 // MARK: - Delete Candidate
 
 /// Delete a candidate
 /// - Parameter:
 ///     candidateId: The candidate uuid to delete
 func deleteCandidate(candidateId: UUID) async throws {
 guard let token = self.token else {
 throw APIError.unAuthorized
 }
 
 let endpoint = Endpoint.deleteCandidate(candidateId: candidateId, token: token)
 
 do {
 // The API returns the full Candidate object upon success
 try await apiService.requestVoid(endpoint)
 } catch let error as APIError {
 throw error
 }
 }
 
 // MARK: - Toggle favorite status for a Candidate
 
 /// Delete a candidate
 /// - Parameter:
 ///     candidateId: The candidate uuid to have favorite status toggled
 func toogleCandidateFavoriteStatus(candidateId: UUID) async throws -> Candidate {
 guard let token = self.token else {
 throw APIError.unAuthorized
 }
 
 let endpoint = Endpoint.toogleCandidateFavoriteStatus(candidateId: candidateId, token: token)
 
 do {
 // The API returns the full Candidate object upon success
 return try await apiService.request(endpoint)
 } catch let error as APIError {
 throw error
 }
 }
 }
 
 import Playgrounds
 
 #Playground {
 let sharedBackendService: CandidateBackendService
 
 sharedBackendService = CandidateBackendService()
 
 // Test login with bad credentials
 do {
 try await sharedBackendService.userAuthenticate(email: "bob@bob.fr", password: "1234")
 
 } catch let apiError as APIError {
 print(apiError.errorDescription!)
 }
 
 // Test login with good credentials
 do {
 try await sharedBackendService.userAuthenticate(email: "admin@vitesse.com", password: "test123")
 
 } catch let apiError as APIError {
 print(apiError.errorDescription!)
 }
 
 // Test user register
 do {
 try await sharedBackendService.userRegister(firstName: "Mathieu", lastName: "ARRIO", email: "mathieu@vitesse.com", password: "test1234")
 }
 catch let apiError as APIError {
 print(apiError.errorDescription!)
 }
 
 // Test login with good credentials
 do {
 try await sharedBackendService.userAuthenticate(email: "mathieu@vitesse.com", password: "test1234")
 } catch let apiError as APIError {
 print(apiError.errorDescription!)
 }
 
 // Test fetch all candidates
 do {
 let candidatesResponse = try await sharedBackendService.fetchAllCandidates()
 print(candidatesResponse)
 } catch let apiError as APIError {
 print("FETCHALLCANDIDATES ERROR")
 print(apiError.errorDescription!)
 }
 
 // Test fetch a candidate
 do {
 let candidateResponse = try await sharedBackendService.fetchCandidate(candidateId: UUID(uuidString: "C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2")!)
 print("CANDIDATE (C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2) : \(candidateResponse)")
 } catch let apiError as APIError {
 print("FETCHCANDIDATE ERROR")
 print(apiError.errorDescription!)
 }
 
 // Test create a candidate
 var candidateToCreate = CandidateRequest(firstName: "Bob", lastName: "LEPONGE", email: "bob@leponge.fr", phone: nil, linkedinURL: nil, note: nil)
 do {
 let candidateResponse = try await sharedBackendService.createCandidate(candidateRequest: candidateToCreate)
 print(candidateResponse)
 } catch let apiError as APIError {
 print("CREATECANDIDATE ERROR")
 print(apiError.errorDescription!)
 }
 
 // Test update a candidate
 candidateToCreate = CandidateRequest(firstName: "Bob", lastName: "LEPONGE", email: "bob@leponge.fr", phone: "0622222222", linkedinURL: nil, note: nil)
 do {
 let candidateResponse = try await sharedBackendService.updateCandidate(candidateId: UUID(uuidString: "469BCC2B-66EA-4991-A00E-6715422624EA")!, candidateRequest: candidateToCreate)
 print(candidateResponse)
 } catch let apiError as APIError {
 print("UPDATECANDIDATE ERROR")
 print(apiError.errorDescription!)
 }
 
 // Test delete a candidate
 do {
 try await sharedBackendService.deleteCandidate(candidateId: UUID(uuidString: "F44F4769-BD46-49EE-8F1F-EC3CA619F63C")!)
 
 } catch let apiError as APIError {
 print("DELETECANDIDATE ERROR")
 print(apiError.errorDescription!)
 }
 
 // Test toggle favorite status for a candidate (Authentiacted user is not admin)
 do {
 let candidateResponse = try await sharedBackendService.toogleCandidateFavoriteStatus(candidateId: UUID(uuidString: "C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2")!)
 print(candidateResponse)
 } catch let apiError as APIError {
 print("TOGGLE FAVORITE STATUS CANDIDATE ERROR")
 print(apiError.errorDescription!)
 }
 
 // Test login with good credentials with an admin user
 do {
 try await sharedBackendService.userAuthenticate(email: "admin@vitesse.com", password: "test123")
 } catch let apiError as APIError {
 print(apiError.errorDescription!)
 }
 
 // Test toggle favorite status for a candidate (Authentiacted user is admin)
 do {
 let candidateResponse = try await sharedBackendService.toogleCandidateFavoriteStatus(candidateId: UUID(uuidString: "C75C7C0C-EB67-4F74-ACEC-7D2703B65DC2")!)
 print(candidateResponse)
 } catch let apiError as APIError {
 print("TOGGLE FAVORITE STATUS CANDIDATE ERROR")
 print(apiError.errorDescription!)
 }
 
 }
 */
