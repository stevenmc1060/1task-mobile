# MSAL Import Error Troubleshooting Guide

## Error: "No such module 'MSAL'"

This error occurs when the MSAL package isn't properly linked in Xcode, even though you've added it.

## 🔧 Quick Fixes to Try

### 1. Clean Build Folder
- In Xcode: **Product** → **Clean Build Folder** (⇧⌘K)
- Then build again (⌘B)

### 2. Restart Xcode
- Quit Xcode completely
- Reopen your project
- Try building again

### 3. Check Package Dependencies
1. In Xcode, select your project in the navigator
2. Go to your app target
3. Click on **Build Phases** tab
4. Expand **Link Binary With Libraries**
5. Make sure **MSAL** is listed there
6. If not, click **+** and add it

### 4. Verify Package in Package Dependencies
1. Select your project in the navigator
2. Go to **Package Dependencies** tab
3. Make sure you see `https://github.com/AzureAD/microsoft-authentication-library-for-objc` listed
4. If not, add it again with **+** button

### 5. Check Target Membership
1. Select the `MSALAuthenticationService.swift` file
2. In the File Inspector (right panel), make sure your app target is checked

### 6. Reset Package Caches
1. In Xcode: **File** → **Packages** → **Reset Package Caches**
2. Wait for it to complete
3. Try building again

### 7. Remove and Re-add Package
1. Select your project → Package Dependencies
2. Select the MSAL package and click **-** to remove it
3. Click **+** to add it back
4. Use URL: `https://github.com/AzureAD/microsoft-authentication-library-for-objc`
5. Choose latest version and add to your target

## 🚀 Alternative: Continue with Mock Authentication

If you want to continue development while fixing the MSAL issue, I can temporarily update the authentication service to use mock authentication so you can test the rest of the app.

Let me know if you'd like me to create a mock version for now!

## 📱 Verify Installation Steps

Make sure you followed these steps when adding MSAL:

1. **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/AzureAD/microsoft-authentication-library-for-objc`
3. Click **Add Package**
4. Select **MSAL** library
5. Click **Add Package**
6. Make sure it's added to your app target (not just the project)

## ⚠️ Common Issues

- **Wrong URL**: Make sure you used the correct GitHub URL
- **Target Selection**: Package must be added to your app target, not just the project
- **Xcode Cache**: Sometimes Xcode's package cache gets corrupted
- **Xcode Version**: Make sure you're using a recent version of Xcode

Try these solutions in order, and let me know which one fixes the issue!
