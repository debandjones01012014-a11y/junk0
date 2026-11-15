# Safety model

Junk0 is built around one rule: **only remove things that are either rebuilt automatically, or that you picked yourself — and never anything else.**

## Hard guarantees (enforced in `Sources/Engine.swift`)

| Guarantee | How |
|---|---|
| Never touches anything outside your home folder | Every path is checked against `NSHomeDirectory()` before removal (`safe()`); the home folder itself can never be a target. |
| Never needs or asks for an admin password | Runs with your normal user rights only, so system files are physically out of reach. |
| Never touches excluded folders | A path is skipped if it *is* an excluded folder, is *inside* one, or *contains* one. Scans don't even walk into them. |
| Never removes caches of open apps | Running apps are read from `NSWorkspace`; matching cache folders are skipped at scan time and re-checked at clean time. |
| Never follows symbolic links | Sizes and removals act on the link itself, never on what it points to. |
| Never misreads file names | All paths are handled as native `URL`s — no shell, no text parsing. Names with hidden characters are listed separately for review. |
| Nothing happens without confirmation | Scanning is read-only. Removal starts only after the confirmation dialog. |
| No network access | The app makes no network connections and collects no data. |

## Two kinds of removal

**Deleted permanently** — only for pure caches and logs that apps regenerate on their own:

| Group | Paths |
|---|---|
| After Effects log files | `~/Library/Preferences/Adobe/After Effects/<version>/logs/*` |
| After Effects disk cache | `~/Library/Caches/Adobe/After Effects*` |
| Adobe Media Cache + Peak files | `~/Library/Application Support/Adobe/Common/Media Cache Files`, `…/Peak Files` |
| Other app caches | `~/Library/Caches/*` and `~/Library/Caches/Adobe/*`, **except** `com.apple.*`, `CloudKit`, browsers, Teams, Media Encoder and caches of running apps |
| Chrome / Brave caches | `~/Library/Caches/Google`, `…/BraveSoftware`, `…/com.google.Chrome`, `…/com.brave.Browser`, Service Worker `CacheStorage` |
| Microsoft Teams cache | `~/Library/Containers/com.microsoft.teams2/Data/Library/Caches`, `~/Library/Caches/com.microsoft.teams*` |
| User log files | `~/Library/Logs/*` |
| Developer caches | `~/.cache/*`, `~/.npm/_cacache` |

**Moved to the Trash** — anything that is a real file, only after you review it:

| Group | What | Default |
|---|---|---|
| Installers in Downloads | `.dmg` / `.pkg` up to two folders deep | Not selected |
| Old Adobe version leftovers | Older After Effects settings folders, Photoshop UXP plugin data, Photoshop/Illustrator support folders. The highest version is always kept. | Selected |
| Old Premiere preview renders | Files in `Adobe Premiere Pro * Previews` folders older than *N* days | Selected |
| Old Premiere autosaves | Files in `Adobe Premiere Pro Auto-Save` folders older than *N* days | Not selected |
| Unusual file names | Any candidate above whose name has control characters or leading/trailing spaces | Not selected |

## Never touched

- Documents, Desktop, Pictures, Music, Movies, Photos and Mail libraries — except Premiere preview/autosave folders you review
- Your current app settings, preferences, licenses and plugins
- Browser profiles: logins, passwords, bookmarks, history, open tabs
- Apple system caches (`com.apple.*`) and anything outside your home folder
- Time Machine snapshots, iOS backups, macOS updates
- Folders you've excluded

## Things to know

- After clearing the Adobe caches, the first previews are slower while they rebuild.
- Clearing `~/.cache` removes downloaded AI models (e.g. Whisper, Hugging Face); they download again when needed.
- Files in OneDrive / iCloud folders are flagged: moving them to the Trash removes them for everyone the folder is shared with.
- Reviewed files only free space once you empty the Trash.
