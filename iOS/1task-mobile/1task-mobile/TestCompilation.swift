import SwiftUI

// Minimal test app to verify basic compilation
// @main - commented out to avoid duplicate main attribute error
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello World")
        }
    }
}

// Test if basic SwiftUI compiles
struct TestView: View {
    var body: some View {
        VStack {
            Text("Testing basic SwiftUI compilation")
            Button("Test Button") {
                print("Button tapped")
            }
        }
    }
}

#Preview {
    TestView()
}
