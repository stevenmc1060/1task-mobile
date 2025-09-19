import Foundation
import Combine

// MARK: - API Configuration
struct APIConfiguration {
    // Use the centralized configuration
    static let baseURL = AppConfiguration.API.baseURL
    static let timeout = AppConfiguration.API.requestTimeout
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case httpError(Int)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Chat API Models
struct ChatMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Request/Response Models for Backend
struct CreateTaskRequest: Codable {
    let title: String
    let description: String?
    let dueDate: String?
    let priority: String
    let status: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case dueDate = "due_date"
        case priority
        case status
        case userId = "user_id"
    }
}

struct UpdateTaskRequest: Codable {
    let title: String?
    let description: String?
    let dueDate: String?
    let priority: String?
    let status: String?
    let completedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case dueDate = "due_date"
        case priority
        case status
        case completedAt = "completed_at"
    }
}

struct CreateHabitRequest: Codable {
    let title: String
    let description: String?
    let frequency: String
    let targetCount: Int
    let tags: [String]
    let status: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case frequency
        case targetCount = "target_count"
        case tags
        case status
        case userId = "user_id"
    }
}

struct UpdateHabitRequest: Codable {
    let title: String?
    let description: String?
    let frequency: String?
    let targetCount: Int?
    let tags: [String]?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case frequency
        case targetCount = "target_count"
        case tags
        case status
    }
}

struct CreateYearlyGoalRequest: Codable {
    let title: String
    let description: String?
    let targetYear: Int
    let keyMetrics: [String]
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case targetYear = "target_year"
        case keyMetrics = "key_metrics"
        case userId = "user_id"
    }
}

struct UpdateYearlyGoalRequest: Codable {
    let title: String?
    let description: String?
    let weekStartDate: String?
    let keyMetrics: [String]?
    let progressPercentage: Double?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case weekStartDate = "week_start_date"
        case keyMetrics = "key_metrics"
        case progressPercentage = "progress_percentage"
        case status
    }
}

struct CreateProjectRequest: Codable {
    let title: String
    let description: String?
    let status: String
    let priority: String
    let startDate: String?
    let endDate: String?
    let tags: [String]
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case status
        case priority
        case startDate = "start_date"
        case endDate = "end_date"
        case tags
        case userId = "user_id"
    }
}

struct UpdateProjectRequest: Codable {
    let title: String?
    let description: String?
    let status: String?
    let priority: String?
    let startDate: String?
    let endDate: String?
    let tags: [String]?
    let progressPercentage: Double?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case status
        case priority
        case startDate = "start_date"
        case endDate = "end_date"
        case tags
        case progressPercentage = "progress_percentage"
    }
}

struct CreateWeeklyGoalRequest: Codable {
    let title: String
    let description: String?
    let weekStartDate: String
    let keyMetrics: [String]
    let userId: String
    let quarterlyGoalId: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case weekStartDate = "week_start_date"
        case keyMetrics = "key_metrics"
        case userId = "user_id"
        case quarterlyGoalId = "quarterly_goal_id"
    }
}

struct CreateQuarterlyGoalRequest: Codable {
    let title: String
    let description: String?
    let targetQuarter: Int
    let targetYear: Int
    let keyMetrics: [String]
    let userId: String
    let yearlyGoalId: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case targetQuarter = "target_quarter"
        case targetYear = "target_year"
        case keyMetrics = "key_metrics"
        case userId = "user_id"
        case yearlyGoalId = "yearly_goal_id"
    }
}

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    private let session = URLSession.shared
    private let baseURL = APIConfiguration.baseURL
    
    // User ID for API requests - this should be set after login
    @Published var currentUserId: String = "demo-user"
    
    // Authentication token for API requests
    @Published var authToken: String?
    
    private init() {}
    
    // MARK: - Helper Methods
    private func makeRequest(endpoint: String, method: String = "GET", body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfiguration.timeout
        
        // Add authentication token if available
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - Authentication Methods
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) -> AnyPublisher<T, APIError> {
        return session.dataTaskPublisher(for: request)
            .map { data, response in
                // Debug: Log raw response
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 HTTP Status: \(httpResponse.statusCode)")
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🌐 Raw API Response: \(responseString)")
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder.apiDecoder)
            .mapError { error in
                print("🚨 Decoding error for \(T.self): \(error)")
                if let decodingError = error as? DecodingError {
                    print("🚨 Detailed decoding error: \(decodingError)")
                }
                if error is DecodingError {
                    return APIError.decodingError
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Health Check
    func checkHealth() -> AnyPublisher<Bool, APIError> {
        guard let request = makeRequest(endpoint: "health") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map { _ in true }
            .mapError { APIError.networkError($0) }
            .eraseToAnyPublisher()
    }
     // MARK: - Tasks API
    func getTasks() -> AnyPublisher<[Task], APIError> {
        guard let request = makeRequest(endpoint: "tasks?user_id=\(currentUserId)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        return performRequest(request, responseType: [Task].self)
    }
    
    func createTask(_ task: Task) -> AnyPublisher<Task, APIError> {
        let createRequest = CreateTaskRequest(
            title: task.title,
            description: task.description,
            dueDate: task.dueDate?.ISO8601Format(),
            priority: task.priority.rawValue,
            status: task.status.rawValue,
            userId: currentUserId
        )
        
        guard let data = try? JSONEncoder().encode(createRequest),
              let request = makeRequest(endpoint: "tasks", method: "POST", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Task.self)
    }
    
    func updateTask(_ task: Task) -> AnyPublisher<Task, APIError> {
        let updateRequest = UpdateTaskRequest(
            title: task.title,
            description: task.description,
            dueDate: task.dueDate?.ISO8601Format(),
            priority: task.priority.rawValue,
            status: task.status.rawValue,
            completedAt: task.completedAt?.ISO8601Format()
        )
        
        print("🔄 Sending task update request: \(updateRequest)")
        
        guard let data = try? JSONEncoder().encode(updateRequest),
              let request = makeRequest(endpoint: "tasks/\(task.id)?user_id=\(currentUserId)", method: "PUT", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Task.self)
    }
    
    func deleteTask(_ taskId: String) -> AnyPublisher<Bool, APIError> {
        guard let request = makeRequest(endpoint: "tasks/\(taskId)?user_id=\(currentUserId)", method: "DELETE") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map { response in
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    return false
                }
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 204
            }
            .mapError { APIError.networkError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Habits API
    func getHabits() -> AnyPublisher<[Habit], APIError> {
        guard let request = makeRequest(endpoint: "habits?user_id=\(currentUserId)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: [Habit].self)
    }
    
    func createHabit(_ habit: Habit) -> AnyPublisher<Habit, APIError> {
        let createRequest = CreateHabitRequest(
            title: habit.title,
            description: habit.description,
            frequency: habit.frequency.rawValue,
            targetCount: habit.targetCount,
            tags: habit.tags,
            status: habit.status.rawValue,
            userId: currentUserId
        )
        
        guard let data = try? JSONEncoder().encode(createRequest),
              let request = makeRequest(endpoint: "habits", method: "POST", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Habit.self)
    }
    
    func updateHabit(_ habit: Habit) -> AnyPublisher<Habit, APIError> {
        let updateRequest = UpdateHabitRequest(
            title: habit.title,
            description: habit.description,
            frequency: habit.frequency.rawValue,
            targetCount: habit.targetCount,
            tags: habit.tags,
            status: habit.status.rawValue
        )
        
        guard let data = try? JSONEncoder().encode(updateRequest),
              let request = makeRequest(endpoint: "habits/\(habit.id)?user_id=\(currentUserId)", method: "PUT", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Habit.self)
    }
    
    func deleteHabit(_ habitId: String) -> AnyPublisher<Bool, APIError> {
        guard let request = makeRequest(endpoint: "habits/\(habitId)?user_id=\(currentUserId)", method: "DELETE") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map { response in
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    return false
                }
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 204
            }
            .mapError { APIError.networkError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Goals API
    func getYearlyGoals() -> AnyPublisher<[Goal], APIError> {
        guard let request = makeRequest(endpoint: "yearly-goals?user_id=\(currentUserId)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: [Goal].self)
    }
    
    func createYearlyGoal(_ goal: Goal) -> AnyPublisher<Goal, APIError> {
        let dateFormatter = ISO8601DateFormatter()
        let createRequest = CreateYearlyGoalRequest(
            title: goal.title,
            description: goal.description,
            targetYear: goal.targetYear ?? Calendar.current.component(.year, from: Date()),
            keyMetrics: goal.keyMetrics,
            userId: currentUserId
        )
        
        guard let data = try? JSONEncoder().encode(createRequest),
              let request = makeRequest(endpoint: "yearly-goals", method: "POST", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Goal.self)
    }
    
    func updateYearlyGoal(_ goal: Goal) -> AnyPublisher<Goal, APIError> {
        let dateFormatter = ISO8601DateFormatter()
        let updateRequest = UpdateYearlyGoalRequest(
            title: goal.title,
            description: goal.description,
            weekStartDate: goal.weekStartDate.map { dateFormatter.string(from: $0) },
            keyMetrics: goal.keyMetrics,
            progressPercentage: goal.progressPercentage,
            status: goal.status.rawValue
        )
        
        guard let data = try? JSONEncoder().encode(updateRequest),
              let request = makeRequest(endpoint: "yearly-goals/\(goal.id)?user_id=\(currentUserId)", method: "PUT", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Goal.self)
    }
    
    func deleteYearlyGoal(_ goalId: String) -> AnyPublisher<Bool, APIError> {
        guard let request = makeRequest(endpoint: "yearly-goals/\(goalId)?user_id=\(currentUserId)", method: "DELETE") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map { response in
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    return false
                }
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 204
            }
            .mapError { APIError.networkError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Weekly Goals API
    func getWeeklyGoals() -> AnyPublisher<[Goal], APIError> {
        guard let request = makeRequest(endpoint: "weekly-goals?user_id=\(currentUserId)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: [Goal].self)
    }
    
    func createWeeklyGoal(_ goal: Goal) -> AnyPublisher<Goal, APIError> {
        print("🔵 Creating weekly goal: \(goal.title)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let createRequest = CreateWeeklyGoalRequest(
            title: goal.title,
            description: goal.description,
            weekStartDate: dateFormatter.string(from: goal.weekStartDate ?? Date()),
            keyMetrics: goal.keyMetrics,
            userId: currentUserId,
            quarterlyGoalId: goal.quarterlyGoalId
        )
        
        print("🔵 Weekly goal request: \(createRequest)")
        
        guard let data = try? JSONEncoder().encode(createRequest),
              let request = makeRequest(endpoint: "weekly-goals", method: "POST", body: data) else {
            print("❌ Failed to create weekly goal request")
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        print("🔵 Sending weekly goal to: \(request.url?.absoluteString ?? "unknown")")
        return performRequest(request, responseType: Goal.self)
    }
    
    // MARK: - Quarterly Goals API
    func getQuarterlyGoals() -> AnyPublisher<[Goal], APIError> {
        guard let request = makeRequest(endpoint: "quarterly-goals?user_id=\(currentUserId)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: [Goal].self)
    }
    
    func createQuarterlyGoal(_ goal: Goal) -> AnyPublisher<Goal, APIError> {
        print("🟠 Creating quarterly goal: \(goal.title)")
        let createRequest = CreateQuarterlyGoalRequest(
            title: goal.title,
            description: goal.description,
            targetQuarter: goal.targetQuarter ?? 1,
            targetYear: goal.targetYear ?? Calendar.current.component(.year, from: Date()),
            keyMetrics: goal.keyMetrics,
            userId: currentUserId,
            yearlyGoalId: goal.yearlyGoalId
        )
        
        print("🟠 Quarterly goal request: \(createRequest)")
        
        guard let data = try? JSONEncoder().encode(createRequest),
              let request = makeRequest(endpoint: "quarterly-goals", method: "POST", body: data) else {
            print("❌ Failed to create quarterly goal request")
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        print("🟠 Sending quarterly goal to: \(request.url?.absoluteString ?? "unknown")")
        return performRequest(request, responseType: Goal.self)
    }
    
    // MARK: - Projects API
    func getProjects() -> AnyPublisher<[Project], APIError> {
        guard let request = makeRequest(endpoint: "projects?user_id=\(currentUserId)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: [Project].self)
    }
    
    func createProject(_ project: Project) -> AnyPublisher<Project, APIError> {
        let createRequest = CreateProjectRequest(
            title: project.title,
            description: project.description,
            status: project.status.rawValue,
            priority: project.priority.rawValue,
            startDate: project.startDate?.ISO8601Format(),
            endDate: project.endDate?.ISO8601Format(),
            tags: project.tags,
            userId: currentUserId
        )
        
        guard let data = try? JSONEncoder().encode(createRequest),
              let request = makeRequest(endpoint: "projects", method: "POST", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Project.self)
    }
    
    func updateProject(_ project: Project) -> AnyPublisher<Project, APIError> {
        let updateRequest = UpdateProjectRequest(
            title: project.title,
            description: project.description,
            status: project.status.rawValue,
            priority: project.priority.rawValue,
            startDate: project.startDate?.ISO8601Format(),
            endDate: project.endDate?.ISO8601Format(),
            tags: project.tags,
            progressPercentage: project.progressPercentage
        )
        
        guard let data = try? JSONEncoder().encode(updateRequest),
              let request = makeRequest(endpoint: "projects/\(project.id)?user_id=\(currentUserId)", method: "PUT", body: data) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return performRequest(request, responseType: Project.self)
    }
    
    func deleteProject(_ projectId: String) -> AnyPublisher<Bool, APIError> {
        guard let request = makeRequest(endpoint: "projects/\(projectId)?user_id=\(currentUserId)", method: "DELETE") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map { response in
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    return false
                }
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 204
            }
            .mapError { APIError.networkError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Sync Methods
    func syncAllData() -> AnyPublisher<Bool, APIError> {
        let publishers = [
            getTasks().map { _ in true }.eraseToAnyPublisher(),
            getHabits().map { _ in true }.eraseToAnyPublisher(),
            getYearlyGoals().map { _ in true }.eraseToAnyPublisher(),
            getWeeklyGoals().map { _ in true }.eraseToAnyPublisher(),
            getQuarterlyGoals().map { _ in true }.eraseToAnyPublisher(),
            getProjects().map { _ in true }.eraseToAnyPublisher()
        ]
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { results in
                return results.allSatisfy { $0 }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Chat API Functions
    
    struct ChatRequest: Codable {
        let prompt: String
        let user_id: String
        
        init(prompt: String, user_id: String) {
            self.prompt = prompt
            self.user_id = user_id
        }
    }
    
    // RAG Context Data Structure
    struct UserProductivityContext: Codable {
        let tasks: [TaskForRAG]
        let habits: [HabitForRAG]
        let goals: [GoalForRAG]
        let projects: [ProjectForRAG]
        let metadata: ContextMetadata
    }
    
    struct TaskForRAG: Codable {
        let id: String
        let title: String
        let description: String?
        let status: String
        let priority: String
        let dueDate: String?
        let projectId: String?
        let tags: [String]
        let createdAt: String?
        let completedAt: String?
    }
    
    struct HabitForRAG: Codable {
        let id: String
        let title: String
        let description: String?
        let frequency: String
        let targetCount: Int
        let currentCount: Int
        let status: String
        let tags: [String]
        let streakCount: Int
        let lastCompletedAt: String?
    }
    
    struct GoalForRAG: Codable {
        let id: String
        let title: String
        let description: String?
        let category: String
        let targetDate: String?
        let status: String
        let progressPercentage: Double
        let milestones: [String]
    }
    
    struct ProjectForRAG: Codable {
        let id: String
        let title: String
        let description: String?
        let status: String
        let category: String?
        let createdAt: String?
        let tasksCount: Int
        let completedTasksCount: Int
    }
    
    struct ContextMetadata: Codable {
        let totalTasks: Int
        let completedTasks: Int
        let overdueTasks: Int
        let totalHabits: Int
        let activeHabits: Int
        let totalGoals: Int
        let activeGoals: Int
        let totalProjects: Int
        let activeProjects: Int
        let contextGeneratedAt: String
        let userTimezone: String
    }
    
    struct ChatResponse: Codable {
        let response: String
        let user_id: String?
        let timestamp: String?
        let interview_complete: Bool?
        let current_question: Int?
    }
    
    func sendChatMessage(_ message: String, withRAGContext context: UserProductivityContext? = nil) -> AnyPublisher<ChatResponse, APIError> {
        // Use the separate chat API URL, not the main data API
        guard let chatURL = URL(string: "\(AppConfiguration.API.chatAPIURL)/chat") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🔄 Sending chat request to CHAT API: \(chatURL)")
        print("📊 Main data API: \(AppConfiguration.API.baseURL)")
        
        // If no context provided, fetch fresh data from the main API first
        if context == nil {
            print("📡 No RAG context provided - fetching fresh data from main API first...")
            return fetchFreshRAGContext()
                .flatMap { freshContext in
                    return self.sendChatMessageWithContext(message, context: freshContext, url: chatURL)
                }
                .eraseToAnyPublisher()
        } else {
            print("🧠 Using provided RAG context")
            return sendChatMessageWithContext(message, context: context, url: chatURL)
        }
    }
    
    private func sendChatMessageWithContext(_ message: String, context: UserProductivityContext?, url: URL) -> AnyPublisher<ChatResponse, APIError> {
        // Build a comprehensive prompt with RAG context injected directly into the text
        var enhancedPrompt = message
        
        if let context = context {
            // Build context summary similar to how web frontends do it
            let contextSummary = buildContextSummary(context: context)
            
            enhancedPrompt = """
            You are a productivity assistant with access to the user's current productivity data. Use this data to provide specific, helpful answers about their tasks, habits, goals, and projects.

            CURRENT USER DATA:
            \(contextSummary)

            USER QUESTION: \(message)

            Please provide a helpful response using the specific data above. Reference actual task names, project titles, goal details, and habit information from the provided context.
            """
        }
        
        let chatRequest = ChatRequest(prompt: enhancedPrompt, user_id: currentUserId)
        
        guard let data = try? JSONEncoder().encode(chatRequest) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        if let context = context {
            print("🧠 Including RAG context with \(context.tasks.count) tasks, \(context.habits.count) habits, \(context.goals.count) goals, \(context.projects.count) projects")
            
            // Debug: Show sample of what's being sent
            if !context.tasks.isEmpty {
                print("📋 Sample task data being sent:")
                for task in context.tasks.prefix(2) {
                    print("  - \(task.title) (status: \(task.status), due: \(task.dueDate ?? "none"))")
                }
            }
            
            // Show total context size  
            print("📊 RAG context injected into prompt:")
            print("  • Tasks: \(context.tasks.count)")
            print("  • Habits: \(context.habits.count)")
            print("  • Goals: \(context.goals.count)")
            print("  • Projects: \(context.projects.count)")
        } else {
            print("⚠️ No RAG context being sent to chat API!")
        }
        
        // Print the full JSON payload for debugging
        let jsonString = String(data: data, encoding: .utf8) ?? "invalid JSON"
        print("🔄 Full chat request JSON payload to CHAT API:")
        print(jsonString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "X-Use-RAG-Context")
        request.setValue("MANDATORY", forHTTPHeaderField: "X-Context-Required")
        request.setValue("RAG-ENABLED", forHTTPHeaderField: "X-Chat-Mode")
        request.setValue("mobile-app", forHTTPHeaderField: "X-Client-Source")
        request.httpBody = data
        request.timeoutInterval = 45.0 // Increased timeout for RAG processing
        
        return Future { promise in
            URLSession.shared.dataTask(with: request) { [message] data, response, error in
                if let error = error {
                    print("Chat API network error: \(error)")
                    promise(.failure(APIError.networkError(error)))
                    return
                }
                
                guard let data = data else {
                    promise(.failure(APIError.noData))
                    return
                }
                
                // Log the HTTP response for debugging
                if let httpResponse = response as? HTTPURLResponse {
                    print("Chat API HTTP status: \(httpResponse.statusCode)")
                }
                
                // Log the raw response data for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Chat API raw response: \(responseString.prefix(200))...") // First 200 chars
                    
                    // Check if the response looks like HTML (error page)
                    if responseString.hasPrefix("<") || responseString.hasPrefix("<!DOCTYPE") {
                        print("❌ Chat API returned HTML instead of JSON - likely an error page")
                        // Return a helpful demo response instead of failing
                        let demoResponse = ChatResponse(
                            response: "I'm having trouble connecting to the chat service right now. This is a demo response. Your message was: '\(message)'",
                            user_id: self.currentUserId,
                            timestamp: Date().ISO8601Format(),
                            interview_complete: false,
                            current_question: nil
                        )
                        promise(.success(demoResponse))
                        return
                    }
                    
                    // Check if it's a plain text response (which is valid for this API)
                    if !responseString.hasPrefix("{") && !responseString.hasPrefix("[") {
                        print("✅ Chat API returned plain text response - converting to ChatResponse format")
                        // The API is working but returning plain text instead of JSON
                        // This is actually a successful response, so convert it to our expected format
                        let chatResponse = ChatResponse(
                            response: responseString.trimmingCharacters(in: .whitespacesAndNewlines),
                            user_id: self.currentUserId,
                            timestamp: Date().ISO8601Format(),
                            interview_complete: false,
                            current_question: nil
                        )
                        promise(.success(chatResponse))
                        return
                    }
                }
                
                do {
                    let chatResponse = try JSONDecoder.apiDecoder.decode(ChatResponse.self, from: data)
                    promise(.success(chatResponse))
                } catch {
                    print("Chat API decoding error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Failed to decode response: \(responseString)")
                        
                        // If JSON decoding failed but we have a valid text response,
                        // treat it as a successful plain text response
                        if !responseString.isEmpty && 
                           !responseString.hasPrefix("<") && 
                           !responseString.hasPrefix("<!DOCTYPE") {
                            print("✅ Converting failed JSON decode to plain text ChatResponse")
                            let chatResponse = ChatResponse(
                                response: responseString.trimmingCharacters(in: .whitespacesAndNewlines),
                                user_id: self.currentUserId,
                                timestamp: Date().ISO8601Format(),
                                interview_complete: false,
                                current_question: nil
                            )
                            promise(.success(chatResponse))
                            return
                        }
                    }
                    
                    // If we still can't handle it, provide a demo response
                    let demoResponse = ChatResponse(
                        response: "I'm having trouble processing the response from the chat service right now. This is a demo response. Your message was: '\(message)'",
                        user_id: self.currentUserId,
                        timestamp: Date().ISO8601Format(),
                        interview_complete: false,
                        current_question: nil
                    )
                    promise(.success(demoResponse))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - RAG Context Generation
    
    func createRAGContext(from appState: AppState) -> UserProductivityContext {
        let dateFormatter = ISO8601DateFormatter()
        
        // Convert tasks to RAG format
        let ragTasks = appState.tasks.map { task in
            TaskForRAG(
                id: task.id,
                title: task.title,
                description: task.description,
                status: task.status.rawValue,
                priority: task.priority.rawValue,
                dueDate: task.dueDate.map { dateFormatter.string(from: $0) },
                projectId: task.projectId,
                tags: task.tags,
                createdAt: task.createdAt.map { dateFormatter.string(from: $0) },
                completedAt: task.completedAt.map { dateFormatter.string(from: $0) }
            )
        }
        
        // Convert habits to RAG format
        let ragHabits = appState.habits.map { habit in
            HabitForRAG(
                id: habit.id,
                title: habit.title,
                description: habit.description,
                frequency: habit.frequency.rawValue,
                targetCount: habit.targetCount,
                currentCount: habit.currentCount,
                status: habit.status.rawValue,
                tags: habit.tags,
                streakCount: habit.currentStreak, // Use currentStreak instead of streakCount
                lastCompletedAt: habit.lastCompletedAt.map { dateFormatter.string(from: $0) }
            )
        }
        
        // Convert goals to RAG format
        let ragGoals = appState.goals.map { goal in
            GoalForRAG(
                id: goal.id,
                title: goal.title,
                description: goal.description,
                category: goal.goalType.rawValue, // Use goalType instead of category
                targetDate: nil, // Goals don't have targetDate, use endDate or other field if needed
                status: goal.status.rawValue,
                progressPercentage: goal.progressPercentage,
                milestones: goal.keyMetrics // Use keyMetrics instead of milestones
            )
        }
        
        // Convert projects to RAG format
        let ragProjects = appState.projects.map { project in
            let projectTasks = appState.tasks.filter { $0.projectId == project.id }
            let completedProjectTasks = projectTasks.filter { $0.status == .completed }
            
            return ProjectForRAG(
                id: project.id,
                title: project.title,
                description: project.description,
                status: project.status.rawValue,
                category: nil, // Projects don't have a category field
                createdAt: project.createdAt.map { dateFormatter.string(from: $0) },
                tasksCount: projectTasks.count,
                completedTasksCount: completedProjectTasks.count
            )
        }
        
        // Calculate metadata
        let completedTasks = appState.tasks.filter { $0.status == .completed }.count
        let overdueTasks = appState.tasks.filter { task in
            guard let dueDate = task.dueDate, task.status != .completed else { return false }
            return dueDate < Date()
        }.count
        
        let activeHabits = appState.habits.filter { $0.status == .active }.count
        let inProgressGoals = appState.goals.filter { $0.status == .inProgress }.count // Use inProgress instead of active
        let activeProjects = appState.projects.filter { $0.status == .active }.count
        
        let metadata = ContextMetadata(
            totalTasks: appState.tasks.count,
            completedTasks: completedTasks,
            overdueTasks: overdueTasks,
            totalHabits: appState.habits.count,
            activeHabits: activeHabits,
            totalGoals: appState.goals.count,
            activeGoals: inProgressGoals, // Use inProgressGoals instead of activeGoals
            totalProjects: appState.projects.count,
            activeProjects: activeProjects,
            contextGeneratedAt: dateFormatter.string(from: Date()),
            userTimezone: TimeZone.current.identifier
        )
        
        return UserProductivityContext(
            tasks: ragTasks,
            habits: ragHabits,
            goals: ragGoals,
            projects: ragProjects,
            metadata: metadata
        )
    }
    
    // MARK: - Fresh RAG Context Fetching
    
    private func fetchFreshRAGContext() -> AnyPublisher<UserProductivityContext, APIError> {
        print("🔄 Fetching fresh RAG context from main data API...")
        
        // Fetch all data from the main API simultaneously
        let tasksPublisher = getTasks()
        let habitsPublisher = getHabits()
        let yearlyGoalsPublisher = getYearlyGoals()
        let projectsPublisher = getProjects()
        
        return Publishers.Zip4(tasksPublisher, habitsPublisher, yearlyGoalsPublisher, projectsPublisher)
            .map { (tasks, habits, goals, projects) -> UserProductivityContext in
                print("✅ Fresh data fetched: \(tasks.count) tasks, \(habits.count) habits, \(goals.count) goals, \(projects.count) projects")
                return self.createRAGContextFromBackendData(tasks: tasks, habits: habits, goals: goals, projects: projects)
            }
            .eraseToAnyPublisher()
    }
    
    private func createRAGContextFromBackendData(tasks: [Task], habits: [Habit], goals: [Goal], projects: [Project]) -> UserProductivityContext {
        // Convert to RAG format with proper type conversions
        let ragTasks = tasks.map { task in
            TaskForRAG(
                id: task.id,
                title: task.title,
                description: task.description,
                status: task.status.rawValue,
                priority: task.priority.rawValue,
                dueDate: task.dueDate?.ISO8601Format(),
                projectId: task.projectId,
                tags: task.tags,
                createdAt: task.createdAt?.ISO8601Format(),
                completedAt: task.completedAt?.ISO8601Format()
            )
        }
        
        let ragHabits = habits.map { habit in
            HabitForRAG(
                id: habit.id,
                title: habit.title,
                description: habit.description ?? "",
                frequency: habit.frequency.rawValue,
                targetCount: habit.targetCount,
                currentCount: habit.currentCount,
                status: habit.status.rawValue,
                tags: habit.tags,
                streakCount: habit.currentStreak, // Use currentStreak from the model
                lastCompletedAt: habit.lastCompletedAt?.ISO8601Format()
            )
        }
        
        let ragGoals = goals.map { goal in
            GoalForRAG(
                id: goal.id,
                title: goal.title,
                description: goal.description ?? "",
                category: goal.goalType.rawValue, // Use goal type as category
                targetDate: nil, // Goals don't have a single target date in this model
                status: goal.status.rawValue,
                progressPercentage: goal.progressPercentage,
                milestones: goal.keyMetrics // Use keyMetrics as milestones
            )
        }
        
        let ragProjects = projects.map { project in
            ProjectForRAG(
                id: project.id,
                title: project.title,
                description: project.description,
                status: project.status.rawValue,
                category: project.priority.rawValue, // Use priority as category
                createdAt: project.createdAt?.ISO8601Format(),
                tasksCount: project.taskIds.count, // Use taskIds count
                completedTasksCount: 0 // We don't have this info, so default to 0
            )
        }
        
        let completedTasks = tasks.filter { $0.status == .completed }.count
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && task.status != .completed
        }.count
        
        let metadata = ContextMetadata(
            totalTasks: tasks.count,
            completedTasks: completedTasks,
            overdueTasks: overdueTasks,
            totalHabits: habits.count,
            activeHabits: habits.filter { $0.status == .active }.count,
            totalGoals: goals.count,
            activeGoals: goals.filter { $0.status == .inProgress }.count,
            totalProjects: projects.count,
            activeProjects: projects.filter { $0.status == .active }.count,
            contextGeneratedAt: ISO8601DateFormatter().string(from: Date()),
            userTimezone: TimeZone.current.identifier
        )
        
        return UserProductivityContext(
            tasks: ragTasks,
            habits: ragHabits,
            goals: ragGoals,
            projects: ragProjects,
            metadata: metadata
        )
    }
    
    // MARK: - RAG Context Formatting (Web Frontend Style)
    
    private func buildContextSummary(context: UserProductivityContext) -> String {
        var summary = ""
        
        // Tasks Section
        if !context.tasks.isEmpty {
            summary += "TASKS (\(context.tasks.count) total):\n"
            
            // Group tasks by status
            let pendingTasks = context.tasks.filter { $0.status == "pending" }
            let inProgressTasks = context.tasks.filter { $0.status == "in_progress" }
            let completedTasks = context.tasks.filter { $0.status == "completed" }
            
            if !pendingTasks.isEmpty {
                summary += "• Pending Tasks (\(pendingTasks.count)):\n"
                for task in pendingTasks.prefix(5) {
                    let dueInfo = task.dueDate != nil ? " (due: \(task.dueDate!))" : ""
                    summary += "  - \(task.title) [Priority: \(task.priority)]\(dueInfo)\n"
                }
                if pendingTasks.count > 5 {
                    summary += "  ... and \(pendingTasks.count - 5) more pending tasks\n"
                }
            }
            
            if !inProgressTasks.isEmpty {
                summary += "• In Progress (\(inProgressTasks.count)):\n"
                for task in inProgressTasks.prefix(3) {
                    summary += "  - \(task.title)\n"
                }
                if inProgressTasks.count > 3 {
                    summary += "  ... and \(inProgressTasks.count - 3) more in progress\n"
                }
            }
            
            if !completedTasks.isEmpty {
                summary += "• Recently Completed (\(completedTasks.count)): \(completedTasks.prefix(3).map(\.title).joined(separator: ", "))\n"
            }
            summary += "\n"
        }
        
        // Projects Section
        if !context.projects.isEmpty {
            summary += "PROJECTS (\(context.projects.count) total):\n"
            for project in context.projects.prefix(5) {
                let tasksInfo = project.tasksCount > 0 ? " (\(project.completedTasksCount)/\(project.tasksCount) tasks complete)" : ""
                summary += "• \(project.title) [Status: \(project.status)]\(tasksInfo)\n"
                if let description = project.description, !description.isEmpty {
                    summary += "  Description: \(description)\n"
                }
            }
            if context.projects.count > 5 {
                summary += "... and \(context.projects.count - 5) more projects\n"
            }
            summary += "\n"
        }
        
        // Goals Section
        if !context.goals.isEmpty {
            summary += "GOALS (\(context.goals.count) total):\n"
            for goal in context.goals.prefix(5) {
                let progressInfo = goal.progressPercentage > 0 ? " (\(Int(goal.progressPercentage))% complete)" : ""
                summary += "• \(goal.title) [Status: \(goal.status)]\(progressInfo)\n"
                if let description = goal.description, !description.isEmpty {
                    summary += "  \(description)\n"
                }
            }
            if context.goals.count > 5 {
                summary += "... and \(context.goals.count - 5) more goals\n"
            }
            summary += "\n"
        }
        
        // Habits Section
        if !context.habits.isEmpty {
            summary += "HABITS (\(context.habits.count) total):\n"
            for habit in context.habits.prefix(5) {
                let progressInfo = "\(habit.currentCount)/\(habit.targetCount)"
                let streakInfo = habit.streakCount > 0 ? " (streak: \(habit.streakCount))" : ""
                summary += "• \(habit.title) [Progress: \(progressInfo)]\(streakInfo)\n"
            }
            if context.habits.count > 5 {
                summary += "... and \(context.habits.count - 5) more habits\n"
            }
            summary += "\n"
        }
        
        // Summary Stats
        summary += "SUMMARY:\n"
        summary += "• Total Tasks: \(context.metadata.totalTasks) (\(context.metadata.completedTasks) completed, \(context.metadata.overdueTasks) overdue)\n"
        summary += "• Active Projects: \(context.metadata.activeProjects)/\(context.metadata.totalProjects)\n"
        summary += "• Active Goals: \(context.metadata.activeGoals)/\(context.metadata.totalGoals)\n"
        summary += "• Active Habits: \(context.metadata.activeHabits)/\(context.metadata.totalHabits)\n"
        summary += "• Context generated: \(context.metadata.contextGeneratedAt)\n"
        
        return summary
    }
}

// MARK: - Date Formatting Extension
extension Date {
    func ISO8601Format() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - Custom JSONDecoder with Date Handling
extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Backend format with timezone: "2025-08-11 18:32:03.312000+00:00"
            let backendFormatterWithTZ = DateFormatter()
            backendFormatterWithTZ.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSxxxx"
            backendFormatterWithTZ.locale = Locale(identifier: "en_US_POSIX")
            if let date = backendFormatterWithTZ.date(from: dateString) {
                return date
            }
            
            // Backend format without timezone but with microseconds: "2025-08-07 13:08:23.609608"
            let backendFormatterNoTZ = DateFormatter()
            backendFormatterNoTZ.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
            backendFormatterNoTZ.locale = Locale(identifier: "en_US_POSIX")
            backendFormatterNoTZ.timeZone = TimeZone.current // Use local timezone
            if let date = backendFormatterNoTZ.date(from: dateString) {
                return date
            }
            
            // Backend format with timezone but without microseconds: "2025-08-11 18:32:03+00:00"
            backendFormatterWithTZ.dateFormat = "yyyy-MM-dd HH:mm:ssxxxx"
            if let date = backendFormatterWithTZ.date(from: dateString) {
                return date
            }
            
            // Backend format without timezone and without microseconds: "2025-08-07 13:08:23"
            backendFormatterNoTZ.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = backendFormatterNoTZ.date(from: dateString) {
                return date
            }
            
            // ISO format with T separator and microseconds but no timezone: "2025-08-13T13:58:11.628404"
            let isoFormatterNoTZ = DateFormatter()
            isoFormatterNoTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            isoFormatterNoTZ.locale = Locale(identifier: "en_US_POSIX")
            isoFormatterNoTZ.timeZone = TimeZone.current // Use local timezone
            if let date = isoFormatterNoTZ.date(from: dateString) {
                return date
            }
            
            // ISO format with T separator and shorter fractional seconds: "2025-08-13T13:58:11.628"
            isoFormatterNoTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            if let date = isoFormatterNoTZ.date(from: dateString) {
                return date
            }
            
            // ISO format with T separator but no fractional seconds: "2025-08-13T13:58:11"
            isoFormatterNoTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = isoFormatterNoTZ.date(from: dateString) {
                return date
            }
            
            // Date only format: "2025-08-07"
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateOnlyFormatter.timeZone = TimeZone.current
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to ISO8601 format with T separator (standard format)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Final fallback to basic ISO8601
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
}
