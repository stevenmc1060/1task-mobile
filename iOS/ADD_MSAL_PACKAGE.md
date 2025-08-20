# Adding MSAL Package to Xcode Project

## 🚨 Current Status
The app is using a **mock MSAL implementation** so it can build and run. Follow these steps to add the real MSAL package.

## 📱 Step-by-Step Instructions

### Step 1: Add MSAL Package in Xcode

1. **Open your Xcode project**
   - `/Users/stevemcpherson/1TaskAssistant Root/1task-mobile/iOS/1task-mobile/1task-mobile.xcodeproj`

2. **Add Package Dependencies**
   - Go to **File** → **Add Package Dependencies...**
   - Or click **+** in the Project Navigator under "Package Dependencies"

3. **Enter MSAL Package URL**
   ```
   https://github.com/AzureAD/microsoft-authentication-library-for-objc
   ```

4. **Configure Package**
   - **Dependency Rule**: "Up to Next Major Version" 
   - **Version**: Latest (should be 1.2.x or higher)
   - Click **Add Package**

5. **Add to Target**
   - Select **MSAL** 
   - Choose your app target: **1task-mobile**
   - Click **Add Package**

### Step 2: Verify Package Installation

1. **Check Package Dependencies**
   - In Project Navigator, expand "Package Dependencies"
   - You should see "microsoft-authentication-library-for-objc"

2. **Build Test**
   - Press **⌘+B** to build
   - Should build successfully (still using mock implementation)

### Step 3: Replace Mock Implementation (After Package Added)

Once MSAL package is added, update `MSALAuthenticationService.swift`:

```swift
// Replace this:
import Foundation

// With this:
import Foundation
import MSAL

// Then remove the mock structs:
// Delete: struct MSALAccount { ... }
// Delete: struct MSALAccountId { ... }
```

### Step 4: Test Build Again

- Press **⌘+B** to build
- Should now use real MSAL types
- App ready for real Microsoft authentication

## 🔧 Alternative: Manual Installation

If package manager doesn't work:

1. **Download MSAL Framework**
   - Go to: https://github.com/AzureAD/microsoft-authentication-library-for-objc/releases
   - Download latest `MSAL.framework`

2. **Add to Project**
   - Drag `MSAL.framework` to your Xcode project
   - Choose "Copy items if needed"
   - Add to your app target

3. **Configure Framework**
   - Project Settings → General → Frameworks, Libraries, and Embedded Content
   - Ensure MSAL.framework is "Embed & Sign"

## 🧪 Current Functionality

**With Mock MSAL (Current State):**
- ✅ App builds and runs
- ✅ "Sign in with Microsoft" button works
- ✅ Shows loading states and mock authentication
- ✅ UI flows work perfectly
- ❌ No real authentication (uses mock user)

**After Adding Real MSAL:**
- ✅ Everything above PLUS
- ✅ Real Microsoft authentication
- ✅ Organization credential support
- ✅ Token management
- ✅ Cross-platform user consistency

## 🎯 Quick Test

1. **Build and run** current app
2. **Tap "Sign in with Microsoft"**
3. **Should show loading** for 2 seconds
4. **Mock user signed in** → "Mock User" appears
5. **Data loads** → Sample data shown
6. **Ready for real MSAL** when package added

## 📞 Need Help?

If you encounter issues:

1. **Clean Build Folder**: Product → Clean Build Folder
2. **Restart Xcode**: Close and reopen Xcode
3. **Check iOS Version**: Ensure deployment target is iOS 14.0+
4. **Check Xcode Version**: Ensure Xcode 14.0+

The app is fully functional with mock authentication and ready for real MSAL integration! 🚀
