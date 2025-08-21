//
//  DashboardView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingProfile = false
    @State private var showingTasksEditor = false
    @State private var showingHabitsEditor = false
    @State private var showingGoalsEditor = false
    @State private var showingProjectsEditor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with greeting and quick add
                    headerSection
                    
                    // Quick stats
                    quickStatsSection
                    
                    // Today's Tasks
                    tasksSection
                    
                    // Today's Habits
                    habitsSection
                    
                    // Active Goals
                    goalsSection
                    
                    // Active Projects
                    projectsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $appState.showingAddSheet) {
            AddItemView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingTasksEditor) {
            TasksEditorView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingHabitsEditor) {
            HabitsEditorView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingGoalsEditor) {
            GoalsEditorView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingProjectsEditor) {
            ProjectsEditorView()
                .environmentObject(appState)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(greetingTime)!")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\(appState.userFirstName)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Profile button
            Button(action: { showingProfile = true }) {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(appState.userFirstName.prefix(1)))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.top)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 15) {
            QuickStatCard(
                title: "Tasks",
                count: appState.todaysTasks.filter { $0.status != .completed }.count,
                total: appState.todaysTasks.count,
                color: .blue,
                icon: "checkmark.circle.fill"
            )
            
            QuickStatCard(
                title: "Habits",
                count: appState.todaysHabits.filter { $0.status == .active }.count,
                total: appState.todaysHabits.count,
                color: .green,
                icon: "repeat.circle.fill"
            )
            
            // Quick Add Button
            Button(action: { appState.showingAddSheet = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Tasks Section
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Today's Tasks",
                count: appState.todaysTasks.count,
                action: { showingTasksEditor = true }
            )
            
            LazyVStack(spacing: 8) {
                ForEach(appState.todaysTasks.prefix(3)) { task in
                    SimpleTaskRowView(task: task)
                        .environmentObject(appState)
                }
                
                if appState.todaysTasks.count > 3 {
                    Button("View all \(appState.todaysTasks.count) tasks") {
                        // Navigate to full tasks view
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Habits Section
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Today's Habits",
                count: appState.todaysHabits.count,
                action: { showingHabitsEditor = true }
            )
            
            LazyVStack(spacing: 8) {
                ForEach(appState.todaysHabits) { habit in
                    SimpleHabitRowView(habit: habit)
                        .environmentObject(appState)
                }
            }
        }
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Active Goals",
                count: appState.activeGoals.count,
                action: { showingGoalsEditor = true }
            )
            
            // Goal type filters
            goalTypeFilters
            
            LazyVStack(spacing: 8) {
                ForEach(appState.activeGoals) { goal in
                    GoalRowView(goal: goal)
                }
            }
        }
    }
    
    // MARK: - Projects Section
    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Active Projects",
                count: appState.activeProjects.count,
                action: { showingProjectsEditor = true }
            )
            
            LazyVStack(spacing: 8) {
                ForEach(appState.activeProjects) { project in
                    ProjectRowView(project: project)
                }
            }
        }
    }
    
    // MARK: - Goal Type Filters
    private var goalTypeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                GoalFilterChip(
                    type: .weekly,
                    isSelected: appState.showWeeklyGoals,
                    count: appState.goals.filter { $0.goalType == .weekly && $0.status != .completed }.count
                ) {
                    appState.showWeeklyGoals.toggle()
                }
                
                GoalFilterChip(
                    type: .quarterly,
                    isSelected: appState.showQuarterlyGoals,
                    count: appState.goals.filter { $0.goalType == .quarterly && $0.status != .completed }.count
                ) {
                    appState.showQuarterlyGoals.toggle()
                }
                
                GoalFilterChip(
                    type: .yearly,
                    isSelected: appState.showYearlyGoals,
                    count: appState.goals.filter { $0.goalType == .yearly && $0.status != .completed }.count
                ) {
                    appState.showYearlyGoals.toggle()
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
    }
    
    private var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
