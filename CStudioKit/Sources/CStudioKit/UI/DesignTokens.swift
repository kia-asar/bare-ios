//
//  DesignTokens.swift
//  CStudioKit
//
//  Design system tokens for consistent UI across the app
//

import SwiftUI

/// Centralized design tokens for colors, spacing, and other UI constants
///
/// Use these tokens instead of hardcoded values to ensure consistency
/// and make it easy to update the design system across the entire app.
public enum DesignTokens {
    // MARK: - Colors

    /// Color palette for the app
    public enum Colors {
        /// Background overlays
        public static let backgroundOverlay = Color.black.opacity(0.3)

        /// Surface backgrounds
        public static let surfaceLight = Color.gray.opacity(0.1)
        public static let surfaceMedium = Color.gray.opacity(0.2)

        /// Borders and dividers
        public static let borderLight = Color.gray.opacity(0.2)
        public static let borderError = Color.red.opacity(0.5)

        /// Button and interactive elements
        public static let interactiveOverlay = Color.white.opacity(0.2)
        public static let primaryGradientStart = Color.blue.opacity(0.7)

        /// Shadows
        public static let shadowLight = Color.black.opacity(0.15)
        public static let shadowBlue = Color.blue.opacity(0.3)
        
        /// Todo/Checklist colors
        public static let checkboxUnchecked = Color.gray.opacity(0.4)
        public static let checkboxChecked = Color.orange
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let textStrikethrough = Color.gray.opacity(0.5)
        public static let listBackground = Color(UIColor.systemBackground)
        public static let listRowBackground = Color(UIColor.secondarySystemBackground)
    }

    // MARK: - Spacing

    /// Standard spacing values for padding, margins, and gaps
    public enum Spacing {
        /// Extra small spacing (8pt)
        public static let xs: CGFloat = 8

        /// Small spacing (12pt)
        public static let sm: CGFloat = 12

        /// Medium spacing (16pt)
        public static let md: CGFloat = 16

        /// Large spacing (20pt)
        public static let lg: CGFloat = 20

        /// Extra large spacing (24pt)
        public static let xl: CGFloat = 24

        /// Extra extra large spacing (32pt)
        public static let xxl: CGFloat = 32

        /// Huge spacing (40pt)
        public static let xxxl: CGFloat = 40
    }

    // MARK: - Corner Radius

    /// Standard corner radius values
    public enum CornerRadius {
        /// Small corner radius (8pt)
        public static let sm: CGFloat = 8

        /// Medium corner radius (12pt)
        public static let md: CGFloat = 12

        /// Large corner radius (16pt)
        public static let lg: CGFloat = 16

        /// Extra large corner radius (20pt)
        public static let xl: CGFloat = 20
    }

    // MARK: - Shadows

    /// Standard shadow configurations
    public enum Shadow {
        /// Light shadow for subtle elevation
        public static func light(radius: CGFloat = 12, x: CGFloat = 0, y: CGFloat = 4) -> ViewModifier {
            ShadowModifier(color: Colors.shadowLight, radius: radius, x: x, y: y)
        }

        /// Medium shadow for cards and modals
        public static func medium(radius: CGFloat = 20, x: CGFloat = 0, y: CGFloat = 8) -> ViewModifier {
            ShadowModifier(color: Colors.shadowBlue, radius: radius, x: x, y: y)
        }
    }
}

// MARK: - Helper Modifiers

/// Shadow modifier for applying consistent shadows
private struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Apply standard light shadow
    public func designShadowLight() -> some View {
        self.shadow(color: DesignTokens.Colors.shadowLight, radius: 12, x: 0, y: 4)
    }

    /// Apply standard medium shadow with blue tint
    public func designShadowMedium() -> some View {
        self.shadow(color: DesignTokens.Colors.shadowBlue, radius: 20, x: 0, y: 8)
    }
}
