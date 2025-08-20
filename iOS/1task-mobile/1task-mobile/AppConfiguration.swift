import Foundation

// MARK: - Configuration
struct AppConfiguration {
    
    // MARK: - API Configuration
    struct API {
        // For local development with Azure Functions running locally
        static let localBaseURL = "http://localhost:7071/api"
        
        // For production - your deployed Azure Function App URL
        static let productionBaseURL = "https://1task-backend-api-gse0fsgngtfxhjc6.southcentralus-01.azurewebsites.net/api"
        
        // Current base URL - set this to use Azure deployment
        static var baseURL: String {
            // Using Azure deployment by default
            return productionBaseURL
            
            // Uncomment below to switch back to environment-based logic:
            // #if DEBUG
            // return localBaseURL
            // #else
            // return productionBaseURL
            // #endif
        }
        
        // Timeout configuration
        static let requestTimeout: TimeInterval = 30.0
    }
    
    // MARK: - App Settings
    struct App {
        static let name = "1TaskAssistant"
        static let version = "1.0.0"
        static let supportEmail = "support@1taskassistant.com"
    }
    
    // MARK: - Development Settings
    struct Development {
        // Set to true to enable debug logging
        static let enableDebugLogging = true
        
        // Set to true to use demo data when backend is unavailable
        static let fallbackToDemoData = true
        
        // Demo user credentials
        static let demoUserId = "demo-user"
        static let demoUserName = "Demo User"
    }
}

// MARK: - Environment Detection
enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}
