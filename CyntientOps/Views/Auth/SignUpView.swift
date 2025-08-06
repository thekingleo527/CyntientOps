//
//  SignUpView.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Binding conversion issues and missing UserRole cases
//  ✅ FIXED: Use correct UserRole enum cases (admin, manager, worker, client)
//  ✅ FIXED: Remove incorrect .wrappedValue usage
//

import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var selectedRole: CoreTypes.UserRole = .worker
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    signUpButton
                    signInLink
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Join CyntientOps")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Create your account to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            CustomTextField(
                title: "Full Name",
                text: $fullName,
                isValid: isValidName(fullName)
            )
            
            CustomTextField(
                title: "Email",
                text: $email,
                isValid: isValidEmail(email)
            )
            
            CustomTextField(
                title: "Password",
                text: $password,
                isSecure: true,
                isValid: isValidPassword(password)
            )
            
            CustomTextField(
                title: "Confirm Password",
                text: $confirmPassword,
                isSecure: true,
                isValid: password == confirmPassword && !password.isEmpty
            )
            
            roleSelectionSection
        }
    }
    
    private var roleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Role")
                .font(.headline)
                .foregroundColor(.white)
            
            // ✅ FIXED: Use actual UserRole cases (admin, manager, worker, client)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach([CoreTypes.UserRole.worker, CoreTypes.UserRole.manager, CoreTypes.UserRole.admin, CoreTypes.UserRole.client], id: \.self) { role in
                    roleButton(for: role)
                }
            }
        }
    }
    
    private func roleButton(for role: CoreTypes.UserRole) -> some View {
        Button(action: {
            selectedRole = role
        }) {
            VStack(spacing: 8) {
                Image(systemName: iconForRole(role))
                    .font(.title2)
                    .foregroundColor(selectedRole == role ? .blue : .white.opacity(0.7))
                
                Text(role.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(selectedRole == role ? .blue : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedRole == role ? Color.blue.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedRole == role ? Color.blue : Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var signUpButton: some View {
        Button(action: signUp) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(isLoading || !isFormValid)
    }
    
    private var signInLink: some View {
        Button("Already have an account? Sign In") {
            dismiss()
        }
        .font(.subheadline)
        .foregroundColor(.blue)
    }
    
    // MARK: - Helper Methods
    
    private func iconForRole(_ role: CoreTypes.UserRole) -> String {
        switch role {
        case .worker: return "person.fill"
        case .admin: return "person.badge.key.fill"
        case .manager: return "person.3.fill"
        case .client: return "building.2.fill"
        }
    }
    
    private var isFormValid: Bool {
        return isValidEmail(email) &&
               isValidPassword(password) &&
               password == confirmPassword &&
               isValidName(fullName)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }
    
    private func isValidName(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2
    }
    
    private func signUp() {
        isLoading = true
        
        // Simulate sign up process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            dismiss()
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var isValid: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Group {
                if isSecure {
                    SecureField("Enter \(title.lowercased())", text: $text)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                }
            }
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isValid ? Color.white.opacity(0.3) : Color.red, lineWidth: 1)
                    )
            )
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
