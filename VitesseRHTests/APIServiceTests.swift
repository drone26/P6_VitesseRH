//
//  APIServiceTests.swift
//  AuraTests
//
//  Created by Mathieu ARRIO on 15/01/2026.
//

import XCTest
@testable import VitesseRH

final class APIServiceTests: XCTestCase {

    var service: APIService!
    var mockSession: MockURLSession!
    
    // MARK: - Test Helpers
    
    struct MockData: Codable, Equatable, Sendable {
        let id: Int
        let name: String
    }
    
    struct MockEndpoint: APIEndpoint {
        var baseURL: URL? = URL(string: "https://api.test.com")
        var path: String = "/test"
        var method: HTTPMethod = .get
        var headers: [String: String]? = nil
        var body: (any Encodable & Sendable)? = nil
    }
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        service = APIService(session: mockSession)
    }
    
    override func tearDown() {
        service = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Request Building Tests
    
    func test_request_builds_correct_url_and_headers() async throws {
        // Given
        let endpoint = MockEndpoint(
            headers: ["Custom-Header": "Value"],
            body: MockData(id: 1, name: "Test")
        )
        
        let responseData = try JSONEncoder().encode(MockData(id: 1, name: "Test"))
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // When
        let _: MockData = try await service.request(endpoint)
        
        // Then
        let request = mockSession.lastRequest
        XCTAssertEqual(request?.url?.absoluteString, "https://api.test.com/test")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Custom-Header"), "Value")
        // Assert default header addition
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        let sentBody = try JSONDecoder().decode(MockData.self, from: request!.httpBody!)
        XCTAssertEqual(sentBody.id, 1)
    }
    
    func test_request_fails_with_invalid_url() async {
        // When (Arrange: Endpoint with nil baseURL)
        let endpoint = MockEndpoint(baseURL: nil)
        
        // Given / Then
        do {
            let _: MockData = try await service.request(endpoint)
            XCTFail("Should fail with invalid URL")
        } catch let error as APIError {
            XCTAssertEqual(error, .invalidURL)
        } catch {
            XCTFail("Wrong error type")
        }
    }

    // MARK: - Generic Request (Decodable) Tests
    
    func test_request_success_decodes_data() async throws {
        // When
        let expected = MockData(id: 123, name: "Success")
        mockSession.data = try JSONEncoder().encode(expected)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        let result: MockData = try await service.request(MockEndpoint())
        
        // Then
        XCTAssertEqual(result, expected)
    }
    
    // MARK: - Decoding Error Tests (Coverage for catch blocks)
    
    func test_request_decoding_error_type_mismatch() async throws {
        // When (Arrange: JSON has 'id' as String, Model expects Int)
        let json = """
        { "id": "not an int", "name": "Test" }
        """.data(using: .utf8)!
        
        mockSession.data = json
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            let _: MockData = try await service.request(MockEndpoint())
            XCTFail("Should fail decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        }
    }
    
    func test_request_decoding_error_key_not_found() async throws {
        // When (Arrange: JSON missing 'id')
        let json = """
        { "name": "Test" }
        """.data(using: .utf8)!
        
        mockSession.data = json
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            let _: MockData = try await service.request(MockEndpoint())
            XCTFail("Should fail decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        }
    }
    
    func test_request_decoding_error_value_not_found() async throws {
        // When (Arrange: JSON has null for non-optional 'name')
        let json = """
        { "id": 1, "name": null }
        """.data(using: .utf8)!
        
        mockSession.data = json
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            let _: MockData = try await service.request(MockEndpoint())
            XCTFail("Should fail decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        }
    }
    
    func test_request_decoding_error_data_corrupted() async throws {
        // When (Arrange: Invalid JSON format)
        let json = """
        { "id": 1, "name": "Test"
        """.data(using: .utf8)! // Missing closing brace
        
        mockSession.data = json
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            let _: MockData = try await service.request(MockEndpoint())
            XCTFail("Should fail decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        }
    }

    // MARK: - Request Data / String / Void Tests
    
    func test_requestData_returns_raw_data() async throws {
        // When
        let expectedData = "Raw Data".data(using: .utf8)!
        mockSession.data = expectedData
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        let data = try await service.requestData(MockEndpoint())
        
        // Then
        XCTAssertEqual(data, expectedData)
    }
    
    func test_requestString_success() async throws {
        // When
        let expectedString = "Hello World"
        mockSession.data = expectedString.data(using: .utf8)
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given
        let result = try await service.requestString(MockEndpoint())
        
        // Then
        XCTAssertEqual(result, expectedString)
    }
    
    func test_requestString_failure_encoding() async throws {
        // When (Arrange: Invalid UTF8 data)
        let invalidData = Data([0xFF, 0xFF])
        mockSession.data = invalidData
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            _ = try await service.requestString(MockEndpoint())
            XCTFail("Should fail encoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        }
    }
    
    func test_requestVoid_success() async throws {
        // When
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 204, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        try await service.requestVoid(MockEndpoint())
    }

    // MARK: - Response Validation & Error Mapping Tests
    
    func test_network_error_non_http_response() async {
        // When (Use URLResponse instead of HTTPURLResponse)
        mockSession.data = Data()
        mockSession.response = URLResponse(url: URL(string: "http://test.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        
        // Given / Then
        do {
            try await service.requestVoid(MockEndpoint())
            XCTFail("Should fail")
        } catch let error as APIError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func test_error_400_bad_request_with_reason() async {
        // When
        let errorJson = """
        { "error": true, "reason": "Invalid Input" }
        """.data(using: .utf8)!
        
        mockSession.data = errorJson
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.requestVoid(MockEndpoint())
            XCTFail("Should fail")
        } catch let error as APIError {
            XCTAssertEqual(error.errorDescription, "Invalid Input") // Maps to .badRequest(reason:)
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func test_error_401_unauthorized() async {
        // When
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.requestVoid(MockEndpoint())
            XCTFail("Should fail")
        } catch let error as APIError {
            // Verify default message when no reason JSON provided
            // .unAuthorized(reason: nil) -> "Unauthorized access"
            XCTAssertTrue(error.errorDescription?.contains("Unauthorized") ?? false)
        } catch { XCTFail() }
    }
    
    func test_error_403_forbidden() async {
        // When
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 403, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.requestVoid(MockEndpoint())
            XCTFail("Should fail")
        } catch let error as APIError {
            // .unAuthorized(reason: nil)
            XCTAssertTrue(error.errorDescription?.contains("Unauthorized") ?? false)
        } catch { XCTFail() }
    }
    
    func test_error_404_not_found() async {
        // When
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.requestVoid(MockEndpoint())
            XCTFail("Should fail")
        } catch let error as APIError {
            // .notFound(reason: nil) -> "Not found"
            XCTAssertEqual(error.errorDescription, "Not found")
        } catch { XCTFail() }
    }
    
    func test_error_500_server_error() async {
        // When
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.requestVoid(MockEndpoint())
            XCTFail("Should fail")
        } catch let error as APIError {
            // .serverError(500, reason: nil)
            XCTAssertTrue(error.errorDescription?.contains("Server error: 500") ?? false)
        } catch { XCTFail() }
    }
    
    func test_error_unknown_status_code_defaults_to_server_error() async {
        // When (Status code not explicitly switched)
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 418, httpVersion: nil, headerFields: nil)
        
        // Given / Then
        do {
            try await service.requestVoid(MockEndpoint())
            XCTFail("Should fail")
        } catch let error as APIError {
            // Falls to default case -> .serverError
            XCTAssertTrue(error.errorDescription?.contains("Server error: 418") ?? false)
        } catch { XCTFail() }
    }
}
