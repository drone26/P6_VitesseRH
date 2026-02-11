//
//  ViewExtension.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 02/02/2026.
//

import SwiftUI

extension View {
    func endEditing(_ force: Bool) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        window?.endEditing(force)
    }
}
