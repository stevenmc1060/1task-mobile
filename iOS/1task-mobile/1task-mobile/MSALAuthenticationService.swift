import Foundation
import UIKit
import Combine
import MSAL

// MARK: - Mock MSAL Types (fallback when real MSAL fails)
struct MockMSALAccount {
    let username: String?
    let identifier: String
}

// MARK: - MSAL Authentication Service (Hybrid: Real MSAL with Mock Fallback)
class MSALAuthenticationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: MSALAccount?
    @Published var currentMockUser: MockMSALAccount?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUsingMockAuth = false
    
    // MARK: - Private Properties
    private var applicationContext: MSALPublicClientApplication?
    private var webViewParameters: MSALWebviewParameters?
    
    // MARK: - Configuration (improved for network connectivity)
    // Azure AD configuration from web frontend
    private let kClientID = "24243302-91ba-46a3-bbe2-f946278e5a33"
    private let kRedirectUri = "msauth.com.onetaskassistant.mobile://auth"
    private let kAuthority = "https://login.microsoftonline.com/common"
    
    private let kScopes: [String] = [
        "User.Read"
    ]
    
    // MARK: - Initialization
    init() {
        setupMSAL()
        checkForExistingAccount()
    }
    
    // MARK: - MSAL Setup
    private func setupMSAL() {
        print("🔧 Setting up MSAL with improved configuration...")
        print("   Client ID: '\(kClientID)'")
        print("   Redirect URI: '\(kRedirectUri)'")
        print("   Authority: '\(kAuthority)'")
        
        // Validate Client ID format (should be a GUID)
        let guidPattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        let guidRegex = try? NSRegularExpression(pattern: guidPattern)
        let isValidGuid = guidRegex?.firstMatch(in: kClientID, range: NSRange(location: 0, length: kClientID.count)) != nil
        print("   Client ID is valid GUID: \(isValidGuid)")
        
        guard isValidGuid else {
            let errorMessage = "Invalid Client ID format: \(kClientID)"
            print("❌ \(errorMessage)")
            self.errorMessage = errorMessage
            return
        }
        
        do {
            // Create configuration with explicit redirect URI and authority
            let pcaConfig = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: kRedirectUri, authority: try MSALAuthority(url: URL(string: kAuthority)!))
            
            print("🔧 Created MSAL config with explicit redirect URI and authority")
            
            self.applicationContext = try MSALPublicClientApplication(configuration: pcaConfig)
            print("✅ MSAL application context created successfully with full config")
            
        } catch let error as NSError {
            let errorMessage = "Failed to initialize MSAL: \(error.localizedDescription)"
            print("❌ MSAL Setup Error Code: \(error.code)")
            print("❌ MSAL Setup Error Domain: \(error.domain)")
            print("❌ MSAL Setup Error: \(error)")
            print("❌ Error User Info: \(error.userInfo)")
            print("❌ Full Error Description: \(errorMessage)")
            self.errorMessage = errorMessage
        }
    }
    
    private func checkForExistingAccount() {
        // Check if we have a cached account
        guard let applicationContext = applicationContext else { return }
        
        do {
            let cachedAccounts = try applicationContext.allAccounts()
            if let firstAccount = cachedAccounts.first {
                self.currentUser = firstAccount
                self.isAuthenticated = true
                print("✅ Found existing account: \(firstAccount.username ?? "unknown")")
            }
        } catch {
            print("⚠️ No cached accounts found: \(error)")
        }
    }
    
    // MARK: - Authentication Methods
    func signIn() {
        // First test network connectivity, then attempt sign-in
        print("🔄 Testing network connectivity before authentication...")
        testNetworkConnectivity()
        
        // Delay sign-in to allow network test to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.signInWithRetry(attempt: 1)
        }
    }
    
    private func signInWithRetry(attempt: Int) {
        let maxAttempts = 2
        
        print("🔄 Starting Microsoft sign-in (attempt \(attempt)/\(maxAttempts))...")
        
        guard let applicationContext = self.applicationContext else {
            self.errorMessage = "Application context not initialized"
            return
        }
        
        // Create web view parameters
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "No root view controller available"
            return
        }
        
        let webViewParameters = MSALWebviewParameters(authPresentationViewController: rootViewController)
        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        
        // Add extra parameters for better network handling
        parameters.promptType = .selectAccount
        
        isLoading = true
        errorMessage = nil
        
        applicationContext.acquireToken(with: parameters) { [weak self] (result, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    let nsError = error as NSError
                    print("❌ Microsoft sign-in failed (attempt \(attempt)):")
                    print("   Error Domain: \(nsError.domain)")
                    print("   Error Code: \(nsError.code)")
                    print("   Error Description: \(nsError.localizedDescription)")
                    print("   Error User Info: \(nsError.userInfo)")
                    
                    // Check if this is actually a successful auth with scope mismatch
                    if nsError.domain == "MSALErrorDomain" && 
                       nsError.code == -50003 && 
                       nsError.userInfo["MSALInvalidResultKey"] != nil {
                        
                        // Extract the result from the error - this is actually successful!
                        if let result = nsError.userInfo["MSALInvalidResultKey"] as? MSALResult {
                            print("✅ Authentication actually succeeded despite error!")
                            print("   Granted scopes: \(nsError.userInfo["MSALGrantedScopesKey"] ?? "unknown")")
                            print("   Declined scopes: \(nsError.userInfo["MSALDeclinedScopesKey"] ?? "none")")
                            
                            self?.currentUser = result.account
                            self?.isAuthenticated = true
                            self?.errorMessage = nil
                            
                            print("✅ Microsoft sign-in successful (with scope adjustment): \(result.account.username ?? "unknown")")
                            print("   Account ID: \(result.account.homeAccountId?.identifier ?? "unknown")")
                            print("   Access Token received: \(result.accessToken.prefix(20))...")
                            return
                        }
                    }
                    
                    // Check if this is a network error that we can retry
                    if nsError.domain == "MSALErrorDomain" && 
                       (nsError.code == -50003 || nsError.code == -50004) && 
                       attempt < maxAttempts &&
                       nsError.userInfo["MSALInvalidResultKey"] == nil { // Only retry if no result
                        
                        print("🔄 Network error detected, retrying in 2 seconds...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.signInWithRetry(attempt: attempt + 1)
                        }
                        return
                    }
                    
                    // Provide more specific error messages
                    var friendlyError = nsError.localizedDescription
                    if nsError.domain == "MSALErrorDomain" {
                        switch nsError.code {
                        case -50003:
                            friendlyError = "Authentication completed with scope differences."
                        case -50004:
                            friendlyError = "Network timeout. Please try again."
                        case -50005:
                            friendlyError = "Invalid server response. Please try again."
                        default:
                            friendlyError = "Authentication error (\(nsError.code)): \(nsError.localizedDescription)"
                        }
                    }
                    
                    self?.errorMessage = friendlyError
                    return
                }
                
                guard let result = result else {
                    print("❌ No result from Microsoft sign-in")
                    self?.errorMessage = "Authentication failed - no result"
                    return
                }
                
                self?.currentUser = result.account
                self?.isAuthenticated = true
                
                print("✅ Microsoft sign-in successful: \(result.account.username ?? "unknown")")
                print("   Account ID: \(result.account.homeAccountId?.identifier ?? "unknown")")
                print("   Access Token received: \(result.accessToken.prefix(20))...")
            }
        }
    }
    
    func signOut() {
        print("🔄 Starting Microsoft sign-out...")
        
        guard let applicationContext = self.applicationContext else {
            self.errorMessage = "Application context not initialized"
            return
        }
        
        guard let currentUser = self.currentUser else {
            // User is already signed out
            self.isAuthenticated = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try applicationContext.remove(currentUser)
            
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = nil
                self?.isAuthenticated = false
                self?.isLoading = false
                print("✅ Microsoft sign-out successful")
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.errorMessage = "Sign-out failed: \(error.localizedDescription)"
                print("❌ Microsoft sign-out failed: \(error)")
            }
        }
    }
    
    func getAccessToken() -> AnyPublisher<String, Error> {
        return Future<String, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MSALError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication service unavailable"])))
                return
            }
            
            guard let applicationContext = self.applicationContext else {
                promise(.failure(NSError(domain: "MSALError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Application context not initialized"])))
                return
            }
            
            guard let account = self.currentUser else {
                promise(.failure(NSError(domain: "MSALError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }
            
            let parameters = MSALSilentTokenParameters(scopes: self.kScopes, account: account)
            
            applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let result = result else {
                    promise(.failure(NSError(domain: "MSALError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No token result"])))
                    return
                }
                
                promise(.success(result.accessToken))
            }
        }
        .eraseToAnyPublisher()
    }
    // MARK: - User Info Properties
    var userDisplayName: String {
        return currentUser?.username?.components(separatedBy: "@").first?.capitalized ?? "Unknown User"
    }
    
    var userId: String {
        return currentUser?.homeAccountId?.identifier ?? "unknown"
    }
    
    var userEmail: String {
        return currentUser?.username ?? ""
    }
    
    // MARK: - Network Diagnostics
    private func testNetworkConnectivity() {
        print("🌐 Testing network connectivity to Microsoft endpoints...")
        
        let testUrls = [
            "https://login.microsoftonline.com/common/discovery/instance",
            "https://graph.microsoft.com/v1.0/",
            "https://login.microsoftonline.com/common/oauth2/v2.0/token"
        ]
        
        for urlString in testUrls {
            if let url = URL(string: urlString) {
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    if let error = error {
                        print("❌ Failed to reach \(urlString): \(error.localizedDescription)")
                    } else if let httpResponse = response as? HTTPURLResponse {
                        print("✅ Successfully reached \(urlString): HTTP \(httpResponse.statusCode)")
                    }
                }
                task.resume()
            }
        }
    }

    // MARK: - Fallback Authentication with Custom URLSession
    private func signInWithCustomNetworking() {
        print("🔄 Attempting sign-in with custom networking configuration...")
        
        // Create a custom URLSession with more resilient configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        
        // Test network connectivity first
        testNetworkConnectivity()
        
        // Continue with regular MSAL but after network test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.signInWithRetry(attempt: 1)
        }
    }
}
