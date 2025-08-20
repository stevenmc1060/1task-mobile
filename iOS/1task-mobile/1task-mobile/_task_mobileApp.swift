//
//  _task_mobileApp.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

@main
struct _task_mobileApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.showSplash {
                    SplashScreenView()
                        .environmentObject(appState)
                } else if !appState.isLoggedIn {
                    ContentView()
                        .environmentObject(appState)
                        .onAppear {
                            // Debug: Log app state when login screen appears
                            print("🎯 App State Debug:")
                            print("   📱 showSplash: \(appState.showSplash)")
                            print("   👤 isLoggedIn: \(appState.isLoggedIn)")
                            print("   🆔 userId: \(appState.userId)")
                            print("   👥 userName: \(appState.userName)")
                            print("   📧 userEmail: \(appState.userEmail)")
                            print("   🔐 MSAL isAuthenticated: \(appState.authService.isAuthenticated)")
                            print("   📊 Tasks count: \(appState.tasks.count)")
                            print("   🎯 Habits count: \(appState.habits.count)")
                            print("   🏆 Goals count: \(appState.goals.count)")
                            print("   📁 Projects count: \(appState.projects.count)")
                        }
                } else {
                    DashboardView()
                        .environmentObject(appState)
                        .onAppear {
                            // Debug: Log app state when dashboard appears
                            print("🎯 Dashboard Appeared - App State Debug:")
                            print("   👤 isLoggedIn: \(appState.isLoggedIn)")
                            print("   🆔 userId: \(appState.userId)")
                            print("   👥 userName: \(appState.userName)")
                            print("   📧 userEmail: \(appState.userEmail)")
                            print("   📊 Tasks count: \(appState.tasks.count)")
                            print("   🎯 Habits count: \(appState.habits.count)")
                            print("   🏆 Goals count: \(appState.goals.count)")
                            print("   📁 Projects count: \(appState.projects.count)")
                            
                            // Try to sync data from backend when dashboard appears
                            if appState.tasks.isEmpty && appState.habits.isEmpty && 
                               appState.goals.isEmpty && appState.projects.isEmpty {
                                print("🔄 Starting data sync because all arrays are empty")
                                appState.syncDataFromBackend()
                            } else {
                                print("📊 Skipping data sync - arrays not empty")
                            }
                        }
                }
            }
            .alert("Error", isPresented: $appState.showingError) {
                Button("OK") {
                    appState.showingError = false
                }
            } message: {
                Text(appState.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}
