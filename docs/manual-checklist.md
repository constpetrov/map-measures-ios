# Manual Checklist: Field Measures

Covers every acceptance criterion (spec/criteria.md) that the unit tests don't prove on their own. Run it on the iOS 17.0 simulator unless a row says otherwise. Each result line gives the date and where the check ran.

**Status: 43 PASS, 6 YOURS (open).** The open rows need you: either a mouse in the iOS 17.0 simulator (UI automation can't reach that runtime), or a real iPhone.

## Setup

```sh
xcodegen generate
xcodebuild build -project FieldMeasures.xcodeproj -scheme FieldMeasures \
  -destination 'platform=iOS Simulator,OS=17.0,name=iPhone 15 Pro'
SIM=<iOS 17.0 simulator id>          # xcrun simctl list devices 'iOS 17.0'
APP=$(find ~/Library/Developer/Xcode/DerivedData/FieldMeasures-*/Build/Products/Debug-iphonesimulator -name FieldMeasures.app -maxdepth 1)
xcrun simctl install $SIM "$APP"
xcrun simctl location $SIM set 52.520008,13.404954   # a fixed position (Berlin)
```

Launch with flags, for example: `xcrun simctl launch $SIM com.example.FieldMeasures -SeedPoints 40`. The debug flags (`-FailSaves`, `-FailExportWrite`, `-SeedPoints <n>`, `-SeedCenter <lat>,<lon>`) also appear, unticked, in Xcode under Scheme › Run › Arguments.

To read the store: `sqlite3 "$(xcrun simctl get_app_container $SIM com.example.FieldMeasures data)/Library/Application Support/default.store" 'select ZTEXT, ZCREATEDAT from ZMEASURE'`

## Location and map

| AC | Check | Steps | Result |
|---|---|---|---|
| AC-1 | Permission prompt on first launch | `xcrun simctl privacy $SIM reset location com.example.FieldMeasures`, launch | PASS 2026-10-24, iOS 17.0: prompt shows the usage text |
| AC-2 | No prompt once decided | Grant, reboot the simulator (a stale alert survives terminate), launch | PASS 2026-10-24, iOS 17.0 |
| AC-106 | Usage text | Read the prompt | PASS 2026-10-24, iOS 17.0: "Your location is used to place measurement points on the map." |
| AC-3 | Map follows position | Launch with location granted | PASS 2026-10-24, iOS 17.0 and 27 |
| AC-4 | Recentre button | Pan away, tap the location button (top right) | PASS 2026-10-24, iOS 27: tracking turns back on |
| AC-5, AC-6 | Style toggle persists | Tap the globe button, relaunch | PASS 2026-10-24, iOS 17.0: satellite after relaunch |
| AC-7, AC-8 | Location off: + disabled, banner | `xcrun simctl privacy $SIM revoke location com.example.FieldMeasures`, launch | PASS 2026-10-24, iOS 17.0 and 27 |
| AC-8 | Open Settings | Tap Open Settings in the banner | PASS 2026-10-24, iOS 27: the Settings app opens |
| AC-9 | Points shown without location | With location revoked and points stored, launch | PASS 2026-10-24, iOS 27: pins drawn |
| AC-10 | Access granted while running | With the banner showing, `simctl privacy … grant location` | PASS 2026-10-24, iOS 27: banner hides, + enabled |

## Add point

| AC | Check | Steps | Result |
|---|---|---|---|
| AC-11, AC-12, AC-13 | Sheet with live position | Tap +; change `simctl location` while it's open | PASS 2026-10-24, iOS 27: latitude, longitude and ±m shown and updated |
| AC-14, AC-15 | Waiting for GPS | Device, or Xcode › Debug › Simulate Location › None, then open + before any fix | **YOURS**: the simulator always had a cached fix; Save was seen disabled without coordinates once |
| AC-16–AC-19 | Low-accuracy warning | On a device, indoors, until accuracy is worse than 20 m: an orange "Low accuracy (±N m)" warning, Save still enabled | **YOURS**: the simulator always reports ±5 m. The 15/20/21 m boundary is covered by AccuracyRulesTests |
| AC-20, AC-21, AC-22 | Save enablement | Empty, spaces only, then text | PASS 2026-10-24, iOS 27 |
| AC-23–AC-27, AC-29 | Save stores and shows the point | Type text, Save; check the SQLite row and the pin | PASS 2026-10-24, iOS 27 |
| AC-30 | Cancel stores nothing | Type, Cancel; the row count is unchanged | PASS 2026-10-24, iOS 27 |
| AC-31 | Survives relaunch | Terminate, launch | PASS 2026-10-24, iOS 27 (and PersistenceTests on 17.0) |
| AC-32 | Save failure | Launch with `-FailSaves`, add a point | PASS 2026-10-24, iOS 27: "Could not save point", sheet and text kept, no row, no stray pin |

## Pins, detail, edit, delete

| AC | Check | Steps | Result |
|---|---|---|---|
| AC-33, AC-34 | One pin per filtered point | `-SeedPoints 40`; compare the pin count with the filter count | PASS 2026-10-24, iOS 27: 7 Days shows 10 list rows and 10 pins |
| AC-35, AC-36, AC-37 | Labels only when zoomed in | Pinch to street level (about 1 km tall): 12-character labels under the pins. Zoom out to city level: no labels | **YOURS**: UI automation can't pinch or double-tap zoom. The threshold is covered by PointLabelTests |
| AC-42, AC-43 | Pin tap opens detail | Tap a pin | PASS 2026-10-24, iOS 27: full text, date and time, position, accuracy, altitude |
| AC-44, AC-45 | Edit saves the text only | Edit, type, Save; check SQLite | PASS 2026-10-24, iOS 27: text changed, createdAt and position unchanged |
| AC-46, AC-47 | Edit validation | Clear the field | PASS 2026-10-24, iOS 27: Save disabled |
| AC-48 | Edit failure | `-FailSaves`, Edit, type, Save | PASS 2026-10-24, iOS 27: "Could not save changes", stored text unchanged, draft kept |
| AC-49, AC-50 | Delete asks; declining keeps the point | Delete Point, then tap outside the popover | PASS 2026-10-24, iOS 27 |
| AC-51 | Confirmed delete | Delete Point › Delete | PASS 2026-10-24, iOS 27: row, pin and sheet gone |
| AC-52 | Delete failure | `-FailSaves`, delete, terminate; check SQLite | PASS 2026-10-24, iOS 27: "Could not delete point", row still there after termination |

## Filter and list

| AC | Check | Steps | Result |
|---|---|---|---|
| AC-53, AC-54 | Options; All on launch | Open Filter and list; relaunch | PASS 2026-10-24, iOS 27 |
| AC-66 | Filter applies to map, list, export | Today: list, pins and export each show the same points | PASS 2026-10-24, iOS 27: Today exported exactly the 1 listed point |
| AC-67 | Camera fixed on filter change | Change the filter; the camera stays in tracking | PASS 2026-10-24, iOS 27 |
| AC-68, AC-69 | Filter icon state | Today: filled. All: outline | PASS 2026-10-24, iOS 27 (accessibility value "Filter active" / "All points") |
| AC-108–AC-110 | From past To | Custom, set From to a later day | PASS 2026-10-24, iOS 27: To followed to 29 Oct |
| AC-70, AC-71 | List order and rows | Open the list | PASS 2026-10-24, iOS 27: newest first, text and date |
| AC-72 | Swipe delete | Swipe a row › Delete | PASS 2026-10-24, iOS 27: no dialog, row removed |
| AC-73 | Row tap centres | Tap a row | PASS 2026-10-24, iOS 27: sheet closes, map centred on the point, same zoom |
| AC-74 | Empty message | Custom range with no points | PASS 2026-10-24, iOS 27: "No points for this filter" |

## Export

| AC | Check | Steps | Result |
|---|---|---|---|
| AC-75 | Disabled when empty | Empty custom range | PASS 2026-10-24, iOS 27 |
| AC-76, AC-77 | Format and share sheet | Export: GPX preselected; Export opens the share sheet with the file | PASS 2026-10-24, iOS 27 |
| AC-78 | Only filtered points | Today filter, export, read the file in the app's `tmp/` folder | PASS 2026-10-24, iOS 27 |
| AC-111, AC-90–AC-93 | CSV bytes | Export CSV, `xxd` the file | PASS 2026-10-24, iOS 27: EF BB BF, header, CRLF, UTC and +02:00 times |
| AC-80, AC-89 | GPX schema | `curl -O https://www.topografix.com/GPX/1/1/gpx.xsd` to a scratch folder; `xmllint --noout --schema gpx.xsd <file>` on the unit-test sample (path printed as "GPX sample:" in the test log) and on a real export | PASS 2026-10-24: sample (iOS 17.0 tests) and a 40-waypoint export (iOS 27) both validate |
| AC-100 | File name range | Export All | PASS 2026-10-24, iOS 27: `measures_2026-09-25_2026-10-24.gpx` |
| AC-102 | Write failure | `-FailExportWrite`, Export | PASS 2026-10-24, iOS 27: "Could not create export file", no share sheet |

## Non-functional

| AC | Check | Steps | Result |
|---|---|---|---|
| AC-103 | No networking | `grep -rnE 'URLSession\|import Network\|NWConnection\|URLRequest' FieldMeasures` | PASS 2026-10-24: no matches |
| AC-104 | Foreground-only location | `grep -rnE 'allowsBackgroundLocationUpdates\|UIBackgroundModes\|requestAlwaysAuthorization' FieldMeasures project.yml`; built Info.plist has no `UIBackgroundModes` | PASS 2026-10-24 |
| AC-105 | Runs on iOS 17.0 | Build, install, launch on the iOS 17.0 simulator | PASS 2026-10-24 |
| AC-107 | Filter change ≤ 1 s with 3,000 points | See the procedure below | **YOURS** |
| — | iOS 17.0 tap-through | On the iOS 17.0 simulator with the mouse: add a point, edit it, delete it, switch filters, export GPX and CSV | **YOURS**: automation taps don't reach iOS 17.0. Storage behaviour is covered there by PersistenceTests |
| — | Device install | `cp Local.xcconfig.example Local.xcconfig`, set your team, `xcodegen generate`, run on your iPhone | **YOURS** |

### AC-107 timing procedure

UI automation tools act as an accessibility client. With 3,000 markers on screen, MapKit's accessibility tree takes over the CPU, so this must be done by hand, without VoiceOver or Accessibility Inspector running.

1. Delete the app from the iOS 17.0 simulator, install it, launch with `-SeedPoints 3000`.
2. Open Instruments › Blank, add **Points of Interest** (or the **os_signpost** instrument), target FieldMeasures on the simulator, and start recording.
3. In the app, open Filter and list, choose **7 Days**.
4. Stop recording. Read the **FilterChange** interval duration (subsystem `com.example.FieldMeasures`). Pass if it is under 1 s.

For reference, with 40 points on iOS 27 the interval measured 25 ms (2026-10-24).
