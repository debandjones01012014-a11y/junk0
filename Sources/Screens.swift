import SwiftUI
import AppKit

// Renders documentation screenshots offscreen using sample data (no real files, no screen recording).
//   JunkCleaner --render-screens <folder>

func demoGroups() -> [CleanGroup] {
  let MB: Int64 = 1_000_000, GB: Int64 = 1_000_000_000
  func e(_ path: String, _ b: Int64, _ days: Double, _ on: Bool, _ note: String = "") -> Entry {
    Entry(url: home / path, bytes: b, date: Date().addingTimeInterval(-days * 86_400), on: on, note: note)
  }
  func auto(_ id: String, _ n: String, _ d: String, _ i: String, _ t: Color, _ b: Int64, _ blocker: String = "", on: Bool = true) -> CleanGroup {
    var g = CleanGroup(id: id, name: n, detail: d, icon: i, tint: t, kind: .auto); g.bytes = b; g.blocker = blocker; g.on = on; return g
  }
  func review(_ id: String, _ n: String, _ d: String, _ i: String, _ t: Color, _ es: [Entry]) -> CleanGroup {
    var g = CleanGroup(id: id, name: n, detail: d, icon: i, tint: t, kind: .review)
    g.entries = es.sorted { $0.bytes > $1.bytes }; g.bytes = es.reduce(0) { $0 + $1.bytes }; return g
  }
  let p = "Documents/Projects/Spring Campaign/Adobe Premiere Pro Video Previews/"
  return [
    auto("ae_cache", "After Effects disk cache", "Rendered preview frames — rebuilt automatically", "film.stack", .purple, 48_400 * MB, "After Effects"),
    auto("media_cache", "Adobe Media Cache + Peak files", "Conformed audio & waveforms — rebuilt automatically", "waveform", .purple, 17_800 * MB),
    auto("browsers", "Chrome / Brave caches", "Websites load a little slower once", "globe", .blue, 8_050 * MB),
    review("installers", "Installers in Downloads", "Disk images & packages — tick the ones to move to Trash", "shippingbox", .brown, [
      e("Downloads/Blender-4.2-macos-arm64.dmg", 380 * MB, 64, true),
      e("Downloads/Figma.dmg", 245 * MB, 120, true),
      e("Downloads/Client Assets Vol 2.dmg", 1_200 * MB, 9, false),
      e("Downloads/Zoom.pkg", 96 * MB, 200, true),
      e("Downloads/Old Apps/HandBrake-1.8.dmg", 72 * MB, 310, true)]),
    auto("dev", "Developer caches", "uv, npm, pip, AI models — downloaded again if needed", "chevron.left.forwardslash.chevron.right", .orange, 2_670 * MB),
    review("pr_previews", "Old Premiere preview renders", "Older than 21 days — Premiere re-renders them if needed", "play.rectangle.on.rectangle", .indigo, [
      e(p + "Spring Campaign.prproj-1a2b-Sequence 01.mov", 812 * MB, 34, true, "Preview render"),
      e(p + "Spring Campaign.prproj-1a2b-Cutdown 30s.mov", 404 * MB, 33, true, "Preview render"),
      e(p + "Spring Campaign.prproj-1a2b-Cutdown 15s.mov", 196 * MB, 33, true, "Preview render"),
      e("Library/CloudStorage/OneDrive-Team/Shared Edit/Adobe Premiere Pro Video Previews/Interview.mov", 655 * MB, 41, false,
        "Preview render · Cloud folder — removal syncs to everyone")]),
    auto("app_caches", "Other app caches", "3 caches of open apps are left alone", "square.stack.3d.up", .teal, 828 * MB),
    review("old_adobe", "Old Adobe version leftovers", "Settings & plugin data of versions you've upgraded from — moved to Trash", "clock.arrow.circlepath", .purple, [
      e("Library/Application Support/Adobe/UXP/PluginsStorage/PHSP/26", 2_500 * MB, 400, true, "Photoshop v26 plugin data"),
      e("Library/Application Support/Adobe/UXP/PluginsStorage/PHSP/25", 2_500 * MB, 700, true, "Photoshop v25 plugin data"),
      e("Library/Preferences/Adobe/After Effects/26.2", 3 * MB, 90, true, "After Effects 26.2 settings"),
      e("Library/Preferences/Adobe/After Effects/25.6", 2 * MB, 300, true, "After Effects 25.6 settings"),
      e("Library/Application Support/Adobe/Adobe Photoshop 2025", 7 * MB, 380, true, "Old Photoshop support folder")]),
    auto("logs", "User log files", "Old diagnostic text files", "doc.plaintext", .gray, 221 * MB),
    review("pr_autosaves", "Old Premiere autosaves", "Older than 21 days — off by default, tick to move to Trash", "doc.badge.clock", .pink, [
      e("Documents/Projects/Spring Campaign/Adobe Premiere Pro Auto-Save/Spring Campaign--12-10-2026_14-02-11.prproj", 4 * MB, 35, false, "Autosave"),
      e("Documents/Projects/Spring Campaign/Adobe Premiere Pro Auto-Save/Spring Campaign--11-10-2026_17-45-03.prproj", 4 * MB, 36, false, "Autosave")]),
    review("unusual", "Unusual file names", "Names with hidden characters — review each one", "exclamationmark.triangle", .orange, [
      e("Downloads/Invoice\ncopy.dmg", 12 * MB, 50, false, "Unusual name (hidden characters) — check before removing")]),
  ]
}

@MainActor func renderScreens(to dir: String) {
  _ = NSApplication.shared
  NSApp.setActivationPolicy(.regular); NSApp.finishLaunching(); NSApp.activate(ignoringOtherApps: true); RunLoop.current.run(until: Date().addingTimeInterval(1))
  try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

  func shot<V: View>(_ name: String, _ size: CGSize, dark: Bool, @ViewBuilder _ v: () -> V) {
    let ap = NSAppearance(named: dark ? .darkAqua : .aqua)!
    let host = NSHostingView(rootView: v().environment(\.controlActiveState, .key).frame(width: size.width, height: size.height)
      .background(Color(nsColor: .windowBackgroundColor)))
    host.appearance = ap
    let win = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
    win.appearance = ap
    win.contentView = host
    host.frame = CGRect(origin: .zero, size: size)
    win.setFrameOrigin(NSPoint(x: -20000, y: -20000)); win.makeKeyAndOrderFront(nil)
    for _ in 0..<6 { host.layoutSubtreeIfNeeded(); RunLoop.current.run(until: Date().addingTimeInterval(0.15)) }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    ap.performAsCurrentDrawingAppearance { host.cacheDisplay(in: host.bounds, to: rep) }
    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: dir) / "\(name).png")
    win.orderOut(nil); print("rendered \(name).png")
  }

  let main = CGSize(width: 620, height: 700)
  let prefs = Prefs(excluded: [(home / "Documents/Projects/Spring Campaign").path, (home / "Documents/Projects/Client Pitch").path,
                               (home / "Movies/Wedding Film 2026").path],
                    roots: [(home / "Documents").path, (home / "Movies").path, (home / "Desktop").path], days: 21)
  func model(_ phase: Phase) -> Model {
    let m = Model(prefs: prefs, demo: true); m.groups = demoGroups(); m.phase = phase; return m
  }
  let gs = demoGroups()
  func group(_ id: String) -> CleanGroup { gs.first { $0.id == id }! }

  for dark in [false, true] {
    let sfx = dark ? "-dark" : "-light"
    shot("main" + sfx, main, dark: dark) { ContentView(model: model(.ready)) }
    shot("review-installers" + sfx, CGSize(width: 680, height: 540), dark: dark) { ReviewSheet(group: .constant(group("installers"))) }
    shot("review-premiere" + sfx, CGSize(width: 680, height: 540), dark: dark) { ReviewSheet(group: .constant(group("pr_previews"))) }
    shot("review-old-adobe" + sfx, CGSize(width: 680, height: 540), dark: dark) { ReviewSheet(group: .constant(group("old_adobe"))) }
    shot("review-unusual" + sfx, CGSize(width: 680, height: 300), dark: dark) { ReviewSheet(group: .constant(group("unusual"))) }
    shot("settings" + sfx, CGSize(width: 580, height: 560), dark: dark) { SettingsSheet(prefs: prefs) {} }
    shot("scanning" + sfx, main, dark: dark) { ContentView(model: model(.scanning)) }
    shot("done" + sfx, main, dark: dark) {
      ContentView(model: model(.done(CleanResult(freed: 29_300_000_000, trashed: 5_810_000_000,
                                                 skipped: ["After Effects disk cache"], failed: 0))))
    }
  }
}
