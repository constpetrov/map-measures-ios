import os
import SwiftData
import SwiftUI

/// A point's full description and details, with editing of the description and deletion.
struct MeasureDetailSheet: View {
    let measure: Measure

    @Environment(\.modelContext) private var modelContext
    @Environment(\.persistence) private var persistence
    @Environment(\.dismiss) private var dismiss
    /// Non-nil while editing. The stored text changes only when Save succeeds.
    @State private var draft: String?
    @State private var isConfirmingDelete = false
    @State private var errorTitle: String?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FieldMeasures", category: "MeasureDetail")

    var body: some View {
        NavigationStack {
            if measure.isDeleted {
                Color.clear
            } else {
                content
            }
        }
    }

    private var content: some View {
        Form {
            Section("Description") {
                if let draft {
                    TextField("Description", text: Binding(get: { draft }, set: { self.draft = $0 }), axis: .vertical)
                        .lineLimit(3...10)
                } else {
                    Text(measure.text)
                        .textSelection(.enabled)
                }
            }
            Section("Details") {
                LabeledContent("Created", value: measure.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Latitude", value: String(format: "%.6f", measure.latitude))
                LabeledContent("Longitude", value: String(format: "%.6f", measure.longitude))
                LabeledContent("Accuracy", value: "±\(Int(measure.accuracy.rounded())) m")
                if let altitude = measure.altitude {
                    LabeledContent("Altitude", value: String(format: "%.1f m", altitude))
                }
            }
            if draft == nil {
                Section {
                    Button("Delete Point", role: .destructive) {
                        isConfirmingDelete = true
                    }
                }
            }
        }
        .navigationTitle(draft == nil ? "Point" : "Edit Point")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let draft {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { self.draft = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveEdit)
                        .disabled(!isValidDescription(draft))
                }
            } else {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { draft = measure.text }
                }
            }
        }
        .confirmationDialog("Delete this point?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
        }
        .alert(errorTitle ?? "", isPresented: Binding(get: { errorTitle != nil }, set: { if !$0 { errorTitle = nil } })) {
            Button("OK", role: .cancel) {}
        }
    }

    private func saveEdit() {
        guard let draft else { return }
        let previous = measure.text
        do {
            try persistence.update(in: modelContext, change: { measure.text = draft }, revert: { measure.text = previous })
            self.draft = nil
        } catch {
            logger.error("Saving an edited description failed: \(error.localizedDescription)")
            errorTitle = "Could not save changes"
        }
    }

    private func delete() {
        do {
            try persistence.delete(measure, from: modelContext)
            dismiss()
        } catch {
            logger.error("Deleting a point failed: \(error.localizedDescription)")
            errorTitle = "Could not delete point"
        }
    }
}
