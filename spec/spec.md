# Field Measures — Spec

Source: `spec/proposal.md`

## Feature summary

Field Measures is a minimal native iPhone app (SwiftUI, MapKit, Core Location, SwiftData, iOS 17+, no third-party code, no network) for logging field measurements such as light or noise levels. The user taps "+" on a full-screen map, types a free-text description, and saves a point at their current GPS position. Points are stored only on the device, shown as pins with a short label, and listed, edited and deleted through sheets over the map. One date filter (All, Today, Last 7 days, custom range) controls which points appear on the map and in the list, and which points are exported. Filtered points export as GPX 1.1 or CSV through the iOS share sheet. The app is installed on the user's own iPhone through Xcode.

## Resolved ambiguities

| # | Question | Decision | Rationale |
|---|---|---|---|
| R-1 | Description: free text or number + unit? | Free text only | User decision |
| R-2 | Which position is saved? | The add sheet shows a live fix that updates while it is open; Save stores the latest fix at the moment of tapping | User decision; first fixes are often inaccurate |
| R-3 | Weak GPS | Accuracy worse than 20 m shows an orange warning, and Save stays enabled. Save is disabled only when there is no fix | User decision; never block work indoors |
| R-4 | Overlapping labels | Pins always show. Labels show only when the map's visible latitude span is ≤ 0.01° (about 1 km). No clustering | User decision |
| R-5 | CSV dialect | RFC 4180: comma separator, dot decimals, UTF-8 with byte-order mark (R-26), header row | User decision |
| R-6 | CSV timestamps | Two columns: `created_at_utc` (ISO 8601, `Z`) and `created_at_local` (ISO 8601 with offset) | User decision |
| R-7 | Camera on filter change | The camera does not move on a filter change. A user-location button recentres on the user, and tapping a list row centres on that point | User decision |
| R-8 | Pin drag, projects or sessions | Not in v1 | User decision |
| R-9 | Distribution | Xcode install only, iOS 17+ | User decision |
| R-10 | `createdAt` | The device time at the moment Save is tapped, not the fix timestamp | Matches "date of creation" in the filter |
| R-11 | Empty description | Save is disabled while the trimmed description is empty | Every point must carry a measurement |
| R-12 | Filter day boundaries | Local device calendar. Today = from the start of today. Last 7 days = from the start of the day 6 days ago (7 calendar days including today). Custom = from 00:00 on the From date to 23:59:59 on the To date, inclusive | Matches how a person reads dates |
| R-13 | Custom range order | The To picker cannot select a date before From. When From is moved to a date after the current To, To is set to the same date as From | Removes the invalid state; user decision (To follows From) |
| R-14 | Filter persistence | The filter is not persisted. Every launch starts on All | Avoids "where are my points" confusion |
| R-15 | What Edit changes | Description only. Position and `createdAt` never change | Pin drag is deferred (R-8) |
| R-16 | Delete confirmation | Delete from the detail sheet asks for confirmation. Swipe-to-delete in the list does not (the swipe is the confirmation) | iOS conventions |
| R-17 | Export file name | `measures_<first>_<last>.<gpx/csv>`, using the local dates (yyyy-MM-dd) of the earliest and latest exported points. One date only → `measures_<date>.<ext>` | Works for every filter, All included |
| R-18 | Label text | The first 12 characters of the description, with newlines replaced by spaces, plus "…" if it is longer | Proposal F4 |
| R-19 | GPX `<name>` | The first 12 characters of the description, with newlines replaced by spaces, and no ellipsis | Proposal export format |
| R-20 | Number formatting in exports | Lat/lon 6 decimals, altitude 1 decimal, accuracy rounded to whole metres. Always a dot decimal, whatever the locale | Exports must be machine-readable |
| R-21 | Missing altitude | GPX leaves out `<ele>` and the CSV cell is empty. Altitude is treated as missing when `verticalAccuracy < 0` | Never write fake zeros |
| R-22 | Map style | A toggle switches standard and satellite. The choice persists across launches (`@AppStorage`) | Field users usually keep one style |
| R-23 | Pin tap | Opens the point detail sheet | Proposal F4 |
| R-24 | Map camera at launch | Follows the user's position once a fix arrives | Proposal F1 |
| R-25 | Export order | Oldest first | GPX and CSV readers expect points in time order |
| R-26 | CSV byte-order mark | The CSV file starts with the UTF-8 byte-order mark (EF BB BF) | User decision; Excel reads non-Latin descriptions correctly |

## Explicit assumptions

- A-1 The app runs in the foreground only. It uses no background location and no background modes.
- A-2 Location permission is "When In Use", requested on first launch.
- A-3 The UI is English only and has no localization.
- A-4 Dark mode follows the system, with no custom theme.
- A-5 A dataset of up to a few thousand points needs no paging or performance work.
- A-6 Data lives in the default SwiftData store in the app container and is included in the normal iPhone backup. Deleting the app deletes the data.
- A-7 The app is iPhone only, uses the default orientation behaviour, and has no iPad layout.
- A-8 Display name "Field Measures". The bundle identifier is chosen when the Xcode project is created.
- A-9 Dates in the UI use the device locale's medium date + short time format.

## Handled edge cases

| # | Case | Behaviour |
|---|---|---|
| E-1 | Location permission not yet asked | The app requests "When In Use" on first launch |
| E-2 | Permission denied or restricted, or Location Services off | The map still shows existing points. "+" is disabled, and a banner "Location access is off" with an "Open Settings" button appears |
| E-3 | No fix yet in the add sheet | Coordinates show "Waiting for GPS…" and Save is disabled |
| E-4 | Fix accuracy > 20 m | An orange "Low accuracy (±N m)" warning shows, and Save stays enabled |
| E-5 | The user cancels the add sheet | Nothing is saved |
| E-6 | Description with only whitespace | Save disabled (R-11). Edit uses the same rule |
| E-7 | Multiline description | Stored as entered. Labels and GPX `<name>` replace newlines with spaces. CSV quotes the field |
| E-8 | Description with `& < > " '` | GPX escapes XML entities |
| E-9 | Description with commas, quotes or newlines | CSV quotes the field and doubles inner quotes (RFC 4180) |
| E-10 | The filter matches zero points | The map shows no pins, the list shows "No points for this filter", and Export is disabled |
| E-11 | A new point falls outside the active custom range | It is saved but stays hidden by the filter. The filter button shows an active (filled) state whenever the filter is not All |
| E-12 | Altitude unavailable | See R-21 |
| E-13 | The device time zone changes between points | Each point keeps an absolute instant. Filters and the local CSV column use the current device time zone at export time |
| E-14 | A save fails (SwiftData error) | An alert "Could not save point" appears and the sheet stays open with the text kept |
| E-15 | Deleting a point while its detail sheet is open | After confirmation the point is removed and the sheet closes |
| E-16 | Zoomed out beyond the label threshold | Pins only, no labels (R-4) |
| E-17 | Saving an edit fails | An alert "Could not save changes" appears, the stored description stays unchanged, and the detail sheet stays in edit mode with the typed text kept |
| E-18 | A delete fails (detail sheet or list swipe) | An alert "Could not delete point" appears and the point stays stored and visible |
| E-19 | Writing the export file fails | An alert "Could not create export file" appears and the share sheet does not open |
| E-20 | Custom From moved after the current To | To is set to the same date as From. The range is never inverted (R-13) |

## Behaviors to verify

1. **B-1** The system requests "When In Use" location permission on first launch when the status is not determined.
2. **B-2** The system shows a full-screen map that follows the user's position once a fix is available.
3. **B-3** The system offers a user-location button that recentres the map on the user.
4. **B-4** The system toggles the map between standard and satellite styles and keeps the choice across launches.
5. **B-5** The system disables "+" and shows a "Location access is off" banner with an "Open Settings" button when location permission is denied or restricted, or Location Services are off.
6. **B-6** The system opens the add sheet when the user taps "+".
7. **B-7** The system shows the latest latitude, longitude and horizontal accuracy in the add sheet, updating live while it is open.
8. **B-8** The system shows "Waiting for GPS…" and disables Save when the add sheet has no fix.
9. **B-9** The system shows an orange "Low accuracy (±N m)" warning, and keeps Save enabled, when the current fix accuracy is worse than 20 m.
10. **B-10** The system disables Save while the trimmed description is empty.
11. **B-11** The system saves a point with the latest fix's latitude, longitude, horizontal accuracy, altitude (nil when `verticalAccuracy < 0`), the description, a new UUID, and `createdAt` = the time of the tap, when the user taps Save.
12. **B-12** The system discards the input without saving when the user cancels the add sheet.
13. **B-13** The system keeps saved points across app restarts.
14. **B-14** The system shows an error alert and keeps the add sheet open with the text kept when a save fails.
15. **B-15** The system shows one pin per point that matches the active filter.
16. **B-16** The system shows a label under each pin, built from the first 12 characters of the description with newlines replaced by spaces and "…" added when longer, only when the visible latitude span is ≤ 0.01°.
17. **B-17** The system opens a detail sheet with the full description and the created date and time when the user taps a pin.
18. **B-18** The system lets the user edit only the description in the detail sheet, with Save disabled while the trimmed text is empty, and keeps the position and `createdAt` unchanged.
19. **B-19** The system deletes a point from the detail sheet only after the user confirms, then closes the sheet.
20. **B-20** The system offers filters All, Today, Last 7 days and Custom (From–To), defaulting to All on every launch.
21. **B-21** The system computes Today, Last 7 days and Custom bounds in the device's local calendar as defined in R-12, with Custom inclusive of both dates.
22. **B-22** The system prevents the Custom To date from being earlier than the From date.
23. **B-23** The system applies the active filter to the map pins, the list and the export alike.
24. **B-24** The system does not move the map camera when the filter changes.
25. **B-25** The system shows the filter button in an active (filled) state whenever the filter is not All.
26. **B-26** The system lists the filtered points newest first, each with its description and created date and time.
27. **B-27** The system deletes a point without confirmation when the user swipes to delete it in the list.
28. **B-28** The system closes the list and centres the map on a point when the user taps its row.
29. **B-29** The system shows "No points for this filter" in the list and disables Export when the filter matches zero points.
30. **B-30** The system lets the user choose GPX (default) or CSV and shares the filtered points as a file through the iOS share sheet.
31. **B-31** The system writes GPX 1.1 with one `<wpt lat lon>` per point, plus `<ele>` (only when altitude exists), `<time>` in UTC ISO 8601, `<name>` = the first 12 characters with newlines as spaces, and `<desc>` = the full description, XML-escaped.
32. **B-32** The system writes CSV with header `created_at_utc,created_at_local,latitude,longitude,altitude_m,accuracy_m,description`, comma-separated, dot decimals, UTF-8, with RFC 4180 quoting.
33. **B-33** The system formats exported lat/lon with 6 decimals, altitude with 1 decimal, and accuracy in whole metres, independent of device locale, leaving the altitude cell empty when altitude is missing.
34. **B-34** The system names the export file `measures_<earliest>_<latest>.<ext>` from the local dates of the exported points, or `measures_<date>.<ext>` when both dates are the same.
35. **B-35** The system orders exported points oldest first.
36. **B-36** The system shows an error alert, keeps the stored description unchanged and keeps the typed text in the edit field when saving an edit fails.
37. **B-37** The system shows an error alert and keeps the point stored and visible when a delete fails.
38. **B-38** The system shows an error alert and does not open the share sheet when the export file cannot be written.
39. **B-39** The system sets the Custom To date equal to the From date when the user moves From to a date after the current To.
40. **B-40** The system starts every CSV export file with the UTF-8 byte-order mark.

## Out of scope

- Separate numeric value + unit field, and colouring pins by level
- Dragging a pin to correct its position
- Projects or sessions
- Clustering pins
- Reading sensors (light meter, microphone)
- Photos, import, KML export
- iCloud sync, accounts, any network access
- iPad layout, localization
- TestFlight and App Store distribution
- Background location

## External dependencies

None.
