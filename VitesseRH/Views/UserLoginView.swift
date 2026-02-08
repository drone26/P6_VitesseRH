//
//  UserLoginView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 30/01/2026.
//

import SwiftUI

struct UserLoginView: View {
    
    // MARK: - Architecture Properties
    @State private var viewModel: UserLoginViewModel
    let appViewModel: AppViewModel
    
    // MARK: - Navigation State
    @State private var register = false
    // 'login' state is removed because we use appViewModel.isLogged to switch views
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _viewModel = State(initialValue: appViewModel.loginViewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient (Restored exactly as requested)
                LinearGradient(gradient: Gradient(colors: [.vitesseGreen.opacity(0.7), .vitesseGreen.opacity(0.0)]), startPoint: .top, endPoint: .bottomLeading)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Login")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    // Email Input
                    VStack(alignment: .leading) {
                        Text("Email address")
                            .accessibilityHidden(viewModel.isEmailValid)
                            .font(.headline)
                        
                        TextField("Email address",
                                  text: $viewModel.email,
                                  prompt: Text(viewModel.isEmailValid ? "" : "Enter a valid email address"))
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .disabled(viewModel.isLoading)
                        .overlay() {
                            if !viewModel.email.isEmpty {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.isEmailValid ? Color.clear : Color.red, lineWidth: 2)
                            }
                        }
                    }
                    
                    // Password Input
                    VStack(alignment: .leading) {
                        Text("Password")
                            .accessibilityHidden(viewModel.isPasswordValid)
                            .font(.headline)
                        
                        SecureField("Password", text: $viewModel.password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .disabled(viewModel.isLoading)
                            .overlay() {
                                if !viewModel.password.isEmpty {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.isPasswordValid ? Color.clear : Color.red, lineWidth: 2)
                                }
                            }
                    }
                    .padding(.bottom, 20)
                    
                    // Sign In Button
                    Button(action: {
                        Task {
                            await viewModel.loginWithErrorHandling()
                            if viewModel.isLoggedIn {
                                // This triggers the switch in VitesseRHApp to the CandidateListView
                                appViewModel.isLogged = true
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .foregroundColor(.white.opacity(viewModel.isFormValid ? 1.0 : 0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.vitesseGreen.opacity(viewModel.isFormValid ? 1.0 : 0.7))
                    .cornerRadius(8)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    
                    // Register Button
                    Button(action: {
                        register = true
                    }) {
                        Text("Register")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.vitesseGreen)
                    .cornerRadius(8)
                    .navigationDestination(isPresented: $register) {
                        UserRegisterView()
                    }
                    
                    // Error message display (Restored and uncommented)
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
                }
                .padding(.horizontal, 40)
            }
            .onTapGesture {
                self.endEditing(true) // This will dismiss the keyboard when tapping outside
            }
        }
    }
}

#Preview {
    @Previewable @State var appViewModel = AppViewModel()
    UserLoginView(appViewModel: appViewModel)
}
