//
//  HabitsEditorView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct HabitsEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            habitsScrollView
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
                .environmentObject(appState)
        }
    }
    
    private var habitsScrollView: some View {
        ScrollView {
            habitsListView
        }
        .navigationTitle("Habits")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarItems(
            leading: doneButton,
            trailing: addButton
        )
    }
    
    private var habitsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(appState.todaysHabits.indices, id: \.self) { index in
                let habit = appState.todaysHabits[index]
                habitRow(for: habit)
            }
        }
        .padding()
    }
    
    private func habitRow(for habit: Habit) -> some View {
        HabitRowView(habit: habit)
            .swipeActions(edge: .trailing) {
                Button("Delete") {
                    appState.deleteHabit(habit.id)
                }
                .tint(.red)
            }
    }
    
    private var doneButton: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var addButton: some View {
        Button(action: { showingAddHabit = true }) {
            Image(systemName: "plus")
                .font(.title3)
                .fontWeight(.medium)
        }
    }
}

struct AddHabitView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var frequency: HabitFrequency = .daily
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Habit name", text: $title)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newHabit = Habit(
                        title: title,
                        frequency: frequency
                    )
                    appState.addHabit(newHabit)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// Fix HabitRowView to use Habit model
struct HabitRowView: View {
    let habit: Habit
    
    private var isHabitCompleted: Bool {
        habit.currentCount >= habit.targetCount
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { 
                // TODO: Implement habit completion via AppState method
            }) {
                ZStack {
                    Circle()
                        .stroke(isHabitCompleted ? Color.green : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isHabitCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.body)
                    .foregroundColor(isHabitCompleted ? .secondary : .primary)
                
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("\(habit.currentStreak) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
    }
}

#Preview {
    HabitsEditorView()
        .environmentObject(AppState())
}
