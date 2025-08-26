//
//  ContentView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("1TaskAssistant")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your intelligent task companion")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Connect with Microsoft to sync your tasks across all devices")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            if let error = appState.errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Show retry options for authentication errors
                    if error.contains("authentication") || error.contains("Device") || error.contains("-50000") || error.contains("Keychain") || error.contains("broker key") {
                        VStack(spacing: 8) {
                            // First row - primary recovery options
                            HStack(spacing: 12) {
                                Button("Fix Broker Key") {
                                    appState.authService.handleBrokerKeyError()
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                                
                                Button("Web-View Only") {
                                    appState.authService.authenticateWithWebViewOnly()
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                                
                                Button("Demo Login") {
                                    appState.loginAsDemo()
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(6)
                            }
                            
                            // Second row - advanced options
                            if error.contains("-34018") || error.contains("broker key") {
                                VStack(spacing: 4) {
                                    Text("⚠️ Keychain entitlement issue detected. Try 'Web-View Only' - Microsoft Authenticator is not the problem")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Show Solution Guide") {
                                        appState.authService.showDeviceSpecificGuidance()
                                    }
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Simple button without trailing closure
            SignInButton(appState: appState)
            
            // Demo login button for testing and device compatibility
            Button("Demo Login (Skip Auth)") {
                appState.loginAsDemo()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.caption)
            
            Text("Use Demo Login if Microsoft authentication fails on your device")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("Secure OAuth 2.0 authentication")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationBarHidden(true)
    }
}

struct SignInButton: View {
    let appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary Microsoft Sign-In Button
            Button(action: {
                handleMicrosoftSignIn()
            }) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("Sign in with Microsoft")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Alternative Demo Sign-In Button
            Button(action: {
                handleDemoSignIn()
            }) {
                HStack {
                    Image(systemName: "theatermasks")
                    Text("Continue with Demo Account")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.purple)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(12)
            }
            
            Text("Demo mode gives you full access to all features - perfect for testing the app!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }
    
    private func handleMicrosoftSignIn() {
        print("🔘 Microsoft sign in button tapped!")
        print("   AppState available: \(appState)")
        print("   Auth service available: \(appState.authService)")
        
        // Call your working Microsoft authentication
        appState.loginWithMSAL()
        print("✅ Called appState.loginWithMSAL()")
    }
    
    private func handleDemoSignIn() {
        print("🎭 Demo sign in button tapped!")
        print("   AppState available: \(appState)")
        
        // Call demo authentication
        appState.loginAsDemo()
        print("✅ Called appState.loginAsDemo()")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
