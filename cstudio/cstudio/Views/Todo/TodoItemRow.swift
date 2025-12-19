//
//  TodoItemRow.swift
//  cstudio
//
//  A single checklist row mimicking iOS Notes checklist style
//

import SwiftUI
import CStudioKit

/// A single todo item row with checkbox and editable text field
struct TodoItemRow: View {
    
    // MARK: - Properties
    
    let item: TodoItem
    let isFocused: Bool
    let onToggle: () -> Void
    let onTextChange: (String) -> Void
    let onSubmit: () -> Void
    let onDelete: () -> Void
    
    @State private var localText: String
    @FocusState private var textFieldFocused: Bool
    
    // MARK: - Initialization
    
    init(
        item: TodoItem,
        isFocused: Bool,
        onToggle: @escaping () -> Void,
        onTextChange: @escaping (String) -> Void,
        onSubmit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.isFocused = isFocused
        self.onToggle = onToggle
        self.onTextChange = onTextChange
        self.onSubmit = onSubmit
        self.onDelete = onDelete
        self._localText = State(initialValue: item.text)
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            // Checkbox button
            checkboxButton
            
            // Editable text field
            textField
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .contentShape(Rectangle())
        .onChange(of: isFocused) { _, newValue in
            textFieldFocused = newValue
        }
        .onChange(of: textFieldFocused) { _, newValue in
            if !newValue {
                // Commit text when losing focus
                onTextChange(localText)
            }
        }
        .onAppear {
            if isFocused {
                textFieldFocused = true
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Circular checkbox button
    private var checkboxButton: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .strokeBorder(
                        item.isCompleted ? DesignTokens.Colors.checkboxChecked : DesignTokens.Colors.checkboxUnchecked,
                        lineWidth: 2
                    )
                    .frame(width: 22, height: 22)
                
                if item.isCompleted {
                    Circle()
                        .fill(DesignTokens.Colors.checkboxChecked)
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 2) // Align with text baseline
        .accessibilityLabel(item.isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle completion")
    }
    
    /// Editable text field with Notes-like styling
    private var textField: some View {
        TextField("", text: $localText, axis: .vertical)
            .focused($textFieldFocused)
            .textFieldStyle(.plain)
            .font(.body)
            .foregroundStyle(item.isCompleted ? DesignTokens.Colors.textStrikethrough : DesignTokens.Colors.textPrimary)
            .strikethrough(item.isCompleted, color: DesignTokens.Colors.textStrikethrough)
            .submitLabel(.return)
            .onSubmit {
                onTextChange(localText)
                onSubmit()
            }
            .onChange(of: localText) { _, newValue in
                // Handle backspace on empty - delete item
                if newValue.isEmpty && !item.text.isEmpty {
                    // Text was cleared, might be backspace
                }
            }
            .onChange(of: item.text) { _, newValue in
                // Sync external changes
                if newValue != localText {
                    localText = newValue
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TodoItemRow(
            item: TodoItem(text: "Buy groceries", isCompleted: false),
            isFocused: false,
            onToggle: {},
            onTextChange: { _ in },
            onSubmit: {},
            onDelete: {}
        )
        
        TodoItemRow(
            item: TodoItem(text: "Call mom", isCompleted: true),
            isFocused: false,
            onToggle: {},
            onTextChange: { _ in },
            onSubmit: {},
            onDelete: {}
        )
        
        TodoItemRow(
            item: TodoItem(text: "This is a longer todo item that might wrap to multiple lines to show how the layout handles it", isCompleted: false),
            isFocused: true,
            onToggle: {},
            onTextChange: { _ in },
            onSubmit: {},
            onDelete: {}
        )
    }
    .padding()
}
