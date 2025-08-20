# 🔧 Azure AD Redirect URI Configuration Fix

## ✅ Success So Far
- MSAL is working correctly! ✅
- Microsoft authentication web view launches ✅  
- Info.plist configuration is correct ✅

## ❌ Current Issue: Redirect URI Mismatch

**Error:** `AADSTS50011: The redirect URI 'msauth.-task.mobile.-task-mobile://auth' does not match the redirect URIs configured for the application`

**App ID:** `24243302-91ba-46a3-bbe2-f946278e5a33`

## 🛠️ Step-by-Step Fix

### 1. Open Azure Portal
- Go to [https://portal.azure.com](https://portal.azure.com)
- Sign in with your Microsoft account

### 2. Navigate to App Registrations
- Search for "App registrations" in the top search bar
- Click on **App registrations**

### 3. Find Your App
- Look for your app with ID: `24243302-91ba-46a3-bbe2-f946278e5a33`
- Or search by the app name if you remember it
- Click on the app to open it

### 4. Configure Authentication
- In the left menu, click **Authentication**
- Look for **Platform configurations** section

### 5. Add Mobile Platform (if needed)
- If you don't see a "Mobile and desktop applications" platform:
  - Click **+ Add a platform**
  - Select **Mobile and desktop applications**
  - **Enter Bundle ID:** `com.onetaskassistant.mobile`
  - Click **Configure**

### 6. Add Redirect URI
- In the **Mobile and desktop applications** section
- Find the **Redirect URIs** text box
- Add this exact URI: `msauth.com.onetaskassistant.mobile://auth`
- Click **Save**

### 7. Verify Configuration
After saving, you should see:
- Platform: **Mobile and desktop applications** ✅
- Redirect URI: **msauth.com.onetaskassistant.mobile://auth** ✅

## � Bundle ID Fix Applied!

**NEW Valid Bundle ID:** `com.onetaskassistant.mobile`

I've updated your Xcode project to use a valid Bundle ID that Azure will accept.

**For Azure Configuration:**
- **Bundle ID:** `com.onetaskassistant.mobile`
- **Redirect URI:** `msauth.com.onetaskassistant.mobile://auth`

## �📱 Bundle ID Information

**Your iOS app's Bundle ID is:** `-task.mobile.-task-mobile`

When Azure asks for the Bundle ID during mobile platform setup:
- Enter exactly: `-task.mobile.-task-mobile`
- Don't worry about the leading hyphen - that's how it appears in your Xcode project

## 🧪 Test Again
1. Go back to your iOS app
2. Tap **Cancel** to close the current auth flow
3. Tap **Sign In** again
4. You should now be able to complete the Microsoft authentication!

## 📋 Alternative: Check Existing Redirect URIs
If you already have redirect URIs configured, make sure one of them is exactly:
```
msauth.-task.mobile.-task-mobile://auth
```

The URI format is: `msauth.<bundle-id>://auth`
Where your bundle ID appears to be: `-task.mobile.-task-mobile`

## 📋 Copy This Redirect URI

**For Azure Portal - Copy this exact URI:**

```
msauth.com.onetaskassistant.mobile://auth
```

**Bundle ID to use:**
```
com.onetaskassistant.mobile
```

## ⚠️ Common Issues
- **Case sensitivity**: Make sure the URI is exactly as shown
- **Typos**: Double-check each character
- **Missing platform**: Mobile platform must be added first
- **Save**: Don't forget to click Save after adding the URI

Once this is fixed, your iOS app should authenticate successfully with Microsoft! 🚀
