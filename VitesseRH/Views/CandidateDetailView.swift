//
//  CandidateDetailView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import SwiftUI

struct CandidateDetailView: View {
    @State var candidate: Candidate
    
    @Environment(\.openURL) private var openURL
    
    @State private var edit: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("\(candidate.firstName.capitalized) \(candidate.lastName.uppercased())")
                        .font(.title)
                    Spacer()
                    Button {
                        candidate.isFavorite.toggle()
                    } label: {
                        Image(systemName: candidate.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(.vitesseGreen)
                            .font(.title)                    }
                }
                Text("Phone: \(candidate.phone ?? "")")
                Text("Email: \(candidate.email)")
                HStack {
                    Text("LinkedIn: ")
                    
                    if let urlString = candidate.linkedinURL, let url = URL(string: urlString) {
                        Button("Go to LinkedIn") {
                            openURL(url)
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(.vitesseGreen)
                        .cornerRadius(8)
                        .padding()
                    } else {
                        Text("No link available")
                            .foregroundColor(.vitesseGreen)
                    }
                }
                Text("Note:")
                if let note = candidate.note {
                    if !note.isEmpty {
                        Text("\(note)")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(20)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Spacer()
        }
        .background(.vitesseGreen.opacity(0.7))
        .navigationBarItems(
            trailing: Button("Edit") {
                edit = true
            }
                .navigationDestination(isPresented: $edit) {
                    // CandidateEditDetailView(candidate: $candidate)
                }
        )
    }
}


#Preview("candidat 1") {
    @Previewable @State var candidate =
    Candidate(id: UUID(), firstName: "bOB", lastName: "lePONge", email: "bob@leponge.fr", phone: "0601020304", linkedinURL: nil, note: "", isFavorite: false)
        
    CandidateDetailView(candidate: candidate)
}

#Preview("candidat 2") {
    @Previewable @State var candidate =
    Candidate(id: UUID(), firstName: "maTHieu", lastName: "aRRIO", email: "mathieu@greatcandidate.fr", phone: nil, linkedinURL: "https://www.linkedin.com/in/minimat26/", note: "Accedebant enim eius asperitati, ubi inminuta vel laesa amplitudo imperii dicebatur, et iracundae suspicionum quantitati proximorum cruentae blanditiae exaggerantium incidentia et dolere inpendio simulantium, si principis periclitetur vita, a cuius salute velut filo pendere statum orbis terrarum fictis vocibus exclamabant.", isFavorite: false)
    
    CandidateDetailView(candidate: candidate)
}

