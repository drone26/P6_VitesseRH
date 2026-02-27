//
//  MockURLSession.swift
//  AuraTests
//
//  Created by Mathieu ARRIO on 16/01/2026.
//

import Foundation
import XCTest
@testable import VitesseRH


final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    private let lock = NSLock()

    private var _lastRequest: URLRequest?
    var lastRequest: URLRequest? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _lastRequest
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _lastRequest = newValue
        }
    }

    private var _data: Data?
    var data: Data? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _data
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _data = newValue
        }
    }

    private var _response: URLResponse?
    var response: URLResponse? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _response
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _response = newValue
        }
    }

    private var _error: Error?
    var error: Error? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _error
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _error = newValue
        }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        self.lastRequest = request

        if let error = self.error {
            throw error
        }

        let response = self.response ?? HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        guard let data = self.data else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock data provided"])
        }

        return (data, response)
    }
}
