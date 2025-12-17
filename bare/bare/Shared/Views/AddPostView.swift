//
//  AddPostView.swift
//  bare
//
//  Shared view for adding posts - used by both main app and share extension
//

import SwiftUI
import UIKit
import BareKit

struct AddPostView: View {
    // MARK: - Properties

    let onSave: (Post) -> Void
    let onCancel: () -> Void

    @State private var viewModel: AddPostViewModel
    @FocusState private var isTextEditorFocused: Bool

    // MARK: - Initialization

    init(initialURL: URL? = nil, onSave: @escaping (Post) -> Void, onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel
        _viewModel = State(initialValue: AddPostViewModel(initialURL: initialURL))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                DesignTokens.Colors.backgroundOverlay
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }

                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(spacing: DesignTokens.Spacing.md) {
                            // URL input field (only shown if no initial URL)
                            if viewModel.urlText.isEmpty && viewModel.linkPreview == nil {
                                URLInputField(
                                    urlText: $viewModel.urlText,
                                    validationError: $viewModel.urlValidationError,
                                    isLoading: viewModel.isLoadingPreview,
                                    onSubmit: viewModel.validateAndLoadURL
                                )
                                .id("urlInput")
                            }

                            // Error banner
                            if let error = viewModel.errorMessage {
                                ErrorBanner(message: error, onDismiss: viewModel.clearError)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Content card
                            contentCard
                                .background {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .strokeBorder(DesignTokens.Colors.interactiveOverlay, lineWidth: 1)
                                        }
                                }
                                .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                            // Analysis text input
                            AnalysisTextField(
                                text: $viewModel.analysisText,
                                isFocused: $isTextEditorFocused
                            )
                            .id("textEditor")

                            // Action buttons
                            ActionButtons(
                                isSaving: viewModel.isSavingPost,
                                canSave: viewModel.linkPreview != nil,
                                onCancel: onCancel,
                                onSave: handleSave
                            )
                        }
                        .frame(maxWidth: 400)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.lg)
                        .frame(minHeight: geometry.size.height)
                        .onChange(of: isTextEditorFocused) { _, isFocused in
                            if isFocused {
                                withAnimation {
                                    proxy.scrollTo("textEditor", anchor: .center)
                                }
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .task {
            await viewModel.loadInitialPreview()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var contentCard: some View {
        if viewModel.isLoadingPreview {
            PreviewLoadingView()
        } else if let preview = viewModel.linkPreview {
            LinkPreviewCard(preview: preview)
        } else if let error = viewModel.errorMessage {
            PreviewErrorView(message: error)
        } else {
            PreviewPlaceholder()
        }
    }

    // MARK: - Actions

    private func handleSave() {
        viewModel.savePost { post in
            playSuccessHaptic()
            onSave(post)
        }
    }

    private func hideKeyboard() {
        isTextEditorFocused = false
    }

    /// Play success haptic feedback
    private func playSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Previews

#Preview {
    AddPostView(onSave: { _ in }, onCancel: {})
}

#Preview("With Initial URL") {
    AddPostView(
        initialURL: URL(string: "https://www.apple.com"),
        onSave: { _ in },
        onCancel: {}
    )
}
