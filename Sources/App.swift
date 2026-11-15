import SwiftUI
import AppKit

// MARK: - Preferences (saved between launches)

final class Prefs: ObservableObject {
  private let d = UserDefaults.standard
  @Published var excluded: [String] { didSet { d.set(excluded, forKey: "excluded") } }
  @Published var roots: [String] { didSet { d.set(roots, forKey: "roots") } }
  @Published var days: Int { didSet { d.set(days, forKey: "days") } }
  init(excluded: [String], roots: [String], days: Int) {
    self.excluded = excluded; self.roots = roots; self.days = days
  }
  init() {
    excluded = d.stringArray(forKey: "excluded") ?? []
    roots = d.stringArray(forKey: "roots") ?? ["Documents", "Movies", "Desktop"].map { (home / $0).path }
    let v = d.integer(forKey: "days"); days = v == 0 ? 21 : v
  }
}

// MARK: - Model

enum Phase { case scanning, ready, cleaning, done(CleanResult) }
struct RID: Identifiable { let id: String }

@MainActor final class Model: ObservableObject {
  @Published var groups: [CleanGroup] = []
  @Published var phase: Phase = .scanning
  let prefs: Prefs
  let demo: Bool
  init(prefs: Prefs = Prefs(), demo: Bool = false) { self.prefs = prefs; self.demo = demo }

  var total: Int64 { groups.reduce(0) { $0 + $1.bytes } }
  var selected: Int64 { groups.reduce(0) { $0 + $1.selectedBytes } }
  var deleteBytes: Int64 { groups.filter { $0.kind == .auto }.reduce(0) { $0 + $1.selectedBytes } }
  var trashBytes: Int64 { groups.filter { $0.kind == .review }.reduce(0) { $0 + $1.selectedBytes } }
  var trashCount: Int { groups.reduce(0) { $0 + $1.selectedCount } }

  func scan() async {
    phase = .scanning
    let ex = prefs.excluded, roots = prefs.roots, days = prefs.days, run = RunningApps.now()
    groups = await Task.detached { scanAll(ex: ex, roots: roots, days: days, run: run) }.value
      .sorted { $0.bytes > $1.bytes }
    phase = .ready
  }
  func clean() async {
    let gs = groups, ex = prefs.excluded, run = RunningApps.now()
    phase = .cleaning
    let r = await Task.detached { cleanAll(gs, ex: ex, run: run) }.value
    phase = .done(r)
  }
}

// MARK: - Main window

struct ContentView: View {
  @StateObject var m: Model
  @MainActor init(model: Model? = nil) { _m = StateObject(wrappedValue: model ?? Model()) }
  @State var confirm = false
  @State var reviewing: RID?
  @State var settings = false

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      switch m.phase {
      case .scanning: busy("Scanning your Mac…")
      case .cleaning: busy("Cleaning…")
      case .ready: list
      case .done(let r): done(r)
      }
    }
    .frame(width: 620, height: 700)
    .tint(brandViolet)
    .background(.background)
    .task { if !m.demo { await m.scan() } }
    .sheet(item: $reviewing) { r in
      if let i = m.groups.firstIndex(where: { $0.id == r.id }) { ReviewSheet(group: $m.groups[i]) }
    }
    .sheet(isPresented: $settings) {
      SettingsSheet(prefs: m.prefs) { settings = false; Task { await m.scan() } }
    }
    .alert("Clean \(fmt(m.selected))?", isPresented: $confirm) {
      Button("Cancel", role: .cancel) {}
      Button("Clean", role: .destructive) { Task { await m.clean() } }
    } message: {
      Text(confirmText)
    }
  }

  var confirmText: String {
    var s: [String] = []
    if m.deleteBytes > 0 { s.append("\(fmt(m.deleteBytes)) of caches and logs will be permanently deleted. Apps rebuild these.") }
    if m.trashCount > 0 { s.append("\(m.trashCount) files (\(fmt(m.trashBytes))) will be moved to the Trash, so you can still recover them.") }
    s.append("Excluded folders and caches of open apps are never touched.")
    return s.joined(separator: "\n\n")
  }

  var header: some View {
    HStack(spacing: 16) {
      Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64)
      VStack(alignment: .leading, spacing: 2) {
        (Text("Junk") + Text("0").foregroundStyle(brandViolet).fontDesign(.rounded)).font(.system(size: 22, weight: .semibold))
        Group {
          if case .ready = m.phase { Text("\(fmt(m.total)) found") } else { Text("Caches, logs and leftovers — safely") }
        }.font(.subheadline).foregroundStyle(.secondary)
      }
      Spacer()
      if case .ready = m.phase {
        Button { Task { await m.scan() } } label: { Image(systemName: "arrow.clockwise") }
          .buttonStyle(.borderless).help("Scan again")
      }
      Button { settings = true } label: { Label("Scan Options", systemImage: "slider.horizontal.3") }
        .buttonStyle(.bordered).controlSize(.regular)
        .help("Choose where Junk0 looks, exclude folders, and set what counts as old")
    }
    .font(.system(size: 15))
    .padding(20)
  }

  func busy(_ t: String) -> some View {
    VStack(spacing: 14) { ProgressView().controlSize(.large); Text(t).foregroundStyle(.secondary) }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  var list: some View {
    VStack(spacing: 0) {
      if m.groups.isEmpty {
        VStack(spacing: 10) {
          Image(systemName: "checkmark.seal.fill").font(.system(size: 48)).foregroundStyle(.green)
          Text("Your Mac is clean").font(.title3.weight(.medium))
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          VStack(spacing: 8) { ForEach($m.groups) { $g in row($g) } }.padding(16)
        }
      }
      Divider()
      HStack {
        Text("Nothing is removed until you confirm.").font(.footnote).foregroundStyle(.secondary)
        Spacer()
        Button { confirm = true } label: {
          Text("Clean \(fmt(m.selected))").frame(minWidth: 150).padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent).controlSize(.large)
        .disabled(m.selected == 0)
        .keyboardShortcut(.defaultAction)
      }.padding(16)
    }
  }

  func row(_ g: Binding<CleanGroup>) -> some View {
    let v = g.wrappedValue, blocked = !v.blocker.isEmpty
    return HStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(v.tint.gradient)
        Image(systemName: v.icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
      }.frame(width: 32, height: 32)
      VStack(alignment: .leading, spacing: 2) {
        Text(v.name).font(.body.weight(.medium))
        if blocked {
          Label("Quit \(v.blocker) to clean", systemImage: "lock.fill").font(.caption).foregroundStyle(.orange)
        } else {
          Text(v.kind == .review ? "\(v.selectedCount) of \(v.entries.count) selected · \(v.detail)" : v.detail)
            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
      }
      Spacer()
      if v.kind == .review {
        Text(fmt(v.selectedBytes)).font(.body.monospacedDigit()).foregroundStyle(.secondary)
        Button("Review…") { reviewing = RID(id: v.id) }
      } else {
        Text(fmt(v.bytes)).font(.body.monospacedDigit()).foregroundStyle(.secondary)
        Toggle("", isOn: blocked ? .constant(false) : g.on).toggleStyle(.switch).labelsHidden().disabled(blocked)
      }
    }
    .padding(.horizontal, 14).padding(.vertical, 10)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
    .opacity(blocked ? 0.6 : 1)
  }

  func done(_ r: CleanResult) -> some View {
    VStack(spacing: 12) {
      Image(systemName: "sparkles").font(.system(size: 56))
        .foregroundStyle(.linearGradient(colors: [.cyan, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
      Text("Freed \(fmt(r.freed))").font(.system(size: 28, weight: .semibold))
      if r.trashed > 0 {
        Text("\(fmt(r.trashed)) moved to the Trash — empty it to reclaim that space.").foregroundStyle(.secondary)
      }
      ForEach(r.skipped, id: \.self) { Text("Skipped \($0) — app was open").font(.footnote).foregroundStyle(.orange) }
      if r.failed > 0 { Text("\(r.failed) items couldn't be removed (in use or protected).").font(.footnote).foregroundStyle(.secondary) }
      Button("Scan Again") { Task { await m.scan() } }.controlSize(.large).padding(.top, 8)
    }.frame(maxWidth: .infinity, maxHeight: .infinity).multilineTextAlignment(.center).padding()
  }
}

// MARK: - Review window (pick files one by one)

struct ReviewSheet: View {
  @Binding var group: CleanGroup
  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 2) {
          Text(group.name).font(.title3.weight(.semibold))
          Text(group.detail).font(.subheadline).foregroundStyle(.secondary)
        }
        Spacer()
        Button("Select All") { for i in group.entries.indices { group.entries[i].on = true } }
        Button("Select None") { for i in group.entries.indices { group.entries[i].on = false } }
      }.padding(16)
      Divider()
      List {
        ForEach($group.entries) { $e in
          HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: $e.on).toggleStyle(.checkbox).labelsHidden()
            VStack(alignment: .leading, spacing: 2) {
              Text(e.title ?? visibleName(e.url.lastPathComponent)).lineLimit(1).truncationMode(.middle)
              Text(tilde(e.url.deletingLastPathComponent().path)).font(.caption).foregroundStyle(.secondary)
                .lineLimit(1).truncationMode(.middle)
              if !e.note.isEmpty {
                Text(e.note).font(.caption)
                  .foregroundStyle(e.note.contains("Unusual") || e.note.contains("Cloud") ? .orange : .secondary)
              }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
              Text(fmt(e.bytes)).monospacedDigit()
              if let d = e.date { Text(d, format: .dateTime.day().month().year()).font(.caption).foregroundStyle(.secondary) }
            }
            Button { NSWorkspace.shared.activateFileViewerSelecting([e.url]) } label: { Image(systemName: "magnifyingglass") }
              .buttonStyle(.borderless).help("Show in Finder")
          }.padding(.vertical, 3)
        }
      }
      Divider()
      HStack {
        Text("\(group.selectedCount) selected · \(fmt(group.selectedBytes)) · moved to Trash").foregroundStyle(.secondary)
        Spacer()
        Button("Done") { dismiss() }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
      }.padding(16)
    }
    .frame(width: 680, height: 540)
    .tint(brandViolet)
  }
}

// MARK: - Settings (exclusions, Premiere folders, age)

struct SettingsSheet: View {
  @ObservedObject var prefs: Prefs
  let done: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Scan Options").font(.title2.weight(.semibold))
      folders("Excluded folders", "Never scanned or touched — e.g. projects you're working on now.", "folder.badge.minus", $prefs.excluded)
      folders("Project folders", "Where to look for Premiere previews & autosaves, Resolve render caches and Final Cut libraries.", "film", $prefs.roots)
      HStack {
        Text("Old project files: older than")
        Picker("", selection: $prefs.days) {
          ForEach([14, 21, 30, 60, 90], id: \.self) { Text("\($0) days").tag($0) }
        }.labelsHidden().frame(width: 110)
      }
      HStack { Spacer(); Button("Done & Rescan") { done() }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction) }
    }
    .padding(22).frame(width: 580)
    .tint(brandViolet)
  }

  func folders(_ title: String, _ sub: String, _ icon: String, _ list: Binding<[String]>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(title, systemImage: icon).font(.headline)
      Text(sub).font(.caption).foregroundStyle(.secondary)
      VStack(spacing: 0) {
        if list.wrappedValue.isEmpty {
          Text("None").foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(10)
        }
        ForEach(list.wrappedValue, id: \.self) { p in
          HStack {
            Image(systemName: "folder.fill").foregroundStyle(.blue)
            Text(tilde(p)).lineLimit(1).truncationMode(.middle)
            Spacer()
            Button { list.wrappedValue.removeAll { $0 == p } } label: {
              Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
            }.buttonStyle(.borderless).help("Remove")
          }.padding(.horizontal, 10).padding(.vertical, 6)
        }
      }
      .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.04)))
      Button { pick(list) } label: { Label("Add Folder…", systemImage: "plus") }
    }
  }

  func pick(_ list: Binding<[String]>) {
    let p = NSOpenPanel()
    p.canChooseDirectories = true; p.canChooseFiles = false; p.allowsMultipleSelection = true
    p.directoryURL = home; p.prompt = "Add"
    if p.runModal() == .OK {
      for u in p.urls {
        let s = u.standardizedFileURL.path
        if !list.wrappedValue.contains(s) { list.wrappedValue.append(s) }
      }
    }
  }
}

// MARK: - Entry point

struct Junk0App: App {
  var body: some Scene {
    WindowGroup { ContentView() }.windowResizability(.contentSize)
  }
}

@main enum Main {
  static func main() {
    // Diagnostic: print what a scan finds, delete nothing.
    if let i = CommandLine.arguments.firstIndex(of: "--render-screens"), i + 1 < CommandLine.arguments.count {
      MainActor.assumeIsolated { renderScreens(to: CommandLine.arguments[i + 1]) }
      exit(0)
    }
    if CommandLine.arguments.contains("--scan-report") {
      let p = Prefs()
      for g in scanAll(ex: p.excluded, roots: p.roots, days: p.days, run: RunningApps.now()) {
        print("\(g.id)\t\(fmt(g.bytes))\t\(g.kind == .review ? "\(g.entries.count) files" : "auto")\t\(g.blocker)")
        for e in g.entries { print("    \(e.on ? "[x]" : "[ ]") \(e.title ?? e.url.lastPathComponent)  \(fmt(e.bytes))  \(e.note)") }
      }
      exit(0)
    }
    Junk0App.main()
  }
}

/// Junk0 brand accent (matches the icon glow).
let brandViolet = Color(red: 0.43, green: 0.29, blue: 1.0)
