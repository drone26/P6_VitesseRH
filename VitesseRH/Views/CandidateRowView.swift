//
//  CandidateRowView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 05/02/2026.
//

import SwiftUI

struct CandidateRowView: View {
    var firstName: String
    var lastName: String
    var isFavorite: Bool
    
    var body: some View {
        HStack {
            Text("\(firstName.capitalized) \(lastName.prefix(1).capitalized).")
                .font(.headline)
            Spacer()
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview("1") {
    CandidateRowView(firstName: "Mathieu", lastName: "ARRIO", isFavorite: true)
}

#Preview("2") {
    CandidateRowView(firstName: "Mathieu", lastName: "ARRIO", isFavorite: false)
}
