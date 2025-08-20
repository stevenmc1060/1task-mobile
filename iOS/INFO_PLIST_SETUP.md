# Info.plist Configuration for MSAL

## ⚠️ IMPORTANT: You need to add URL Scheme to Info.plist

The "Application content not initialized" error is likely because the app's Info.plist doesn't have the required URL scheme configuration for MSAL.

## 📱 Steps to Fix in Xcode:

### 1. Open Info.plist in Xcode
1. In your Xcode project navigator, find **Info.plist** 
2. Right-click → **Open As** → **Source Code**

### 2. Add URL Scheme Configuration
Add this XML configuration to your Info.plist file (inside the `<dict>` tags):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.onetaskassistant</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>msauth.24243302-91ba-46a3-bbe2-f946278e5a33</string>
        </array>
    </dict>
</array>
```

### 3. Alternative: Use Xcode UI
If you prefer using Xcode's visual editor:

1. Select your **project** in navigator
2. Select your **1task-mobile target**
3. Go to **Info** tab
4. Expand **URL Types** section
5. Click **+** to add a new URL Type
6. Set:
   - **Identifier**: `com.yourcompany.onetaskassistant`
   - **URL Schemes**: `msauth.24243302-91ba-46a3-bbe2-f946278e5a33`
   - **Role**: `Editor`

## 🔧 Current MSAL Configuration
- **Client ID**: `24243302-91ba-46a3-bbe2-f946278e5a33`
- **Redirect URI**: `msauth.24243302-91ba-46a3-bbe2-f946278e5a33://auth`
- **Authority**: `https://login.microsoftonline.com/25dcc072-a2bf-4e88-876a-b63e6e0d0c3e`

## 🚀 After Adding URL Scheme:
1. **Clean Build Folder**: Product → Clean Build Folder
2. **Build and Run** the app
3. **Check Console**: Look for "✅ MSAL application context created successfully" message
4. **Test Sign In**: Try the Microsoft sign-in flow

## 📋 Debugging Steps:
1. Check Xcode console for MSAL setup debug messages
2. Make sure the URL scheme matches exactly: `msauth.24243302-91ba-46a3-bbe2-f946278e5a33`
3. Verify the redirect URI in Azure AD app registration matches

Let me know if you see the "✅ MSAL application context created successfully" message after adding the URL scheme!
