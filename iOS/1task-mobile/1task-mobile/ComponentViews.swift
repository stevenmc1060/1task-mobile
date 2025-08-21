//
//  ComponentViews.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text("\(count)/\(total)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.horizontal, 8)
        .background(color.gradient)
        .cornerRadius(16)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Task Row View (Simple version for dashboard)
struct SimpleTaskRowView: View {
    let task: Task
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                toggleTaskCompletion()
            }) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.status == .completed ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                if let dueDate = task.dueDate {
                    Text("Due \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Priority indicator
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func toggleTaskCompletion() {
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .pending : .completed
        appState.updateTask(updatedTask)
    }
}

// MARK: - Habit Row View (Simple version for dashboard)
struct SimpleHabitRowView: View {
    let habit: Habit
    @EnvironmentObject var appState: AppState
    @State private var currentProgress: Int = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                toggleHabitProgress()
            }) {
                ZStack {
                    Circle()
                        .stroke(currentProgress >= habit.targetCount ? Color.green : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if currentProgress >= habit.targetCount {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.body)
                    .foregroundColor(currentProgress >= habit.targetCount ? .secondary : .primary)
                
                Text("\(currentProgress)/\(habit.targetCount) completions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(habit.frequency.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            // TODO: Load today's progress from API or local storage
            currentProgress = 0
        }
    }
    
    private func toggleHabitProgress() {
        if currentProgress >= habit.targetCount {
            currentProgress = 0
        } else {
            currentProgress += 1
        }
        // TODO: Save progress to backend
    }
}

// MARK: - Goal Row View
struct GoalRowView: View {
    let goal: Goal
    
    private var progress: Double {
        return goal.progressPercentage / 100.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(goal.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Goal type tag
                        HStack(spacing: 4) {
                            Image(systemName: goal.goalType.icon)
                                .font(.caption2)
                            Text(goal.goalType.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(goal.goalType.color.opacity(0.1))
                        .foregroundColor(goal.goalType.color)
                        .cornerRadius(8)
                    }
                    
                    if let description = goal.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Additional info based on goal type
                    if let weekStart = goal.weekStartDate {
                        Text("Week of \(weekStart, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if let quarter = goal.targetQuarter, let year = goal.targetYear {
                        Text("Q\(quarter) \(year)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if let year = goal.targetYear {
                        Text("\(year)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progressPercentage))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .tint(goal.goalType.color)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Project Row View
struct ProjectRowView: View {
    let project: Project
    
    private var progressPercentage: Double {
        return project.progressPercentage / 100.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if let startDate = project.startDate, let endDate = project.endDate {
                        Text("\(startDate, style: .date) - \(endDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(project.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(project.status.color.opacity(0.1))
                    .foregroundColor(project.status.color)
                    .cornerRadius(8)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("\(Int(project.progressPercentage))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(project.priority.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(project.priority.color)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Goal Filter Chip
struct GoalFilterChip: View {
    let type: GoalType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    if isSelected {
                        type.color
                    } else {
                        Color(.systemGray5)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .opacity(isSelected ? 1.0 : 0.7)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
