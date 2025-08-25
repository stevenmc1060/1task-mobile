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
        Text("Sign in with Microsoft")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .onTapGesture {
                handleSignIn()
            }
    }
    
    private func handleSignIn() {
        // Call your working Microsoft authentication
        appState.loginWithMSAL()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
