import os
import SwiftData
import SwiftUI

/// The date filter and the list of filtered points, newest first.
struct FilterListSheet: View {
    @Binding var filterKind: FilterKind
    @Binding var customRange: CustomRange
    /// Already filtered and sorted newest first by the map screen.
    let measures: [Measure]
    let onSelect: (Measure) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.persistence) private var persistence
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteError = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FieldMeasures", category: "FilterList")

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Show", selection: $filterKind) {
                        ForEach(FilterKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    if filterKind == .custom {
                        DatePicker("From", selection: fromBinding, displayedComponents: .date)
                        DatePicker("To", selection: toBinding, in: customRange.from..., displayedComponents: .date)
                    }
                }
                Section("\(measures.count) \(measures.count == 1 ? "point" : "points")") {
                    if measures.isEmpty {
                        Text("No points for this filter")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(measures) { measure in
                            Button {
                                onSelect(measure)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(measure.text)
                                        .lineLimit(2)
                                        .foregroundStyle(.primary)
                                    Text(measure.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Could not delete point", isPresented: $isShowingDeleteError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var fromBinding: Binding<Date> {
        Binding(
            get: { customRange.from },
            set: { customRange = customRange.settingFrom($0, calendar: .current) }
        )
    }

    private var toBinding: Binding<Date> {
        Binding(
            get: { customRange.to },
            set: { customRange = customRange.settingTo($0, calendar: .current) }
        )
    }

    private func delete(at offsets: IndexSet) {
        do {
            for measure in offsets.map({ measures[$0] }) {
                try persistence.delete(measure, from: modelContext)
            }
        } catch {
            logger.error("Deleting a point from the list failed: \(error.localizedDescription)")
            isShowingDeleteError = true
        }
    }
}
