# iOS Build Error Troubleshooting Guide

## Error: "Command SwiftCompile failed with a nonzero exit code"

This generic error can have several causes. Let's systematically troubleshoot:

## 🔧 Step-by-Step Troubleshooting

### 1. Clean and Rebuild
```
1. In Xcode: Product → Clean Build Folder (⇧⌘K)
2. Wait for completion
3. Product → Build (⌘B)
```

### 2. Check Build Log Details
```
1. In Xcode, open the Navigator panel
2. Click the "Report" tab (looks like a speech bubble)
3. Find the latest build attempt
4. Expand the SwiftCompile error to see specific details
5. Look for the actual error message (not just "nonzero exit code")
```

### 3. Common iOS Swift Compilation Issues

#### Missing Dependencies/Imports
- Make sure all Swift files have correct import statements
- Verify all referenced modules are available

#### Package Manager Issues
- File → Packages → Reset Package Caches
- File → Packages → Update to Latest Package Versions

#### Target Configuration Issues
- Check that all Swift files are added to the correct target
- Verify deployment target is compatible (iOS 14.0+ recommended)

#### Syntax/Type Errors
- Look for any red error indicators in Xcode
- Check for missing @Published, @StateObject, @ObservedObject annotations

### 4. iOS-Specific Checks

#### Info.plist Issues
- Verify Info.plist has required keys
- Check bundle identifier is valid

#### Signing Issues
- Verify code signing settings
- Check provisioning profiles

#### Architecture Issues
- Check if building for correct architecture (arm64 for devices, x86_64 for simulator)

### 5. Project-Specific Checks

#### MSAL Package Issues
Since we're using mock MSAL, ensure:
- No remaining `import MSAL` statements in any files
- All MSAL types are properly mocked
- No reference to real MSAL classes

#### SwiftUI Issues
- Check all @State, @Published, @ObservedObject are correctly used
- Verify all View protocol conformance
- Check binding syntax ($variable) is correct

## 🚀 Quick Fixes to Try

### Option 1: Reset Everything
```
1. Close Xcode
2. Delete derived data: ~/Library/Developer/Xcode/DerivedData/
3. Open Xcode
4. Clean Build Folder
5. Build again
```

### Option 2: Simplify to Test
```
1. Comment out complex views temporarily
2. Start with a simple "Hello World" app
3. Add components back one by one to identify the problematic file
```

### Option 3: Check Minimum Requirements
```
1. iOS Deployment Target: 14.0 or higher
2. Xcode Version: Recent version
3. Swift Version: 5.0+
```

## 📋 Debugging Steps

1. **Get Specific Error**: Look at the build log for the actual Swift compiler error
2. **Isolate the Problem**: Try building individual files or comment out sections
3. **Check Dependencies**: Ensure all packages and frameworks are properly linked
4. **Verify Syntax**: Look for any SwiftUI or Swift syntax issues

## 💡 Common Solutions

- **Missing @Published**: Add @Published to properties that need to trigger UI updates
- **Incorrect Binding**: Use $ syntax correctly for two-way bindings
- **Type Mismatches**: Ensure all types match between models and views
- **Missing Conformance**: Make sure all structs conform to required protocols (Codable, etc.)

## 🆘 If All Else Fails

Try creating a minimal test project with just:
1. Basic SwiftUI App structure
2. Simple ContentView
3. One model class
4. Build and run to verify Xcode setup

Let me know the specific error details from the build log and I can provide more targeted help!
