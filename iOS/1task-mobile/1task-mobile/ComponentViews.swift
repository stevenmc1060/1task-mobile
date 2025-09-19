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
    @State private var showingEditSheet = false
    
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
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            TaskEditView(task: task)
                .environmentObject(appState)
        }
    }
    
    private func toggleTaskCompletion() {
        var updatedTask = task
        if task.status == .completed {
            // Mark as pending (uncomplete)
            updatedTask.status = .pending
            updatedTask.completedAt = nil
        } else {
            // Mark as completed
            updatedTask.status = .completed
            updatedTask.completedAt = Date()
        }
        
        print("🔄 Updating task: \(updatedTask.title) to status: \(updatedTask.status)")
        appState.updateTask(updatedTask)
    }
}

// MARK: - Habit Row View (Simple version for dashboard)
struct SimpleHabitRowView: View {
    let habit: Habit
    @EnvironmentObject var appState: AppState
    @State private var currentProgress: Int = 0
    @State private var showingEditSheet = false
    
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
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitEditView(habit: habit)
                .environmentObject(appState)
        }
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
    @EnvironmentObject var appState: AppState
    @State private var showingEditSheet = false
    
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
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            GoalEditView(goal: goal)
                .environmentObject(appState)
        }
    }
}

// MARK: - Project Row View
struct ProjectRowView: View {
    let project: Project
    @EnvironmentObject var appState: AppState
    @State private var showingEditSheet = false
    
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
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            ProjectEditView(project: project)
                .environmentObject(appState)
        }
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

// MARK: - Task Edit View
struct TaskEditView: View {
    let task: Task
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var notes: String
    @State private var priority: TaskPriority
    @State private var dueDate: Date
    @State private var showingDatePicker: Bool
    @State private var showingDeleteAlert = false
    
    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.description ?? "")
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _showingDatePicker = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Title")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter task title...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Priority picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                HStack {
                                    Circle()
                                        .fill(priority.color)
                                        .frame(width: 12, height: 12)
                                    Text(priority.rawValue.capitalized)
                                }
                                .tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Due date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Toggle("Set due date", isOn: $showingDatePicker)
                        
                        if showingDatePicker {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }
                    }
                    
                    // Notes input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Delete button
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Task")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                appState.deleteTask(task.id)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = notes.isEmpty ? nil : notes
        updatedTask.priority = priority
        updatedTask.dueDate = showingDatePicker ? dueDate : nil
        
        appState.updateTask(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Habit Edit View
struct HabitEditView: View {
    let habit: Habit
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var frequency: HabitFrequency
    @State private var targetCount: Int
    @State private var status: HabitStatus
    @State private var reminderTime: String
    @State private var hasReminder: Bool
    @State private var showingDeleteAlert = false
    
    init(habit: Habit) {
        self.habit = habit
        _title = State(initialValue: habit.title)
        _description = State(initialValue: habit.description ?? "")
        _frequency = State(initialValue: habit.frequency)
        _targetCount = State(initialValue: habit.targetCount)
        _status = State(initialValue: habit.status)
        _reminderTime = State(initialValue: habit.reminderTime ?? "")
        _hasReminder = State(initialValue: habit.reminderTime != nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habit Title")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter habit title...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Description input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Frequency picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Frequency", selection: $frequency) {
                            ForEach(HabitFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue.capitalized)
                                    .tag(frequency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Target count
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Count")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Button(action: { 
                                if targetCount > 1 { targetCount -= 1 }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.orange)
                            }
                            .disabled(targetCount <= 1)
                            
                            Text("\(targetCount)")
                                .frame(minWidth: 40)
                                .font(.headline)
                            
                            Button(action: { targetCount += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("Times per \(frequency.rawValue.lowercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Status picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Status", selection: $status) {
                            ForEach(HabitStatus.allCases, id: \.self) { status in
                                Text(status.rawValue.capitalized)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Reminder toggle and time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Toggle("Set reminder", isOn: $hasReminder)
                        
                        if hasReminder {
                            TextField("Reminder time (e.g., 08:00)", text: $reminderTime)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                    }
                    
                    // Progress info (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress Statistics")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Current Streak:")
                                Spacer()
                                Text("\(habit.currentStreak) days")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Longest Streak:")
                                Spacer()
                                Text("\(habit.longestStreak) days")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Total Completions:")
                                Spacer()
                                Text("\(habit.totalCompletions)")
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .font(.body)
                    }
                    
                    // Delete button
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Habit")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveHabit()
                }
                .disabled(title.isEmpty)
            )
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                appState.deleteHabit(habit.id)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
    }
    
    private func saveHabit() {
        var updatedHabit = habit
        updatedHabit.title = title
        updatedHabit.description = description.isEmpty ? nil : description
        updatedHabit.frequency = frequency
        updatedHabit.targetCount = targetCount
        updatedHabit.status = status
        updatedHabit.reminderTime = hasReminder && !reminderTime.isEmpty ? reminderTime : nil
        
        appState.updateHabit(updatedHabit)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Goal Edit View
struct GoalEditView: View {
    let goal: Goal
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var status: GoalStatus
    @State private var progressPercentage: Double
    @State private var keyMetrics: String
    @State private var targetYear: Int
    @State private var targetQuarter: Int
    @State private var weekStartDate: Date
    @State private var goalType: GoalType
    @State private var showingDeleteAlert = false
    
    init(goal: Goal) {
        self.goal = goal
        _title = State(initialValue: goal.title)
        _description = State(initialValue: goal.description ?? "")
        _status = State(initialValue: goal.status)
        _progressPercentage = State(initialValue: goal.progressPercentage)
        _keyMetrics = State(initialValue: goal.keyMetrics.joined(separator: ", "))
        _targetYear = State(initialValue: goal.targetYear ?? Calendar.current.component(.year, from: Date()))
        _targetQuarter = State(initialValue: goal.targetQuarter ?? 1)
        _weekStartDate = State(initialValue: goal.weekStartDate ?? Date())
        _goalType = State(initialValue: goal.goalType)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Title")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter goal title...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Description input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Goal type picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Type")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Goal Type", selection: $goalType) {
                            ForEach(GoalType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Type-specific inputs
                    if goalType == .weekly {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week Start Date")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            DatePicker("Week Start Date", selection: $weekStartDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }
                    } else if goalType == .quarterly {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Quarter & Year")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Picker("Quarter", selection: $targetQuarter) {
                                    Text("Q1").tag(1)
                                    Text("Q2").tag(2)
                                    Text("Q3").tag(3)
                                    Text("Q4").tag(4)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                Spacer()
                                
                                Picker("Year", selection: $targetYear) {
                                    ForEach(2024...2030, id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(maxWidth: 100)
                            }
                        }
                    } else if goalType == .yearly {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Year")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Picker("Year", selection: $targetYear) {
                                ForEach(2024...2030, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    
                    // Status picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Status", selection: $status) {
                            ForEach(GoalStatus.allCases, id: \.self) { status in
                                Text(status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                    .tag(status)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Progress slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $progressPercentage, in: 0...100, step: 1)
                                .tint(goalType.color)
                            
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Current: \(Int(progressPercentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Key metrics input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Metrics (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter metrics separated by commas...", text: $keyMetrics)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                        
                        Text("Example: Revenue targets, Customer acquisition, etc.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Delete button
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Goal")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveGoal()
                }
                .disabled(title.isEmpty)
            )
        }
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                appState.deleteGoal(goal.id)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
    }
    
    private func saveGoal() {
        var updatedGoal = goal
        updatedGoal.title = title
        updatedGoal.description = description.isEmpty ? nil : description
        updatedGoal.status = status
        updatedGoal.progressPercentage = progressPercentage
        updatedGoal.keyMetrics = keyMetrics.isEmpty ? [] : keyMetrics.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Update goal type-specific fields
        switch goalType {
        case .weekly:
            updatedGoal.weekStartDate = weekStartDate
            updatedGoal.targetQuarter = nil
            updatedGoal.targetYear = nil
        case .quarterly:
            updatedGoal.weekStartDate = nil
            updatedGoal.targetQuarter = targetQuarter
            updatedGoal.targetYear = targetYear
        case .yearly:
            updatedGoal.weekStartDate = nil
            updatedGoal.targetQuarter = nil
            updatedGoal.targetYear = targetYear
        }
        
        appState.updateGoal(updatedGoal)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Project Edit View
struct ProjectEditView: View {
    let project: Project
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var status: ProjectStatus
    @State private var priority: TaskPriority
    @State private var progressPercentage: Double
    @State private var tags: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasStartDate: Bool
    @State private var hasEndDate: Bool
    @State private var showingDeleteAlert = false
    
    init(project: Project) {
        self.project = project
        _title = State(initialValue: project.title)
        _description = State(initialValue: project.description ?? "")
        _status = State(initialValue: project.status)
        _priority = State(initialValue: project.priority)
        _progressPercentage = State(initialValue: project.progressPercentage)
        _tags = State(initialValue: project.tags.joined(separator: ", "))
        _startDate = State(initialValue: project.startDate ?? Date())
        _endDate = State(initialValue: project.endDate ?? Date())
        _hasStartDate = State(initialValue: project.startDate != nil)
        _hasEndDate = State(initialValue: project.endDate != nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Title")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter project title...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Description input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Status picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Status", selection: $status) {
                            ForEach(ProjectStatus.allCases, id: \.self) { status in
                                Text(status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                    .tag(status)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Priority picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                HStack {
                                    Circle()
                                        .fill(priority.color)
                                        .frame(width: 12, height: 12)
                                    Text(priority.rawValue.capitalized)
                                }
                                .tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Progress slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $progressPercentage, in: 0...100, step: 1)
                                .tint(.orange)
                            
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Current: \(Int(progressPercentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Start date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Toggle("Set start date", isOn: $hasStartDate)
                        
                        if hasStartDate {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }
                    }
                    
                    // End date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Date")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Toggle("Set end date", isOn: $hasEndDate)
                        
                        if hasEndDate {
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }
                    }
                    
                    // Tags input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter tags separated by commas...", text: $tags)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                        
                        Text("Example: frontend, mobile, urgent")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Delete button
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Project")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProject()
                }
                .disabled(title.isEmpty)
            )
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                appState.deleteProject(project.id)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
        }
    }
    
    private func saveProject() {
        var updatedProject = project
        updatedProject.title = title
        updatedProject.description = description.isEmpty ? nil : description
        updatedProject.status = status
        updatedProject.priority = priority
        updatedProject.progressPercentage = progressPercentage
        updatedProject.tags = tags.isEmpty ? [] : tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        updatedProject.startDate = hasStartDate ? startDate : nil
        updatedProject.endDate = hasEndDate ? endDate : nil
        
        appState.updateProject(updatedProject)
        presentationMode.wrappedValue.dismiss()
    }
}
