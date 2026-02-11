//
//  VitesseRHApp.swift
//  VitesseRH
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

@main
struct VitesseApp: App {
    @State private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            if appViewModel.isLogged {
                // User is logged in - show main app
                CandidateListView(appViewModel: appViewModel)
                    .environment(appViewModel)
            } else {
                // User is not logged in - show login screen
                UserLoginView(appViewModel: appViewModel)
                    .environment(appViewModel)
            }
        }
    }
}
