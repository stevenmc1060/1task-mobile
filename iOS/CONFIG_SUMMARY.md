# iOS App Configuration Summary

## Azure AD Configuration (Updated from Web Frontend)
```
Client ID: 24243302-91ba-46a3-bbe2-f946278e5a33
Tenant ID: 25dcc072-a2bf-4e88-876a-b63e6e0d0c3e
Authority: https://login.microsoftonline.com/25dcc072-a2bf-4e88-876a-b63e6e0d0c3e
```

## API Endpoints
```
Backend API: https://1task-backend-api-gse0fsgngtfxhjc6.southcentralus-01.azurewebsites.net/api
Chat API: https://1task-api-mvp-ejfqasajcmcddsha.southcentralus-01.azurewebsites.net/api
```

## iOS Redirect URI (to add in Azure AD)
```
msauth.com.yourcompany.onetaskassistant://auth
```

## Info.plist URL Scheme
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

## File Locations
- MSALAuthenticationService: `1task-mobile/iOS/1task-mobile/1task-mobile/MSALAuthenticationService.swift`
- AppConfiguration: `1task-mobile/iOS/1task-mobile/1task-mobile/AppConfiguration.swift`
- Setup Guides: `1task-mobile/iOS/FINAL_SETUP_GUIDE.md`

## Status: ✅ Configuration Complete
The iOS app is now configured with the correct Azure AD settings from your web frontend and is ready for MSAL package installation and testing.
