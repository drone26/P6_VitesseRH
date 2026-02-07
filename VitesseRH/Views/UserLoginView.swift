//
//  UserLoginView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 30/01/2026.
//

import SwiftUI

struct UserLoginView: View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @State private var register = false
    @State private var login = false
        
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [.vitesseGreen.opacity(0.7), .vitesseGreen.opacity(0.0)]), startPoint: .top, endPoint: .bottomLeading)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Login")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading) {
                        Text("Email address")
                            .accessibilityHidden(isValidEmailFormat(username))
                            .font(.headline)
                        
                        TextField("Email address",
                                  text: $username,
                                  prompt: Text(isValidEmailFormat(username) ? "" : "Enter a valid email address"))
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .overlay() {
                            if !username.isEmpty {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isValidEmailFormat(username) ? Color.clear : Color.red, lineWidth: 2)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Password")
                            .accessibilityHidden(password.count > 4)
                            .font(.headline)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay() {
                                if !password.isEmpty {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(password.count > 4 ? Color.clear : Color.red, lineWidth: 2)
                                }
                            }
                    }
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        login = true
                    }) {
                        Text("Sign In")
                            .foregroundColor(.white.opacity(isValidEmailFormat(username) && isValidPassword(password) ? 1.0 : 0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.vitesseGreen.opacity(isValidEmailFormat(username) && isValidPassword(password) ? 1.0 : 0.7))
                    .cornerRadius(8)
                    .fullScreenCover(isPresented: $login) {
                        // CandidateListView()
                    }
                    
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
                        // UserRegisterView()
                    }
                    
                    /*
                     // Error message display
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
                     */
                }
                .padding(.horizontal, 40)
            }
            .onTapGesture {
                self.endEditing(true)  // This will dismiss the keyboard when tapping outside
            }
        }
    }
}

#Preview("Filtered List") {
    UserLoginView()
}
