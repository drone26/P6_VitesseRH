//
//  MockURLSession.swift
//  AuraTests
//
//  Created by Mathieu ARRIO on 16/01/2026.
//

import Foundation
import XCTest
@testable import VitesseRH


final class MockURLSession: URLSessionProtocol {
    var lastRequest: URLRequest?
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request

        if let error = error {
            throw error
        }

        let response = self.response ?? HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        guard let data = data else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock data provided"])
        }

        return (data, response)
    }
}

