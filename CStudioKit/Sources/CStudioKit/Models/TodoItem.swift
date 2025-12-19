//
//  TodoItem.swift
//  CStudioKit
//
//  Model representing a single checklist/todo item
//

import Foundation

/// Represents a single checklist item in the todo list
public struct TodoItem: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var text: String
    public var isCompleted: Bool
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        text: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
    
    /// Creates a copy with updated text
    public func withText(_ newText: String) -> TodoItem {
        TodoItem(id: id, text: newText, isCompleted: isCompleted, createdAt: createdAt)
    }
    
    /// Creates a copy with toggled completion state
    public func toggled() -> TodoItem {
        TodoItem(id: id, text: text, isCompleted: !isCompleted, createdAt: createdAt)
    }
}

// MARK: - Sample Data

extension TodoItem {
    public static let sampleData: [TodoItem] = [
        TodoItem(text: "Buy groceries", isCompleted: false),
        TodoItem(text: "Call mom", isCompleted: true),
        TodoItem(text: "Finish project report", isCompleted: false),
        TodoItem(text: "Schedule dentist appointment", isCompleted: false),
        TodoItem(text: "Read a chapter", isCompleted: true)
    ]
    
    public static var sample: TodoItem {
        sampleData[0]
    }
}
