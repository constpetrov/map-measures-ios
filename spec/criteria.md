# Acceptance Criteria: Field Measures

## Functional

### Location permission and map

### AC-1: Permission request on first launch
**Covers:** B-1

When the app launches and location permission has not been determined, the app shall request "When In Use" location permission.

### AC-2: No repeated permission request
**Covers:** B-1

If the app launches and location permission has already been granted or denied, then the app shall not show the system permission request.

### AC-3: Map follows user
**Covers:** B-2, Resolved ambiguities, "Map camera at launch"

While location permission is granted, when the first position fix arrives after launch, the app shall centre the map on the user's position.

### AC-4: Recentre on user
**Covers:** B-3

When the user requests to recentre on their position, the app shall centre the map on the user's current position.

### AC-5: Map style toggle
**Covers:** B-4

When the user toggles the map style, the app shall switch the map between standard and satellite imagery.

### AC-6: Map style persists
**Covers:** B-4

When the app is relaunched, the app shall show the map in the style that was last selected.

### AC-7: Add disabled without location access
**Covers:** B-5, Handled edge cases E-2

While location permission is denied or restricted, or Location Services are off, the app shall disable the add-point action.

### AC-8: Location-off banner
**Covers:** B-5

While location permission is denied or restricted, or Location Services are off, the app shall show a "Location access is off" message with an action that opens the app's page in iOS Settings.

### AC-9: Points visible without location access
**Covers:** Handled edge cases E-2, "map still shows existing points"

While location permission is denied or restricted, the app shall display the stored points that match the active filter.

### AC-10: Access granted later
**Covers:** B-5

While location access is off, when the user grants location permission and returns to the app, the app shall enable the add-point action and hide the "Location access is off" message.

### Add point

### AC-11: Open add sheet
**Covers:** B-6

While location access is granted, when the user invokes the add-point action, the app shall present the add-point form.

### AC-12: Live coordinates
**Covers:** B-7

While the add-point form is open and a position fix is available, the app shall display the latest fix's latitude, longitude and horizontal accuracy in metres.

### AC-13: Live update
**Covers:** B-7

While the add-point form is open, when a new position fix arrives, the app shall replace the displayed latitude, longitude and accuracy with the new fix's values.

### AC-14: No fix yet
**Covers:** B-8, Handled edge cases E-3

While the add-point form is open and no position fix is available, the app shall show "Waiting for GPS…" in place of coordinates.

### AC-15: Save blocked without fix
**Covers:** B-8

While the add-point form is open and no position fix is available, the app shall disable Save.

### AC-16: Accuracy within threshold
**Covers:** B-9

While the add-point form shows a fix with horizontal accuracy of 15 m, the app shall show no low-accuracy warning.

### AC-17: Accuracy at threshold
**Covers:** B-9

While the add-point form shows a fix with horizontal accuracy of exactly 20 m, the app shall show no low-accuracy warning.

### AC-18: Accuracy beyond threshold
**Covers:** B-9, Handled edge cases E-4

While the add-point form shows a fix with horizontal accuracy of 21 m, the app shall show a warning reading "Low accuracy (±21 m)".

### AC-19: Weak fix still saveable
**Covers:** B-9

While the add-point form shows a fix with horizontal accuracy worse than 20 m and a non-empty description, the app shall keep Save enabled.

### AC-20: Empty description
**Covers:** B-10, Handled edge cases E-6

While the add-point description is empty, the app shall disable Save.

### AC-21: Whitespace-only description
**Covers:** B-10, Handled edge cases E-6

While the add-point description contains only spaces, tabs or newlines, the app shall disable Save.

### AC-22: One-character description
**Covers:** B-10

While a position fix is available and the add-point description contains one non-whitespace character, the app shall enable Save.

### AC-23: Saved coordinates
**Covers:** B-11, Resolved ambiguities R-2

When the user saves a new point, the app shall store the latitude, longitude and horizontal accuracy of the latest fix received before the save.

### AC-24: Saved altitude
**Covers:** B-11

When the user saves a new point and the latest fix has a valid vertical accuracy, the app shall store that fix's altitude with the point.

### AC-25: Missing altitude
**Covers:** B-11, Resolved ambiguities R-21

If the user saves a new point and the latest fix has an invalid (negative) vertical accuracy, then the app shall store the point with no altitude and not store a substitute value.

### AC-26: Saved description
**Covers:** B-11, Handled edge cases E-7

When the user saves a new point, the app shall store the description exactly as entered, including line breaks.

### AC-27: Creation time
**Covers:** B-11, Resolved ambiguities R-10

When the user saves a new point, the app shall record the device time of the save as the point's creation time.

### AC-28: Unique identifier
**Covers:** B-11

When the user saves a new point, the app shall assign it an identifier that differs from every other stored point's identifier.

### AC-29: New point on map
**Covers:** B-11, B-15

When the user saves a new point that matches the active filter, the app shall close the add-point form and show the new point's pin on the map.

### AC-30: Cancel add
**Covers:** B-12, Handled edge cases E-5

When the user cancels the add-point form, the app shall close the form and not store a point.

### AC-31: Persistence across restart
**Covers:** B-13

When the app is terminated and relaunched, the app shall display every point that was saved before termination, with unchanged description, position, accuracy, altitude and creation time.

### AC-32: Add save failure
**Covers:** B-14, Handled edge cases E-14

If storing a new point fails, then the app shall show a "Could not save point" alert, keep the add-point form open with the typed description, and not store a partial point.

### Map pins and labels

### AC-33: Pins for filtered points
**Covers:** B-15, B-23

The app shall display exactly one pin for each stored point that matches the active filter.

### AC-34: Hidden non-matching points
**Covers:** B-15, B-23, Handled edge cases E-11

If a stored point does not match the active filter, then the app shall not display its pin on the map.

### AC-35: Labels when zoomed in
**Covers:** B-16

While the map's visible latitude span is 0.005°, the app shall show each visible pin's label.

### AC-36: Labels at zoom threshold
**Covers:** B-16

While the map's visible latitude span is exactly 0.01°, the app shall show each visible pin's label.

### AC-37: No labels when zoomed out
**Covers:** B-16, Handled edge cases E-16

While the map's visible latitude span is 0.02°, the app shall show pins without labels.

### AC-38: Label under limit
**Covers:** B-16, Resolved ambiguities R-18

When a point's description has 11 characters, the app shall show the whole description as its label, with no ellipsis.

### AC-39: Label at limit
**Covers:** B-16

When a point's description has exactly 12 characters, the app shall show the whole description as its label, with no ellipsis.

### AC-40: Label over limit
**Covers:** B-16

When a point's description has 13 or more characters, the app shall show its first 12 characters followed by "…" as its label.

### AC-41: Label line breaks
**Covers:** B-16, Handled edge cases E-7

When a point's description contains line breaks, the app shall show each line break in its label as a single space.

### Point detail

### AC-42: Open detail
**Covers:** B-17, Resolved ambiguities R-23

When the user taps a pin, the app shall present that point's detail view showing its full description.

### AC-43: Detail date
**Covers:** B-17

When the app presents a point's detail view, it shall show the point's creation date and time in the device locale's medium date and short time format.

### AC-44: Edit description
**Covers:** B-18

When the user saves an edited description, the app shall store the new description for that point.

### AC-45: Edit keeps position and time
**Covers:** B-18, Resolved ambiguities R-15

When the user saves an edited description, the app shall leave the point's latitude, longitude, accuracy, altitude and creation time unchanged.

### AC-46: Edit empty description
**Covers:** B-18

While the edited description is empty or contains only whitespace, the app shall disable saving the edit.

### AC-47: Edit one-character description
**Covers:** B-18

While the edited description contains one non-whitespace character, the app shall enable saving the edit.

### AC-48: Edit save failure
**Covers:** B-36, Handled edge cases E-17

If storing an edited description fails, then the app shall show a "Could not save changes" alert, keep the previously stored description, and keep the typed text in the edit field.

### AC-49: Delete asks for confirmation
**Covers:** B-19, Resolved ambiguities R-16

When the user requests deletion from a point's detail view, the app shall ask for confirmation before deleting.

### AC-50: Delete cancelled
**Covers:** B-19

When the user declines the delete confirmation, the app shall keep the point stored and keep the detail view open.

### AC-51: Delete confirmed
**Covers:** B-19, Handled edge cases E-15

When the user confirms deletion from a point's detail view, the app shall remove the point from storage, remove its pin from the map, and close the detail view.

### AC-52: Delete failure
**Covers:** B-37, Handled edge cases E-18

If removing a point from storage fails, then the app shall show a "Could not delete point" alert and keep the point stored and displayed.

### Filter

### AC-53: Filter options
**Covers:** B-20

The app shall offer the filter options All, Today, Last 7 days and Custom with a From date and a To date.

### AC-54: Default filter
**Covers:** B-20, Resolved ambiguities R-14

When the app launches, the app shall set the active filter to All, regardless of the filter used in the previous session.

### AC-55: Filter All
**Covers:** B-21

While the active filter is All, the app shall treat every stored point as matching.

### AC-56: Today, inside
**Covers:** B-21, Resolved ambiguities R-12

While the active filter is Today, the app shall treat a point created at 00:00:00 local time today as matching.

### AC-57: Today, boundary
**Covers:** B-21

While the active filter is Today, the app shall treat a point created at 23:59:59 local time yesterday as not matching.

### AC-58: Last 7 days, inside
**Covers:** B-21

While the active filter is Last 7 days, the app shall treat a point created at 00:00:00 local time six days before today as matching.

### AC-59: Last 7 days, boundary
**Covers:** B-21

While the active filter is Last 7 days, the app shall treat a point created at 23:59:59 local time seven days before today as not matching.

### AC-60: Custom, From day inclusive
**Covers:** B-21

While the active filter is Custom, the app shall treat a point created at 00:00:00 local time on the From date as matching.

### AC-61: Custom, To day inclusive
**Covers:** B-21

While the active filter is Custom, the app shall treat a point created at 23:59:59 local time on the To date as matching.

### AC-62: Custom, before From
**Covers:** B-21

While the active filter is Custom, the app shall treat a point created at 23:59:59 local time on the day before the From date as not matching.

### AC-63: Custom, after To
**Covers:** B-21

While the active filter is Custom, the app shall treat a point created at 00:00:00 local time on the day after the To date as not matching.

### AC-64: Custom single day
**Covers:** B-21, B-22

While the active filter is Custom with From and To set to the same date, the app shall treat every point created on that local date as matching.

### AC-65: To not before From
**Covers:** B-22, Resolved ambiguities R-13

If the user tries to set the Custom To date earlier than the From date, then the app shall not accept that To date.

### AC-108: From moved, still before To
**Covers:** B-39, Resolved ambiguities R-13

While the active filter is Custom, when the user moves the From date to a date one day before the current To date, the app shall keep the To date unchanged.

### AC-109: From moved onto To
**Covers:** B-39

While the active filter is Custom, when the user moves the From date to the same date as the current To date, the app shall keep the To date unchanged.

### AC-110: From moved past To
**Covers:** B-39, Handled edge cases E-20

If the user moves the Custom From date to a date after the current To date, then the app shall set the To date equal to the new From date and not apply a range whose end is before its start.

### AC-66: Filter change applies everywhere
**Covers:** B-23

When the active filter changes, the app shall apply the new filter to the map pins, the list and the next export.

### AC-67: Camera fixed on filter change
**Covers:** B-24, Resolved ambiguities R-7

When the active filter changes, the app shall keep the map's centre and zoom unchanged.

### AC-68: Filter indicator active
**Covers:** B-25, Handled edge cases E-11

While the active filter is Today, Last 7 days or Custom, the app shall show the filter control in its active state.

### AC-69: Filter indicator inactive
**Covers:** B-25

While the active filter is All, the app shall show the filter control in its inactive state.

### List

### AC-70: List order
**Covers:** B-26, B-23

When the user opens the list, the app shall show the points that match the active filter, newest creation time first.

### AC-71: List row content
**Covers:** B-26

The app shall show each list row with the point's description and its creation date and time.

### AC-72: Swipe delete
**Covers:** B-27, Resolved ambiguities R-16

When the user swipes to delete a list row, the app shall remove the point from storage and from the map without asking for confirmation.

### AC-73: Row tap centres map
**Covers:** B-28

When the user taps a list row, the app shall close the list and centre the map on that point.

### AC-74: Empty list
**Covers:** B-29, Handled edge cases E-10

While no stored point matches the active filter, the app shall show "No points for this filter" in the list.

### Export

### AC-75: Export disabled when empty
**Covers:** B-29, Handled edge cases E-10

While no stored point matches the active filter, the app shall disable the export action.

### AC-76: Format choice
**Covers:** B-30

When the user opens export, the app shall offer GPX and CSV formats, with GPX preselected.

### AC-77: Share sheet
**Covers:** B-30

When the user confirms an export, the app shall present the iOS share sheet with one file containing the points that match the active filter in the chosen format.

### AC-78: Export contains only filtered points
**Covers:** B-23, B-30

If a stored point does not match the active filter, then the app shall not include it in the exported file.

### AC-79: Export order
**Covers:** B-35, Resolved ambiguities R-25

When the app writes an export file, it shall list the points in order of creation time, oldest first.

### AC-80: GPX structure
**Covers:** B-31

When the user exports as GPX, the app shall produce a document that validates against the GPX 1.1 schema, with one waypoint per exported point at that point's latitude and longitude.

### AC-81: GPX time
**Covers:** B-31

When the user exports as GPX, the app shall write each waypoint's time as the point's creation time in UTC ISO 8601 format ending in "Z".

### AC-82: GPX elevation present
**Covers:** B-31, B-33

When the user exports as GPX a point that has an altitude, the app shall write a waypoint elevation equal to that altitude rounded to 1 decimal.

### AC-83: GPX elevation absent
**Covers:** B-31, Resolved ambiguities R-21

If an exported point has no altitude, then the app shall omit the elevation element from its GPX waypoint and not write a substitute value.

### AC-84: GPX name under limit
**Covers:** B-31, Resolved ambiguities R-19

When the user exports as GPX a point whose description has 11 characters, the app shall write the whole description as the waypoint name.

### AC-85: GPX name at limit
**Covers:** B-31

When the user exports as GPX a point whose description has exactly 12 characters, the app shall write the whole description as the waypoint name.

### AC-86: GPX name over limit
**Covers:** B-31

When the user exports as GPX a point whose description has 13 or more characters, the app shall write its first 12 characters, with no ellipsis, as the waypoint name.

### AC-87: GPX name line breaks
**Covers:** B-31, Handled edge cases E-7

When the user exports as GPX a point whose description's first 12 characters contain line breaks, the app shall write each line break in the waypoint name as a single space.

### AC-88: GPX description
**Covers:** B-31

When the user exports as GPX, the app shall write each point's full description as the waypoint description.

### AC-89: GPX escaping
**Covers:** B-31, Handled edge cases E-8

When the user exports as GPX a point whose description contains `&`, `<`, `>`, `"` or `'`, the app shall produce well-formed XML that a GPX reader decodes back to the original description.

### AC-90: CSV header
**Covers:** B-32

When the user exports as CSV, the app shall write the first line, after the byte-order mark, as `created_at_utc,created_at_local,latitude,longitude,altitude_m,accuracy_m,description`.

### AC-111: CSV byte-order mark
**Covers:** B-40, Resolved ambiguities R-26

When the user exports as CSV, the app shall write the bytes EF BB BF as the first three bytes of the file.

### AC-91: CSV rows
**Covers:** B-32

When the user exports as CSV, the app shall write one comma-separated UTF-8 row per exported point after the header.

### AC-92: CSV UTC time
**Covers:** B-32, Resolved ambiguities R-6

When the user exports as CSV, the app shall write `created_at_utc` as ISO 8601 in UTC ending in "Z".

### AC-93: CSV local time
**Covers:** B-32, Resolved ambiguities R-6, Handled edge cases E-13

When the user exports as CSV, the app shall write `created_at_local` as ISO 8601 in the device's current time zone at export time, including its UTC offset.

### AC-94: CSV quoting
**Covers:** B-32, Handled edge cases E-9

When the user exports as CSV a description that contains a comma, double quote or line break, the app shall enclose the field in double quotes and double each inner double quote.

### AC-95: CSV round-trip
**Covers:** B-32, Handled edge cases E-9

When the user exports as CSV, the app shall produce a file from which an RFC 4180 compliant reader, after skipping the byte-order mark, returns each description identical to the stored description.

### AC-96: Coordinate precision
**Covers:** B-33, Resolved ambiguities R-20

When the app writes an export file, it shall format latitude and longitude with exactly 6 decimal places.

### AC-97: Accuracy precision
**Covers:** B-33

When the user exports as CSV, the app shall write `accuracy_m` rounded to a whole number of metres.

### AC-98: CSV altitude
**Covers:** B-33, Resolved ambiguities R-21

When the user exports as CSV, the app shall write `altitude_m` with 1 decimal place, or an empty field when the point has no altitude.

### AC-99: Locale-independent numbers
**Covers:** B-33

While the device region uses a comma as decimal separator, when the app writes an export file, it shall write every number with a dot as decimal separator.

### AC-100: File name, date range
**Covers:** B-34, Resolved ambiguities R-17

When the exported points span more than one local date, the app shall name the file `measures_<earliest>_<latest>.<ext>`, with both dates in `yyyy-MM-dd` format and `<ext>` set to `gpx` or `csv`.

### AC-101: File name, single date
**Covers:** B-34

When all exported points share one local date, the app shall name the file `measures_<date>.<ext>`.

### AC-102: Export write failure
**Covers:** B-38, Handled edge cases E-19

If the export file cannot be written, then the app shall show a "Could not create export file" alert and not present the share sheet.

## Non-functional

### AC-103: No network access
**Covers:** Feature summary, "no network"; Out of scope, "any network access"

The app shall not make any network request other than the map tile and imagery requests made by the system map.

### AC-104: Foreground-only location
**Covers:** Explicit assumptions A-1, A-2

While the app is in the background, the app shall not receive location updates.

### AC-105: Platform compatibility
**Covers:** Resolved ambiguities R-9

The app shall install and run on an iPhone or iPhone simulator with iOS 17.0.

### AC-106: Location permission text
**Covers:** Explicit assumptions A-2

When iOS shows the location permission request, the app shall supply a usage description explaining that location is used to place measurement points.

### AC-107: Scale
**Covers:** Explicit assumptions A-5

While 3,000 points spread evenly over the last 30 days are stored and the app runs on the iOS 17.0 iPhone simulator on the development Mac, when the user changes the active filter from All to Last 7 days, the app shall show the new set of pins on the map and rows in the list within 1 second, measured from the filter selection to the last of the two updates.

## Coverage exclusions

- Accessibility (VoiceOver labels, Dynamic Type): not in the spec. The app uses standard SwiftUI controls with their default accessibility, and no specific requirement is set.
- Localization: English only (A-3).
- Security, authentication: no accounts, no network and no sensitive data beyond location stored in the app sandbox (A-6). Nothing is authorization-relevant, so there are no negative authz criteria.
- Backup and restore: the default iOS backup applies (A-6). The app adds no behaviour of its own.
- Dark mode, orientation, iPad: system defaults, or out of scope (A-4, A-7).
- Battery or energy use: foreground-only location (AC-104) is the only constraint the spec sets.
