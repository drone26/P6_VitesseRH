//
//  CandidateSearchBarView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

struct CandidateSearchBarView: View {
    
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search candidates...", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var text = "search"
    return CandidateSearchBarView(searchText: $text)
}
