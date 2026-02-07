//
//  UserRegisterView.swift
//  Vitesse
//
//  Created by Mathieu ARRIO on 02/02/2026.
//

import SwiftUI

struct UserRegisterView: View {
    @State private var firstname: String = ""
    @State private var lastname: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var register: Bool = false
    
    @Environment(\.dismiss) var dismiss // This allows us to "go back"
    
    var body: some View {
        
        ZStack {
            Color(.vitesseGreen.opacity(0.7))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading) {
                    Text("First Name")
                        .font(.headline)
                    
                    TextField("First Name",
                              text: $firstname)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                }
                
                VStack(alignment: .leading) {
                    Text("Last Name")
                        .font(.headline)
                    
                    TextField("Last Name",
                              text: $lastname)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                }
                
                
                VStack(alignment: .leading) {
                    Text("Email address")
                        .accessibilityHidden(isValidEmailFormat(email))
                        .font(.headline)
                    
                    TextField("Email address",
                              text: $email,
                              prompt: Text(isValidEmailFormat(email) ? "" : "Enter a valid email address"))
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .overlay() {
                        if !email.isEmpty {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isValidEmailFormat(email) ? Color.clear : Color.red, lineWidth: 2)
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
                
                VStack(alignment: .leading) {
                    Text("Confirm password")
                        .accessibilityHidden(confirmPassword.count > 4)
                        .font(.headline)
                    
                    SecureField("Confirm password", text: $confirmPassword)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay() {
                            if !confirmPassword.isEmpty {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(confirmPassword == password ? Color.clear : Color.red, lineWidth: 2)
                            }
                        }
                }
                .padding(.bottom, 20)
                
                
                
                Button(action: {
                    createUser()
                }) {
                    Text("Register")
                        .foregroundColor(.white)
                    /*
                     if viewModel.isLoading {
                     ProgressView()
                     .tint(Color(UIColor.secondarySystemBackground))
                     } else {
                     Text("Se connecter")
                     .foregroundColor(Color(UIColor.secondarySystemBackground))
                     }
                     */
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.vitesseGreen)
                .cornerRadius(8)
                .navigationDestination(isPresented: $register) {
                    UserLoginView()
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
    
    func createUser() {
            print("Creating user: \(firstname)...")
            dismiss()
        }
}



#Preview {
    UserRegisterView()
}
