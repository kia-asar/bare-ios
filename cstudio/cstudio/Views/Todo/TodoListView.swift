//
//  TodoListView.swift
//  cstudio
//
//  Main todo list view mimicking iOS Notes checklist interface
//

import SwiftUI
import CStudioKit

/// Main todo list view with iOS Notes-like checklist interface
struct TodoListView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = TodoListViewModel()
    @State private var showClearCompletedAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignTokens.Colors.listBackground
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Checklist items
                    checklistContent
                    
                    // Bottom stats bar
                    if !viewModel.items.isEmpty {
                        statsBar
                    }
                }
            }
            .navigationTitle("Checklist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .alert("Clear Completed?", isPresented: $showClearCompletedAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.clearCompleted()
                    }
                }
            } message: {
                Text("This will remove \(viewModel.completedCount) completed item(s).")
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Scrollable checklist content
    private var checklistContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.items) { item in
                        TodoItemRow(
                            item: item,
                            isFocused: viewModel.focusedItemId == item.id,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleCompletion(for: item.id)
                                }
                            },
                            onTextChange: { newText in
                                viewModel.updateText(for: item.id, text: newText)
                            },
                            onSubmit: {
                                viewModel.handleReturnKey(for: item.id)
                            },
                            onDelete: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.deleteItem(item.id)
                                }
                            }
                        )
                        .id(item.id)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.deleteItem(item.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        
                        // Separator line
                        if item.id != viewModel.items.last?.id {
                            Divider()
                                .padding(.leading, 42) // Align with text
                        }
                    }
                    
                    // Tap area to add new item at bottom
                    addItemTapArea
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.focusedItemId) { _, newId in
                if let id = newId {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
    
    /// Tap area at bottom to add new items
    private var addItemTapArea: some View {
        Button {
            viewModel.addNewItem()
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Empty circle placeholder
                Circle()
                    .strokeBorder(DesignTokens.Colors.checkboxUnchecked.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                
                Text("Add item...")
                    .font(.body)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                
                Spacer()
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    /// Bottom stats bar showing completion count
    private var statsBar: some View {
        HStack {
            Text("\(viewModel.incompleteCount) remaining")
                .font(.footnote)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            if viewModel.hasCompletedItems {
                Text("\(viewModel.completedCount) completed")
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.Colors.checkboxChecked)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfaceLight)
    }
    
    /// Toolbar content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section {
                    Button {
                        viewModel.addNewItem()
                    } label: {
                        Label("New Item", systemImage: "plus")
                    }
                }
                
                Section {
                    Button {
                        withAnimation {
                            viewModel.markAllComplete()
                        }
                    } label: {
                        Label("Complete All", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(viewModel.incompleteCount == 0)
                    
                    Button {
                        withAnimation {
                            viewModel.markAllIncomplete()
                        }
                    } label: {
                        Label("Uncheck All", systemImage: "circle")
                    }
                    .disabled(viewModel.completedCount == 0)
                }
                
                if viewModel.hasCompletedItems {
                    Section {
                        Button(role: .destructive) {
                            showClearCompletedAlert = true
                        } label: {
                            Label("Clear Completed", systemImage: "trash")
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
            }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }
    }
}

// MARK: - Preview

#Preview("Empty State") {
    TodoListView()
}

#Preview("With Items") {
    let view = TodoListView()
    return view
}
