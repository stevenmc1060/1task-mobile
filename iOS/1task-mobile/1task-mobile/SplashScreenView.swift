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
            // Dark background to match the logo
            Color.black
                .ignoresSafeArea()
            
            // Subtle animated glow effect
            RadialGradient(
                colors: showGradient ? 
                    [Color.blue.opacity(0.3), Color.clear] :
                    [Color.blue.opacity(0.1), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: showGradient)
            
            VStack(spacing: 40) {
                // OneTask Logo
                Image("OneTaskLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // App name and tagline
                VStack(spacing: 12) {
                    Text("OneTask Assistant")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: titleOffset)
                        .opacity(logoOpacity)
                    
                    Text("Your AI-Powered Productivity Companion")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
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
        // Start subtle glow animation
        showGradient = true
        
        // Animate logo with a smooth entrance
        withAnimation(.easeOut(duration: 1.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animate title with slight delay for dramatic effect
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            titleOffset = 0
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AppState())
}
