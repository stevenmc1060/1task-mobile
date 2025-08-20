# Complete MSAL Info.plist Configuration

## ✅ Progress: URL Scheme Added Successfully!
The error changed from URL scheme to query schemes - this means the first fix worked!

## 🔧 Next Step: Add Query Schemes

### Error Message:
```
The required query schemes "msauthv2" and "msauthv3" are not registered in the app's info.plist file. Please add "msauthv2" and "msauthv3" into Info.plist under LSApplicationQueriesSchemes
```

## 📋 Complete Info.plist Configuration Needed:

Your Info.plist needs both:
1. ✅ **CFBundleURLTypes** (URL Schemes) - Already added!
2. ❌ **LSApplicationQueriesSchemes** (Query Schemes) - Need to add

### Method 1: Xcode Visual Editor

1. **Select project** → **1task-mobile target** → **Info tab**
2. **Right-click** in the property list → **Add Row**
3. **Type**: `LSApplicationQueriesSchemes`
4. **Set type**: Array
5. **Add two string items**:
   - Item 0: `msauthv2`
   - Item 1: `msauthv3`

### Method 2: Source Code

Add this to your Info.plist inside the main `<dict>`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>msauthv2</string>
    <string>msauthv3</string>
</array>
```

## 🎯 Complete Info.plist Should Have:

```xml
<!-- URL Types (already added) -->
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

<!-- Query Schemes (need to add) -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>msauthv2</string>
    <string>msauthv3</string>
</array>
```

## 🚀 After Adding Query Schemes:

1. **Save** (⌘S)
2. **Clean Build Folder** (⇧⌘K)
3. **Build and Run**
4. **Check console** - should see: `✅ MSAL application context created successfully`
5. **Microsoft sign-in should work!**
