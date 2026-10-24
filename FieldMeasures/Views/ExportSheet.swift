import os
import SwiftUI

/// Exports the filtered points as GPX or CSV and hands the file to the share sheet.
struct ExportSheet: View {
    /// The map screen's filtered points.
    let measures: [Measure]

    @Environment(\.persistence) private var persistence
    @Environment(\.dismiss) private var dismiss
    @State private var format = ExportFileFormat.gpx
    @State private var sharedFile: SharedFile?
    @State private var isShowingWriteError = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FieldMeasures", category: "Export")

    struct SharedFile: Identifiable {
        let url: URL
        var id: URL { url }
    }

    /// Gregorian with the current time zone, so file names use local yyyy-MM-dd whatever the device calendar.
    private var fileNameCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private var points: [ExportPoint] {
        measures.map {
            ExportPoint(
                id: $0.id,
                createdAt: $0.createdAt,
                latitude: $0.latitude,
                longitude: $0.longitude,
                altitude: $0.altitude,
                accuracy: $0.accuracy,
                text: $0.text
            )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFileFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(format == .gpx
                        ? "Waypoints for map apps such as Google Earth, QGIS or OsmAnd."
                        : "A table for spreadsheets, one row per point.")
                }
                Section {
                    LabeledContent("Points", value: "\(measures.count)")
                    LabeledContent("File", value: exportFileName(for: points, format: format, calendar: fileNameCalendar))
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export", action: export)
                        .disabled(measures.isEmpty)
                }
            }
            .sheet(item: $sharedFile) { file in
                ActivityView(fileURL: file.url)
                    .presentationDetents([.medium, .large])
            }
            .alert("Could not create export file", isPresented: $isShowingWriteError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func export() {
        let points = points
        let data = switch format {
        case .gpx: GPXWriter.data(for: points)
        case .csv: CSVWriter.data(for: points, timeZone: .current)
        }
        let name = exportFileName(for: points, format: format, calendar: fileNameCalendar)
        do {
            sharedFile = SharedFile(url: try persistence.writeExport(data, named: name))
        } catch {
            logger.error("Writing the export file failed: \(error.localizedDescription)")
            isShowingWriteError = true
        }
    }
}
