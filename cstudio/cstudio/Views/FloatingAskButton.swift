//
//  FloatingAskButton.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/5/25.
//

import SwiftUI
import CStudioKit

/// Floating button with glassmorphism effect for initiating AI conversation
struct FloatingAskButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Ask anything about this post")
                    .font(.system(size: 15, weight: .semibold))
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Glass effect background with vertical glow from bottom
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DesignTokens.Colors.primaryGradientStart,
                                            Color.purple.opacity(0.5),
                                            Color.purple.opacity(0.2),
                                            Color.clear
                                        ],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    DesignTokens.Colors.interactiveOverlay,
                                    lineWidth: 1
                                )
                        )
                }
            )
            .shadow(color: DesignTokens.Colors.shadowLight, radius: 12, x: 0, y: 4)
            .shadow(color: DesignTokens.Colors.shadowBlue, radius: 20, x: 0, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.surfaceLight
            .ignoresSafeArea()

        VStack {
            Spacer()
            FloatingAskButton {
                print("Ask button tapped")
            }
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
    }
}
