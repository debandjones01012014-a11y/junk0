import AppKit

// Draws candidate app icons (1024px) — each keeps the AI "sparkles".
let S: CGFloat = 1024, inset: CGFloat = 100, R = S - inset * 2
let box = CGRect(x: inset, y: inset, width: R, height: R)

func rounded(_ size: CGFloat, _ w: NSFont.Weight) -> NSFont {
  let f = NSFont.systemFont(ofSize: size, weight: w)
  return NSFont(descriptor: f.fontDescriptor.withDesign(.rounded) ?? f.fontDescriptor, size: size) ?? f
}
func sym(_ name: String, _ pt: CGFloat, _ w: NSFont.Weight = .semibold, color: NSColor = .white) -> NSImage? {
  NSImage(systemSymbolName: name, accessibilityDescription: nil)?
    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: pt, weight: w).applying(.init(paletteColors: [color])))
}
func drawSym(_ img: NSImage?, center: CGPoint) {
  guard let i = img else { return }
  i.draw(in: CGRect(x: center.x - i.size.width / 2, y: center.y - i.size.height / 2, width: i.size.width, height: i.size.height))
}
func text(_ s: String, _ font: NSFont, center: CGPoint, kern: CGFloat = 0) {
  let a = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor.white, .kern: kern])
  let b = a.boundingRect(with: .zero, options: [.usesLineFragmentOrigin, .usesFontLeading])
  a.draw(at: CGPoint(x: center.x - b.width / 2, y: center.y - b.height / 2 - b.minY / 2))
}

func icon(_ file: String, colors: [NSColor], content: (CGContext) -> Void) {
  let img = NSImage(size: NSSize(width: S, height: S))
  img.lockFocus()
  let ctx = NSGraphicsContext.current!.cgContext
  let path = NSBezierPath(roundedRect: box, xRadius: R * 0.225, yRadius: R * 0.225)
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 30, color: NSColor.black.withAlphaComponent(0.35).cgColor)
  NSColor.black.setFill(); path.fill()
  ctx.restoreGState()
  ctx.saveGState()
  path.addClip()
  NSGradient(colors: colors)!.draw(in: box, angle: -60)
  NSGradient(colors: [NSColor.white.withAlphaComponent(0.26), NSColor.white.withAlphaComponent(0)])!
    .draw(in: CGRect(x: inset, y: inset + R * 0.5, width: R, height: R * 0.5), angle: -90)
  ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 22, color: NSColor.black.withAlphaComponent(0.25).cgColor)
  content(ctx)
  ctx.restoreGState()
  img.unlockFocus()
  let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
  try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: file))
}

let brand = [NSColor(red: 0.20, green: 0.85, blue: 0.95, alpha: 1), NSColor(red: 0.18, green: 0.45, blue: 1.0, alpha: 1),
             NSColor(red: 0.45, green: 0.25, blue: 0.95, alpha: 1)]
let fresh = [NSColor(red: 0.25, green: 0.95, blue: 0.75, alpha: 1), NSColor(red: 0.10, green: 0.70, blue: 0.85, alpha: 1),
             NSColor(red: 0.20, green: 0.40, blue: 0.95, alpha: 1)]
let out = CommandLine.arguments[1]

// SpaceUp Studio — A: bold S with a rising arrow, sparkles top-right
icon("\(out)/spaceup-a.png", colors: brand) { _ in
  text("S", rounded(560, .heavy), center: CGPoint(x: 445, y: 500))
  drawSym(sym("arrow.up", 300, .black), center: CGPoint(x: 700, y: 470))
  drawSym(sym("sparkles", 190, .bold), center: CGPoint(x: 720, y: 760))
}
// SpaceUp Studio — B: S inside an upward chevron badge feel: S + small arrow above, sparkles left
icon("\(out)/spaceup-b.png", colors: brand) { _ in
  drawSym(sym("chevron.up", 210, .black), center: CGPoint(x: 512, y: 770))
  text("S", rounded(600, .heavy), center: CGPoint(x: 512, y: 430))
  drawSym(sym("sparkles", 170, .bold), center: CGPoint(x: 285, y: 735))
}
// Junk0 — A: a big zero ring ("junk zeroed out") with the AI sparkles inside it
icon("\(out)/junk0-a.png", colors: fresh) { ctx in
  let ring = NSBezierPath(ovalIn: CGRect(x: 512 - 215, y: 512 - 290, width: 430, height: 580))
  ring.lineWidth = 96; NSColor.white.setStroke(); ring.stroke()
  drawSym(sym("sparkles", 230, .bold), center: CGPoint(x: 512, y: 505))
}
// Junk0 — B: "J0" wordmark, slashed zero, sparkles top-right
icon("\(out)/junk0-b.png", colors: fresh) { _ in
  text("J", rounded(520, .heavy), center: CGPoint(x: 300, y: 490))
  let z = NSBezierPath(ovalIn: CGRect(x: 500, y: 300, width: 250, height: 370)); z.lineWidth = 70; NSColor.white.setStroke(); z.stroke()
  let sl = NSBezierPath(); sl.move(to: CGPoint(x: 545, y: 370)); sl.line(to: CGPoint(x: 705, y: 600)); sl.lineWidth = 46; sl.lineCapStyle = .round; sl.stroke()
  drawSym(sym("sparkles", 180, .bold), center: CGPoint(x: 745, y: 770))
}
print("ok")
