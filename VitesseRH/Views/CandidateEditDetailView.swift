//
//  CandidateEditDetailView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import SwiftUI

struct CandidateEditDetailView: View {
    @Binding var candidate: Candidate
    @State private var viewModel: CandidateEditDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    init(candidate: Binding<Candidate>, viewModel: CandidateEditDetailViewModel) {
        self._candidate = candidate
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(candidate.firstName.capitalized) \(candidate.lastName.uppercased())")
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text("Phone").font(.headline)
                    TextField("Phone", text: $viewModel.phone)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text("Email").font(.headline)
                    TextField("Email", text: $viewModel.email)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text("LinkedIn").font(.headline)
                    TextField("LinkedIn URL", text: $viewModel.linkedinURL)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text("Notes").font(.headline)
                    TextEditor(text: $viewModel.note)
                        .frame(minHeight: 150)
                        .padding(4)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(.vitesseGreen.opacity(0.7))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    Task {
                        if let updated = try? await viewModel.updateCandidate() {
                            candidate = updated
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}

#Preview {
    @Previewable @State var sampleCandidate = Candidate(
        id: UUID(),
        firstName: "Mathieu",
        lastName: "ARRIO",
        email: "mathieu@greatcandidate.fr",
        phone: "0601020304",
        linkedinURL: "https://www.linkedin.com/in/minimat26/",
        note: "Belles expériences de sysOps Linux avec une affinité au DevOps aussi bien en méthode de travail que que d'outillage.",
        isFavorite: false
    )
    // 1. Initialize the AppViewModel (the source of truth for services)
    let appViewModel = AppViewModel()
    
    // 3. Use the appViewModel to provide the CandidateEditDetailViewModel
    return CandidateEditDetailView(
        candidate: $sampleCandidate,
        viewModel: appViewModel.candidateEditDetailViewModel(candidate: sampleCandidate)
    )
}
