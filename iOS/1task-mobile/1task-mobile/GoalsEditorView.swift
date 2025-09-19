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
    @State private var goalType: GoalType = .quarterly
    @State private var deadline: Date = {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Goal title", text: $title)
                    
                    TextField("Description (optional)", text: $description)
                    
                    Picker("Goal Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    DatePicker(deadlineLabel, selection: $deadline, displayedComponents: .date)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newGoal = createGoalFromInputs()
                    appState.addGoal(newGoal)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private var deadlineLabel: String {
        switch goalType {
        case .weekly:
            return "Week start date"
        case .quarterly:
            return "Target deadline"
        case .yearly:
            return "Target deadline"
        }
    }
    
    private func createGoalFromInputs() -> Goal {
        let calendar = Calendar.current
        
        switch goalType {
        case .weekly:
            return Goal(
                title: title,
                description: description.isEmpty ? nil : description,
                weekStartDate: deadline
            )
        case .quarterly:
            let quarter = calendar.quarter(from: deadline)
            return Goal(
                title: title,
                description: description.isEmpty ? nil : description,
                targetQuarter: quarter
            )
        case .yearly:
            let year = calendar.component(.year, from: deadline)
            return Goal(
                title: title,
                description: description.isEmpty ? nil : description,
                targetYear: year
            )
        }
    }
}

// MARK: - Calendar Extension
extension Calendar {
    func quarter(from date: Date) -> Int {
        let month = self.component(.month, from: date)
        return (month - 1) / 3 + 1
    }
}

#Preview {
    GoalsEditorView()
        .environmentObject(AppState())
}
