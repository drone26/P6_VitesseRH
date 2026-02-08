//
//  CandidateListView.swift (Fixed - Direct Initialization)
//  Vitesse
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import SwiftUI

struct CandidateListView: View {
    @State private var viewModel: CandidateListViewModel
    let appViewModel: AppViewModel
    
    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var edit: Bool = false
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _viewModel = State(initialValue: appViewModel.candidateListViewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.vitesseGreen.opacity(0.7))
                    .ignoresSafeArea()
                
                VStack {
                    // Search bar from your original snippet
                    CandidateSearchBarView(searchText: $searchText)
                        .padding(.vertical, 10)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            let filtered = viewModel.candidates.filter {
                                (searchText.isEmpty ||
                                 $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                                 $0.lastName.localizedCaseInsensitiveContains(searchText)) &&
                                (!showFavoritesOnly || $0.isFavorite)
                            }
                            
                            ForEach(filtered) { candidate in
                                NavigationLink {
                                    CandidateDetailView(
                                        candidate: candidate,
                                        viewModel: appViewModel.candidateViewModel(candidate: candidate),
                                        appViewModel: appViewModel
                                    )
                                } label: {
                                    CandidateRowView(
                                        firstName: candidate.firstName,
                                        lastName: candidate.lastName,
                                        isFavorite: candidate.isFavorite
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    // Restoring your original list-like modifiers
                    .listStyle(.plain)
                    .listRowSpacing(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Candidates")
            .navigationBarTitleDisplayMode(.inline) // Restore original header style
            .toolbar {
                // Leading Edit button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        edit = true
                    }
                    .foregroundColor(.white)
                }
                
                // Trailing Star button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationDestination(isPresented: $edit) {
                // CandidateEditView() - Placeholder as per original code
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchAllCandidates()
            }
        }
    }
}

#Preview {
    @Previewable @State var appViewModel = AppViewModel()
    CandidateListView(appViewModel: appViewModel)
        .environment(appViewModel)
}
