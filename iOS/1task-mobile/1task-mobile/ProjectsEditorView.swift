//
//  ProjectsEditorView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI

struct ProjectsEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddProject = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(appState.activeProjects.indices, id: \.self) { index in
                        ProjectRowView(project: appState.activeProjects[index])
                            .swipeActions(edge: .trailing) {
                                Button("Delete") {
                                    let projectId = appState.activeProjects[index].id
                                    appState.deleteProject(projectId)
                                }
                                .tint(.red)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: { showingAddProject = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            )
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView()
                .environmentObject(appState)
        }
    }
}

struct AddProjectView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var status: ProjectStatus = .planning
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project title", text: $title)
                    
                    TextField("Description (optional)", text: $description)
                    
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newProject = Project(
                        title: title,
                        description: description.isEmpty ? nil : description,
                        status: status
                    )
                    appState.addProject(newProject)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

#Preview {
    ProjectsEditorView()
        .environmentObject(AppState())
}
