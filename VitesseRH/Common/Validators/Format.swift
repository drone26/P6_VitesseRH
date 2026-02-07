//
//  Format.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 02/02/2026.
//

import Foundation

/// Test if email format of username is RFC 5322 compliant
/// - Returns: result of RFC 5322 compliance test
func isValidEmailFormat(_ email: String) -> Bool {
    // email regex format RFC 5322 compliant
    let emailRegex = #/(?:[a-zA-Z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?/#
    return (try? emailRegex.wholeMatch(in: email)) != nil
}

func isValidPassword(_ password: String) -> Bool {
    return password.count > 4
}


