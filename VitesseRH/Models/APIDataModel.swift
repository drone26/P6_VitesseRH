//
//  APIDataModel.swift
//  Aura
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import Foundation

// Candidate API backend requests, responses and errors model

// POST /user/auth
struct UserAuthenticationRequest: Codable {
    let email: String
    let password: String
}

struct UserAuthenticationResponse: Codable {
    let token: String
    let isAdmin: Bool
}

// POST /user/register
struct UserRegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

struct Candidate: Codable, Identifiable {
    var id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var linkedinURL: String?
    var note: String?
    var isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, email, phone, linkedinURL, note, isFavorite
    }
}

// POST /candidate
struct CandidateRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let linkedinURL: String?
    let note: String?
}

struct BackendErrorResponse: Codable {
    let error: Bool
    let reason: String
}
