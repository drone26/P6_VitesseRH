//
//  CandidateEditView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 07/02/2026.
//

import SwiftUI

struct CandidateEditView: View {
    @State private var viewModel: CandidateEditViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText: String = ""
    
    init(viewModel: CandidateEditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matching CandidateListView
                Color(.vitesseGreen.opacity(0.7))
                    .ignoresSafeArea()
                
                VStack {
                    // Search Bar
                    CandidateSearchBarView(searchText: $searchText)
                        .padding(.vertical, 10)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            // Filter logic
                            let filtered = viewModel.candidates.filter {
                                searchText.isEmpty ||
                                $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                                $0.lastName.localizedCaseInsensitiveContains(searchText)
                            }
                            
                            ForEach(filtered) { candidate in
                                Button {
                                    viewModel.toggleSelection(for: candidate.id)
                                } label: {
                                    HStack {
                                        // Selection Circle (Wireframe style)
                                        Image(systemName: viewModel.selectedIds.contains(candidate.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.primary)
                                            .font(.title2)
                                            .padding(.trailing, 8)
                                        
                                        // Name
                                        Text("\(candidate.firstName.capitalized) \(candidate.lastName.prefix(1).capitalized).")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        // Star
                                        Image(systemName: candidate.isFavorite ? "star.fill" : "star")
                                            .foregroundColor(.primary)
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor.secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .listStyle(.plain)
                    .listRowSpacing(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Candidates")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // Hide default back button
            .toolbar {
                // Cancel Button (Left)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // Delete Button (Right)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        Task {
                            await viewModel.deleteSelectedCandidates()
                            dismiss() // Dismissing view after deletion
                        }
                    }
                    .foregroundColor(viewModel.hasSelection ? .red : .primary.opacity(0.5))
                    .disabled(!viewModel.hasSelection)
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchCandidates()
                }
            }
        }
    }
}

#Preview {
    let appViewModel = AppViewModel()
    CandidateEditView(viewModel: appViewModel.candidateEditViewModel)
}
