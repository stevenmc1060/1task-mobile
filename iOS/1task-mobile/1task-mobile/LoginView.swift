//
//  LoginView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email: String = ""
    @State private var isLoggingIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo section
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 100, height: 100)
                            .shadow(radius: 20)
                        
                        Text("1")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 8) {
                        Text("1TaskAssistant")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your Productivity Companion")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Login form
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        // Microsoft Sign-In Button
                        Button(action: {
                            appState.loginWithMSAL()
                        }) {
                            HStack {
                                if appState.authService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.title2)
                                }
                                
                                Text(appState.authService.isLoading ? "Signing In..." : "Sign in with Microsoft")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .opacity(appState.authService.isLoading ? 0.7 : 1.0)
                        }
                        .disabled(appState.authService.isLoading)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.white.opacity(0.3))
                        }
                        
                        TextField("Email address", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        // Quick demo button
                        Button(action: {
                            // Login as demo user
                            appState.loginAsDemo()
                        }) {
                            Text("Continue as Demo User")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            loginUser()
                        }) {
                            HStack {
                                if isLoggingIn {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                
                                Text(isLoggingIn ? "Signing In..." : "Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .opacity(email.isEmpty ? 0.6 : 1.0)
                        }
                        .disabled(email.isEmpty || isLoggingIn)
                    }
                    
                    // Sign up option
                    HStack {
                        Text("New to 1TaskAssistant?")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Sign Up") {
                            showingSignUp = true
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding(.top, 60)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(appState)
        }
    }
    
    private func loginUser() {
        isLoggingIn = true
        
        // Simulate login process - in a real app this would authenticate with backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoggingIn = false
            
            // Extract username from email and create user ID
            let userName = email.components(separatedBy: "@").first?.capitalized ?? "User"
            let userId = email.lowercased().replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_")
            
            // Use the new login method that syncs with backend
            appState.login(userId: userId, userName: userName)
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 20) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Join thousands of productive users")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 16) {
                        TextField("Full name", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        TextField("Email address", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        Button("Create Account") {
                            // Set user info and login
                            appState.userName = name.isEmpty ? email.components(separatedBy: "@").first?.capitalized ?? "User" : name
                            appState.userId = UUID().uuidString
                            
                            presentationMode.wrappedValue.dismiss()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    appState.isLoggedIn = true
                                }
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .disabled(name.isEmpty || email.isEmpty)
                        .opacity((name.isEmpty || email.isEmpty) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
