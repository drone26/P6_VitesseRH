//
//  CandidateListView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 03/02/2026.
//

import SwiftUI

struct CandidateListView: View {
    @State private var viewModel: CandidateListViewModel
    let appViewModel: AppViewModel
    
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
                    CandidateSearchBarView(searchText: $viewModel.searchText)
                        .padding(.vertical, 10)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.filteredCandidates) { candidate in
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
                    // MARK: - Refreshable Modifier
                    .refreshable {
                        await viewModel.fetchAllCandidates()
                    }
                    .listStyle(.plain)
                    .listRowSpacing(12)
                    .padding(.horizontal)
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchAllCandidates()
                }
            }
            .navigationTitle("Candidates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        edit = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                    }
                }
            }
            .navigationDestination(isPresented: $edit) {
                CandidateEditView(viewModel: appViewModel.candidateEditViewModel)
            }
        }
    }
}

#Preview {
    @Previewable @State var appViewModel = AppViewModel()
    CandidateListView(appViewModel: appViewModel)
        .environment(appViewModel)
}
