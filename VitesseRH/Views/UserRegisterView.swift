//
//  UserRegisterView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 02/02/2026.
//

import SwiftUI

// MARK: - UserRegisterView avec RegisterViewModel

struct UserRegisterView: View {
    @State private var viewModel = UserRegisterViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(.vitesseGreen.opacity(0.7))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // First name input
                        VStack(alignment: .leading) {
                            Text("First Name")
                                .font(.headline)
                            
                            TextField("First Name", text: $viewModel.firstName)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .overlay {
                                    if !viewModel.firstName.isEmpty {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                viewModel.isFirstNameValid ? Color.clear : Color.red,
                                                lineWidth: 2
                                            )
                                    }
                                }
                        }
                        
                        // Last name input
                        VStack(alignment: .leading) {
                            Text("Last Name")
                                .font(.headline)
                            
                            TextField("Last Name", text: $viewModel.lastName)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .overlay {
                                    if !viewModel.lastName.isEmpty {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                viewModel.isLastNameValid ? Color.clear : Color.red,
                                                lineWidth: 2
                                            )
                                    }
                                }
                        }
                        
                        // Email input
                        VStack(alignment: .leading) {
                            Text("Email address")
                                .accessibilityHidden(viewModel.isEmailValid)
                                .font(.headline)
                            
                            TextField(
                                "Email address",
                                text: $viewModel.email,
                                prompt: Text(viewModel.isEmailValid ? "" : "Enter a valid email address")
                            )
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .overlay {
                                if !viewModel.email.isEmpty {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            viewModel.isEmailValid ? Color.clear : Color.red,
                                            lineWidth: 2
                                        )
                                }
                            }
                        }
                        
                        // Password input
                        VStack(alignment: .leading) {
                            Text("Password")
                                .accessibilityHidden(viewModel.isPasswordValid)
                                .font(.headline)
                            
                            SecureField("Password", text: $viewModel.password)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay {
                                    if !viewModel.password.isEmpty {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                viewModel.isPasswordValid ? Color.clear : Color.red,
                                                lineWidth: 2
                                            )
                                    }
                                }
                        }
                        
                        // Confirm password input
                        VStack(alignment: .leading) {
                            Text("Confirm password")
                                .accessibilityHidden(viewModel.isPasswordConfirmValid)
                                .font(.headline)
                            
                            SecureField("Confirm password", text: $viewModel.confirmPassword)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay {
                                    if !viewModel.confirmPassword.isEmpty {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                viewModel.isPasswordConfirmValid ? Color.clear : Color.red,
                                                lineWidth: 2
                                            )
                                    }
                                }
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .lineLimit(nil)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Register button
                Button(action: {
                    Task {
                        await viewModel.registerWithErrorHandling()
                        if viewModel.isRegistered {
                            // Navigate back to login
                            dismiss()
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Creating account...")
                        }
                    } else {
                        Text("Register")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(.vitesseGreen.opacity(viewModel.isFormValid && !viewModel.isLoading ? 1.0 : 0.7))
                .cornerRadius(8)
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }
            .padding(.horizontal, 40)
        }
        .onTapGesture {
            self.endEditing(true)
        }
    }
}


#Preview {
    UserRegisterView()
}
