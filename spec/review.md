# Spec Review: Field Measures

## Summary
- Feature: Field Measures (iOS map-based measurement logger)
- Verdict: PASS
- Counts: 0 blockers, 0 majors, 2 minors
- Action: proceed to `/05-tasks`. The minors can be fixed in passing.

The earlier MAJOR-1 to MAJOR-3 are resolved:
- MAJOR-1 by spec R-13, E-20 and B-39, criteria AC-108 to AC-110, and rules RULE-14 and RULE-37.
- MAJOR-2 by RULE-9, RULE-29, RULE-31 and RULE-38.
- MAJOR-3 by the rewritten AC-107, RULE-38 and RULE-39.

The earlier MINOR-1, MINOR-2 and MINOR-4 are fixed in criteria.md and rules.md.

## Discipline Check

These checks were run by script:
- All 40 behaviours (B-1 to B-40) are covered by criteria.
- AC-1 to AC-111 are numbered with no gaps.
- Every `Covers: AC-N` in rules.md points to a real criterion.
- Every criterion appears in the Cross-Reference table.
- Every criterion opens with an EARS keyword.

AC-108 to AC-111 are placed next to the criteria they relate to rather than in number order. That's a deliberate trade-off to keep the existing numbers stable, and it isn't a finding.

- **MINOR-1: Cross-Reference rows name rules whose `Covers:` lines omit the AC.** Source: rules.md. The script found these pairs where the table names a rule that doesn't list the AC: (AC-47, RULE-10), (AC-55, RULE-6), (AC-55, RULE-14), (AC-65, RULE-6), (AC-108, RULE-5), (AC-109, RULE-5) and (AC-110, RULE-5). For example, the row "| AC-108, AC-109 | RULE-5, RULE-31, RULE-37 |" against "### RULE-5 / **Covers:** AC-20–AC-22, AC-38–AC-41, AC-46, AC-47, AC-55–AC-65, AC-79–AC-101". Each rule does apply in substance; only its `Covers:` line is stale. Impact: none on behaviour. Resolution: widen those `Covers:` lines on any future rules rerun.

## Conflicts

No conflicts found. Spot checks:
- **RULE-37 against AC-65 and AC-108–AC-110:** "sets To equal to From when the new From's day is after To's day" and "ignores a To whose day is before From's day" match the criteria exactly.
- **RULE-28 against AC-90 and AC-111:** the byte-order mark comes first and the header follows it.
- **RULE-38 against AC-107:** seeding "n points spread evenly over the last 30 days" matches the AC-107 precondition.
- **RULE-9 against RULE-10:** the draft text is assigned inside the `commit` change closure, so rollback reverts it.
- **Declined options:** none reappear (`ShareLink`, XCUITest, third-party packages, view models).

- **MINOR-2: A MUST rule depends on a SHOULD rule.** Source: rules.md. RULE-32 says "It **MUST** include: … the AC-107 timing procedure from RULE-39", while RULE-39 opens "**SHOULD** emit an `OSSignposter` interval named `FilterChange`". If the signposts are skipped, the checklist has no timing procedure to point to. Impact: small, because a stopwatch fallback still measures AC-107 roughly. Resolution: on any future rules rerun, raise RULE-39 to MUST or give RULE-32 a fallback.

## Codebase Grounding

The repository now holds `spec/` and `LICENSE`, and still has no source or build files, so the rules can't conflict with existing code. The toolchain is unchanged: Xcode 27.1, XcodeGen and the iOS 17.0 simulator runtime. The newly named APIs exist on iOS 17.0: `ModelContext.rollback()`, `OSSignposter` (iOS 15+), the `ProcessInfo` launch arguments behind `#if DEBUG`, and `DatePicker(in: from...)`. XcodeGen sets the `DEBUG` compilation condition only for the Debug configuration, so RULE-38's Release exclusion holds. Scheme launch arguments for `-SeedPoints 3000` can be declared in `project.yml`.

## EARS ↔ Test Strategy

Every pattern now has a fitting test approach:

| Pattern | How it's tested |
|---|---|
| Ubiquitous, boundary triples (20 m, 0.01°, 12 characters, day edges, From/To) | Pure `Core` unit tests |
| Unwanted behaviours: storage failures (AC-32, AC-48, AC-52) | Injected throwing save, with the store state asserted afterwards |
| Unwanted behaviour: export write failure (AC-102) | Injected throwing write |
| What the alerts look like on screen | `-FailSaves` and `-FailExportWrite` on the manual checklist |
| Event-driven, state-driven and combined criteria about map, GPS and sheets | Manual checklist on the iOS 17.0 simulator with a simulated location |
| AC-107 performance | Signposts plus `-SeedPoints 3000` |

The "and not" halves are checked:
- AC-25 and AC-83: no substitute altitude, checked by a writer test.
- AC-30: cancelling stores nothing, checked by hand.
- AC-32: nothing partial is stored, checked by asserting the store after the injected failure.
- AC-110: no backwards range, checked with `CustomRange`.

## Risk Hotspots

1. **Map performance with many pins.** A SwiftUI `Map` builds one view per `Annotation`. Mitigation: run `-SeedPoints 3000` and the AC-107 measurement as soon as pins render, before building the sheets. If it's slow, draw only points in the visible region.
2. **Date pickers carry a time of day.** `DatePicker` returns a full `Date`. If From holds 15:00 and the To picker uses `in: from...`, the same day picked as To can be clamped or rejected depending on its time part. Mitigation: `CustomRange` stores both dates as `calendar.startOfDay` and the pickers show `.date` components only. Add a unit test where From and To are the same day with different times.
3. **Location delegate under MainActor-default isolation.** `CLLocationManagerDelegate` needs an isolated conformance or nonisolated methods that hop to the main actor. Mitigation: create `CLLocationManager` on the main thread and build this file first.
4. **SwiftData rollback on iOS 17.0.** RULE-9 now depends on `rollback()`, and early iOS 17 releases didn't always refresh `@Query` results after a rollback. Mitigation: run the `Persistence` tests and the `-FailSaves` checklist on the 17.0 simulator, and confirm the deleted or edited pin reappears unchanged.
5. **Export order vs query order.** `@Query` sorts newest first, and files must list oldest first (AC-79). Mitigation: the `Core` writers sort by `createdAt` ascending themselves. Test this with shuffled input.
