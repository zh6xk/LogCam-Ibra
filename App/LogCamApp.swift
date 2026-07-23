import SwiftUI

@main
struct LogCamApp: App {
    init() {
        NSSetUncaughtExceptionHandler { exception in
            UserDefaults.standard.set(exception.reason ?? "Unknown", forKey: "crash_reason")
            UserDefaults.standard.synchronize()
        }
    }

    var body: some Scene {
        WindowGroup {
            if let crash = UserDefaults.standard.string(forKey: "crash_reason") {
                VStack {
                    Text("App Crashed Sebelumnya:")
                        .foregroundColor(.red)
                        .font(.headline)
                    Text(crash)
                        .padding()
                    Button("Reset") {
                        UserDefaults.standard.removeObject(forKey: "crash_reason")
                    }
                }
            } else {
                ContentView()
            }
        }
    }
}
