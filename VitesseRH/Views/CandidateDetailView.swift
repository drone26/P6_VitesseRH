//
//  CandidateDetailView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import SwiftUI

struct CandidateDetailView: View {
    @State var candidate: Candidate
    let viewModel: CandidateViewModel
    let appViewModel: AppViewModel
    
    @Environment(\.openURL) private var openURL
    @State private var edit: Bool = false
    
    init(candidate: Candidate, viewModel: CandidateViewModel, appViewModel: AppViewModel) {
        self._candidate = State(initialValue: candidate)
        self.viewModel = viewModel
        self.appViewModel = appViewModel
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header with Name and Favorite Star
                HStack {
                    Text("\(candidate.firstName.capitalized) \(candidate.lastName.uppercased())")
                        .font(.title)
                    Spacer()
                    Button {
                        Task {
                            // 1. Optimistic UI Update: Toggle immediately
                            candidate.isFavorite.toggle()
                            
                            // 2. Call API
                            await viewModel.toggleFavorite()
                            
                            // 3. Sync state: Ensure local state matches server response
                            // If the API call failed, this will revert the star
                            self.candidate = viewModel.candidate
                        }
                    } label: {
                        Image(systemName: candidate.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(.vitesseGreen)
                            .font(.title)
                    }
                }
                
                // Details
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
                if let note = candidate.note, !note.isEmpty {
                    Text("\(note)")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(20)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
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
        )
        // Integration with the actual Edit view and its ViewModel
        .navigationDestination(isPresented: $edit) {
            CandidateEditDetailView(
                candidate: $candidate,
                viewModel: appViewModel.candidateEditDetailViewModel(candidate: candidate)
            )
        }
        .onAppear {
            Task {
                await viewModel.refreshCandidate()
                // Update local state if the background refresh found changes
                self.candidate = viewModel.candidate
            }
        }
    }
}

#Preview {
    let appViewModel = AppViewModel()
    let sampleCandidate = Candidate(
        id: UUID(),
        firstName: "Mathieu",
        lastName: "ARRIO",
        email: "mathieu@example.fr",
        phone: "0601020304",
        linkedinURL: "https://www.linkedin.com/in/minimat26/",
        note: "Excellent iOS developer with 5+ years of experience",
        isFavorite: true
    )
    
    return CandidateDetailView(
        candidate: sampleCandidate,
        viewModel: appViewModel.candidateViewModel(candidate: sampleCandidate),
        appViewModel: appViewModel
    )
}
