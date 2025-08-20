//
//  ProfileView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showingNameEditor = false
    @State private var newName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    // Quick Stats
                    statsSection
                    
                    // Settings Options
                    settingsSection
                    
                    // Add extra space to ensure Sign Out is visible
                    Spacer()
                        .frame(height: 50)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingNameEditor) {
            nameEditorSheet
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(appState.userName.prefix(1)))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Name and edit button
            VStack(spacing: 8) {
                Text(appState.userName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Button("Edit Name") {
                    newName = appState.userName
                    showingNameEditor = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Tasks Completed",
                    value: "\(appState.todaysTasks.filter { $0.status == .completed }.count)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Habits Tracked",
                    value: "\(appState.todaysHabits.filter { $0.currentCount >= $0.targetCount }.count)",
                    icon: "repeat.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Active Goals",
                    value: "\(appState.activeGoals.count)",
                    icon: "target",
                    color: .purple
                )
                
                StatCard(
                    title: "Projects",
                    value: "\(appState.activeProjects.count)",
                    icon: "folder.fill",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Notifications",
                    icon: "bell.fill",
                    color: .red
                ) {
                    // Handle notifications settings
                }
                
                Divider()
                
                SettingsRow(
                    title: "Data & Sync",
                    icon: "icloud.fill",
                    color: .blue
                ) {
                    // Handle sync settings
                }
                
                Divider()
                
                SettingsRow(
                    title: "Help & Support",
                    icon: "questionmark.circle.fill",
                    color: .green
                ) {
                    // Handle help
                }
                
                Divider()
                
                SettingsRow(
                    title: "About",
                    icon: "info.circle.fill",
                    color: .gray
                ) {
                    // Handle about
                }
                
                Divider()
                
                SettingsRow(
                    title: "Sign Out",
                    icon: "arrow.right.square.fill",
                    color: .red
                ) {
                    print("🚪 Sign Out button tapped!")
                    appState.logout()
                }
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Name Editor Sheet
    private var nameEditorSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter your name", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingNameEditor = false
                },
                trailing: Button("Save") {
                    appState.userName = newName
                    showingNameEditor = false
                }
                .disabled(newName.isEmpty)
            )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
