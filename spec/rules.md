# Technical Design and Constraints: Field Measures

## Overview

This is a native iPhone app that saves free-text measurement points at the current GPS position, shows them on a map, filters them by date and exports them as GPX or CSV. Stack: Swift 6 (language mode 6, default MainActor isolation), SwiftUI, MapKit for SwiftUI, Core Location, SwiftData, Swift Testing, XcodeGen. Built with Xcode 27.1, deployment target iOS 17.0. See [spec.md](spec.md) and [criteria.md](criteria.md).

## Design

Components:
- `FieldMeasuresApp`: app entry, creates the SwiftData `ModelContainer`.
- `Measure`: the `@Model` for one point.
- `LocationManager`: `@Observable` `CLLocationManager` wrapper: authorization state and latest valid fix.
- `Core/`: pure, nonisolated logic: date filter, custom range, text validation, labels, GPX/CSV writers, file names.
- `Persistence`: store saves and export writes, with injectable save and write functions.
- `DebugOptions`: DEBUG-only launch flags for forced failures and seeding.
- Views: `MapScreen` (map, pins, toolbar, filter state), `AddMeasureSheet`, `MeasureDetailSheet`, `FilterListSheet`, `ExportSheet`, `ActivityView` (share sheet bridge).

Boundaries: no external surface. `Core/` imports no SwiftUI, SwiftData or Core Location. Views pass `ExportPoint` values to `Core`.

Flow:
1. `LocationManager` publishes fixes.
2. `AddMeasureSheet` validates the text and inserts a `Measure` through `Persistence`, which saves and rolls back on failure.
3. `MapScreen` reads all points with `@Query` and applies `DateFilter` in memory. The same filtered array feeds the pins, the list and the export.
4. `ExportSheet` maps points to `ExportPoint`, builds the file data with `GPXWriter` or `CSVWriter`, writes a temp file through `Persistence`, then presents the share sheet.

Key dependencies: Apple frameworks only. Declined: CoreGPX, CSV libraries, MVVM view models, a store service layer, XCUITest.

## Codebase Alignment

The repository has no source code, no AGENTS.md or CLAUDE.md, and no build files, so nothing is inherited. Every rule below sets a new convention. The proposal's "about 6 files" grows to about 14 small files, because `Core/` is split by concern so it can be unit tested. Behaviour and dependencies stay the same.

## Rules

### RULE-1
**Covers:** project-wide, AC-105
**MUST** define the project in `project.yml` (XcodeGen) with one app target `FieldMeasures` and one unit-test target `FieldMeasuresTests`, and **MUST** gitignore the generated `FieldMeasures.xcodeproj`.
**Reason:** The user chose a readable, agent-editable project definition over a hand-maintained `.pbxproj`.

### RULE-2
**Covers:** AC-105
**MUST** set `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `TARGETED_DEVICE_FAMILY = 1`, `SWIFT_VERSION = 6.0` and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` for both targets.
**Reason:** iOS 17 is the agreed minimum, the app is iPhone only, and the user chose Swift 6 with MainActor by default.

### RULE-3
**Covers:** project-wide
**MUST NOT** add any Swift package or other third-party dependency.
**Reason:** The proposal promises Apple frameworks only. CoreGPX and CSV parsers were surveyed and declined, because each format here takes under 60 lines of string building.

### RULE-4
**Covers:** project-wide
**MUST** place sources as follows: `FieldMeasures/App/`, `FieldMeasures/Model/`, `FieldMeasures/Location/`, `FieldMeasures/Core/` and `FieldMeasures/Views/`, with tests in `FieldMeasuresTests/`, one primary type per file, and the file named after it. `Persistence.swift` goes in `Model/` and `DebugOptions.swift` in `App/`.
**Reason:** Gives a predictable location for each component and its tests.

### RULE-5
**Covers:** AC-20–AC-22, AC-38–AC-41, AC-46, AC-47, AC-55–AC-65, AC-79–AC-101
**MUST** keep `FieldMeasures/Core/` free of `import SwiftUI`, `SwiftData`, `CoreLocation` and `MapKit`, and **MUST** declare its types and free functions `nonisolated`.
**Reason:** The user chose views plus pure helpers. Pure, nonisolated code can be unit tested synchronously from any test, even though the target is MainActor by default.

### RULE-6
**Covers:** AC-56–AC-64, AC-81, AC-92, AC-93, AC-100, AC-101
**MUST** pass `now: Date`, `calendar: Calendar` and `timeZone: TimeZone` into every `Core` function whose result depends on them, and **MUST NOT** read `Date()`, `Calendar.current` or `TimeZone.current` inside `Core`.
**Reason:** Day-boundary and time-zone criteria must be testable for fixed instants and zones.

### RULE-7
**Covers:** AC-23–AC-28, AC-31
**MUST** model a point as `@Model final class Measure` with the properties `@Attribute(.unique) id: UUID`, `createdAt: Date`, `latitude: Double`, `longitude: Double`, `altitude: Double?`, `accuracy: Double` and `text: String`, and **MUST NOT** name any property `description`.
**Reason:** Matches the spec's data model. `description` clashes with `CustomStringConvertible`.

### RULE-8
**Covers:** project-wide
**MUST NOT** introduce a `VersionedSchema` or `SchemaMigrationPlan` in v1, and **MUST** make any property added later optional or give it a default value.
**Reason:** SwiftData migrates added optional or defaulted properties without a plan. A schema plan was considered and deferred until a non-additive change is needed.

### RULE-9
**Covers:** AC-29, AC-32, AC-44, AC-48, AC-51, AC-52, AC-72
**MUST** perform every insert, edit and delete through `Persistence.commit(_ change: () -> Void, in context: ModelContext) throws`. It applies the change, calls the injected save function (default `context.save()`), calls `context.rollback()` and rethrows on failure. Views **MUST NOT** call `modelContext.save()` directly.
**Reason:** Autosave hides failures, and the criteria need each failure detected and the store left all-or-nothing. One choke point lets the user-chosen injectable save prove the rollback in a unit test.

### RULE-10
**Covers:** AC-45, AC-46, AC-48
**MUST** edit the description in a local `@State` draft and assign it to `Measure.text` only when the user taps Save, and **MUST NOT** bind a text field directly to `Measure.text`.
**Reason:** If a save fails the stored text must stay unchanged while the typed text is kept. A direct binding would change the model on every keystroke.

### RULE-11
**Covers:** AC-9, AC-33, AC-34, AC-66, AC-70, AC-75, AC-78, AC-107
**MUST** load points through a single `@Query(sort: \Measure.createdAt, order: .reverse)` in `MapScreen` and derive one filtered array with `DateFilter`, which **MUST** be passed to the pins, the list and the export. **MUST NOT** build a separate `#Predicate` per filter.
**Reason:** One source guarantees the map, the list and the export agree. Filtering 3,000 values in memory takes well under 1 s.

### RULE-12
**Covers:** AC-54, AC-68, AC-69
**MUST** hold the active filter in `@State` on `MapScreen`, and **MUST NOT** persist it (no `@AppStorage` or `@SceneStorage`).
**Reason:** The spec requires the filter to reset to All on every launch.

### RULE-13
**Covers:** AC-5, AC-6
**MUST** store the map style choice in `@AppStorage("mapStyle")` as a string raw value of `standard` or `satellite`.
**Reason:** The choice must persist across launches, and a string survives future enum changes.

### RULE-14
**Covers:** AC-56–AC-65, AC-110
**MUST** compute filter bounds with `calendar.startOfDay(for:)` and `calendar.date(byAdding: .day, …)` as a half-open interval `[start, endExclusive)`, where Custom's end is the start of the day after To. **MUST NOT** use fixed 86,400-second arithmetic, and **MUST NOT** construct `DateInterval` from unchecked bounds.
**Reason:** Days are 23 or 25 hours long at daylight-saving changes. A half-open interval makes 23:59:59.999 inclusive without special cases. `DateInterval(start:end:)` traps when end < start.

### RULE-15
**Covers:** AC-20–AC-22, AC-46, AC-47
**MUST** decide whether text is valid with one `Core` function that returns false when `text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`, used by both the add and edit forms.
**Reason:** The add and edit rules are the same and must not drift apart.

### RULE-16
**Covers:** AC-38–AC-41, AC-84–AC-87
**MUST** build labels and GPX names by replacing each `Character` where `isNewline` is true with one space, then taking `prefix(12)` of the `Character`s. The label adds "…" only when the original has more than 12 `Character`s.
**Reason:** Users see grapheme clusters, not UTF-16 units, and `\r\n` is one `Character`, so it becomes one space.

### RULE-17
**Covers:** AC-35–AC-37
**MUST** show labels only when `latitudeDelta <= 0.01`. The span comes from `onMapCameraChange(frequency: .onEnd)` and the comparison is a `Core` function with the threshold as a named constant.
**Reason:** Makes the boundary test pure and keeps per-frame updates out of the view body.

### RULE-18
**Covers:** AC-3, AC-4, AC-67, AC-73
**MUST** drive the map through `Map(position:)`, starting at `.userLocation(fallback: .automatic)`, with `MapUserLocationButton` in `mapControls`. Changing the filter **MUST NOT** write to the camera position. A list-row tap **MUST** set a region centred on the point using the last observed span.
**Reason:** The user chose a camera that stays put on filter changes. Keeping the span honours "centre" without a zoom jump.

### RULE-19
**Covers:** AC-1, AC-2, AC-7, AC-8, AC-10
**MUST** keep exactly one `LocationManager` (owned by the app and injected through the environment). It requests `requestWhenInUseAuthorization()` only when the status is `.notDetermined`, and treats `.denied` and `.restricted` as location access off. It **MUST NOT** call `CLLocationManager.locationServicesEnabled()` on the main actor.
**Reason:** With Location Services turned off system-wide, iOS reports `.denied`, so status alone covers E-2. `locationServicesEnabled()` blocks the main thread, and the runtime warns about it.

### RULE-20
**Covers:** AC-12–AC-15, AC-23–AC-25
**MUST** ignore fixes with `horizontalAccuracy < 0`, and **MUST** set altitude to `nil` when `verticalAccuracy < 0`. Fixes come from `CLLocationManager` with `desiredAccuracy = kCLLocationAccuracyBest`.
**Reason:** Negative accuracy marks an invalid value, and the spec forbids substitute altitudes.

### RULE-21
**Covers:** AC-16–AC-19
**MUST** show the low-accuracy warning only when `horizontalAccuracy > 20`, with 20 as a named `Core` constant, and **MUST NOT** let the warning affect whether Save is enabled.
**Reason:** Sets the boundary (exactly 20 m shows no warning) and the agreed rule that a weak fix never blocks Save.

### RULE-22
**Covers:** AC-104
**MUST NOT** add `UIBackgroundModes` `location` or set `allowsBackgroundLocationUpdates`.
**Reason:** Location stays foreground only (A-1), and iOS then stops updates in the background on its own.

### RULE-23
**Covers:** AC-106
**MUST** set `NSLocationWhenInUseUsageDescription` in `project.yml` to "Your location is used to place measurement points on the map."
**Reason:** iOS requires the text, and it must state the purpose.

### RULE-24
**Covers:** AC-103
**MUST NOT** use `URLSession`, `Network` or any other networking API.
**Reason:** The app makes no network requests besides the system map's own tile loading.

### RULE-25
**Covers:** AC-96–AC-99
**MUST** format export numbers with `Locale(identifier: "en_US_POSIX")` (for example `String(format: "%.6f", locale: posix, value)`), and **MUST NOT** use `formatted()`, `NumberFormatter` or string interpolation of `Double` in export code.
**Reason:** The device locale may use comma decimals, and interpolation drops trailing zeros.

### RULE-26
**Covers:** AC-81, AC-92, AC-93, AC-100, AC-101
**MUST** format UTC times with `ISO8601DateFormatter` (`.withInternetDateTime`, UTC time zone) and local times with the same formatter set to the injected `timeZone`. File-name dates **MUST** come from `calendar.dateComponents` and be zero-padded to `yyyy-MM-dd`.
**Reason:** These give a fixed-format output with no locale influence and a `Z` or `±hh:mm` suffix.

### RULE-27
**Covers:** AC-80–AC-89
**MUST** build GPX as a string in this order: XML declaration, `<gpx version="1.1" creator="FieldMeasures" xmlns="http://www.topografix.com/GPX/1/1">`, then per point `<wpt lat lon>` with children in schema order `ele?`, `time`, `name`, `desc`. Text **MUST** be escaped through one function that maps `& < > " '` to entities, applying `&` first.
**Reason:** GPX 1.1 is a sequence schema, so out-of-order children fail validation. Escaping `&` first avoids double escaping.

### RULE-28
**Covers:** AC-90–AC-95, AC-111
**MUST** write CSV rows ending in `\r\n`, and **MUST** wrap a field in double quotes, with each inner `"` doubled, when it contains `,`, `"`, `\r` or `\n`. `CSVWriter` **MUST** return `Data` whose first three bytes are `EF BB BF`, followed by the UTF-8 text.
**Reason:** These are the RFC 4180 rules that the round-trip criterion checks. The byte-order mark is the user's choice for Excel, and returning `Data` lets a test assert the exact bytes.

### RULE-29
**Covers:** AC-77, AC-102
**MUST** write the export to `FileManager.default.temporaryDirectory/<UUID>/<file name>` with `.atomic`, through `Persistence.writeExport(_:named:)` with an injectable write function, before presenting the share sheet, and **MUST** present it through a `UIActivityViewController` wrapped in `UIViewControllerRepresentable`. **MUST NOT** use `ShareLink`.
**Reason:** `ShareLink` opens before the app can detect a write failure, and the criteria require an alert instead of the share sheet. A UUID folder keeps the readable file name unique.

### RULE-30
**Covers:** AC-32, AC-48, AC-52, AC-102
**MUST** use the exact alert titles from the spec ("Could not save point", "Could not save changes", "Could not delete point", "Could not create export file"), and **SHOULD** log the underlying error with `os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "FieldMeasures", category: <component>)`.
**Reason:** The titles are tested exactly. Logging helps debug failures on the device and costs no network or dependency.

### RULE-31
**Covers:** AC-20–AC-22, AC-28, AC-31, AC-32, AC-38–AC-41, AC-46–AC-48, AC-52, AC-55–AC-65, AC-79–AC-102, AC-108–AC-111
**MUST** write unit tests with Swift Testing (`import Testing`) for every `Core` function, plus these tests. **MUST NOT** add an XCUITest target.
- A persistence test that writes to an on-disk `ModelContainer` in a temp directory, creates a new container on the same URL, and compares all fields.
- `Persistence.commit` tests with a throwing save function for insert, edit and delete, asserting the store holds its pre-change state.
- A `Persistence.writeExport` test with a throwing write function, asserting the error propagates.

**Reason:** The user chose unit tests plus a manual checklist, with injectable failures. Reopening the store on disk is the only automated way to show data survives a relaunch.

### RULE-32
**Covers:** AC-1–AC-19, AC-29, AC-30, AC-32–AC-37, AC-42–AC-45, AC-48–AC-54, AC-66–AC-78, AC-80, AC-102–AC-107
**MUST** keep `docs/manual-checklist.md`, which lists every criterion not fully covered by unit tests, with steps for the iOS 17.0 simulator (using a simulated location) or a device. It **MUST** include:
- a GPX schema check with `xmllint --schema gpx.xsd`;
- alert checks using the RULE-38 failure flags;
- the AC-107 timing procedure from RULE-39.

**Reason:** Map, GPS and share-sheet criteria, and what the alerts look like on screen, can't be unit tested under the chosen strategy. Schema validation needs a tool that isn't available inside iOS tests.

### RULE-33
**Covers:** AC-80, AC-89
**MUST** check in a unit test that the generated GPX parses without error through `XMLParser`, and that it decodes the escaped description back to the original.
**Reason:** Proves the file is well-formed and escaped correctly automatically. Full schema validation stays manual (RULE-32).

### RULE-34
**Covers:** AC-8
**MUST** open Settings with `UIApplication.openSettingsURLString`.
**Reason:** This is the only public way to reach the app's Settings page.

### RULE-35
**Covers:** AC-49–AC-51, AC-72
**MUST** confirm a detail-sheet delete with `confirmationDialog`, and **MUST NOT** ask for confirmation on a list `onDelete` swipe.
**Reason:** These are the two delete paths the spec defines (R-16).

### RULE-36
**Covers:** project-wide, AC-105
**SHOULD** read `DEVELOPMENT_TEAM` and the bundle-ID prefix from a gitignored `Local.xcconfig` referenced in `project.yml`, with a checked-in `Local.xcconfig.example`.
**Reason:** Keeps your Apple team ID out of git, and the simulator still builds with no team set.

### RULE-37
**Covers:** AC-65, AC-108–AC-110
**MUST** hold the custom range as a `Core` value type whose only mutators are `settingFrom(_:calendar:)` and `settingTo(_:calendar:)`. The first sets To equal to From when the new From's day is after To's day. The second ignores a To whose day is before From's day. The view's To picker **MUST** use `in: from...` as its range.
**Reason:** Keeps the "To follows From" decision in one testable place. The picker range alone doesn't cover From moving past To.

### RULE-38
**Covers:** AC-32, AC-48, AC-52, AC-102, AC-107
**MUST** read the launch arguments `-FailSaves`, `-FailExportWrite` and `-SeedPoints <n>` only inside `#if DEBUG` in `DebugOptions`. The first two replace `Persistence`'s save or write function with one that throws. `-SeedPoints` inserts n points spread evenly over the last 30 days at launch, but only when the store is empty. **MUST NOT** compile any of this into Release builds.
**Reason:** Lets you see each error alert and load 3,000 points on the simulator without test-only code shipping.

### RULE-39
**Covers:** AC-107
**SHOULD** emit an `OSSignposter` interval named `FilterChange`, beginning when the active filter changes and ending in the next main-actor turn after the map and list receive the new array. AC-107 is measured with Instruments' Points of Interest on the iOS 17.0 simulator after launching with `-SeedPoints 3000`.
**Reason:** Gives a repeatable start and stop for the 1-second budget instead of a stopwatch. The signposts cost nothing when Instruments isn't attached.

## Cross-Reference

| AC | Rules |
|---|---|
| AC-1, AC-2 | RULE-19, RULE-32 |
| AC-3, AC-4 | RULE-18, RULE-32 |
| AC-5, AC-6 | RULE-13, RULE-32 |
| AC-7 | RULE-19, RULE-32 |
| AC-8 | RULE-19, RULE-34, RULE-32 |
| AC-9 | RULE-11 |
| AC-10 | RULE-19, RULE-32 |
| AC-11 | RULE-32 |
| AC-12–AC-15 | RULE-20, RULE-32 |
| AC-16–AC-19 | RULE-21, RULE-32 |
| AC-20–AC-22 | RULE-5, RULE-15, RULE-31 |
| AC-23–AC-25 | RULE-7, RULE-20 |
| AC-26, AC-27 | RULE-7 |
| AC-28 | RULE-7, RULE-31 |
| AC-29 | RULE-9, RULE-32 |
| AC-30 | RULE-32 |
| AC-31 | RULE-7, RULE-31 |
| AC-32 | RULE-9, RULE-30, RULE-31, RULE-32, RULE-38 |
| AC-33, AC-34 | RULE-11, RULE-32 |
| AC-35–AC-37 | RULE-17, RULE-32 |
| AC-38–AC-41 | RULE-5, RULE-16, RULE-31 |
| AC-42, AC-43 | RULE-32 |
| AC-44 | RULE-9, RULE-32 |
| AC-45 | RULE-10, RULE-32 |
| AC-46, AC-47 | RULE-10, RULE-15, RULE-31 |
| AC-48 | RULE-9, RULE-10, RULE-30, RULE-31, RULE-32, RULE-38 |
| AC-49, AC-50 | RULE-35, RULE-32 |
| AC-51 | RULE-9, RULE-35, RULE-32 |
| AC-52 | RULE-9, RULE-30, RULE-31, RULE-32, RULE-38 |
| AC-53 | RULE-32 |
| AC-54 | RULE-12, RULE-32 |
| AC-55–AC-65 | RULE-5, RULE-6, RULE-14, RULE-31 (AC-65 also RULE-37) |
| AC-66 | RULE-11, RULE-32 |
| AC-67 | RULE-18, RULE-32 |
| AC-68, AC-69 | RULE-12, RULE-32 |
| AC-70 | RULE-11, RULE-32 |
| AC-71 | RULE-32 |
| AC-72 | RULE-9, RULE-35, RULE-32 |
| AC-73 | RULE-18, RULE-32 |
| AC-74 | RULE-32 |
| AC-75 | RULE-11, RULE-32 |
| AC-76 | RULE-32 |
| AC-77 | RULE-29, RULE-32 |
| AC-78 | RULE-11, RULE-32 |
| AC-79 | RULE-5, RULE-31 |
| AC-80 | RULE-27, RULE-32, RULE-33 |
| AC-81 | RULE-6, RULE-26, RULE-27, RULE-31 |
| AC-82–AC-88 | RULE-27, RULE-31 (AC-84–AC-87 also RULE-16) |
| AC-89 | RULE-27, RULE-33 |
| AC-90, AC-91, AC-94, AC-95 | RULE-28, RULE-31 |
| AC-92, AC-93 | RULE-6, RULE-26, RULE-31 |
| AC-96–AC-99 | RULE-25, RULE-31 |
| AC-100, AC-101 | RULE-6, RULE-26, RULE-31 |
| AC-102 | RULE-29, RULE-30, RULE-31, RULE-32, RULE-38 |
| AC-103 | RULE-24, RULE-32 |
| AC-104 | RULE-22, RULE-32 |
| AC-105 | RULE-1, RULE-2, RULE-36, RULE-32 |
| AC-106 | RULE-23, RULE-32 |
| AC-107 | RULE-11, RULE-32, RULE-38, RULE-39 |
| AC-108, AC-109 | RULE-5, RULE-31, RULE-37 |
| AC-110 | RULE-5, RULE-14, RULE-31, RULE-37 |
| AC-111 | RULE-28, RULE-31 |

## Design Exclusions

- View models and a store service layer: declined by the user in favour of views plus pure `Core` helpers.
- UI test automation: declined by the user. Covered by the manual checklist.
- Schema versioning and migration plans: deferred (RULE-8).
- Concurrency off the main actor: nothing in the app needs background work. Export of a few thousand points is synchronous on the main actor.
- Accessibility, localization, energy: excluded in criteria.md and inherited here.

## External Dependencies

- **Apple Developer team ID for device install:** blocked until you set it locally. Default: `Local.xcconfig` without a team, which builds for the simulator. You add `DEVELOPMENT_TEAM` before installing on the iPhone (RULE-36).
