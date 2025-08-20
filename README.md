# 1TaskAssistant Mobile

## Overview
Native iOS application for 1TaskAssistant - an intelligent task management system that helps users organize tasks, habits, goals, and projects.

## Features
- **Microsoft Authentication** - Secure OAuth 2.0 login with Azure AD
- **Task Management** - Create, track, and complete tasks with priorities and due dates
- **Habit Tracking** - Build and maintain daily, weekly, and custom habits
- **Goal Setting** - Set and track yearly, quarterly, and weekly goals
- **Project Organization** - Manage complex projects with multiple tasks
- **Real-time Sync** - Seamlessly sync data with Azure backend services

## Architecture
- **SwiftUI** - Modern declarative UI framework
- **MSAL** - Microsoft Authentication Library for iOS
- **Combine** - Reactive programming for data flow
- **REST API** - Integration with Azure Functions backend

## Backend Integration
- **API Base URL**: https://1task-backend-api-gse0fsgngtfxhjc6.southcentralus-01.azurewebsites.net/api
- **Authentication**: Microsoft Azure AD OAuth 2.0
- **Data Models**: Tasks, Habits, Goals, Projects with full CRUD operations

## Requirements
- iOS 18.5+
- Xcode 16+
- Swift 5.9+

## Setup
1. Clone the repository
2. Open `1task-mobile.xcodeproj` in Xcode
3. Configure Microsoft Authentication (MSAL) settings in `MSALAuthenticationService.swift`
4. Build and run on iOS Simulator or device

## Current Status
✅ Core UI components and navigation
✅ Microsoft authentication integration
✅ Backend API integration
✅ Task, habit, goal, and project CRUD operations
✅ Data synchronization with Azure backend
🔧 Testing and debugging authentication flow
🔧 Performance optimization and error handling

## Development Notes
- Uses Microsoft user ID: `2da56370-78bc-4278-9ed3-c693615ba407`
- Supports both authenticated and demo modes
- Comprehensive logging for debugging authentication and API calls

Last Updated: August 20, 2025
