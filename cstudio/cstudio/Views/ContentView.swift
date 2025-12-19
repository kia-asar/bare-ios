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
    @State private var selectedTab: AppTab = .studio

    var body: some View {
        Group {
            if isInitializing {
                ProgressView("Loading...")
            } else if let authManager {
                if authManager.isAuthenticated {
                    mainTabView
                } else {
                    SignInView()
                }
            }
        }
        .task {
            await initialize()
        }
    }
    
    /// Main tab view with Studio and Checklist tabs
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            ContentGridView()
                .tag(AppTab.studio)
                .tabItem {
                    Label("Studio", systemImage: "square.grid.2x2")
                }
            
            TodoListView()
                .tag(AppTab.checklist)
                .tabItem {
                    Label("Checklist", systemImage: "checklist")
                }
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

/// App tab enumeration
enum AppTab: Hashable {
    case studio
    case checklist
}

#Preview {
    ContentView()
}
