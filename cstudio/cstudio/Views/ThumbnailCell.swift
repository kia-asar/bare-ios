//
//  ThumbnailCell.swift
//  cstudio
//
//  Created by Kiarash Asar on 11/3/25.
//

import SwiftUI
import NukeUI
import CStudioKit

/// Individual thumbnail cell for the grid with cached image loading
struct ThumbnailCell: View {
    let item: ContentItem

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let imageUrlString = item.imageUrl,
                   let imageUrl = URL(string: imageUrlString) {
                    // Load image from URL with automatic caching
                    LazyImage(source: imageUrl)
                } else {
                    // Use system symbol as fallback
                    fallbackIcon
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.gray.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle()) // Ensures entire cell is tappable
        }
        .aspectRatio(9.0/16.0, contentMode: .fit)
    }

    /// Fallback icon when no URL is provided
    private var fallbackIcon: some View {
        Image(systemName: item.thumbnailName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.white)
            .padding(DesignTokens.Spacing.lg)
    }
}

#Preview {
    ThumbnailCell(item: ContentItem.sampleData[0])
        .frame(width: 120, height: 120)
}
