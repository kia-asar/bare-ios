//
//  SignInView.swift
//  bare
//
//  Email magic link sign-in view
//

import SwiftUI
import BareKit

struct SignInView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var emailSent = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo/Title
            VStack(spacing: 8) {
                Text("bare")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Save and organize your content")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if emailSent {
                // Check email message
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    
                    Text("Check your email")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("We sent a magic link to\n\(email)")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    Text("Click the link in the email to sign in")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Use different email") {
                        emailSent = false
                        email = ""
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                }
                .padding()
            } else {
                // Email input form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Button {
                        sendMagicLink()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Send Magic Link")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidEmail ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .disabled(!isValidEmail || isLoading)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private func sendMagicLink() {
        guard isValidEmail else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let authManager = try await DependencyContainer.shared.getAuthManager()
                try await authManager.sendMagicLink(to: email)
                await MainActor.run {
                    isLoading = false
                    emailSent = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send magic link. Please try again."
                }
            }
        }
    }
}

#Preview {
    SignInView()
}


