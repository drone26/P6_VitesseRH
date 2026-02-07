//
//  CandidateListView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import SwiftUI

struct CandidateListView: View {
    let candidates = [
        Candidate(id: UUID(), firstName: "Bob", lastName: "LEPONGE", email: "bob@leponge.fr", phone: "0601020304", linkedinURL: nil, note: nil, isFavorite: false),
        Candidate(id: UUID(), firstName: "Toto", lastName: "TUTU", email: "toto@tutu.fr", phone: nil, linkedinURL: nil, note: nil, isFavorite: true),
        Candidate(id: UUID(), firstName: "mAThieu", lastName: "ARRIO", email: "mathieu@greatcandidate.fr", phone: "0601020304", linkedinURL: "https://www.linkedin.com/in/minimat26/", note: "Belles expériences de sysOps Linux avec une affinité au DevOps aussion bien en méthode de travail que que d'outillage.", isFavorite: false)
    ]
    
    @State private var edit: Bool = false
    
    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.vitesseGreen.opacity(0.7))
                    .ignoresSafeArea()
                
                VStack() {
                    CandidateSearchBarView(searchText: $searchText)
                        .padding(.vertical, 10)
                    ScrollView {
                        VStack(spacing: 10) {
                            let filtered = candidates.filter {
                                (searchText.isEmpty ||
                                $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                                 $0.lastName.localizedCaseInsensitiveContains(searchText)) && (!showFavoritesOnly || $0.isFavorite)
                            }
                            
                            ForEach(filtered) { candidate in
                                NavigationLink {
                                    // CandidateDetailView(candidate: candidate)
                                } label: {
                                    CandidateRowView(firstName: candidate.firstName, lastName: candidate.lastName, isFavorite: candidate.isFavorite)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .listStyle(.plain)
                    .listRowSpacing(12)
                    .navigationBarTitleDisplayMode(.inline)
                    .padding(.horizontal)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Edit") {
                                edit = true
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button() {
                                showFavoritesOnly.toggle()
                            } label: {
                                Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            }
                        }
                    }
                    .navigationTitle("Candidates")
                    .navigationDestination(isPresented: $edit) {
                        // CandidateEditView()
                    }
                }
            }
        }
    }
}



#Preview {
    CandidateListView()
}

