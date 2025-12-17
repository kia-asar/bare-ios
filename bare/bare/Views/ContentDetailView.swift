//
//  ContentDetailView.swift
//  bare
//
//  Created by Kiarash Asar on 11/3/25.
//

import SwiftUI
import NukeUI
import BareKit

/// Detail view showing full content item information
struct ContentDetailView: View {
    let item: ContentItem
    @Environment(\.openURL) private var openURLAction
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // Image at top
                    imageSection
                    
                    // Main content body
                    VStack(spacing: 20) {
                        // Metrics bar
                        if let metrics = item.engagementMetrics, !metrics.isEmpty {
                            metricsBarSection
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                        }

                        // Author section
                        if let authorHandle = item.authorHandle {
                            authorSection(handle: authorHandle)
                                .padding(.horizontal, 16)
                        }

                        // Expandable sections
                        expandableSections

                        // Add spacing for the floating button
                        Spacer(minLength: 100)
                    }
                }
            }
            
            // Floating Ask Button
            FloatingAskButton {
                handleAskButtonTapped()
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleAskButtonTapped() {
        // TODO: Implement AI chat interaction
        print("Ask button tapped for item: \(item.title)")
    }

    private func openOriginalURL() {
        guard let url = item.originalURL else { return }
        openURLAction(url)
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        Group {
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                LazyImage(source: url)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            } else {
                placeholderImage
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openOriginalURL()
        }
    }
    
    private var placeholderImage: some View {
        Image(systemName: item.thumbnailName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .foregroundStyle(.white)
            .background(
                Color.gray.gradient
            )
    }
    
    // MARK: - Metrics Bar Section

    private var metricsBarSection: some View {
        HStack(spacing: 16) {
            // Engagement metrics
            if let metrics = item.engagementMetrics {
                ForEach(metrics) { metric in
                    HStack(spacing: 4) {
                        Image(systemName: metric.iconName)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Text(metric.count)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(metric.count) \(metric.iconName)")
                }
            }

            Spacer()

            // Viral status badge
            if let status = item.viralStatus {
                Text(status)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black)
                    )
            }
        }
    }
    
    // MARK: - Author Section

    private func authorSection(handle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Author")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)

                Text(handle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(.leading, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Expandable Sections

    private var expandableSections: some View {
        VStack(spacing: 0) {
            // Summary
            if let summary = item.summary {
                ExpandableSection(
                    icon: "list.bullet",
                    title: "Summary",
                    content: summary
                )
                Divider()
            }

            // Research Answer
            if let answer = item.userResearchAnswer {
                ExpandableSection(
                    icon: "lightbulb",
                    title: "Research Answer",
                    content: answer
                )
                Divider()
            }

            // Transcript
            if let transcript = item.audioTranscription {
                ExpandableSection(
                    icon: "headphones",
                    title: "Audio Transcript",
                    content: transcript
                )
                Divider()
            }

            // Visual transcription
            if let visual = item.visualTranscription {
                ExpandableSection(
                    icon: "eye",
                    title: "Visual Transcript",
                    content: visual
                )
                Divider()
            }

            // Comments Analysis
            if let comments = item.commentsAnalysis {
                ExpandableSection(
                    icon: "bubble.left",
                    title: "Comments",
                    content: comments
                )
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

#Preview {
    NavigationStack {
        ContentDetailView(item: ContentItem.sampleData[0])
    }
}
