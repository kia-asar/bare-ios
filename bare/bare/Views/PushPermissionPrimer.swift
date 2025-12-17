//
//  PushPermissionPrimer.swift
//  bare
//
//  Pre-prompt UI for push notification permissions
//  Follows iOS best practices: educate users about value before system prompt
//

import SwiftUI
import BareKit

/// Pre-prompt view that educates users about push notifications before showing system dialog
///
/// Best Practices Implemented:
/// - Value-focused messaging (explains benefit to user)
/// - Non-blocking UI (dismissible)
/// - Transparent about what notifications will contain
/// - Tracks user response for analytics
/// - Settings deep link for previously denied permissions
struct PushPermissionPrimer: View {
    let status: PushPermissionStatus
    let onAllow: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.surfaceLight)
                    .frame(width: 80, height: 80)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.primaryGradientStart,
                                .blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title & Message
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(status == .denied ? "Enable Notifications" : "Stay Updated")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(status == .denied
                    ? "You've disabled notifications. Enable them in Settings to stay updated on interactions with your posts"
                    : "Get notified when people comment on or interact with your posts")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Actions
            VStack(spacing: DesignTokens.Spacing.md) {
                Button {
                    onAllow()
                } label: {
                    Text(status == .denied ? "Open Settings" : "Enable Notifications")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button {
                    onDismiss()
                } label: {
                    Text("Not Now")
                        .fontWeight(.medium)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .fill(.regularMaterial)
                .shadow(
                    color: DesignTokens.Colors.shadowLight,
                    radius: 20,
                    y: 10
                )
        )
        .padding(DesignTokens.Spacing.xl)
    }
}

#Preview("First Time") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        PushPermissionPrimer(
            status: .notDetermined,
            onAllow: { print("Allow tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
    }
}

#Preview("Previously Denied") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        PushPermissionPrimer(
            status: .denied,
            onAllow: { print("Open Settings tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
    }
}
