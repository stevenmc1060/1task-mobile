# MSAL Configuration Guide for 1TaskAssistant iOS

This guide will help you set up Microsoft Authentication Library (MSAL) so your iOS app uses the same organizational credentials as your web application.

## 🚀 Quick Setup Overview

1. **Azure App Registration** - Configure your app in Azure AD
2. **iOS Configuration** - Update app settings and Info.plist
3. **MSAL Integration** - Update authentication service with your details
4. **Backend Authentication** - Ensure backend accepts MSAL tokens
5. **Testing** - Verify cross-platform data consistency

---

## 📋 Step 1: Azure App Registration

### Option A: Use Existing Registration (Recommended)
If your web app already has an Azure App Registration:

1. **Find your existing app registration** in Azure Portal
2. **Note these values**:
   - Application (client) ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Directory (tenant) ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
3. **Add Mobile Platform**:
   - Go to Authentication → Add a platform
   - Choose "iOS / macOS"
   - Bundle ID: `com.yourcompany.onetaskassistant` (or your bundle ID)
   - Configure redirect URI: `msauth.com.yourcompany.onetaskassistant://auth`

### Option B: Create New Registration
1. **Azure Portal** → App registrations → New registration
2. **Name**: "1TaskAssistant Mobile"
3. **Supported account types**: Choose based on your needs
4. **Platform**: Add iOS/macOS platform as above

---

## 📱 Step 2: iOS App Configuration

### Update Bundle Identifier
Make sure your iOS app bundle ID matches what you configured in Azure:
- **Current**: `com.example.onetaskassistant` (or similar)
- **Should be**: `com.yourcompany.onetaskassistant`

### Add URL Scheme to Info.plist
Add this to your app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.onetaskassistant</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>msauth.com.yourcompany.onetaskassistant</string>
        </array>
    </dict>
</array>
```

### Add MSAL Package
In Xcode:
1. **File** → Add Package Dependencies
2. **URL**: `https://github.com/AzureAD/microsoft-authentication-library-for-objc`
3. **Add to target**: Your main app target

---

## 🔧 Step 3: Update MSAL Configuration

Update `MSALAuthenticationService.swift` with your values:

```swift
// Replace with your actual values from Azure App Registration
private let kClientID = "YOUR_CLIENT_ID_HERE"        // Application (client) ID
private let kRedirectUri = "msauth.com.yourcompany.onetaskassistant://auth"  // Must match Azure config
private let kAuthority = "https://login.microsoftonline.com/YOUR_TENANT_ID"  // Directory (tenant) ID
```

### Example with real values:
```swift
private let kClientID = "12345678-1234-1234-1234-123456789abc"
private let kRedirectUri = "msauth.com.yourcompany.onetaskassistant://auth"
private let kAuthority = "https://login.microsoftonline.com/87654321-4321-4321-4321-cba987654321"
```

---

## 🌐 Step 4: Backend Authentication (If Needed)

If your backend requires authenticated requests:

### Option A: Anonymous Access (Current)
Your backend currently uses `auth_level=func.AuthLevel.ANONYMOUS`, so MSAL tokens are optional but can be sent for user identification.

### Option B: Require Authentication
To require MSAL tokens, update your Azure Functions:

```python
# In function_app.py, change from:
@app.route(route="tasks", auth_level=func.AuthLevel.ANONYMOUS)

# To:
@app.route(route="tasks", auth_level=func.AuthLevel.FUNCTION)
```

And add token validation middleware.

---

## 🧪 Step 5: Testing Cross-Platform Consistency

### Test Scenario 1: Demo Mode
1. **iOS App**: "Continue as Demo User"
2. **Web App**: Use demo data
3. **Verify**: Both show same sample data

### Test Scenario 2: MSAL Authentication
1. **iOS App**: "Sign in with Microsoft"
2. **Web App**: Sign in with same Microsoft account
3. **Create data**: Add task in web app
4. **Verify**: Task appears in iOS app
5. **Create data**: Add habit in iOS app  
6. **Verify**: Habit appears in web app

### Test Scenario 3: Multi-Device
1. **iPhone**: Sign in and create project
2. **iPad**: Sign in with same account
3. **Verify**: Project syncs across devices

---

## 🔍 Troubleshooting

### Common Issues

**"Invalid redirect URI"**
- Ensure redirect URI in Azure matches exactly: `msauth.com.yourcompany.onetaskassistant://auth`
- Check Info.plist URL scheme matches bundle ID

**"Client ID not found"**
- Double-check Application (client) ID from Azure
- Ensure no extra spaces or characters

**"Authority URL invalid"**
- Verify tenant ID is correct
- Use format: `https://login.microsoftonline.com/YOUR_TENANT_ID`

**"Data not syncing between platforms"**
- Ensure both apps use same user ID from MSAL
- Check API endpoints are same for both platforms
- Verify Cosmos DB connection

### Debug Logging
Enable debug logging in `AppConfiguration.swift`:
```swift
static let enableDebugLogging = true
```

This will show authentication flows and API requests in Xcode console.

---

## 🎯 Expected User Experience

### First Launch
1. **Splash Screen** → Beautiful animated intro
2. **Login Screen** → Shows Microsoft sign-in + demo option
3. **Microsoft Auth** → Opens system browser for organization login
4. **Data Sync** → Automatically loads user's real data
5. **Dashboard** → Shows tasks/habits/goals from web app

### Subsequent Launches
1. **Splash Screen** → Quick animation
2. **Auto Login** → Uses stored MSAL tokens
3. **Dashboard** → Immediate access to synchronized data

### Cross-Platform Flow
1. **Web App**: User creates weekly goals
2. **iOS App**: Goals automatically appear in dashboard
3. **iOS App**: User marks habit as complete
4. **Web App**: Habit status updates in real-time

---

## 🎉 Success Criteria

✅ **Authentication**: iOS app signs in with org credentials  
✅ **Data Sync**: Same data appears on web and mobile  
✅ **Real-time Updates**: Changes sync immediately  
✅ **Offline Graceful**: App works without internet  
✅ **Security**: Proper token handling and storage  

---

## 📞 Need Help?

If you encounter issues:

1. **Check Azure Portal**: Verify app registration settings
2. **Review Logs**: Enable debug logging for detailed info  
3. **Test Web App**: Ensure backend APIs work via browser
4. **Test Demo Mode**: Verify app works with demo data first
5. **Check Bundle ID**: Must match Azure configuration exactly

The iOS app is now ready to provide a seamless, authenticated experience that perfectly complements your web application! 🚀
