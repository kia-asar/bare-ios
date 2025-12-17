//
//  KillSwitchViews.swift
//  cstudio
//
//  Kill switch UI components
//

import SwiftUI
import CStudioKit

// MARK: - Soft Kill Switch Alert

struct SoftKillSwitchAlert: ViewModifier {
    let message: String
    @State private var isPresented = true

    func body(content: Content) -> some View {
        content
            .alert("Update Available", isPresented: $isPresented) {
                Button("Update") {
                    UIApplication.shared.open(AppConstants.appStoreURL)
                }
                Button("Later", role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func softKillSwitchAlert(message: String) -> some View {
        modifier(SoftKillSwitchAlert(message: message))
    }
}

// MARK: - Hard Kill Switch View

struct HardKillSwitchView: View {
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Update Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                UIApplication.shared.open(AppConstants.appStoreURL)
            } label: {
                Text("Update Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Emergency Kill Switch View

struct EmergencyKillSwitchView: View {
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Service Unavailable")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Please try again later")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Maintenance View

struct MaintenanceView: View {
    let message: String
    let endTime: Date?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Maintenance")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let endTime = endTime {
                VStack(spacing: 8) {
                    Text("Expected to be back:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(endTime, style: .time)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(endTime, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Soft Kill Switch") {
    Text("Main Content")
        .softKillSwitchAlert(message: "A new version of CStudio is available. Please update for the best experience.")
}

#Preview("Hard Kill Switch") {
    HardKillSwitchView(message: "This version of CStudio is no longer supported. Please update to continue using the app.")
}

#Preview("Emergency Kill Switch") {
    EmergencyKillSwitchView(message: "We're experiencing technical difficulties. Please try again later.")
}

#Preview("Maintenance") {
    MaintenanceView(
        message: "Scheduled maintenance in progress. Back at 3pm EST.",
        endTime: Date().addingTimeInterval(3600)
    )
}
