import Foundation
import UIKit
import Combine
import MSAL
import Network

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
            DispatchQueue.main.async {
                self.errorMessage = errorMessage
            }
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
            
            DispatchQueue.main.async {
                self.errorMessage = errorMessage
            }
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
        print("🔄 MSALAuthenticationService.signIn() called!")
        print("   Current state: isAuthenticated=\(isAuthenticated), isLoading=\(isLoading)")
        print("   Application context: \(applicationContext != nil ? "available" : "nil")")
        print("🔄 Starting real MSAL authentication...")
        
        // Reset any mock auth state
        isUsingMockAuth = false
        currentMockUser = nil
        
        // Check if we can present UI safely
        if !canPresentAuthenticationUI() {
            print("⚠️ Cannot present authentication UI - waiting for safe state...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.signIn() // Retry after delay
            }
            return
        }
        
        // Proceed with MSAL sign-in
        signInWithRetry(attempt: 1)
    }
    
    private func canPresentAuthenticationUI() -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("⚠️ No root view controller available")
            return false
        }
        
        // Check if any modal is already being presented
        if let presentedVC = rootViewController.presentedViewController {
            print("⚠️ Another view controller is being presented: \(type(of: presentedVC))")
            
            // If it's an alert, dismiss it safely
            if presentedVC is UIAlertController {
                print("🔧 Dismissing existing alert to make room for authentication...")
                presentedVC.dismiss(animated: true)
                return false // Wait for dismissal to complete
            }
            return false
        }
        
        return true
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
                
                if let authError = error {
                    let nsError = authError as NSError
                    print("❌ Microsoft sign-in failed (attempt \(attempt)):")
                    print("   Error Domain: \(nsError.domain)")
                    print("   Error Code: \(nsError.code)")
                    print("   Error Description: \(nsError.localizedDescription)")
                    print("   Error User Info: \(nsError.userInfo)")
                    
                    // Check network connectivity for network-related errors
                    if nsError.domain == NSURLErrorDomain {
                        let isConnected = self?.checkNetworkConnectivity() ?? false
                        print("🌐 Network connectivity check: \(isConnected ? "Connected" : "No Connection")")
                    }
                    
                    // Check for physical device specific error and handle it
                    if self?.handlePhysicalDeviceAuthenticationError(error: nsError) == true {
                        return // Error handled by device-specific handler
                    }
                    
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
                    let isRetryableError = (
                        // MSAL network errors
                        (nsError.domain == "MSALErrorDomain" && 
                         (nsError.code == -50003 || nsError.code == -50004)) ||
                        // URLSession network errors
                        (nsError.domain == NSURLErrorDomain && 
                         (nsError.code == NSURLErrorNetworkConnectionLost || 
                          nsError.code == NSURLErrorTimedOut ||
                          nsError.code == NSURLErrorNotConnectedToInternet))
                    )
                    
                    if isRetryableError && 
                       attempt < maxAttempts &&
                       nsError.userInfo["MSALInvalidResultKey"] == nil { // Only retry if no result
                        
                        print("🔄 Retryable network error detected, retrying in 2 seconds...")
                        print("🔄 Will check connectivity before retry...")
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
        print("   Current auth state: isAuthenticated=\(isAuthenticated)")
        print("   Current user: \(currentUser?.username ?? "none")")
        print("   Application context: \(applicationContext != nil ? "available" : "nil")")
        
        isLoading = true
        errorMessage = nil
        
        // First, try to sign out from MSAL if we have the proper context and user
        if let applicationContext = self.applicationContext,
           let currentUser = self.currentUser {
            
            do {
                // Attempt to remove from MSAL keychain
                try applicationContext.remove(currentUser)
                print("✅ Successfully removed from MSAL keychain")
            } catch {
                print("⚠️ MSAL keychain removal failed: \(error)")
                print("   Error domain: \((error as NSError).domain)")
                print("   Error code: \((error as NSError).code)")
                // Continue with local sign-out - don't fail the entire operation
                
                // Check if it's the specific keychain error we're seeing
                let nsError = error as NSError
                if nsError.domain == "NSOSStatusErrorDomain" && nsError.code == -34018 {
                    print("⚠️ Keychain access error (-34018) - proceeding with local sign-out only")
                } else if nsError.domain.contains("MSALError") && error.localizedDescription.contains("keychain") {
                    print("⚠️ MSAL keychain error - proceeding with local sign-out only")
                }
            }
        } else {
            print("⚠️ MSAL context or user not available - performing local sign-out only")
        }
        
        // Always perform local sign-out regardless of MSAL keychain operation
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
            self?.currentMockUser = nil
            self?.isAuthenticated = false
            self?.isLoading = false
            self?.isUsingMockAuth = false
            // Don't set errorMessage for keychain issues during sign-out
            // Only clear it to ensure clean state
            self?.errorMessage = nil
            print("✅ Local sign-out completed successfully")
            print("   Final auth state: isAuthenticated=\(self?.isAuthenticated ?? false)")
        }
        
        // Note: We don't treat keychain errors as failures since the user
        // should still be able to sign out locally. The token may remain
        // in keychain but the app state is properly reset.
    }
    
    func getAccessToken() -> AnyPublisher<String, Error> {
        return Future<String, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MSAL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication service unavailable"])))
                return
            }
            
            guard let applicationContext = self.applicationContext else {
                promise(.failure(NSError(domain: "MSAL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Application context not initialized"])))
                return
            }
            
            guard let account = self.currentUser else {
                promise(.failure(NSError(domain: "MSAL", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }
            
            let parameters = MSALSilentTokenParameters(scopes: self.kScopes, account: account)
            
            applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
                if let tokenError = error {
                    promise(.failure(tokenError))
                    return
                }
                
                guard let result = result else {
                    promise(.failure(NSError(domain: "MSAL", code: -1, userInfo: [NSLocalizedDescriptionKey: "No token result"])))
                    return
                }
                
                promise(.success(result.accessToken))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Async version of getAccessToken for use with await
    func getAccessTokenAsync() async -> String? {
        return await withCheckedContinuation { continuation in
            getAccessToken()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure = completion {
                            continuation.resume(returning: nil)
                        }
                    },
                    receiveValue: { token in
                        continuation.resume(returning: token)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    // MARK: - User Info Properties
    var userDisplayName: String {
        if isUsingMockAuth, let mockUser = currentMockUser {
            return mockUser.username?.components(separatedBy: "@").first?.capitalized ?? "Demo User"
        }
        return currentUser?.username?.components(separatedBy: "@").first?.capitalized ?? "Unknown User"
    }
    
    var userId: String {
        if isUsingMockAuth, let mockUser = currentMockUser {
            return mockUser.identifier
        }
        return currentUser?.homeAccountId?.identifier ?? "unknown"
    }
    
    var userEmail: String {
        if isUsingMockAuth, let mockUser = currentMockUser {
            return mockUser.username ?? "demo@onetaskassistant.com"
        }
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
    
    // MARK: - Microsoft Graph API Calls
    
    struct UserProfile: Codable {
        let givenName: String?
        let surname: String?
        let displayName: String?
        let mail: String?
        let userPrincipalName: String?
    }
    
    func fetchUserProfile() -> AnyPublisher<UserProfile, Error> {
        return Future<UserProfile, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MSALAuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }
            
            self.acquireTokenSilent { result in
                switch result {
                case .success(let token):
                    self.makeGraphAPIRequest(
                        endpoint: "https://graph.microsoft.com/v1.0/me",
                        accessToken: token
                    ) { (result: Result<UserProfile, Error>) in
                        promise(result)
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchUserPhoto() -> AnyPublisher<UIImage, Error> {
        return Future<UIImage, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MSALAuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }
            
            self.acquireTokenSilent { result in
                switch result {
                case .success(let token):
                    // First try to get the photo
                    var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0/me/photo/$value")!)
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.httpMethod = "GET"
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            promise(.failure(error))
                            return
                        }
                        
                        guard let data = data,
                              let image = UIImage(data: data) else {
                            // If no photo available, create a default avatar with user's initials
                            self.fetchUserProfile().sink(
                                receiveCompletion: { completion in
                                    if case .failure(_) = completion {
                                        // Create a generic default avatar
                                        let defaultImage = self.createDefaultAvatar(with: "?")
                                        promise(.success(defaultImage))
                                    }
                                },
                                receiveValue: { profile in
                                    let initials = self.getInitials(from: profile)
                                    let defaultImage = self.createDefaultAvatar(with: initials)
                                    promise(.success(defaultImage))
                                }
                            ).store(in: &self.cancellables)
                            return
                        }
                        
                        promise(.success(image))
                    }.resume()
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func makeGraphAPIRequest<T: Codable>(
        endpoint: String,
        accessToken: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "MSALAuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MSALAuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func getInitials(from profile: UserProfile) -> String {
        let firstName = profile.givenName?.prefix(1) ?? ""
        let lastName = profile.surname?.prefix(1) ?? ""
        return "\(firstName)\(lastName)".uppercased()
    }
    
    private func createDefaultAvatar(with initials: String) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background circle
            UIColor.systemBlue.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            
            // Text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            
            let text = initials.isEmpty ? "?" : initials
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // Helper method for Graph API calls
    private func acquireTokenSilent(completion: @escaping (Result<String, Error>) -> Void) {
        getAccessToken()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { token in
                    completion(.success(token))
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Microsoft Graph API Calls
    func fetchUserProfile() async -> (givenName: String?, profilePhoto: UIImage?) {
        guard let accessToken = await getAccessTokenAsync() else {
            print("❌ No access token available for Graph API")
            return (nil, nil)
        }
        
        async let profileTask = fetchUserProfileInfo(accessToken: accessToken)
        async let photoTask = fetchUserProfilePhoto(accessToken: accessToken)
        
        let profile = await profileTask
        let photo = await photoTask
        
        return (profile, photo)
    }
    
    private func fetchUserProfileInfo(accessToken: String) async -> String? {
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me?$select=givenName,displayName") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any],
                   let givenName = dict["givenName"] as? String {
                    print("✅ Fetched user profile: \(givenName)")
                    return givenName
                }
            } else {
                print("❌ Failed to fetch user profile: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
        } catch {
            print("❌ Error fetching user profile: \(error)")
        }
        
        return nil
    }
    
    private func fetchUserProfilePhoto(accessToken: String) async -> UIImage? {
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/photo/$value") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                if let image = UIImage(data: data) {
                    print("✅ Fetched user profile photo")
                    return image
                }
            } else if let httpResponse = response as? HTTPURLResponse, 
                      httpResponse.statusCode == 404 {
                print("ℹ️ No profile photo available for user")
            } else {
                print("❌ Failed to fetch user photo: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
        } catch {
            print("❌ Error fetching user photo: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Network and Device Error Handling
    private func checkNetworkConnectivity() -> Bool {
        print("🌐 Checking network connectivity...")
        
        // Simple network check using URLSession
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        
        let task = URLSession.shared.dataTask(with: URL(string: "https://www.microsoft.com")!) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                isConnected = httpResponse.statusCode == 200
            } else if error != nil {
                isConnected = false
            }
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5.0) // Wait up to 5 seconds
        
        print("🌐 Network connectivity: \(isConnected ? "Connected" : "Not Connected")")
        return isConnected
    }
    
    private func handlePhysicalDeviceAuthenticationError(error: NSError) -> Bool {
        print("📱 Checking for physical device authentication errors...")
        
        // Handle keychain/entitlement errors that occur on physical devices
        if error.code == -34018 || error.code == -50000 {
            print("🔧 Detected keychain/broker error on physical device")
            print("🎭 This device has keychain entitlement restrictions. Switching to demo mode immediately...")
            
            DispatchQueue.main.async {
                self.errorMessage = "Microsoft authentication not available on this device. Switching to demo mode..."
                
                // Switch to demo mode after a brief delay to show the message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.signInAsDemo()
                }
            }
            
            return true // Indicate we handled it
        }
        
        // Handle network connection errors
        if error.domain == NSURLErrorDomain {
            print("🌐 Network error detected on physical device")
            
            DispatchQueue.main.async {
                self.errorMessage = """
                Network connection error: \(error.localizedDescription)
                
                Please check:
                • Internet connection
                • Firewall settings
                • VPN configuration
                
                Try 'Demo Login' if network issues persist.
                """
            }
            return true
        }
        
        return false
    }
    
    // MARK: - Web-View Only Authentication (Broker Bypass)
    func authenticateWithWebViewOnly() {
        print("🌐 Starting web-view-only authentication (bypassing Microsoft Authenticator broker)...")
        
        guard let applicationContext = self.applicationContext else {
            DispatchQueue.main.async {
                self.errorMessage = "Authentication service not initialized"
            }
            return
        }
        
        guard canPresentAuthenticationUI() else {
            print("⚠️ UI not ready for web-view authentication")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.authenticateWithWebViewOnly()
            }
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            DispatchQueue.main.async {
                self.errorMessage = "Cannot access app window for authentication"
            }
            return
        }
        
        // Configure web view parameters to explicitly avoid broker
        let webViewParameters = MSALWebviewParameters(authPresentationViewController: rootViewController)
        webViewParameters.webviewType = .wkWebView  // Force WKWebView, not system browser
        
        // Use standard scopes but with web-view only
        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .login  // Force fresh login to avoid cached tokens
        
        // Try to disable broker explicitly
        parameters.extraQueryParameters = ["prompt": "login", "response_mode": "query"]
        
        print("🌐 Configured for pure web-view authentication")
        print("   Scopes: \(kScopes)")
        print("   WebView Type: WKWebView (no system browser)")
        print("   Prompt Type: Login (fresh authentication)")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = "Trying web-view authentication (bypassing broker)..."
        }
        
        applicationContext.acquireToken(with: parameters) { [weak self] (result, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let authError = error as NSError? {
                    print("❌ Web-view authentication failed:")
                    print("   Domain: \(authError.domain)")
                    print("   Code: \(authError.code)")
                    print("   Description: \(authError.localizedDescription)")
                    print("   UserInfo: \(authError.userInfo)")
                    
                    // If it's still a keychain/broker error, provide clear guidance and fallback to demo
                    if authError.code == -50000 || authError.code == -34018 {
                        print("🎭 Keychain/broker error persists. Auto-falling back to demo authentication...")
                        self?.errorMessage = "Microsoft authentication unavailable on this device. Using demo mode..."
                        
                        // Automatically fall back to demo login
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.signInAsDemo()
                        }
                        return
                        
                    } else if "\(authError.userInfo)".contains("broker") {
                        print("🎭 Broker conflict persists. Auto-falling back to demo authentication...")
                        self?.errorMessage = "Microsoft authentication broker conflict. Using demo mode..."
                        
                        // Automatically fall back to demo login
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.signInAsDemo()
                        }
                        return
                        
                    } else if authError.domain == NSURLErrorDomain {
                        self?.errorMessage = "Network error during web authentication. Check internet connection or try demo mode."
                    } else {
                        // For other errors, also suggest demo mode
                        self?.errorMessage = """
                        Web-view authentication failed: \(authError.localizedDescription)
                        
                        Consider using demo mode to test the app.
                        """
                    }
                    return
                }
                
                if let result = result {
                    print("✅ Web-view-only authentication successful!")
                    print("   User: \(result.account.username ?? "unknown")")
                    print("   Account ID: \(result.account.homeAccountId?.identifier ?? "unknown")")
                    
                    self?.currentUser = result.account
                    self?.isAuthenticated = true
                    self?.errorMessage = nil
                    
                    print("🎉 Successfully authenticated without broker conflicts!")
                }
            }
        }
    }
    
    // MARK: - Entitlement Diagnostics
    func diagnoseKeychainEntitlements() -> String {
        var diagnosis = "🔍 KEYCHAIN ENTITLEMENT DIAGNOSIS:\n\n"
        
        // Check main bundle entitlements
        if let path = Bundle.main.path(forResource: "Entitlements", ofType: "plist"),
           let entitlements = NSDictionary(contentsOfFile: path) {
            diagnosis += "📱 Found Entitlements.plist\n"
            
            if let keychainGroups = entitlements["keychain-access-groups"] as? [String] {
                diagnosis += "🔑 Keychain Access Groups: \(keychainGroups.count)\n"
                for group in keychainGroups {
                    diagnosis += "   - \(group)\n"
                }
            } else {
                diagnosis += "⚠️ No keychain-access-groups found\n"
            }
            
            if let appGroups = entitlements["com.apple.security.application-groups"] as? [String] {
                diagnosis += "👥 App Groups: \(appGroups.count)\n"
                for group in appGroups {
                    diagnosis += "   - \(group)\n"
                }
            } else {
                diagnosis += "⚠️ No application groups found\n"
            }
        } else {
            diagnosis += "❌ No Entitlements.plist found\n"
        }
        
        // Check if Microsoft Authenticator is installed
        if UIApplication.shared.canOpenURL(URL(string: "msauth://")!) {
            diagnosis += "\n✅ Microsoft Authenticator is installed\n"
            diagnosis += "   - This is NOT the problem!\n"
            diagnosis += "   - The issue is keychain entitlements\n"
        } else {
            diagnosis += "\n⚠️ Microsoft Authenticator not detected\n"
            diagnosis += "   - Error -34018 still indicates entitlement issue\n"
        }
        
        // Recommendations
        diagnosis += "\n🔧 RECOMMENDATIONS:\n"
        diagnosis += "1. Use 'Web-View Only' authentication (bypasses broker)\n"
        diagnosis += "2. Add proper keychain entitlements if you want SSO\n"
        diagnosis += "3. Demo Login works perfectly for testing\n"
        
        diagnosis += "\n✅ KEEP Microsoft Authenticator - it's not the issue!"
        
        return diagnosis
    }
    
    // MARK: - Error Handling Methods
    func handleBrokerKeyError() {
        print("🔧 Handling broker key error...")
        
        // Clear any cached authentication state
        DispatchQueue.main.async {
            self.errorMessage = "Attempting to fix broker key issues..."
            self.isLoading = true
        }
        
        // Sign out to clear any corrupted state
        signOut()
        
        // Wait a moment then try web-view only authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.authenticateWithWebViewOnly()
        }
    }
    
    func showDeviceSpecificGuidance() {
        print("📱 Showing device-specific guidance for authentication issues")
        
        let guidance = diagnoseKeychainEntitlements()
        
        DispatchQueue.main.async {
            // For now, we'll set this as the error message
            // In a production app, you might want to show this in a dedicated view or alert
            self.errorMessage = """
            AUTHENTICATION GUIDANCE:
            
            The error you're seeing is related to keychain entitlements, not Microsoft Authenticator.
            
            SOLUTION: Use 'Web-View Only' authentication which bypasses the broker completely.
            
            OR use 'Demo Login' to test app functionality.
            
            Technical details:
            \(guidance)
            """
        }
    }
    
    // MARK: - Demo Authentication
    func signInAsDemo() {
        print("🎭 Starting demo authentication (mock login)...")
        print("🎯 Demo mode provides full app functionality for testing")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = "Activating demo mode - you'll have full access to all features..."
        }
        
        // Create a mock user account for demo purposes
        let mockAccount = MockMSALAccount(
            username: "demo@onetaskassistant.com",
            identifier: "demo-account-id-12345"
        )
        
        // Simulate authentication delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isUsingMockAuth = true
            self.currentMockUser = mockAccount
            self.currentUser = nil // Clear any real MSAL account
            self.isAuthenticated = true
            self.isLoading = false
            self.errorMessage = nil
            
            print("✅ Demo authentication successful!")
            print("   Demo User: \(mockAccount.username ?? "unknown")")
            print("   Demo Account ID: \(mockAccount.identifier)")
            print("🎉 You can now use all app features in demo mode!")
        }
    }
}
