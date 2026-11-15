# Changelog

## 2.1 — 2026-11-15
- Renamed to **Junk0** ("junk, zeroed out"); the previous name is kept as git tag `junk-cleaner-2.0`.
- New icon: a zero ring with AI sparkles on a black tile with a violet glow.
- Violet brand accent across the app and the website.

## 2.0 — 2026-11-14
- Rewritten as a native SwiftUI app; scanning and cleaning in Swift (no shell scripts).
- Review windows for installers, older Adobe versions, Premiere previews/autosaves and unusual file names.
- Reviewed files go to the Trash instead of being deleted.
- Caches of running apps are skipped, and re-checked right before cleaning.
- Excluded folders, Premiere project folders and age setting, remembered between launches.
- Old Premiere preview renders and autosaves older than N days.
- Cloud-folder warning for OneDrive / iCloud files.
- Universal build (Apple Silicon + Intel), new icon.
- Full documentation: User Guide with use cases, safety model, build guide, light & dark screenshots, GitHub Pages site.

## 1.0 — 2026-11-13
- First version: AppleScript dialogs over a shell scan/clean engine.
