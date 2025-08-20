//
//  TasksEditorView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct TasksEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(appState.todaysTasks) { task in
                        TaskRowView(task: task)
                            .swipeActions(edge: .trailing) {
                                Button("Delete") {
                                    appState.deleteTask(task.id)
                                }
                                .tint(.red)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            )
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(appState)
        }
    }
}

struct AddTaskView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newTask = Task(
                        title: title,
                        priority: priority,
                        dueDate: hasDueDate ? dueDate : nil
                    )
                    appState.addTask(newTask)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// TaskRowView to display individual tasks
struct TaskRowView: View {
    let task: Task
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { 
                // Note: Since task is not a binding, we can't toggle it directly here
                // The completion toggle should be handled by the parent view
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
}

#Preview {
    TasksEditorView()
        .environmentObject(AppState())
}
