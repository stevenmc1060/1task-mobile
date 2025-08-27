//
//  AddItemView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct AddItemView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedType: AddItemType = .task
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date = Date()
    @State private var showingDatePicker = false
    @State private var showingChatAssistant = false
    
    // Goal specific
    @State private var deadline: Date = {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }()
    @State private var category: String = "General"
    @State private var targetValue: String = "100"
    @State private var unit: String = "percent"
    
    // Habit specific
    @State private var frequency: HabitFrequency = .daily
    @State private var habitTargetValue: String = "1"
    @State private var habitUnit: String = "session"
    @State private var habitCategory: String = "General"
    
    // Project specific
    @State private var projectStatus: ProjectStatus = .planning
    @State private var startDate: Date = Date()
    @State private var endDate: Date = {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Type picker
                    typePicker
                    
                    // Chat Assistant button
                    chatAssistantButton
                    
                    // Title input
                    titleInput
                    
                    // Type-specific inputs
                    typeSpecificInputs
                    
                    // Notes input
                    notesInput
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Add New Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    addItem()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    // MARK: - Type Picker
    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What would you like to add?")
                .font(.headline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(AddItemType.allCases, id: \.self) { type in
                    TypePickerCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.spring()) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Title Input
    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedType.title) Title")
                .font(.headline)
                .fontWeight(.medium)
            
            TextField("Enter \(selectedType.title.lowercased()) title...", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
    }
    
    // MARK: - Type Specific Inputs
    @ViewBuilder
    private var typeSpecificInputs: some View {
        switch selectedType {
        case .task:
            taskSpecificInputs
        case .habit:
            habitSpecificInputs
        case .goal:
            goalSpecificInputs
        case .project:
            projectSpecificInputs
        }
    }
    
    private var taskSpecificInputs: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                Text("Due Date (Optional)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Toggle("Set due date", isOn: $showingDatePicker)
                
                if showingDatePicker {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
            }
        }
    }
    
    private var habitSpecificInputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency")
                .font(.headline)
                .fontWeight(.medium)
            
            Picker("Frequency", selection: $frequency) {
                ForEach(HabitFrequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue.capitalized).tag(freq)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var goalSpecificInputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Deadline")
                .font(.headline)
                .fontWeight(.medium)
            
            DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
        }
    }
    
    private var projectSpecificInputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project Details")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("You can add tasks and set milestones after creating the project.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Notes Input
    private var notesInput: some View {
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
    }
    
    // MARK: - Chat Assistant Button
    private var chatAssistantButton: some View {
        Button(action: { showingChatAssistant = true }) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text("Chat with Assistant")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingChatAssistant) {
            ChatAssistantView()
                .environmentObject(appState)
        }
    }
    
    // MARK: - Add Item Function
    private func addItem() {
        switch selectedType {
        case .task:
            let newTask = Task(
                title: title,
                description: notes.isEmpty ? nil : notes,
                status: .pending,
                priority: priority,
                dueDate: showingDatePicker ? dueDate : nil
            )
            appState.addTask(newTask)
            
        case .habit:
            let newHabit = Habit(
                title: title,
                description: notes.isEmpty ? nil : notes,
                frequency: frequency
            )
            appState.addHabit(newHabit)
            
        case .goal:
            let newGoal = Goal(
                title: title,
                description: notes.isEmpty ? nil : notes
            )
            appState.addGoal(newGoal)
            
        case .project:
            let newProject = Project(
                title: title,
                description: notes.isEmpty ? nil : notes,
                status: projectStatus
            )
            appState.addProject(newProject)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Type Picker Card
struct TypePickerCard: View {
    let type: AddItemType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(
                            colors: [type.color, type.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemGray6)
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(type.color, lineWidth: isSelected ? 2 : 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    AddItemView()
        .environmentObject(AppState())
}
