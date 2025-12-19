//
//  TodoListViewModel.swift
//  cstudio
//
//  ViewModel for managing the todo list state and operations
//

import Foundation
import SwiftUI
import CStudioKit

/// ViewModel managing the todo list state using the Observation framework
@Observable
@MainActor
final class TodoListViewModel {
    
    // MARK: - Properties
    
    /// The list of todo items
    var items: [TodoItem] = []
    
    /// The ID of the item currently being edited (has focus)
    var focusedItemId: UUID?
    
    /// Storage key for UserDefaults persistence
    private let storageKey = "todo_items"
    
    // MARK: - Initialization
    
    init() {
        loadItems()
    }
    
    // MARK: - Public Methods
    
    /// Adds a new empty item at the end of the list and focuses it
    func addNewItem() {
        let newItem = TodoItem()
        items.append(newItem)
        focusedItemId = newItem.id
        saveItems()
    }
    
    /// Inserts a new item after the specified item and focuses it
    /// - Parameter afterId: The ID of the item after which to insert
    func insertItem(after afterId: UUID) {
        guard let index = items.firstIndex(where: { $0.id == afterId }) else {
            addNewItem()
            return
        }
        
        let newItem = TodoItem()
        items.insert(newItem, at: index + 1)
        focusedItemId = newItem.id
        saveItems()
    }
    
    /// Updates the text of an item
    /// - Parameters:
    ///   - id: The ID of the item to update
    ///   - text: The new text value
    func updateText(for id: UUID, text: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].text = text
        saveItems()
    }
    
    /// Toggles the completion state of an item
    /// - Parameter id: The ID of the item to toggle
    func toggleCompletion(for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
        saveItems()
    }
    
    /// Deletes an item from the list
    /// - Parameter id: The ID of the item to delete
    func deleteItem(_ id: UUID) {
        items.removeAll { $0.id == id }
        saveItems()
    }
    
    /// Deletes items at the specified offsets (for swipe-to-delete)
    /// - Parameter offsets: The index set of items to delete
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }
    
    /// Moves items from source to destination (for drag-to-reorder)
    /// - Parameters:
    ///   - source: The source index set
    ///   - destination: The destination index
    func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        saveItems()
    }
    
    /// Handles the return key press - creates new item or moves focus
    /// - Parameter currentId: The ID of the currently focused item
    func handleReturnKey(for currentId: UUID) {
        guard let index = items.firstIndex(where: { $0.id == currentId }) else { return }
        
        // If current item is empty, remove it instead of creating new
        if items[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // If it's the last item and it's empty, just clear focus
            if index == items.count - 1 {
                focusedItemId = nil
                return
            }
            // Otherwise delete empty item and focus next
            deleteItem(currentId)
            if index < items.count {
                focusedItemId = items[index].id
            }
            return
        }
        
        // Create new item after current one
        insertItem(after: currentId)
    }
    
    /// Handles backspace on empty item - deletes and focuses previous
    /// - Parameter currentId: The ID of the currently focused item
    /// - Returns: True if the item was deleted
    func handleBackspaceOnEmpty(for currentId: UUID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == currentId }),
              items[index].text.isEmpty else {
            return false
        }
        
        // Don't delete if it's the only item
        guard items.count > 1 else { return false }
        
        // Focus previous item if available, otherwise next
        if index > 0 {
            focusedItemId = items[index - 1].id
        } else if index + 1 < items.count {
            focusedItemId = items[index + 1].id
        }
        
        deleteItem(currentId)
        return true
    }
    
    /// Clears all completed items
    func clearCompleted() {
        items.removeAll { $0.isCompleted }
        saveItems()
    }
    
    /// Marks all items as completed
    func markAllComplete() {
        for index in items.indices {
            items[index].isCompleted = true
        }
        saveItems()
    }
    
    /// Marks all items as incomplete
    func markAllIncomplete() {
        for index in items.indices {
            items[index].isCompleted = false
        }
        saveItems()
    }
    
    // MARK: - Computed Properties
    
    /// Number of incomplete items
    var incompleteCount: Int {
        items.filter { !$0.isCompleted }.count
    }
    
    /// Number of completed items
    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    /// Whether there are any completed items
    var hasCompletedItems: Bool {
        completedCount > 0
    }
    
    // MARK: - Persistence
    
    /// Saves items to UserDefaults
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            AppLogger.app.error("Failed to save todo items: \(error.localizedDescription)")
        }
    }
    
    /// Loads items from UserDefaults
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            // Start with one empty item for new users
            items = [TodoItem()]
            return
        }
        
        do {
            items = try JSONDecoder().decode([TodoItem].self, from: data)
            // Ensure at least one item exists
            if items.isEmpty {
                items = [TodoItem()]
            }
        } catch {
            AppLogger.app.error("Failed to load todo items: \(error.localizedDescription)")
            items = [TodoItem()]
        }
    }
}
