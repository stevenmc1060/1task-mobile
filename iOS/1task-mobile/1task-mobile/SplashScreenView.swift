//
//  SplashScreenView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 50
    @State private var showGradient = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: showGradient ? 
                    [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.pink.opacity(0.4)] :
                    [Color.blue.opacity(0.3), Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showGradient)
            
            VStack(spacing: 30) {
                // Logo placeholder - you can replace with actual logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    
                    Text("1")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name
                VStack(spacing: 8) {
                    Text("1TaskAssistant")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: titleOffset)
                        .opacity(logoOpacity)
                    
                    Text("Your Productivity Companion")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: titleOffset)
                        .opacity(logoOpacity * 0.8)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start gradient animation
        showGradient = true
        
        // Animate logo
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animate title
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            titleOffset = 0
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AppState())
}
