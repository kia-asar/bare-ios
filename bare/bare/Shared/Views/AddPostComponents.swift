//
//  AddPostComponents.swift
//  bare
//
//  Reusable UI components for AddPostView
//

import SwiftUI
import BareKit

// MARK: - URL Input Field

struct URLInputField: View {
    @Binding var urlText: String
    @Binding var validationError: String?
    let isLoading: Bool
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // URL TextField with inline button
            HStack(spacing: DesignTokens.Spacing.xs) {
                TextField("Enter URL", text: $urlText)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .onSubmit(onSubmit)

                // Inline submit button
                Button(action: onSubmit) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 36, height: 36)
                .background(urlText.isEmpty || isLoading ? Color.gray : Color.accentColor)
                .clipShape(Circle())
                .disabled(urlText.isEmpty || isLoading)
            }
            .padding(DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.surfaceLight)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .strokeBorder(
                        validationError != nil ? DesignTokens.Colors.borderError : DesignTokens.Colors.borderLight,
                        lineWidth: 1
                    )
            }

            // Error message
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Link Preview Card

struct LinkPreviewCard: View {
    let preview: LinkPreview

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Link Preview")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let siteName = preview.siteName {
                        Text(siteName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.lg)

            Divider()
                .padding(.horizontal, DesignTokens.Spacing.lg)

            // Preview Content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Thumbnail
                if let imageURL = preview.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(DesignTokens.Colors.surfaceMedium)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(DesignTokens.Colors.surfaceMedium)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                        .font(.title)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }

                // Title
                Text(preview.displayTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                // Description
                if let description = preview.displayDescription {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                }

                // URL
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(preview.url.host ?? preview.url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xs)
            }
        }
    }
}

// MARK: - Analysis Text Field

struct AnalysisTextField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isFocused)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.surfaceLight)
                .cornerRadius(DesignTokens.CornerRadius.md)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .strokeBorder(DesignTokens.Colors.borderLight, lineWidth: 1)
                }
                .scrollContentBackground(.hidden)

            // Placeholder text
            if text.isEmpty {
                Text("What would you like to analyze about this post?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Action Buttons

struct ActionButtons: View {
    let isSaving: Bool
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surfaceMedium)
                    .cornerRadius(DesignTokens.CornerRadius.md)
            }
            .disabled(isSaving)

            // Save button
            Button(action: onSave) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                } else {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                }
            }
            .background((isSaving || !canSave) ? Color.gray : Color.accentColor)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .disabled(isSaving || !canSave)
        }
    }
}

// MARK: - Placeholder View

struct PreviewPlaceholder: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "link.circle")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Enter a URL")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Paste or type a URL above to load its preview")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xxxl)
    }
}

// MARK: - Loading View

struct PreviewLoadingView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.accentColor)

            Text("Loading preview...")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(DesignTokens.Spacing.xxxl)
    }
}

// MARK: - Error View

struct PreviewErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Unable to Load Preview")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(DesignTokens.Spacing.xxl)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
                .font(.title3)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                .fill(.red.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                        .strokeBorder(.red.opacity(0.3), lineWidth: 1)
                }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
}
