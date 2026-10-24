import os
import SwiftData
import SwiftUI

/// Adds a point at the latest position fix with a free-text description.
struct AddMeasureSheet: View {
    @Environment(LocationManager.self) private var location
    @Environment(\.modelContext) private var modelContext
    @Environment(\.persistence) private var persistence
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var isShowingSaveError = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FieldMeasures", category: "AddMeasure")

    var body: some View {
        NavigationStack {
            Form {
                Section("Position") {
                    if let fix = location.latestFix {
                        LabeledContent("Latitude", value: String(format: "%.6f", fix.latitude))
                        LabeledContent("Longitude", value: String(format: "%.6f", fix.longitude))
                        LabeledContent("Accuracy", value: "±\(Int(fix.accuracy.rounded())) m")
                        if isLowAccuracy(fix.accuracy) {
                            Label("Low accuracy (±\(Int(fix.accuracy.rounded())) m)", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Label("Waiting for GPS…", systemImage: "location.magnifyingglass")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Description") {
                    TextField("e.g. 320 lx or 68 dB, traffic", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Add Point")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(location.latestFix == nil || !isValidDescription(text))
                }
            }
            .alert("Could not save point", isPresented: $isShowingSaveError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func save() {
        guard let fix = location.latestFix else { return }
        let measure = Measure(
            createdAt: .now,
            latitude: fix.latitude,
            longitude: fix.longitude,
            altitude: fix.altitude,
            accuracy: fix.accuracy,
            text: text
        )
        do {
            try persistence.insert(measure, into: modelContext)
            dismiss()
        } catch {
            logger.error("Saving a new point failed: \(error.localizedDescription)")
            isShowingSaveError = true
        }
    }
}
