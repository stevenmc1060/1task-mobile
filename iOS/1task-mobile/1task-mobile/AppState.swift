//
//  AppState.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI
import Foundation
import Combine

class AppState: ObservableObject {
    @Published var showSplash = true
    @Published var isLoggedIn = false
    @Published var selectedTab = 0
    @Published var showingAddSheet = false
    @Published var addItemType: AddItemType = .task
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // User data - now using backend models
    @Published var userId: String = "demo-user"
    @Published var userName: String = "Demo User"
    @Published var userEmail: String = ""
    
    // User profile information
    @Published var userProfile: MSALAuthenticationService.UserProfile?
    @Published var userAvatar: UIImage?
    @Published var userFirstName: String = ""

    /// Computed property to get just the first name from userName
    var computedUserFirstName: String {
        // Handle common display name formats:
        // "Steve McPherson" -> "Steve"
        // "Steve McPherson (Demo)" -> "Steve"  
        // "stevenmc" -> "stevenmc"
        let fullName = userName
            .replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression) // Remove (Demo) etc.
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by space and take the first part
        let components = fullName.components(separatedBy: .whitespaces)
        return components.first?.capitalized ?? "User"
    }
    
    @Published var tasks: [Task] = []
    @Published var habits: [Habit] = []
    @Published var goals: [Goal] = []
    @Published var projects: [Project] = []
    
    // Authentication service
    @Published var authService = MSALAuthenticationService()
    
    // Computed properties for dashboard
    var todaysTasks: [Task] {
        let today = Date()
        let todayTasks = tasks.filter { task in
            // Only show incomplete (pending) tasks
            guard task.status != .completed else { return false }
            
            // Show all pending tasks, or tasks due today
            if task.status == .pending {
                if let dueDate = task.dueDate {
                    // If it has a due date, show if it's today or overdue
                    return dueDate <= today || Calendar.current.isDate(dueDate, inSameDayAs: today)
                } else {
                    // If no due date, show all pending tasks
                    return true
                }
            }
            
            return false
        }
        
        print("📊 todaysTasks computed: \(todayTasks.count) from \(tasks.count) total tasks")
        print("   Pending tasks: \(tasks.filter { $0.status == .pending }.count)")
        print("   Completed tasks: \(tasks.filter { $0.status == .completed }.count)")
        
        return todayTasks
    }
    
    var todaysHabits: [Habit] {
        let activeHabits = habits.filter { $0.status == .active }
        print("🎯 todaysHabits computed: \(activeHabits.count) from \(habits.count) total habits")
        return activeHabits
    }
    
    var activeGoals: [Goal] {
        let allActiveGoals = goals.filter { $0.status != .completed }
        
        // Apply user filtering preferences
        let filteredGoals = allActiveGoals.filter { goal in
            switch goal.goalType {
            case .weekly: return showWeeklyGoals
            case .quarterly: return showQuarterlyGoals
            case .yearly: return showYearlyGoals
            }
        }
        
        print("🏆 activeGoals computed: \(filteredGoals.count) from \(self.goals.count) total goals")
        print("   Weekly: \(allActiveGoals.filter { $0.goalType == .weekly }.count), Quarterly: \(allActiveGoals.filter { $0.goalType == .quarterly }.count), Yearly: \(allActiveGoals.filter { $0.goalType == .yearly }.count)")
        return filteredGoals
    }
    
    var activeProjects: [Project] {
        return projects.filter { $0.status != .completed }
    }
    
    let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up demo data initially
        loadSampleData()
        
        // Hide splash after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.showSplash = false
            }
        }
        
        // Set up API service user ID
        apiService.currentUserId = userId
        
        // Subscribe to authentication changes
        setupAuthenticationSubscription()
    }
    
    
    // MARK: - Sample Data for Demo Mode
    private func loadSampleData() {
        // Sample tasks
        tasks = [
            Task(
                title: "Review project proposals",
                description: "Review and provide feedback on Q1 project proposals",
                status: .pending,
                priority: .high,
                dueDate: Date()
            ),
            Task(
                title: "Call team meeting", 
                description: "Weekly sync with development team",
                status: .completed,
                priority: .medium,
                dueDate: Date()
            ),
            Task(
                title: "Update documentation",
                description: "Update API documentation with latest changes",
                status: .pending,
                priority: .low,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
            )
        ]
        
        // Sample habits
        habits = [
            Habit(
                title: "Morning exercise",
                description: "30 minutes of exercise",
                frequency: .daily
            ),
            Habit(
                title: "Read for 30 minutes", 
                description: "Daily reading habit",
                frequency: .daily
            )
        ]
        
        // Sample goals
        goals = [
            Goal(
                title: "Complete mobile app",
                description: "Finish 1TaskAssistant mobile app"
            ),
            Goal(
                title: "Learn SwiftUI",
                description: "Master SwiftUI framework"
            )
        ]
        
        // Sample projects
        projects = [
            Project(
                title: "1TaskAssistant Mobile",
                description: "iOS companion app",
                status: .active
            ),
            Project(
                title: "Learning SwiftUI",
                description: "Master iOS development",
                status: .active
            )
        ]
    }
    
    // MARK: - Backend Sync
    func syncDataFromBackend() {
        guard !isLoading else { return }
        
        print("🔄 Starting backend sync...")
        isLoading = true
        errorMessage = nil
        
        // First check if backend is available
        apiService.checkHealth()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        // Backend not available, continue with demo data
                        print("❌ Backend not available: \(error.localizedDescription)")
                        print("📱 Using demo data instead")
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] _ in
                    // Backend is available, sync all data
                    print("✅ Backend health check passed!")
                    self?.syncAllDataFromAPI()
                }
            )
            .store(in: &cancellables)
    }
    
    private func syncAllDataFromAPI() {
        print("📡 Fetching data from backend APIs...")
        print("🌐 Backend URL: \(APIConfiguration.baseURL)")
        print("🆔 Using User ID: \(apiService.currentUserId)")
        
        let taskPublisher = apiService.getTasks()
        let habitPublisher = apiService.getHabits()
        let yearlyGoalsPublisher = apiService.getYearlyGoals()
        let quarterlyGoalsPublisher = apiService.getQuarterlyGoals()
        let weeklyGoalsPublisher = apiService.getWeeklyGoals()
        let projectPublisher = apiService.getProjects()
        
        // Combine all goal types into one array
        let allGoalsPublisher = Publishers.Zip3(yearlyGoalsPublisher, quarterlyGoalsPublisher, weeklyGoalsPublisher)
            .map { yearly, quarterly, weekly in
                return yearly + quarterly + weekly
            }
        
        Publishers.Zip4(taskPublisher, habitPublisher, allGoalsPublisher, projectPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ API sync failed: \(error.localizedDescription)")
                        print("📱 Falling back to demo data")
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] tasks, habits, goals, projects in
                    print("✅ API sync successful!")
                    print("📋 Received \(tasks.count) tasks")
                    print("🎯 Received \(habits.count) habits") 
                    print("🏆 Received \(goals.count) goals")
                    print("📁 Received \(projects.count) projects")
                    
                    self?.tasks = tasks
                    self?.habits = habits
                    self?.goals = goals
                    self?.projects = projects
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    func addTask(_ task: Task) {
        apiService.createTask(task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] newTask in
                    self?.tasks.append(newTask)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateTask(_ task: Task) {
        // Update locally first for immediate UI response
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            print("✅ Task updated locally: \(task.title) - status: \(task.status)")
        }
        
        // Then sync with backend
        apiService.updateTask(task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("⚠️ Task update API failed: \(error.localizedDescription)")
                        // Don't show error for task updates - the local update already happened
                        // Just log it for debugging
                        print("⚠️ Task remains updated locally, but could not sync to backend")
                    }
                },
                receiveValue: { [weak self] updatedTask in
                    print("✅ Task successfully synced to backend: \(updatedTask.title)")
                    // Update with the response from backend in case there are server-side changes
                    if let index = self?.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                        self?.tasks[index] = updatedTask
                        print("✅ Task updated from backend response")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteTask(_ taskId: String) {
        apiService.deleteTask(taskId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.tasks.removeAll { $0.id == taskId }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func addHabit(_ habit: Habit) {
        apiService.createHabit(habit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] newHabit in
                    self?.habits.append(newHabit)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateHabit(_ habit: Habit) {
        apiService.updateHabit(habit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedHabit in
                    if let index = self?.habits.firstIndex(where: { $0.id == updatedHabit.id }) {
                        self?.habits[index] = updatedHabit
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteHabit(_ habitId: String) {
        apiService.deleteHabit(habitId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.habits.removeAll { $0.id == habitId }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func addGoal(_ goal: Goal) {
        apiService.createYearlyGoal(goal)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] newGoal in
                    self?.goals.append(newGoal)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateGoal(_ goal: Goal) {
        apiService.updateYearlyGoal(goal)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedGoal in
                    if let index = self?.goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                        self?.goals[index] = updatedGoal
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteGoal(_ goalId: String) {
        apiService.deleteYearlyGoal(goalId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.goals.removeAll { $0.id == goalId }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func addProject(_ project: Project) {
        apiService.createProject(project)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] newProject in
                    self?.projects.append(newProject)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProject(_ project: Project) {
        apiService.updateProject(project)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedProject in
                    if let index = self?.projects.firstIndex(where: { $0.id == updatedProject.id }) {
                        self?.projects[index] = updatedProject
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteProject(_ projectId: String) {
        apiService.deleteProject(projectId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.projects.removeAll { $0.id == projectId }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Setup
    private func setupAuthenticationSubscription() {
        // Monitor authentication state changes
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                self?.isLoggedIn = isAuthenticated
                
                if isAuthenticated {
                    // Get the compound Microsoft user ID
                    let msalUserId = self?.authService.userId ?? "demo-user"
                    
                    // Extract simple user ID for backend compatibility
                    // Microsoft returns IDs like: "2da56370-78bc-4278-9ed3-c693615ba407.e98c967d-d833-4bef-b319-9a388d2cedcd"  
                    // But backend stores data under: "2da56370-78bc-4278-9ed3-c693615ba407"
                    let simpleUserId = AppState.extractSimpleUserId(from: msalUserId)
                    
                    // Update user info from MSAL
                    self?.userId = simpleUserId // Use simple ID for backend calls
                    self?.userName = self?.authService.userDisplayName ?? "User"
                    self?.userEmail = self?.authService.userEmail ?? ""
                    
                    // Use the simple user ID for backend API calls
                    self?.apiService.currentUserId = simpleUserId
                    
                    // Debug user ID information
                    print("👤 User authentication details:")
                    print("   📧 Email: \(self?.userEmail ?? "none")")
                    print("   🆔 MSAL User ID: \(msalUserId)")
                    print("   🔗 Backend User ID: \(simpleUserId)")
                    
                    // Get authentication token and set it in API service  
                    self?.updateAuthToken()
                    
                } else {
                    // Reset to demo data when signed out
                    self?.resetToDemo()
                }
            }
            .store(in: &cancellables)
        
        // Monitor authentication errors
        authService.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                // Don't show keychain errors to users - they're common iOS issues
                if errorMessage.contains("keychain") || 
                   errorMessage.contains("OSStatus error -34018") ||
                   errorMessage.contains("Sign-out failed") ||
                   errorMessage.contains("Failed to get items from keychain") {
                    print("⚠️ Suppressing keychain/sign-out error from user display: \(errorMessage)")
                    return
                }
                
                self?.handleError(APIError.networkError(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            }
            .store(in: &cancellables)
    }
    
    private func updateAuthToken() {
        print("🔑 Attempting to get access token...")
        authService.getAccessToken()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to acquire token: \(error.localizedDescription)")
                        // Continue without token for demo purposes
                        print("📱 Proceeding with backend sync anyway...")
                        self?.syncDataFromBackend()
                    }
                },
                receiveValue: { [weak self] token in
                    print("✅ Successfully acquired auth token")
                    print("🔑 Token preview: \(String(token.prefix(20)))...")
                    self?.apiService.setAuthToken(token)
                    self?.syncDataFromBackend()
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Login Management
    func loginWithMSAL() {
        authService.signIn()
    }
    
    func loginAsDemo() {
        // Demo user login (bypasses MSAL) - use your actual user ID for testing
        login(userId: "2da56370-78bc-4278-9ed3-c693615ba407", userName: "Steve McPherson (Demo)")
    }
    
    func login(userId: String, userName: String) {
        self.userId = userId
        self.userName = userName
        self.userEmail = ""
        self.isLoggedIn = true
        apiService.currentUserId = userId
        
        // Sync data from backend after login
        syncDataFromBackend()
    }
    
    func logout() {
        print("🔄 Starting logout process...")
        
        if authService.isAuthenticated {
            // Attempt to sign out from MSAL
            authService.signOut()
            // The authentication subscription will automatically call resetToDemo() 
            // when isAuthenticated becomes false
        } else {
            // Already signed out, just reset to demo
            resetToDemo()
        }
    }
    
    private func resetToDemo() {
        userId = "demo-user"
        userName = "Demo User"
        userEmail = ""
        isLoggedIn = false
        apiService.currentUserId = "demo-user"
        
        // Reload demo data
        loadSampleData()
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error) {
        print("🚨 AppState Error: \(error.localizedDescription)")
        
        // Check if this is a keychain error during sign-out - these should not be shown to user
        let nsError = error as NSError
        if nsError.domain == "NSOSStatusErrorDomain" && nsError.code == -34018 {
            print("⚠️ Keychain access error - not showing to user (common iOS issue)")
            return
        }
        
        if nsError.domain == "AuthError" && error.localizedDescription.contains("keychain") {
            print("⚠️ Authentication keychain error - not showing to user")
            return
        }
        
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.showingError = true
            self.isLoading = false
        }
    }
    
    // MARK: - UI Actions
    func toggleAddSheet() {
        showingAddSheet.toggle()
    }
    
    func selectTab(_ tab: Int) {
        selectedTab = tab
    }
    
    func dismissError() {
        showingError = false
        errorMessage = nil
    }
    
    // User preferences for goal filtering
    @Published var showWeeklyGoals: Bool = true
    @Published var showQuarterlyGoals: Bool = true  
    @Published var showYearlyGoals: Bool = true

    /// Extract simple user ID from compound Microsoft account ID
    /// Microsoft returns IDs like: "2da56370-78bc-4278-9ed3-c693615ba407.e98c967d-d833-4bef-b319-9a388d2cedcd"
    /// But backend data is stored under: "2da56370-78bc-4278-9ed3-c693615ba407"
    static func extractSimpleUserId(from compoundId: String) -> String {
        // Split by the first dot and return the first part
        if let dotIndex = compoundId.firstIndex(of: ".") {
            return String(compoundId[..<dotIndex])
        }
        // If no dot found, return the original ID
        return compoundId
    }
}

// MARK: - AddItemType enum
enum AddItemType: CaseIterable {
    case task, habit, goal, project
    
    var title: String {
        switch self {
        case .task: return "Task"
        case .habit: return "Habit"
        case .goal: return "Goal"
        case .project: return "Project"
        }
    }
    
    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .habit: return "repeat"
        case .goal: return "target"
        case .project: return "folder"
        }
    }
    
    var color: Color {
        switch self {
        case .task: return .blue
        case .habit: return .green
        case .goal: return .purple
        case .project: return .orange
        }
    }
}
