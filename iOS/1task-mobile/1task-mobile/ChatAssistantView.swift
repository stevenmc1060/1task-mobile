//
//  ChatAssistantView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI
import Combine

struct ChatAssistantView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var messageText: String = ""
    @State private var messages: [DisplayChatMessage] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showingDebugInfo = false
    @State private var showingTestQueries = false
    @State private var currentMessage = ""
    
    // Suggested prompts for RAG queries
    private let suggestedPrompts = [
        "What tasks are due this week?",
        "Show me my project progress",
        "Which habits need attention?",
        "Suggest tasks for my [project name]",
        "What should I focus on today?",
        "How are my goals progressing?"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                            }
                            
                            // Show suggestions if only welcome message exists
                            if messages.count == 1 {
                                suggestionChipsView
                                
                                // Add debug tests in development builds
                                #if DEBUG
                                debugTestsView
                                #endif
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Assistant is thinking...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if isLoading {
                                proxy.scrollTo("loading", anchor: .bottom)
                            } else if let lastMessage = messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isLoading) { oldValue, newValue in
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Message input
                HStack {
                    TextField("Ask about your tasks, projects, goals, or habits...", text: $messageText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty || isLoading ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if messages.isEmpty {
                    addWelcomeMessage()
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if showingDebugInfo {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingDebugInfo = false
                            }
                        debugRAGContextView
                    }
                }
            )
            .overlay(
                Group {
                    if showingTestQueries {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingTestQueries = false
                            }
                        testRAGQueryView
                    }
                }
            )
        }
    }
    
    private func addWelcomeMessage() {
        // Generate context-aware suggestions
        var contextSuggestions: [String] = []
        
        // If user has no data, provide helpful guidance
        let totalItems = appState.tasks.count + appState.habits.count + appState.goals.count + appState.projects.count
        if totalItems == 0 {
            contextSuggestions.append("🚀 **Getting Started**: Create some tasks, habits, goals, or projects first!")
            contextSuggestions.append("📝 Use the Dashboard to add your productivity data")
            contextSuggestions.append("🎯 Then I can provide personalized insights about your progress")
        } else {
            // Check for overdue tasks
            let overdueTasks = appState.tasks.filter { task in
                guard let dueDate = task.dueDate, task.status != .completed else { return false }
                return dueDate < Date()
            }
            if !overdueTasks.isEmpty {
                contextSuggestions.append("📅 I notice you have \(overdueTasks.count) overdue tasks")
            }
            
            // Check for projects without recent activity
            let projectsWithTasks = Set(appState.tasks.compactMap { $0.projectId })
            let inactiveProjects = appState.activeProjects.filter { !projectsWithTasks.contains($0.id) }
            if !inactiveProjects.isEmpty {
                contextSuggestions.append("📁 Some projects might need attention")
            }
            
            // Check habit progress
            let strugglingHabits = appState.todaysHabits.filter { $0.currentCount < $0.targetCount / 2 }
            if !strugglingHabits.isEmpty {
                contextSuggestions.append("🎯 Some habits could use a boost")
            }
        }
        
        let contextText = contextSuggestions.isEmpty ? "" : "\n\n**Quick Insights:**\n" + contextSuggestions.map { "• \($0)" }.joined(separator: "\n")
        
        let welcomeMessage = DisplayChatMessage(
            id: UUID().uuidString,
            content: "Hi \(appState.computedUserFirstName)! I'm your AI assistant with **full access** to all your productivity data. I can help you with:\n\n• **Project Analysis**: \"For my project 'XXX', suggest tasks I should add\"\n• **Task Management**: \"What tasks are due this week?\" or \"Show me high-priority pending tasks\"\n• **Goal Insights**: \"How am I progressing on my quarterly goals?\"\n• **Habit Tracking**: \"Which habits need attention today?\"\n• **Cross-Analysis**: \"What projects are blocking my weekly goals?\"\n• **Recommendations**: \"Based on my workload, what should I focus on?\"\n\n**📊 Current Data Available:**\n• **Tasks**: \(appState.tasks.count) total (\(appState.tasks.filter { $0.status != .completed }.count) pending)\n• **Habits**: \(appState.habits.count) active\n• **Goals**: \(appState.goals.count) tracked\n• **Projects**: \(appState.projects.count) ongoing\(contextText)\n\n**🤖 RAG-Enhanced Assistant**: Every message includes your complete productivity context for personalized responses.\n\nWhat would you like to know?",
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        let messageToSend = currentMessage.isEmpty ? messageText : currentMessage
        guard !messageToSend.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = DisplayChatMessage(
            id: UUID().uuidString,
            content: messageToSend,
            isFromUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        let messageToProcess = messageToSend
        messageText = ""
        currentMessage = "" // Clear the current message too
        isLoading = true
        
        print("🧠 Sending chat message - API will fetch fresh RAG context automatically")
        
        // Enhance the message with detected context
        let enhancedMessage = enhanceMessageWithContext(messageToProcess)
        
        // Add debug information when asking about tasks/lists
        if messageToProcess.lowercased().contains("list") || messageToProcess.lowercased().contains("task") {
            print("🔍 DEBUG: User asked about tasks/lists")
            print("📊 Current app data:")
            print("  - Tasks: \(appState.tasks.count)")
            print("  - Habits: \(appState.habits.count)")  
            print("  - Goals: \(appState.goals.count)")
            print("  - Projects: \(appState.projects.count)")
            
            if !appState.tasks.isEmpty {
                print("📋 Sample tasks:")
                for task in appState.tasks.prefix(3) {
                    print("  - \(task.title) (status: \(task.status), due: \(task.dueDate?.formatted() ?? "none"))")
                }
            }
        }
        
        // Show temporary loading message
        let loadingMessage = DisplayChatMessage(
            id: "loading-temp",
            content: "🤖 Processing your request (fetching fresh productivity data)...",
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(loadingMessage)
        
        // Send to chat API without RAG context - the API will fetch fresh data automatically
        appState.apiService.sendChatMessage(enhancedMessage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    // Remove loading message
                    messages.removeAll { $0.id == "loading-temp" }
                    
                    switch completion {
                    case .failure(let error):
                        errorMessage = "Failed to get response: \(error.localizedDescription)"
                        showingError = true
                    case .finished:
                        break
                    }
                },
                receiveValue: { chatResponse in
                    // Remove loading message
                    messages.removeAll { $0.id == "loading-temp" }
                    
                    let assistantMessage = DisplayChatMessage(
                        id: UUID().uuidString,
                        content: chatResponse.response,
                        isFromUser: false,
                        timestamp: Date()
                    )
                    messages.append(assistantMessage)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Suggestion Chips
    private var suggestionChipsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 8) {
                ForEach(contextualSuggestedPrompts, id: \.self) { prompt in
                    Button(action: {
                        messageText = prompt
                        sendMessage()
                    }) {
                        Text(prompt)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Debug & Testing
    private var debugTestsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔧 RAG Debug Tools:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
            
            HStack {
                Button("Show RAG Data") {
                    showingDebugInfo = true
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
                
                Button("Show JSON") {
                    let ragContext = appState.generateChatContext()
                    let chatRequest = APIService.ChatRequest(prompt: "Test message", user_id: appState.userId)
                    
                    if let data = try? JSONEncoder().encode(chatRequest),
                       let jsonString = String(data: data, encoding: .utf8) {
                        
                        let debugMessage = DisplayChatMessage(
                            id: UUID().uuidString,
                            content: "🔍 **DEBUG: JSON Payload Being Sent**\n\n```json\n\(jsonString.prefix(1000))...\n```\n\n**Summary:**\n• Tasks: \(ragContext.tasks.count)\n• Habits: \(ragContext.habits.count)\n• Goals: \(ragContext.goals.count)\n• Projects: \(ragContext.projects.count)",
                            isFromUser: false,
                            timestamp: Date()
                        )
                        messages.append(debugMessage)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            
            HStack {
                Button("Test Queries") {
                    showingTestQueries = true
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
                
                Button("Quick Test") {
                    currentMessage = "What tasks do I have today? Please list them specifically with their details."
                    sendMessage()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(8)
            }
            
            Button("Test Backend Issue") {
                let ragContext = appState.generateChatContext()
                let hasData = !ragContext.tasks.isEmpty || !ragContext.habits.isEmpty || !ragContext.goals.isEmpty || !ragContext.projects.isEmpty
                
                let testMessage = DisplayChatMessage(
                    id: UUID().uuidString,
                    content: hasData ? 
                    "✅ **RAG Context Analysis:**\n\nYour app HAS productivity data and IS sending it to the backend:\n\n📋 **Tasks**: \(ragContext.tasks.count) (\(ragContext.tasks.filter { $0.status == "pending" }.count) pending)\n🎯 **Habits**: \(ragContext.habits.count)\n🏆 **Goals**: \(ragContext.goals.count)\n📁 **Projects**: \(ragContext.projects.count)\n\n**The Problem:** Your backend chat API is NOT using this context in responses.\n\n**Next Steps:**\n1. Check your backend chat API implementation\n2. Verify it reads the 'context' field from requests\n3. Ensure it includes task/habit/goal data in responses\n\n**Sample Tasks Being Sent:**\n" + ragContext.tasks.prefix(3).map { "• \($0.title) (\($0.status))" }.joined(separator: "\n")
                    :
                    "⚠️ **No Productivity Data Found**\n\nYour app has no tasks, habits, goals, or projects to send as RAG context.\n\n**Solution:** Create some productivity data first:\n1. Go to Tasks tab and add tasks\n2. Go to Habits tab and add habits\n3. Go to Goals tab and add goals\n4. Then test the chat assistant again",
                    isFromUser: false,
                    timestamp: Date()
                )
                messages.append(testMessage)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.1))
            .foregroundColor(.purple)
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Debug RAG Context View
    private var debugRAGContextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔍 RAG Debug Info")
                    .font(.headline)
                Spacer()
                Button("Dismiss") {
                    showingDebugInfo = false
                }
                .foregroundColor(.blue)
            }
            
            let currentRAGContext = appState.generateChatContext()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        Text("📝 Tasks (\(currentRAGContext.tasks.count)):")
                            .font(.subheadline.bold())
                        if currentRAGContext.tasks.isEmpty {
                            Text("No tasks found")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(currentRAGContext.tasks.prefix(3), id: \.title) { task in
                                Text("• \(task.title) - \(task.status)")
                                    .font(.caption)
                            }
                            if currentRAGContext.tasks.count > 3 {
                                Text("... and \(currentRAGContext.tasks.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Group {
                        Text("🎯 Habits (\(currentRAGContext.habits.count)):")
                            .font(.subheadline.bold())
                        if currentRAGContext.habits.isEmpty {
                            Text("No habits found")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(currentRAGContext.habits.prefix(3), id: \.title) { habit in
                                Text("• \(habit.title) - \(habit.frequency)")
                                    .font(.caption)
                            }
                            if currentRAGContext.habits.count > 3 {
                                Text("... and \(currentRAGContext.habits.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Group {
                        Text("🎯 Goals (\(currentRAGContext.goals.count)):")
                            .font(.subheadline.bold())
                        if currentRAGContext.goals.isEmpty {
                            Text("No goals found")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(currentRAGContext.goals.prefix(3), id: \.title) { goal in
                                Text("• \(goal.title) - \(goal.status)")
                                    .font(.caption)
                            }
                            if currentRAGContext.goals.count > 3 {
                                Text("... and \(currentRAGContext.goals.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Group {
                        Text("📁 Projects (\(currentRAGContext.projects.count)):")
                            .font(.subheadline.bold())
                        if currentRAGContext.projects.isEmpty {
                            Text("No projects found")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(currentRAGContext.projects.prefix(3)), id: \.id) { project in
                                Text("• \(project.title) - \(project.status)")
                                    .font(.caption)
                            }
                            if currentRAGContext.projects.count > 3 {
                                Text("... and \(currentRAGContext.projects.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🧠 Context Summary:")
                            .font(.subheadline.bold())
                        Text("Total items: \(currentRAGContext.tasks.count + currentRAGContext.habits.count + currentRAGContext.goals.count + currentRAGContext.projects.count)")
                            .font(.caption)
                        
                        let hasData = currentRAGContext.tasks.count > 0 || currentRAGContext.habits.count > 0 || currentRAGContext.goals.count > 0 || currentRAGContext.projects.count > 0
                        
                        if hasData {
                            Text("✅ RAG context is being sent to backend")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("⚠️ No data available for RAG context")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Tip: Add some tasks, habits, goals, or projects first!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Test RAG Query View
    private var testRAGQueryView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🧪 Test RAG Queries")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    showingTestQueries = false
                }
                .foregroundColor(.blue)
            }
            
            Text("Try these test questions to verify RAG is working:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                let testQueries = [
                    "What tasks do I have today?",
                    "Show me my pending tasks",
                    "What habits am I tracking?",
                    "Tell me about my goals",
                    "What projects am I working on?",
                    "How many incomplete tasks do I have?"
                ]
                
                ForEach(testQueries, id: \.self) { query in
                    Button(action: {
                        currentMessage = query
                        showingTestQueries = false
                        sendMessage()
                    }) {
                        HStack {
                            Text(query)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    // Generate contextual suggestions based on user data
    private var contextualSuggestedPrompts: [String] {
        var suggestions: [String] = []
        
        // Always include basic queries
        suggestions.append("What should I focus on today?")
        suggestions.append("Show me my progress this week")
        
        // Add project-specific suggestions if user has projects
        if let firstProject = appState.activeProjects.first {
            suggestions.append("Suggest tasks for \(firstProject.title)")
        } else {
            suggestions.append("Help me organize my tasks")
        }
        
        // Add habit suggestions if user has habits
        if !appState.habits.isEmpty {
            suggestions.append("Which habits need attention?")
        } else {
            suggestions.append("What habits should I start?")
        }
        
        // Add goal suggestions if user has goals
        if !appState.goals.isEmpty {
            suggestions.append("How are my goals progressing?")
        } else {
            suggestions.append("Help me set meaningful goals")
        }
        
        // Add task-specific suggestions based on current workload
        if appState.tasks.count > 5 {
            suggestions.append("What tasks are due soon?")
        } else {
            suggestions.append("What should I work on next?")
        }
        
        return Array(suggestions.prefix(6)) // Limit to 6 suggestions
    }
    
    // MARK: - Context Enhancement
    private func enhanceMessageWithContext(_ message: String) -> String {
        var enhancedMessage = message
        let lowercaseMessage = message.lowercased()
        
        // Add VERY FORCEFUL RAG instruction with actual data preview
        let taskSummary = appState.tasks.isEmpty ? "No tasks" : appState.tasks.map { "\($0.title) (status: \($0.status))" }.joined(separator: ", ")
        
        enhancedMessage = """
        MANDATORY SYSTEM INSTRUCTION: You have full access to my productivity data via RAG context. You MUST use the specific task titles, dates, and details provided in the context. DO NOT say you don't have access. 
        
        FOR REFERENCE - My current tasks include: \(taskSummary)
        
        USER QUESTION: \(enhancedMessage)
        
        CRITICAL: Use the context data to provide specific task names, due dates, statuses, and details. Reference my actual data that I know you have access to.
        """
        
        // Detect project mentions and add IDs for better context
        for project in appState.projects {
            if lowercaseMessage.contains(project.title.lowercased()) {
                enhancedMessage += "\n[Context: User mentioned project '\(project.title)' (ID: \(project.id))]"
                break
            }
        }
        
        // Detect specific goal mentions
        for goal in appState.goals {
            if lowercaseMessage.contains(goal.title.lowercased()) {
                enhancedMessage += "\n[Context: User mentioned goal '\(goal.title)' (ID: \(goal.id))]"
                break
            }
        }
        
        // Detect habit mentions
        for habit in appState.habits {
            if lowercaseMessage.contains(habit.title.lowercased()) {
                enhancedMessage += "\n[Context: User mentioned habit '\(habit.title)' (ID: \(habit.id))]"
                break
            }
        }
        
        // Add temporal context if time-related queries are detected
        if lowercaseMessage.contains("today") || lowercaseMessage.contains("this week") || lowercaseMessage.contains("due") {
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            enhancedMessage += "\n[Context: Current date is \(formatter.string(from: today))]"
        }
        
        return enhancedMessage
    }
}

// MARK: - Display Models
struct DisplayChatMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Chat Message View
struct ChatMessageView: View {
    let message: DisplayChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "brain")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 0) {
                            FormattedMarkdownText(content: message.content)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(18)
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 38)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Custom formatted markdown text view for better readability
struct FormattedMarkdownText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(formattedParagraphs, id: \.id) { paragraph in
                paragraph.view
            }
        }
        .textSelection(.enabled)
    }
    
    private var formattedParagraphs: [FormattedParagraph] {
        let lines = content.components(separatedBy: .newlines)
        var paragraphs: [FormattedParagraph] = []
        var currentParagraph: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                // Empty line - finish current paragraph if it has content
                if !currentParagraph.isEmpty {
                    paragraphs.append(FormattedParagraph(
                        id: UUID(),
                        content: currentParagraph.joined(separator: "\n"),
                        type: .text
                    ))
                    currentParagraph = []
                }
            } else if trimmedLine.hasPrefix("# ") {
                // Heading
                finishCurrentParagraph(&paragraphs, &currentParagraph)
                paragraphs.append(FormattedParagraph(
                    id: UUID(),
                    content: String(trimmedLine.dropFirst(2)),
                    type: .heading
                ))
            } else if trimmedLine.hasPrefix("## ") {
                // Subheading
                finishCurrentParagraph(&paragraphs, &currentParagraph)
                paragraphs.append(FormattedParagraph(
                    id: UUID(),
                    content: String(trimmedLine.dropFirst(3)),
                    type: .subheading
                ))
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("• ") || trimmedLine.hasPrefix("* ") {
                // Bullet point
                finishCurrentParagraph(&paragraphs, &currentParagraph)
                paragraphs.append(FormattedParagraph(
                    id: UUID(),
                    content: String(trimmedLine.dropFirst(2)),
                    type: .bullet
                ))
            } else if trimmedLine.contains(": ") && currentParagraph.isEmpty {
                // Key-value pair (like "Tasks: 5")
                paragraphs.append(FormattedParagraph(
                    id: UUID(),
                    content: trimmedLine,
                    type: .keyValue
                ))
            } else {
                // Regular text
                currentParagraph.append(line)
            }
        }
        
        // Don't forget the last paragraph
        finishCurrentParagraph(&paragraphs, &currentParagraph)
        
        return paragraphs
    }
    
    private func finishCurrentParagraph(_ paragraphs: inout [FormattedParagraph], _ currentParagraph: inout [String]) {
        if !currentParagraph.isEmpty {
            paragraphs.append(FormattedParagraph(
                id: UUID(),
                content: currentParagraph.joined(separator: "\n"),
                type: .text
            ))
            currentParagraph = []
        }
    }
}

struct FormattedParagraph {
    let id: UUID
    let content: String
    let type: ParagraphType
    
    var view: some View {
        Group {
            switch type {
            case .heading:
                Text(content)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
                
            case .subheading:
                Text(content)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.vertical, 2)
                
            case .bullet:
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                    
                    Text(try! AttributedString(markdown: content))
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                .padding(.leading, 8)
                
            case .keyValue:
                Text(try! AttributedString(markdown: content))
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.vertical, 1)
                
            case .text:
                Text(try! AttributedString(markdown: content))
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .padding(.vertical, 2)
            }
        }
    }
}

enum ParagraphType {
    case heading
    case subheading
    case bullet
    case keyValue
    case text
}

// Extension to add corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatAssistantView()
        .environmentObject(AppState())
}
