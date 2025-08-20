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
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            Spacer()
            
            // Simple button without trailing closure
            SignInButton(appState: appState)
            
            // Temporary demo login button for testing
            Button("Demo Login (Skip Auth)") {
                appState.loginAsDemo()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.caption)
            
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
