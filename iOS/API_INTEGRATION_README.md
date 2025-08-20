# 1TaskAssistant iOS App - API Integration

This document explains how to set up and use the API service in the 1TaskAssistant iOS app to connect to the backend Azure Functions.

## Architecture Overview

The iOS app now includes:

- **APIService.swift**: RESTful API client for connecting to Azure Functions backend
- **AppConfiguration.swift**: Centralized configuration for API endpoints and settings
- **Updated AppState**: Manages local data with backend synchronization
- **Backend Models**: Full Swift models matching the Python backend models

## API Endpoints Supported

The app connects to these backend endpoints:

### Tasks
- `GET /tasks` - Get user's tasks
- `POST /tasks` - Create new task
- `PUT /tasks/{id}` - Update existing task
- `DELETE /tasks/{id}` - Delete task

### Habits
- `GET /habits` - Get user's habits
- `POST /habits` - Create new habit
- `PUT /habits/{id}` - Update existing habit
- `DELETE /habits/{id}` - Delete habit

### Goals (Yearly)
- `GET /yearly-goals` - Get user's yearly goals
- `POST /yearly-goals` - Create new goal
- `PUT /yearly-goals/{id}` - Update existing goal
- `DELETE /yearly-goals/{id}` - Delete goal

### Projects
- `GET /projects` - Get user's projects
- `POST /projects` - Create new project
- `PUT /projects/{id}` - Update existing project
- `DELETE /projects/{id}` - Delete project

## Configuration

### Local Development

1. Start your Azure Functions backend locally:
   ```bash
   cd 1task-backend
   func start
   ```

2. The app is configured to use `http://localhost:7071/api` by default in DEBUG mode.

3. Make sure your backend is running on port 7071 (default for Azure Functions).

### Production Deployment

1. Deploy your Azure Functions to Azure.

2. Update `AppConfiguration.swift`:
   ```swift
   static let productionBaseURL = "https://your-function-app.azurewebsites.net/api"
   ```

3. Build the app in Release mode to use production URLs.

## Usage

### Demo Mode vs Real Backend

The app supports two modes:

#### Demo Mode (Default)
- Uses local sample data
- No network requests
- Perfect for testing UI without backend

#### Backend Mode
- Connects to real Azure Functions API
- Syncs data in real-time
- Handles offline gracefully

### Data Sync Behavior

1. **App Launch**: Attempts to sync data from backend
2. **Login**: Syncs user's data after successful login
3. **CRUD Operations**: Immediately sync changes to backend
4. **Fallback**: Uses demo data if backend is unavailable

### Error Handling

The app includes comprehensive error handling:

- Network connectivity issues
- API response errors
- Data parsing errors
- Timeout handling

## Development Setup

### Prerequisites

- Xcode 15+
- iOS 17+ deployment target
- Azure Functions backend running

### Running the App

1. **With Local Backend**:
   - Start the Azure Functions locally
   - Build and run the iOS app in Debug mode
   - The app will automatically connect to `localhost:7071`

2. **Demo Mode Only**:
   - Build and run without starting the backend
   - App will fall back to demo data automatically

3. **Production Mode**:
   - Update production URL in `AppConfiguration.swift`
   - Build in Release mode

## API Service Usage Examples

### Creating a New Task
```swift
let newTask = Task(
    id: UUID().uuidString,
    title: "My New Task",
    description: "Task description",
    status: .pending,
    priority: .high,
    dueDate: Date(),
    userId: appState.userId,
    createdAt: Date(),
    updatedAt: Date()
)

appState.addTask(newTask)
```

### Syncing All Data
```swift
appState.syncDataFromBackend()
```

### Handling Login
```swift
appState.login(userId: "user123", userName: "John Doe")
```

## Backend Compatibility

The iOS models are designed to be compatible with the Python backend models:

- **Task** ↔ Python `Task` model
- **Habit** ↔ Python `Habit` model  
- **Goal** ↔ Python `YearlyGoal` model
- **Project** ↔ Python `Project` model

All models include the required fields for backend synchronization.

## Troubleshooting

### Common Issues

1. **Connection Failed**: Check if backend is running on correct port
2. **Data Not Syncing**: Verify API URLs in configuration
3. **Authentication Errors**: Ensure user ID is properly set
4. **Model Parsing Errors**: Check backend response format matches Swift models

### Debug Logging

Enable debug logging in `AppConfiguration.swift`:
```swift
static let enableDebugLogging = true
```

This will print API requests and responses to the Xcode console.

## Next Steps

1. **Authentication**: Integrate with Azure AD or similar for real user authentication
2. **Offline Support**: Implement local database with sync when online
3. **Push Notifications**: Add support for backend-triggered notifications
4. **Chat Integration**: Connect to the chat API endpoints
5. **Real-time Updates**: Implement WebSocket connections for live updates

## Support

For issues or questions:
- Check the Xcode console for error messages
- Verify backend is running and accessible
- Review API endpoint responses
- Test with demo data first to isolate UI vs API issues
