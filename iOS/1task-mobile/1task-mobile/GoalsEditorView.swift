//
//  GoalsEditorView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct GoalsEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddGoal = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(appState.activeGoals.indices, id: \.self) { index in
                        GoalRowView(goal: appState.activeGoals[index])
                            .swipeActions(edge: .trailing) {
                                Button("Delete") {
                                    let goalId = appState.activeGoals[index].id
                                    appState.deleteGoal(goalId)
                                }
                                .tint(.red)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: { showingAddGoal = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            )
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
                .environmentObject(appState)
        }
    }
}

struct AddGoalView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var deadline: Date = {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Goal title", text: $title)
                    
                    TextField("Description (optional)", text: $description)
                    
                    DatePicker("Target deadline", selection: $deadline, displayedComponents: .date)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newGoal = Goal(
                        title: title,
                        description: description.isEmpty ? nil : description,
                        weekStartDate: deadline
                    )
                    appState.addGoal(newGoal)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

#Preview {
    GoalsEditorView()
        .environmentObject(AppState())
}
