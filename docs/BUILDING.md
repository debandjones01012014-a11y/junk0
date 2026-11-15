# Building Junk0

## Requirements

- macOS 14 Sonoma or later
- Xcode, or the Xcode Command Line Tools (Swift 5.9 or later)

No Xcode project, package manager or third-party dependency is needed — the app is two Swift files compiled with `swiftc`.

## Build

```bash
./scripts/build.sh                 # build/Junk0.app (universal: arm64 + x86_64)
./scripts/build.sh --install       # also copy to ~/Applications/Junk0.app
./scripts/build.sh --zip           # also create build/Junk0-<version>.zip
```

The version comes from `CFBundleShortVersionString` in `Resources/Info.plist`.

The build is signed ad hoc (`codesign -s -`). That is enough to run it on your own Mac;
other people will need **System Settings → Privacy & Security → Open Anyway** until the app is notarized.

## Check what a scan finds without the UI

```bash
"build/Junk0.app/Contents/MacOS/Junk0" --scan-report
```

This prints each group, its size and whether it's locked by an open app. It never removes anything.

## Releasing

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. Add an entry to `CHANGELOG.md`.
3. `./scripts/build.sh --zip`
4. Create a GitHub Release tagged `v<version>` and attach `build/Junk0-<version>.zip`.

## Notarization (planned)

Requires an Apple Developer Program membership.

```bash
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: <Name> (<TEAMID>)" "build/Junk0.app"
ditto -c -k --keepParent "build/Junk0.app" Junk0.zip
xcrun notarytool submit Junk0.zip --keychain-profile <profile> --wait
xcrun stapler staple "build/Junk0.app"
```

## Troubleshooting

**"You have not agreed to the Xcode license agreements"** — run `sudo xcodebuild -license` once, or
build with the Command Line Tools. The build script calls the toolchain binaries directly to avoid the `xcrun` shims.

**"SDK is not supported by the compiler"** — the Command Line Tools' `swiftc` and SDK are out of sync.
Use Xcode's toolchain (the script prefers it automatically) or reinstall the Command Line Tools.

## Regenerating screenshots

The screenshots in `docs/screenshots/` are rendered by the app itself from sample data (`Sources/Screens.swift`),
in light and dark mode at 2× resolution. No real files are shown and no screen recording permission is needed.

```bash
./scripts/build.sh
open -W -n "build/Junk0.app" --args --render-screens "$PWD/docs/screenshots"
```

Launch through `open` (not directly) so the windows render in their active state.
