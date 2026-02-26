//
//  APIService.swift
//  Aura
//
//  Created by Mathieu ARRIO on 07/01/2026.
//

import Foundation

/// Define API errors
enum APIError: Error, LocalizedError, Equatable {
    case badCredentials(reason: String?)
    case unAuthorized(reason: String?)
    case invalidURL
    case decodingFailed
    case serverError(statusCode: Int, reason: String?)
    case networkError
    case notFound(reason: String?)
    case badRequest(reason: String?)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .badCredentials(let reason):
            return reason ?? "Bad credentials"
        case .unAuthorized(let reason):
            return reason ?? "Unauthorized access"
        case .invalidURL:
            return "Invalid URL"
        case .decodingFailed:
            return "Failed to decode server response"
        case .serverError(let statusCode, let reason):
            return reason ?? "Server error: \(statusCode)"
        case .networkError:
            return "Network error"
        case .notFound(let reason):
            return reason ?? "Not found"
        case .badRequest(let reason):
            return reason ?? "Bad request"
        case .unknown:
            return "Unknown error"
        }
    }
}

/// Defines the possible HTTP methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// A protocol to define API configuration
protocol APIEndpoint: Sendable {
    var baseURL: URL? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: (any Encodable & Sendable)? { get }
}

/// Protocol used for ui test (mock)
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Backend error response model
private struct BackendError: Codable {
    let error: Bool
    let reason: String
}

/// Generic API (Rest) Service
actor APIService {
    private let session: URLSessionProtocol
    private let decoder: JSONDecoder
    
    init(session: URLSessionProtocol = URLSession.shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    /// Performs a request and decodes the response as a decodable type
    /// - Parameter endpoint: endpoint protocol APIEndpoint (baseURL, path, method, headers, body)
    /// - Returns: generic type decodable
    func request<E: APIEndpoint, T: Decodable>(_ endpoint: E) async throws -> T {
        let urlRequest = try buildRequest(from: endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        
        try validateResponse(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            print("DECODINGERROR: \(error)")
            switch error {
            case .typeMismatch(let type, let context):
                print("Type Mismatch: \(type) was expected. \(context.debugDescription)")
                print("Path: \(context.codingPath)")
                
            case .valueNotFound(let type, let context):
                print("Value Not Found: \(type) was expected. \(context.debugDescription)")
                print("Path: \(context.codingPath)")
                
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found. \(context.debugDescription)")
                print("Path: \(context.codingPath)")
                
            case .dataCorrupted(let context):
                print("Data Corrupted: \(context.debugDescription)")
                print("Path: \(context.codingPath)")
                
            @unknown default:
                print("Unknown decoding error")
                
            }
            throw APIError.decodingFailed
        }
    }
    
    /// Performs a request and returns raw data
    /// - Parameter endpoint: endpoint protocol APIEndpoint (baseURL, path, method, headers, body)
    /// - Returns: raw generic type (not decoded)
    func requestData<E: APIEndpoint>(_ endpoint: E) async throws -> Data {
        let urlRequest = try buildRequest(from: endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        
        try validateResponse(response, data: data)
        
        return data
    }
    
    /// Performs a request and returns a String (for plain text responses)
    /// - Parameter endpoint: endpoint protocol APIEndpoint (baseURL, path, method, headers, body)
    /// - Returns: string result
    func requestString<E: APIEndpoint>(_ endpoint: E) async throws -> String {
        let data = try await requestData(endpoint)
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw APIError.decodingFailed
        }
        
        return string
    }
    
    /// Performs a request and validates success without expecting a return body
    /// - Parameter endpoint: endpoint protocol APIEndpoint (baseURL, path, method, headers, body)
    func requestVoid<E: APIEndpoint>(_ endpoint: E) async throws {
        let urlRequest = try buildRequest(from: endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        
        try validateResponse(response, data: data)
    }
    
    /// Helper to extract error message from backend response
    /// - Parameter data: response data
    /// - Returns: reason string if available
    private func extractErrorReason(from data: Data) -> String? {
        do {
            let backendError = try decoder.decode(BackendError.self, from: data)
            return backendError.reason
        } catch {
            return nil
        }
    }
    
    /// Helper to validate HTTP response status codes
    /// - Parameters:
    ///   - response: URLResponse
    ///   - data: response data for error extraction
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorReason = extractErrorReason(from: data)
            
            switch httpResponse.statusCode {
            case 400:
                throw APIError.badRequest(reason: errorReason)
            case 401:
                throw APIError.unAuthorized(reason: errorReason)
            case 403:
                throw APIError.unAuthorized(reason: errorReason)
            case 404:
                throw APIError.notFound(reason: errorReason)
            case 500...599:
                throw APIError.serverError(statusCode: httpResponse.statusCode, reason: errorReason)
            default:
                throw APIError.serverError(statusCode: httpResponse.statusCode, reason: errorReason)
            }
        }
    }
    
    /// Build request (url, body, headers)
    /// - Parameter endpoint: endpoint protocol APIEndpoint (baseURL, path, method, headers, body)
    /// - Returns: formatted URLRequest
    private func buildRequest<E: APIEndpoint>(from endpoint: E) throws -> URLRequest {
        guard let fullURL = endpoint.baseURL?.appendingPathComponent(endpoint.path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: fullURL)
        
        request.httpMethod = endpoint.method.rawValue
        
        // Add Headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add default header for JSON
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Add Body if applicable
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        return request
    }
}


