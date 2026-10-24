# Field Measures — iOS App Proposal

Source: https://claude.ai/artifact/ExAxsu77mrAJRruftPQpg9 (as of 2026-10-24)

## Summary

A one-screen iPhone app for logging field measurements (lux, dB, etc.) at your current GPS position, with a short text note per point. Points live on the device only, show on the map with the start of their note as a label, and export as GPX or CSV filtered by date.

Target size: about 6 Swift files, no backend, no accounts, no third-party libraries.

## Features

| # | Feature | Behaviour |
| --- | --- | --- |
| F1 | Map | Full-screen Apple Map, follows your position, standard / satellite toggle |
| F2 | Add point | "+" button opens a sheet with the current coordinates and GPS accuracy (m); you type a description (e.g. `320 lx` or `68 dB, traffic`) and tap Save |
| F3 | Local storage | Every point is saved on the device with coordinates, altitude, accuracy, timestamp and description; survives app restarts |
| F4 | Map labels | Each point is a pin with the first ~12 characters of its description under it; tap a pin for the full text, date, and Edit / Delete |
| F5 | Show filter | One filter for the map: All, Today, Last 7 days, or a custom From–To date range |
| F6 | List | A simple list of the filtered points, newest first, swipe to delete, tap to centre the map on it |
| F7 | Export | Exports the currently filtered points as GPX (default) or CSV through the iOS share sheet (Files, Mail, AirDrop) |

The map and export share the same filter, so what you see is what you export.

## Screens

One map screen; everything else is a sheet over it:

- Map screen — full screen, follows your position, pins labelled with first 12 chars, toolbar: +, filter, list, export, standard / satellite toggle
- Add point sheet (tap +) — coordinates, accuracy, description field, Save
- Point detail (tap pin) — full description, date and time, Edit, Delete
- Filter and list (filter) — All, Today, 7 days, custom range; point list
- Export (export) — GPX or CSV of filtered points, iOS share sheet

Adding a point takes two taps and the description: tap +, type, Save. Every sheet closes back to the map.

## Data model and storage

One SwiftData model, stored in the app's private container on the device.

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Stable key, used in exports |
| createdAt | Date | Set on save; used by all filters |
| latitude, longitude | Double | WGS84, from Core Location |
| altitude | Double? | Metres, if available |
| accuracy | Double | Horizontal accuracy, metres |
| text | String | Your description, free text |

The description stays free text, so any measure type works without setup. Data is included in the normal iPhone backup.

## Export format

GPX 1.1 waypoints: the description goes into `<desc>`, its first characters into `<name>`, and the timestamp into `<time>` (UTC).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="FieldMeasures" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="52.520008" lon="13.404954">
    <ele>34.2</ele>
    <time>2026-10-24T09:15:02Z</time>
    <name>320 lx, nort</name>
    <desc>320 lx, north entrance, overcast</desc>
  </wpt>
</gpx>
```

CSV, for spreadsheets, has the same fields:

```csv
created_at,latitude,longitude,altitude_m,accuracy_m,description
2026-10-24T09:15:02Z,52.520008,13.404954,34.2,5,"320 lx, north entrance, overcast"
```

File name: `measures_<from>_<to>.gpx`, e.g. `measures_2026-10-01_2026-10-24.gpx`.

## Technical approach

Native Swift app on Apple frameworks only, iOS 17 or later.

| Concern | Choice |
| --- | --- |
| UI | SwiftUI |
| Map, pins, labels | MapKit for SwiftUI (`Map`, `Annotation`, `UserAnnotation`) |
| Position | Core Location, "When In Use" permission only, best accuracy while the add sheet is open |
| Storage | SwiftData |
| Export | Generated GPX/CSV string, shared with `ShareLink` |

Files: `FieldMeasuresApp.swift`, `Measure.swift`, `LocationManager.swift`, `MapScreen.swift`, `AddMeasureSheet.swift`, `Exporter.swift`.

The only Info.plist entry is `NSLocationWhenInUseUsageDescription`. No network access.

## Scope and milestones

Out of scope for v1: accounts, cloud sync, reading sensors (lux meter, microphone), photos, import, iPad layout.

Possible later: a separate numeric value + unit field, auto-reading noise from the microphone, KML export, iCloud sync, dragging a pin to correct its position, projects or sessions.

1. Map with your position, add point with description, local saving
2. Pin labels, detail view with edit and delete, list
3. Date filter for map and list
4. GPX and CSV export through the share sheet
5. Test in the field, install on your iPhone via Xcode

## Decisions

| Question | Decision |
| --- | --- |
| Free text or number + unit? | Free text only for v1 |
| Drag a pin to correct its position? | Not now, maybe later |
| Projects or sessions besides the date filter? | Not now, maybe later |
| Minimum iOS version | iOS 17+ |
| Distribution | Install via Xcode on your own iPhone for v1 |
