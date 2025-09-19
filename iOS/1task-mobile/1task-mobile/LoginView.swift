//
//  LoginView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
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
                    // OneTask Logo
                    Image("OneTaskLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .shadow(radius: 20)
                    
                    VStack(spacing: 8) {
                        Text("OneTaskAssistant")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("World's First AI-Powered Thought to Action System")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Login buttons
                VStack(spacing: 16) {
                    // Personal Microsoft Account Button
                    Button(action: {
                        appState.authService.signInWithPersonalAccount()
                    }) {
                        HStack {
                            if appState.authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                            }
                            
                            Text(appState.authService.isLoading ? "Signing In..." : "Sign in with Personal Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(appState.authService.isLoading ? 0.7 : 1.0)
                    }
                    .disabled(appState.authService.isLoading)
                    
                    // Work/School Microsoft Account Button
                    Button(action: {
                        appState.authService.signInWithWorkSchoolAccount()
                    }) {
                        HStack {
                            if appState.authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "building.2.fill")
                                    .font(.title2)
                            }
                            
                            Text(appState.authService.isLoading ? "Signing In..." : "Sign in with Work/School Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(appState.authService.isLoading ? 0.7 : 1.0)
                    }
                    .disabled(appState.authService.isLoading)
                    
                    // Error message display
                    if let errorMessage = appState.authService.errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
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
