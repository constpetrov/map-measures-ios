# Field Measures

A minimal iPhone app for logging field measurements (light, noise, …) as points on a map, stored on the device and exported as GPX or CSV.

Requirements: Xcode 26 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen), iOS 17.0+.

## Setup

```sh
xcodegen generate
open FieldMeasures.xcodeproj
```

The `.xcodeproj` is generated from `project.yml` and is not committed. Run `xcodegen generate` again after changing `project.yml` or adding files.

## Installing on your iPhone

1. `cp Local.xcconfig.example Local.xcconfig`
2. Set `DEVELOPMENT_TEAM` to your Apple team ID and `BUNDLE_ID_PREFIX` to something unique (e.g. `com.yourname`).
3. `xcodegen generate`, then select your iPhone in Xcode and Run.

The simulator builds without `Local.xcconfig`.

## Tests

```sh
xcodebuild test -project FieldMeasures.xcodeproj -scheme FieldMeasures \
  -destination 'platform=iOS Simulator,OS=17.0,name=iPhone 15 Pro'
```

## Debug launch flags

Debug builds read these launch arguments (Product › Scheme › Edit Scheme › Run › Arguments; they are listed there, unticked). None of them exist in Release builds.

| Flag | Effect |
|---|---|
| `-FailSaves` | Every save fails, to check the "Could not save…" and "Could not delete point" alerts |
| `-FailExportWrite` | Writing the export file fails, to check the "Could not create export file" alert |
| `-SeedPoints 3000` | Fills an empty store with 3,000 points over the last 30 days near `-SeedCenter` (default Berlin) |

## App icon

`FieldMeasures/AppIcon.icon` is an Icon Composer document (open it in Xcode › Open Developer Tool › Icon Composer). It has three layers (map, marker, plus) over a gradient fill, with a dark background and a quieter map for dark mode. iOS 26+ renders it as Liquid Glass in all appearances, and Xcode generates flat images for iOS 17–25. `docs/app-icon-renditions.png` shows every appearance. To re-render it:

```sh
ictool FieldMeasures/AppIcon.icon --export-image --output-file Dark.png --platform iOS --rendition Dark \
  --width 1024 --height 1024 --scale 1
```

(`ictool` is in `Icon Composer.app/Contents/Executables/`; renditions: Default, Dark, ClearLight, ClearDark, TintedLight, TintedDark.)
