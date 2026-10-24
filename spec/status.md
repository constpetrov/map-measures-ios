# Status: Field Measures

## Current

- Task: task-4.1
- Status: NOT_STARTED

## Completed

- task-1.1
- task-1.2
- task-1.3
- task-1.4
- task-1.5
- task-1.6
- task-1.7
- task-2.1
- task-2.2
- task-2.3
- task-2.4
- task-2.5
- task-2.6
- task-3.1
- task-3.2
- task-3.3
- task-3.4

## Phase Approvals

- phase-1: APPROVED
- phase-2: COMPLETE (cp-2 passed; no approval stop, per user instruction at cp-1)
- phase-3: COMPLETE (cp-3 passed; continuing per user instruction)
- phase-4: PENDING

## Blockers

(none)

## Deviations

- task-1.3 / RULE-9 (approved at cp-1, mechanism revised in phase 3): no `context.rollback()` (it doesn't discard pending changes on iOS 17.0). The UndoManager approach approved at cp-1 crashed once in the app (`NSUndoManager endUndoGrouping` raised from `Persistence.commit` while saving an edit). That crash didn't reproduce in unit tests, so Core Data's own undo bookkeeping on the main context is the likely cause. `Persistence` now has three explicit operations, each undone without rollback or undo:
  - `insert`: on failure, the pending insert is deleted.
  - `update(change:revert:)`: on failure, the caller's revert restores the old value.
  - `delete`: deletes in a scratch `ModelContext` with autosave off, then deletes from the main context only after that save succeeds.

  Same all-or-nothing guarantee (AC-32, AC-48, AC-52). Views still never call `save()` directly. Covered by PersistenceTests on iOS 17.0 and 27, including waits that give autosave a chance to run.

- task-1.7 (resolved by user, "Proceed with 1"): panning with 3,000 seeded points all on screen is slow (5.2–8.2 s per swipe plus screenshot via AXe, against 2.1–2.9 s for an empty store). Accepted as a known limitation, because no AC covers panning and clustering is out of scope (R-4). Pins render as native `Marker`s, limited to 2× the visible region (`Core/CoordinateBox`), with titles visible at a latitude span ≤ 0.01. AC-107 is still measured in task-4.3. If it fails there or on-device panning feels slow, revisit with clustering (spec change to R-4).

## Notes

- cp-1 approval: the user asked to commit and push after every phase, and to continue through checkpoints without stopping unless a question needs their answer.

- Simulator: two iOS 17.0 devices are named "iPhone 15", so a destination by name is ambiguous. Tests run on the booted iOS 17.0 "iPhone 15 Pro", `id=D262D98A-1D06-489E-8405-4DF67BA55BD0`, which still satisfies the tasks.yaml assumption ("any iPhone on the iOS 17.0 runtime").
- task-1.1: Signing settings live in `Config/Base.xcconfig`, which includes the optional `Local.xcconfig` with `#include?`, so the simulator builds with no local file. The bundle ID is `$(BUNDLE_ID_PREFIX).FieldMeasures`, with prefix `com.example` until Local.xcconfig sets it.
- task-1.3: On iOS 17.0, creating a `Measure` before any `ModelContainer` exists makes the later save fail with NSCocoaError 134020 ("model configuration … incompatible"). Always create model objects after the container: the app does, and the tests and seeding code must too. Tests give each container a unique configuration name and the suite is `.serialized`.
- task-1.3: An extra simulator "FM iOS27" (EAE4FD1E-FCA6-4AAE-8C5E-F61A7D58C8A0, iOS 27.0) was created to tell iOS 17.0 SwiftData defects apart from code bugs. Delete with `xcrun simctl delete EAE4FD1E-FCA6-4AAE-8C5E-F61A7D58C8A0` if not wanted.
- task-1.4: The delegate uses an isolated conformance (`extension LocationManager: @MainActor CLLocationManagerDelegate`). It compiles cleanly in Swift 6 and works on the iOS 17.0 runtime: the permission prompt appears after `simctl privacy reset`, and after granting and rebooting it no longer appears. A system alert stays on screen after the app is terminated, so reboot the simulator before re-checking the prompt.
- task-1.4: `LocationFix` (in LocationManager.swift) carries the valid-fix and altitude rules and has unit tests (LocationFixTests).
- task-1.5: "Satellite" uses `.hybrid(elevation: .realistic)` (satellite imagery with road labels). Persistence of the style choice was checked by writing the default and relaunching on iOS 17.0. Revoking location shows the banner and greys out +. The Open Settings tap needs a manual check (task-4.3).
- task-1.6/UI driving: AXe was installed through Homebrew (user approved). Touch input via AXe does not reach the iOS 17.0 simulator runtime under Xcode 27.1: taps and swipes report success but have no effect. Tap-through checks therefore run on the booted iOS 27.0 "iPhone 18 Pro" (8D52644F-FA9D-474A-93B2-6FA17A7DE44D). iOS 17.0 is used for unit tests, launch and screenshot checks, and the user's manual checklist. `axe type` also doesn't reach the app; typing works by tapping on-screen keys (their labels flip case with shift).
- task-1.6: Verified on iOS 27: Save is disabled when empty and when whitespace-only, and enabled with text. Saving closes the sheet and the pin appears and survives a relaunch. Cancel stores nothing (SQLite row count unchanged). The low-accuracy warning isn't visible in the simulator (accuracy is always ±5 m), so its boundary is covered by AccuracyRulesTests and the visual check goes on the manual checklist.
- task-1.7: DebugOptions and the Release exclusion work: no flag strings in the Release binary. `-FailSaves` shows "Could not save point", keeps the sheet and text, adds no row, and leaves no stray pin after Cancel. `-SeedPoints 3000` inserts 3,000 rows on both iOS 17.0 and iOS 27. A `-SeedCenter <lat>,<lon>` flag (default Berlin) was added because no location fix exists yet at launch.
- task-1.7: Pins are currently native `Marker`s for only the points inside 2× the visible region (`Core/CoordinateBox`, tested). Titles are visible at a latitude span of 0.01 or less. That's the second attempt, kept pending the blocker decision. Memory with 3,000 points: about 690 MB (Markers) vs about 830 MB (SwiftUI Annotations).
- cp-2: 71/71 tests pass on iOS 17.0. Core has no SwiftUI/SwiftData/CoreLocation/MapKit/UIKit imports, no reads of Date()/.now/Calendar.current/TimeZone.current, and no DateInterval. Every Core file declares its types and functions `nonisolated`.
- task-2.4: Export number and time formatting is shared in `ExportText` (Core/ExportPoint.swift): POSIX `String(format:locale:)` and an `ISO8601DateFormatter` built per call, so no shared non-Sendable state is needed. `ExportFileFormat` (gpx/csv) lives in the same file.
- task-2.4: GPXWriterTests writes a sample to the simulator app's tmp folder as `fieldmeasures-sample.gpx`. The path is printed as "GPX sample: …" in the test log, for the xmllint check in task-4.3.
- task-2.6: `exportFileName` takes a calendar. The export view must pass a Gregorian calendar with the current time zone, so a Buddhist or Japanese device calendar can't change the year in the file name.
- cp-3: 74/74 tests pass on iOS 17.0 and iOS 27. Phase 3 tap-throughs ran on iOS 27:
  - Pin tap opens the detail (description, date, position, accuracy, altitude).
  - An edit saves, and createdAt and position are unchanged in SQLite.
  - An empty edit disables Save.
  - Declining the delete keeps the point; confirming removes the row, the pin and the sheet.
  - With `-FailSaves`, an edit shows "Could not save changes" with the store unchanged and the draft kept, and a delete shows "Could not delete point" with the row kept, even after termination.
  - Filter counts match SQLite (All 38, Today 2, 7 Days 10), and the map shows the same 10 pins.
  - The filter button reports active, and the camera stays in tracking on filter changes.
  - Custom: moving From past To moves To along, and "No points for this filter" shows.
  - A row tap closes the sheet and centres the map at the same zoom (tracking off).
  - Swipe-to-delete removes a row with no dialog.
- phase-3 bug found and fixed: the scratch delete context autosaved its pending delete after an injected save failure, so a failed delete was persisted later. Fixed with `scratch.autosaveEnabled = false`. Regression tests wait 2 s before checking the store; without the fix the suite fails.
- phase-3 not automatable: the map can't be zoomed with AXe (double taps don't register as a zoom), so seeing labels appear at a span of 0.01 or less is on the manual checklist. The threshold logic is covered by PointLabelTests. On iOS 27, `confirmationDialog` shows as a popover with only "Delete"; tapping outside cancels.
- UI driving: accessibility frames for map markers and list rows are sometimes offset by about a row on the iOS 27 simulator. `findred.py` (scratchpad) locates markers in screenshots instead.
