import AppKit
import SwiftUI

// MARK: - Basics

let fm = FileManager.default
let home = URL(fileURLWithPath: NSHomeDirectory()).standardizedFileURL

func / (l: URL, r: String) -> URL { l.appendingPathComponent(r) }
func fmt(_ b: Int64) -> String { ByteCountFormatter.string(fromByteCount: b, countStyle: .file) }
func tilde(_ p: String) -> String { p.hasPrefix(home.path) ? "~" + p.dropFirst(home.path.count) : p }

func kids(_ u: URL) -> [URL] { (try? fm.contentsOfDirectory(at: u, includingPropertiesForKeys: nil)) ?? [] }
func exists(_ u: URL) -> Bool { (try? u.checkResourceIsReachable()) == true || fm.fileExists(atPath: u.path) }
func modDate(_ u: URL) -> Date? { try? u.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }

/// Allocated size on disk. Never follows symlinks.
func size(_ u: URL) -> Int64 {
  let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey]
  guard let v = try? u.resourceValues(forKeys: keys) else { return 0 }
  if v.isSymbolicLink == true { return 0 }
  if v.isDirectory != true { return Int64(v.totalFileAllocatedSize ?? 0) }
  var t: Int64 = 0
  if let e = fm.enumerator(at: u, includingPropertiesForKeys: Array(keys), options: [], errorHandler: { _, _ in true }) {
    for case let f as URL in e {
      if let fv = try? f.resourceValues(forKeys: keys), fv.isRegularFile == true { t += Int64(fv.totalFileAllocatedSize ?? 0) }
    }
  }
  return t
}

/// Names with hidden control characters (line breaks, tabs…) or leading/trailing spaces.
func unusualName(_ n: String) -> Bool {
  n.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) } || n != n.trimmingCharacters(in: .whitespaces)
}
func visibleName(_ n: String) -> String {
  let s = n.unicodeScalars.map { CharacterSet.controlCharacters.contains($0) ? "⏎" : String($0) }.joined()
  return unusualName(n) ? "“\(s)”" : s
}
func isCloud(_ u: URL) -> Bool { u.path.contains("/Library/CloudStorage/") || u.path.contains("/Library/Mobile Documents/") }

/// True when u is an excluded folder or inside one (used while walking folders).
func underExcluded(_ u: URL, _ ex: [String]) -> Bool {
  let p = u.standardizedFileURL.path
  return ex.contains { p == $0 || p.hasPrefix($0 + "/") }
}
/// Safe to remove: strictly inside home, not excluded, and does not contain an excluded folder.
func safe(_ u: URL, _ ex: [String]) -> Bool {
  let p = u.standardizedFileURL.path
  guard p.hasPrefix(home.path + "/"), p.count > home.path.count + 1 else { return false }
  return !ex.contains { p == $0 || p.hasPrefix($0 + "/") || $0.hasPrefix(p + "/") }
}

// MARK: - Running apps

struct RunningApps {
  let ids: [String]
  let names: [String]
  static func now() -> RunningApps {
    let apps = NSWorkspace.shared.runningApplications
    return RunningApps(ids: apps.compactMap { $0.bundleIdentifier?.lowercased() },
                       names: apps.compactMap { $0.localizedName?.lowercased() })
  }
  func has(_ needles: [String]) -> Bool { names.contains { n in needles.contains { n.contains($0) } } }
  /// Does a cache folder belong to an app that's open right now?
  func owns(cacheFolder name: String) -> Bool {
    let n = name.lowercased()
    if ids.contains(where: { n == $0 || n.hasPrefix($0 + ".") || $0.hasPrefix(n + ".") }) { return true }
    guard n.count >= 4, !n.contains(".") else { return false }
    let sq = n.replacingOccurrences(of: " ", with: "")
    return names.contains { $0.contains(n) || $0.replacingOccurrences(of: " ", with: "").contains(sq) }
  }
}

// MARK: - Groups

struct Entry: Identifiable {
  let id = UUID()
  let url: URL
  let bytes: Int64
  let date: Date?
  var on: Bool
  var note = ""
}

enum Kind { case auto, review }

struct CleanGroup: Identifiable {
  let id: String
  let name: String
  let detail: String
  let icon: String
  let tint: Color
  let kind: Kind
  var bytes: Int64 = 0
  var needles: [String] = []   // app names that must be closed first
  var blocker = ""
  var on = true
  var paths: [URL] = []        // .auto: removed permanently (caches/logs)
  var entries: [Entry] = []    // .review: picked one by one, moved to Trash

  var selectedBytes: Int64 {
    switch kind {
    case .auto: return on && blocker.isEmpty ? bytes : 0
    case .review: return entries.filter(\.on).reduce(0) { $0 + $1.bytes }
    }
  }
  var selectedCount: Int { entries.filter(\.on).count }
}

// MARK: - Scan

func scanAll(ex: [String], roots: [String], days: Int, run: RunningApps) -> [CleanGroup] {
  let L = home / "Library", C = L / "Caches", AS = L / "Application Support", adobeC = C / "Adobe"
  var out: [CleanGroup] = []
  var unusual: [Entry] = []

  func auto(_ id: String, _ name: String, _ detail: String, _ icon: String, _ tint: Color,
            _ paths: [URL], needles: [String] = [], label: String = "") {
    let ps = paths.filter { exists($0) && safe($0, ex) }
    var g = CleanGroup(id: id, name: name, detail: detail, icon: icon, tint: tint, kind: .auto)
    g.paths = ps
    g.bytes = ps.reduce(0) { $0 + size($1) }
    g.needles = needles
    if !needles.isEmpty && run.has(needles) { g.blocker = label }
    if g.bytes > 1_000_000 { out.append(g) }
  }
  func entry(_ u: URL, on: Bool, note: String = "") -> Entry? {
    guard safe(u, ex) else { return nil }
    var n = note
    if isCloud(u) { n += (n.isEmpty ? "" : " · ") + "Cloud folder — removal syncs to everyone" }
    if unusualName(u.lastPathComponent) {
      unusual.append(Entry(url: u, bytes: size(u), date: modDate(u), on: false,
                           note: "Unusual name (hidden characters) — check before removing"))
      return nil
    }
    return Entry(url: u, bytes: size(u), date: modDate(u), on: on, note: n)
  }
  func review(_ id: String, _ name: String, _ detail: String, _ icon: String, _ tint: Color, _ es: [Entry]) {
    guard !es.isEmpty else { return }
    var g = CleanGroup(id: id, name: name, detail: detail, icon: icon, tint: tint, kind: .review)
    g.entries = es.sorted { $0.bytes > $1.bytes }
    g.bytes = es.reduce(0) { $0 + $1.bytes }
    out.append(g)
  }

  // Automatic groups: pure caches/logs, rebuilt by the apps
  let aePrefs = L / "Preferences/Adobe/After Effects"
  auto("ae_logs", "After Effects log files", "Diagnostic logs After Effects keeps writing", "doc.text", .purple,
       kids(aePrefs).flatMap { kids($0 / "logs") }, needles: ["after effects"], label: "After Effects")
  auto("ae_cache", "After Effects disk cache", "Rendered preview frames — rebuilt automatically", "film.stack", .purple,
       kids(adobeC).filter { $0.lastPathComponent.hasPrefix("After Effects") }, needles: ["after effects"], label: "After Effects")
  auto("media_cache", "Adobe Media Cache + Peak files", "Conformed audio & waveforms — rebuilt automatically", "waveform", .purple,
       [AS / "Adobe/Common/Media Cache Files", AS / "Adobe/Common/Peak Files"],
       needles: ["media encoder", "premiere pro", "after effects"], label: "Adobe video apps")

  let skipTop: Set<String> = ["adobe", "google", "bravesoftware", "com.google.chrome", "com.brave.browser", "cloudkit"]
  var openSkipped = 0, appPaths: [URL] = []
  for u in kids(C) {
    let n = u.lastPathComponent.lowercased()
    if skipTop.contains(n) || n.hasPrefix("com.apple.") || n.hasPrefix("com.microsoft.teams")
        || n.hasPrefix("com.adobe.ame") || n.hasPrefix("local.junkcleaner") { continue }
    if run.owns(cacheFolder: u.lastPathComponent) { openSkipped += 1; continue }
    appPaths.append(u)
  }
  for u in kids(adobeC) where !u.lastPathComponent.hasPrefix("After Effects") {
    if run.owns(cacheFolder: u.lastPathComponent) { openSkipped += 1; continue }
    appPaths.append(u)
  }
  auto("app_caches", "Other app caches",
       openSkipped > 0 ? "\(openSkipped) caches of open apps are left alone" : "Premiere, Photoshop, plugins, updaters and more",
       "square.stack.3d.up", .teal, appPaths)
  auto("browsers", "Chrome / Brave caches", "Websites load a little slower once", "globe", .blue,
       [C / "Google", C / "BraveSoftware", C / "com.google.Chrome", C / "com.brave.Browser",
        AS / "Google/Chrome/Default/Service Worker/CacheStorage",
        AS / "BraveSoftware/Brave-Browser/Default/Service Worker/CacheStorage"],
       needles: ["google chrome", "brave browser"], label: "Chrome / Brave")
  auto("teams", "Microsoft Teams cache", "Rebuilt next time Teams opens", "person.2", .indigo,
       [L / "Containers/com.microsoft.teams2/Data/Library/Caches"]
         + kids(C).filter { $0.lastPathComponent.lowercased().hasPrefix("com.microsoft.teams") },
       needles: ["microsoft teams"], label: "Teams")
  auto("logs", "User log files", "Old diagnostic text files", "doc.plaintext", .gray, kids(L / "Logs"))
  auto("dev", "Developer caches", "uv, npm, pip, AI models — downloaded again if needed",
       "chevron.left.forwardslash.chevron.right", .orange, kids(home / ".cache") + [home / ".npm/_cacache"])

  // Review: installers in Downloads (off by default)
  var inst: [URL] = []
  if let e = fm.enumerator(at: home / "Downloads", includingPropertiesForKeys: nil, options: [.skipsPackageDescendants]) {
    for case let u as URL in e {
      if underExcluded(u, ex) { e.skipDescendants(); continue }
      if e.level >= 2 { e.skipDescendants() }
      let x = u.pathExtension.lowercased()
      if x == "dmg" || x == "pkg" { inst.append(u) }
    }
  }
  review("installers", "Installers in Downloads", "Disk images & packages — tick the ones to move to Trash",
         "shippingbox", .brown, inst.compactMap { entry($0, on: false) })

  // Review: older-version Adobe leftovers (newest version is always kept)
  func olderVersions(_ dir: URL, _ pattern: String) -> [URL] {
    guard let r = try? NSRegularExpression(pattern: pattern) else { return [] }
    let m = kids(dir).filter { let n = $0.lastPathComponent; return r.firstMatch(in: n, range: NSRange(n.startIndex..., in: n)) != nil }
      .sorted { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedAscending }
    return Array(m.dropLast())
  }
  let old: [(URL, String)] =
    olderVersions(aePrefs, "^[0-9]+\\.[0-9]+$").map { ($0, "After Effects \($0.lastPathComponent) settings") }
    + olderVersions(AS / "Adobe/UXP/PluginsStorage/PHSP", "^[0-9]+$").map { ($0, "Photoshop v\($0.lastPathComponent) plugin data") }
    + olderVersions(AS / "Adobe", "^Adobe Photoshop 20[0-9]{2}$").map { ($0, "Old Photoshop support folder") }
    + olderVersions(AS / "Adobe", "^Adobe Illustrator [0-9]+$").map { ($0, "Old Illustrator support folder") }
  review("old_adobe", "Old Adobe version leftovers", "Settings & plugin data of versions you've upgraded from — moved to Trash",
         "clock.arrow.circlepath", .purple, old.compactMap { entry($0.0, on: true, note: $0.1) })

  // Review: Premiere previews & autosaves older than N days
  let cutoff = Date().addingTimeInterval(-Double(days) * 86_400)
  var autos: [Entry] = [], prevs: [Entry] = [], seen = Set<String>()
  let rootURLs = roots.map { URL(fileURLWithPath: $0) } + [home / "Documents/Adobe/Premiere Pro"]
  for r in rootURLs where exists(r) && !underExcluded(r, ex) {
    guard let e = fm.enumerator(at: r, includingPropertiesForKeys: [.isDirectoryKey],
                                options: [.skipsPackageDescendants, .skipsHiddenFiles]) else { continue }
    for case let u as URL in e {
      if underExcluded(u, ex) { e.skipDescendants(); continue }
      let n = u.lastPathComponent
      let isAuto = n == "Adobe Premiere Pro Auto-Save"
      let isPrev = n.hasPrefix("Adobe Premiere Pro") && n.hasSuffix("Previews")
      guard isAuto || isPrev else { continue }
      e.skipDescendants()
      guard seen.insert(u.path).inserted, let fe = fm.enumerator(at: u, includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey]) else { continue }
      for case let f as URL in fe {
        if underExcluded(f, ex) { fe.skipDescendants(); continue }
        guard (try? f.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
              let d = modDate(f), d < cutoff else { continue }
        if isAuto { if let x = entry(f, on: false, note: "Autosave") { autos.append(x) } }
        else if let x = entry(f, on: true, note: "Preview render") { prevs.append(x) }
      }
    }
  }
  review("pr_previews", "Old Premiere preview renders", "Older than \(days) days — Premiere re-renders them if needed",
         "play.rectangle.on.rectangle", .indigo, prevs)
  review("pr_autosaves", "Old Premiere autosaves", "Older than \(days) days — off by default, tick to move to Trash",
         "doc.badge.clock", .pink, autos)

  review("unusual", "Unusual file names", "Names with hidden characters — review each one",
         "exclamationmark.triangle", .orange, unusual)
  return out
}

// MARK: - Clean

struct CleanResult { var freed: Int64; var trashed: Int64; var skipped: [String]; var failed: Int }

func freeSpace() -> Int64 {
  Int64((try? home.resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity) ?? 0)
}

func cleanAll(_ groups: [CleanGroup], ex: [String], run: RunningApps) -> CleanResult {
  let before = freeSpace()
  var r = CleanResult(freed: 0, trashed: 0, skipped: [], failed: 0)
  for g in groups {
    switch g.kind {
    case .auto:
      guard g.on else { continue }
      if !g.blocker.isEmpty || (!g.needles.isEmpty && run.has(g.needles)) { r.skipped.append(g.name); continue }
      for u in g.paths where safe(u, ex) {
        if g.id == "app_caches", run.owns(cacheFolder: u.lastPathComponent) { continue }   // opened since scan
        do { try fm.removeItem(at: u) } catch { r.failed += 1 }
      }
    case .review:
      for e in g.entries where e.on && safe(e.url, ex) {
        do { try fm.trashItem(at: e.url, resultingItemURL: nil); r.trashed += e.bytes } catch { r.failed += 1 }
      }
    }
  }
  r.freed = max(0, freeSpace() - before)
  return r
}
