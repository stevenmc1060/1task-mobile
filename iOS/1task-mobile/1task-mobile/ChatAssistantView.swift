//
//  ChatAssistantView.swift
//  1task-mobile
//
//  Created by Steve McPherson on 8/20/25.
//

import SwiftUI
import Combine

struct ChatAssistantView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var messageText: String = ""
    @State private var messages: [DisplayChatMessage] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Assistant is thinking...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if isLoading {
                                proxy.scrollTo("loading", anchor: .bottom)
                            } else if let lastMessage = messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isLoading) { oldValue, newValue in
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Message input
                HStack {
                    TextField("Ask me anything about your tasks...", text: $messageText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty || isLoading ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if messages.isEmpty {
                    addWelcomeMessage()
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = DisplayChatMessage(
            id: UUID().uuidString,
            content: "Hi! I'm your AI assistant. I can help you with:\n\n• Creating and managing tasks\n• Setting up habits and goals\n• Organizing projects\n• Answering questions about your productivity\n\nWhat would you like to know?",
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = DisplayChatMessage(
            id: UUID().uuidString,
            content: messageText,
            isFromUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        let currentMessage = messageText
        messageText = ""
        isLoading = true
        
        // Send to chat API
        appState.apiService.sendChatMessage(currentMessage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    switch completion {
                    case .failure(let error):
                        errorMessage = "Failed to get response: \(error.localizedDescription)"
                        showingError = true
                    case .finished:
                        break
                    }
                },
                receiveValue: { chatResponse in
                    let assistantMessage = DisplayChatMessage(
                        id: UUID().uuidString,
                        content: chatResponse.response,
                        isFromUser: false,
                        timestamp: Date()
                    )
                    messages.append(assistantMessage)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Display Models
struct DisplayChatMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Chat Message View
struct ChatMessageView: View {
    let message: DisplayChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "brain")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                        
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray5))
                            .cornerRadius(18)
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 38)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Extension to add corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatAssistantView()
        .environmentObject(AppState())
}
