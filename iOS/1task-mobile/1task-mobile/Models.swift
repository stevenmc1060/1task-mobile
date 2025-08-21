//
//  Models.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import Foundation
import SwiftUI

// MARK: - Task Item
struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var notes: String?
    
    init(title: String, isCompleted: Bool, priority: Priority, dueDate: Date? = nil, notes: String? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.notes = notes
    }
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

// MARK: - Habit Item
struct HabitItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var streak: Int
    var frequency: Frequency
    
    init(title: String, isCompleted: Bool, streak: Int = 0, frequency: Frequency = .daily) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.streak = streak
        self.frequency = frequency
    }
    
    enum Frequency: String, CaseIterable, Codable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
}

// MARK: - Goal Item
struct GoalItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var progress: Double // 0.0 to 1.0
    var deadline: Date
    var description: String?
    var milestones: [String]
    
    init(title: String, progress: Double, deadline: Date, description: String? = nil, milestones: [String] = []) {
        self.id = UUID()
        self.title = title
        self.progress = progress
        self.deadline = deadline
        self.description = description
        self.milestones = milestones
    }
}

// MARK: - Project Item
struct ProjectItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var progress: Double // 0.0 to 1.0
    var taskCount: Int
    var completedTasks: Int
    var description: String?
    var status: ProjectStatus
    
    init(title: String, progress: Double, taskCount: Int, completedTasks: Int, description: String? = nil, status: ProjectStatus = .active) {
        self.id = UUID()
        self.title = title
        self.progress = progress
        self.taskCount = taskCount
        self.completedTasks = completedTasks
        self.description = description
        self.status = status
    }
    
    enum ProjectStatus: String, CaseIterable, Codable {
        case planning = "Planning"
        case active = "Active"
        case onHold = "On Hold"
        case completed = "Completed"
        
        var color: Color {
            switch self {
            case .planning: return .blue
            case .active: return .green
            case .onHold: return .orange
            case .completed: return .gray
            }
        }
    }
}

// MARK: - Enums
enum TaskStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange  
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - Task (Backend API Model)
struct Task: Identifiable, Codable {
    let id: String
    var title: String
    var description: String?
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    var completedAt: Date?
    var tags: [String]
    var projectId: String?
    var weeklyGoalId: String?
    var habitId: String?
    var estimatedHours: Double?
    var actualHours: Double?
    var createdAt: Date?
    var updatedAt: Date?
    var userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case status
        case priority
        case dueDate = "due_date"
        case completedAt = "completed_at"
        case tags
        case projectId = "project_id"
        case weeklyGoalId = "weekly_goal_id"
        case habitId = "habit_id"
        case estimatedHours = "estimated_hours"
        case actualHours = "actual_hours"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
    
    init(title: String, description: String? = nil, status: TaskStatus = .pending, 
         priority: TaskPriority = .medium, dueDate: Date? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.completedAt = nil
        self.tags = []
        self.projectId = nil
        self.weeklyGoalId = nil
        self.habitId = nil
        self.estimatedHours = nil
        self.actualHours = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = nil
    }
}

// MARK: - Additional Enums
enum GoalStatus: String, CaseIterable, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
}

enum ProjectStatus: String, CaseIterable, Codable {
    case planning = "planning"
    case active = "active"
    case onHold = "on_hold"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var color: Color {
        switch self {
        case .planning: return .blue
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

enum HabitFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

enum HabitStatus: String, CaseIterable, Codable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case archived = "archived"
}

// MARK: - Goal (Backend API Model)
struct Goal: Identifiable, Codable {
    let id: String
    var title: String
    var description: String?
    var status: GoalStatus
    
    // Weekly goal fields
    var weekStartDate: Date?
    var quarterlyGoalId: String?
    var taskIds: [String]?
    
    // Yearly goal fields
    var targetYear: Int?
    var quarterlyGoalIds: [String]?
    
    // Common fields
    var progressPercentage: Double
    var keyMetrics: [String]
    var completedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case weekStartDate = "week_start_date"
        case progressPercentage = "progress_percentage"
        case keyMetrics = "key_metrics"
        case quarterlyGoalId = "quarterly_goal_id"
        case quarterlyGoalIds = "quarterly_goal_ids"
        case taskIds = "task_ids"
        case targetYear = "target_year"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
    
    init(title: String, description: String? = nil, weekStartDate: Date? = nil, targetYear: Int? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.status = .notStarted
        self.weekStartDate = weekStartDate
        self.targetYear = targetYear
        self.progressPercentage = 0.0
        self.keyMetrics = []
        self.quarterlyGoalId = nil
        self.quarterlyGoalIds = nil
        self.taskIds = nil
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = nil
    }
}

// MARK: - Habit (Backend API Model)
struct Habit: Identifiable, Codable {
    let id: String
    var title: String
    var description: String?
    var status: HabitStatus
    var frequency: HabitFrequency
    var targetCount: Int
    var currentCount: Int
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var reminderTime: String?
    var tags: [String]
    var lastCompletedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, frequency, tags
        case targetCount = "target_count"
        case currentCount = "current_count"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalCompletions = "total_completions"
        case reminderTime = "reminder_time"
        case lastCompletedAt = "last_completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
    
    init(title: String, description: String? = nil, frequency: HabitFrequency = .daily) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.status = .active
        self.frequency = frequency
        self.targetCount = 1
        self.currentCount = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.reminderTime = nil
        self.tags = []
        self.lastCompletedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = nil
    }
}

// MARK: - Project (Backend API Model)
struct Project: Identifiable, Codable {
    let id: String
    var title: String
    var description: String?
    var status: ProjectStatus
    var priority: TaskPriority
    var startDate: Date?
    var endDate: Date?
    var progressPercentage: Double
    var tags: [String]
    var taskIds: [String]
    var yearlyGoalId: String?
    var quarterlyGoalId: String?
    var completedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, priority, tags
        case startDate = "start_date"
        case endDate = "end_date"
        case progressPercentage = "progress_percentage"
        case taskIds = "task_ids"
        case yearlyGoalId = "yearly_goal_id"
        case quarterlyGoalId = "quarterly_goal_id"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
    
    init(title: String, description: String? = nil, status: ProjectStatus = .planning) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.status = status
        self.priority = .medium
        self.startDate = nil
        self.endDate = nil
        self.progressPercentage = 0.0
        self.tags = []
        self.taskIds = []
        self.yearlyGoalId = nil
        self.quarterlyGoalId = nil
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = nil
    }
}
