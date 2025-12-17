//
//  ExpandableSection.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/12/25.
//

import SwiftUI

/// Expandable section component with icon, title, and collapsible content
struct ExpandableSection: View {
    let icon: String
    let title: String
    let content: String
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Leading icon
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.primary)
                        .frame(width: 24, height: 24)

                    // Title
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Trailing chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityHint("Double tap to expand")

            // Expanded content
            if isExpanded {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    VStack(spacing: 0) {
        ExpandableSection(
            icon: "list.bullet",
            title: "Summary",
            content: "This is a sample summary content that can be expanded and collapsed."
        )
        
        ExpandableSection(
            icon: "headphones",
            title: "Transcript",
            content: "This is a sample transcript content."
        )
    }
    .padding()
}
