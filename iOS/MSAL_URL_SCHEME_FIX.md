# MSAL URL Scheme Fix - Step by Step

## ✅ Exact Problem Identified
Your console shows: 
```
The required app scheme "msauth.-task.mobile.-task-mobile" is not registered in the app's info.plist file.
```

## 📋 Solution: Add URL Scheme to Info.plist

### Method 1: Using Xcode Visual Editor (Recommended)

1. **Open your Xcode project**
2. **Select your project** in the navigator (top-level "1task-mobile" project)
3. **Select your app target** "1task-mobile" (under TARGETS)
4. **Click the "Info" tab** at the top
5. **Find "URL Types" section** and click the **triangle** to expand it
6. **Click the "+" button** to add a new URL Type
7. **Fill in the fields**:
   - **Identifier**: `com.onetaskassistant.msal`
   - **URL Schemes**: `msauth.-task.mobile.-task-mobile`
   - **Role**: `Editor`

### Method 2: Edit Info.plist as Source Code

1. **Find Info.plist** in your project navigator
2. **Right-click on Info.plist** → **Open As** → **Source Code**
3. **Find the main `<dict>` tag** (should be near the top)
4. **Add this XML** anywhere inside the main `<dict>` (before the closing `</dict>`):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.onetaskassistant.msal</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>msauth.-task.mobile.-task-mobile</string>
        </array>
    </dict>
</array>
```

## 🚀 After Making the Change:

1. **Save the file** (⌘S)
2. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
3. **Build and Run** the app
4. **Check console** - you should see: `✅ MSAL application context created successfully with basic config`
5. **Test Microsoft sign-in** - it should now open a web view for real authentication!

## 🎯 Expected Result:

After adding the URL scheme, your console should show:
```
🔧 Setting up MSAL with minimal configuration...
   Client ID: '24243302-91ba-46a3-bbe2-f946278e5a33'
   Client ID length: 36
   Client ID is valid GUID: true
🔧 Created MSAL config object
✅ MSAL application context created successfully with basic config
```

And Microsoft sign-in should work with a real authentication web view!
