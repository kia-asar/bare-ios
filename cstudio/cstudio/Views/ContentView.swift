//
//  ContentView.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/3/25.
//

import SwiftUI
import CStudioKit
import OSLog

struct ContentView: View {
    @State private var authManager: AuthManager?
    @State private var isInitializing = true

    var body: some View {
        Group {
            if isInitializing {
                ProgressView("Loading...")
            } else if let authManager {
                if authManager.isAuthenticated {
                    ContentGridView()
                } else {
                    SignInView()
                }
            }
        }
        .task {
            await initialize()
        }
    }

    private func initialize() async {
        do {
            authManager = try await DependencyContainer.shared.getAuthManager()
        } catch {
            AppLogger.app.error("Failed to initialize auth manager: \(error)")
        }
        isInitializing = false
    }
}

#Preview {
    ContentView()
}
