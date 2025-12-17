//
//  AddPostSheet.swift
//  bare
//
//  Sheet wrapper for manual post addition in the main app
//

import SwiftUI
import BareKit

struct AddPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onPostAdded: (() -> Void)?

    init(onPostAdded: (() -> Void)? = nil) {
        self.onPostAdded = onPostAdded
    }

    var body: some View {
        AddPostView(
            initialURL: nil,
            onSave: { _ in
                // Dismiss sheet
                dismiss()
                // Notify parent to refresh
                onPostAdded?()
            },
            onCancel: {
                dismiss()
            }
        )
    }
}

#Preview {
    AddPostSheet()
}
