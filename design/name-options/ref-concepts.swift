import AppKit

// Ref-1 frame (black tile, violet glow rising from the bottom, white→lavender glyph)
// + Ref-2 interiors (Swiss bars crossed by a line, shapes cut out as negative space). Sparkles kept.
let S: CGFloat = 1024, inset: CGFloat = 100, R = S - inset * 2
let box = CGRect(x: inset, y: inset, width: R, height: R), corner = R * 0.2237
let mid = CGPoint(x: 512, y: 512)
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a) }
func grad(_ cols: [CGColor], _ locs: [CGFloat]) -> CGGradient { CGGradient(colorsSpace: cs, colors: cols as CFArray, locations: locs)! }
var k: CGFloat = 1

func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, pinch: CGFloat = 0.16) -> CGPath {
  let p = CGMutablePath()
  let pts = [CGPoint(x: cx, y: cy + r), CGPoint(x: cx + r, y: cy), CGPoint(x: cx, y: cy - r), CGPoint(x: cx - r, y: cy)]
  p.move(to: pts[0])
  for i in 0..<4 {
    let a = pts[i], b = pts[(i + 1) % 4]
    p.addQuadCurve(to: b, control: CGPoint(x: cx + ((a.x - cx) + (b.x - cx)) * pinch, y: cy + ((a.y - cy) + (b.y - cy)) * pinch))
  }
  p.closeSubpath(); return p
}
/// White → lavender glyph with a soft violet glow (Ref 1).
func glyph(_ ctx: CGContext, _ p: CGPath, alpha: CGFloat = 1, top: CGFloat = 820, bottom: CGFloat = 230) {
  ctx.saveGState()
  ctx.setShadow(offset: .zero, blur: 40 * k, color: c(150, 120, 255, 0.35 * alpha))
  ctx.addPath(p); ctx.setFillColor(c(235, 228, 255, alpha)); ctx.fillPath()
  ctx.restoreGState()
  ctx.saveGState(); ctx.addPath(p); ctx.clip(); ctx.setAlpha(alpha)
  ctx.drawLinearGradient(grad([c(255, 255, 255), c(244, 240, 255), c(206, 194, 255)], [0, 0.55, 1]),
                         start: CGPoint(x: 0, y: top), end: CGPoint(x: 0, y: bottom), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
  ctx.restoreGState()
}

func tileIcon(_ file: String, size: CGFloat, content: (CGContext) -> Void) {
  k = size / S
  let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.scaleBy(x: k, y: k)
  let tile = CGPath(roundedRect: box, cornerWidth: corner, cornerHeight: corner, transform: nil)
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -16 * k), blur: 40 * k, color: c(60, 30, 160, 0.45))
  ctx.addPath(tile); ctx.setFillColor(c(10, 9, 16)); ctx.fillPath()
  ctx.restoreGState()
  ctx.saveGState(); ctx.addPath(tile); ctx.clip()
  // black at the top → deep violet → bright lavender rim at the bottom
  ctx.drawLinearGradient(grad([c(196, 180, 255), c(128, 96, 255), c(58, 38, 150), c(18, 14, 34), c(8, 8, 12)], [0, 0.045, 0.15, 0.34, 1]),
                         start: CGPoint(x: 0, y: inset), end: CGPoint(x: 0, y: S - inset), options: [])
  ctx.drawRadialGradient(grad([c(150, 120, 255, 0.55), c(110, 80, 255, 0)], [0, 1]),
                         startCenter: CGPoint(x: 512, y: 60), startRadius: 0, endCenter: CGPoint(x: 512, y: 60), endRadius: 380, options: [])
  content(ctx)
  ctx.restoreGState()
  // rim: faint top highlight, brighter lavender along the bottom
  ctx.saveGState(); ctx.addPath(tile); ctx.clip(); ctx.addPath(tile); ctx.setLineWidth(7); ctx.replacePathWithStrokedPath(); ctx.clip()
  ctx.drawLinearGradient(grad([c(225, 215, 255, 0.85), c(140, 110, 255, 0.25), c(255, 255, 255, 0.04), c(255, 255, 255, 0.16)], [0, 0.2, 0.7, 1]),
                         start: CGPoint(x: 0, y: inset), end: CGPoint(x: 0, y: S - inset), options: [])
  ctx.restoreGState()
  try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: file))
}

func rect(_ x: CGFloat, _ w: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> CGRect { CGRect(x: x, y: y0, width: w, height: y1 - y0) }

// D — "Zero cut": Swiss bars + crossing line, a zero ring cut out of them as negative space, sparkle inside.
func conceptD(_ ctx: CGContext) {
  let bars = CGMutablePath()
  for r in [rect(262, 64, 330, 748), rect(372, 92, 268, 680), rect(492, 48, 392, 812), rect(574, 104, 300, 664),
            rect(712, 58, 352, 760)] { bars.addRect(r) }
  bars.addRect(rect(222, 580, 496, 522))          // the horizontal line
  let ring = CGMutablePath(); ring.addArc(center: mid, radius: 176, startAngle: 0, endAngle: .pi * 2, clockwise: false)
  let cut = ring.copy(strokingWithWidth: 62, lineCap: .butt, lineJoin: .miter, miterLimit: 10)
  ctx.saveGState()
  ctx.addRect(box); ctx.addPath(cut); ctx.clip(using: .evenOdd)               // knock the ring out of the bars
  ctx.addRect(box); ctx.addPath(CGPath(ellipseIn: CGRect(x: 512 - 145, y: 512 - 145, width: 290, height: 290), transform: nil))
  ctx.clip(using: .evenOdd)                                                    // and clear the inside of the zero
  glyph(ctx, bars)
  ctx.restoreGState()
  glyph(ctx, star(512, 509, 92))
}
// E — "Cleared": bars stepping down to nothing; the freed space holds the sparkles.
func conceptE(_ ctx: CGContext) {
  let bars = CGMutablePath()
  let hs: [CGFloat] = [560, 470, 380, 290, 200]
  for (i, h) in hs.enumerated() { bars.addRect(rect(250 + CGFloat(i) * 78, 50, 260, 260 + h)) }
  bars.addRect(rect(220, 590, 232, 254))
  glyph(ctx, bars)
  let sp = CGMutablePath(); sp.addPath(star(700, 600, 86)); sp.addPath(star(790, 720, 36)); sp.addPath(star(640, 730, 26))
  glyph(ctx, sp)
}
// F — Layers clear (the earlier favourite) in the Ref-1 frame.
func diamond(_ cy: CGFloat, _ w: CGFloat) -> CGPath {
  var t = CGAffineTransform(translationX: 512, y: cy).scaledBy(x: 1, y: 0.56).rotated(by: .pi / 4)
  return CGPath(roundedRect: CGRect(x: -w / 2, y: -w / 2, width: w, height: w), cornerWidth: w * 0.16, cornerHeight: w * 0.16, transform: &t)
}
func conceptF(_ ctx: CGContext) {
  glyph(ctx, diamond(360, 390))
  glyph(ctx, diamond(480, 390), alpha: 0.5)
  ctx.saveGState(); ctx.addPath(diamond(600, 390).copy(strokingWithWidth: 9, lineCap: .round, lineJoin: .round, miterLimit: 10))
  ctx.setFillColor(c(220, 210, 255, 0.5)); ctx.fillPath(); ctx.restoreGState()
  let sp = CGMutablePath(); sp.addPath(star(512, 735, 96)); sp.addPath(star(632, 665, 40)); sp.addPath(star(398, 790, 28))
  glyph(ctx, sp)
}

let out = CommandLine.arguments[1]
for (n, f) in [("ref-d-zero-cut", conceptD), ("ref-e-cleared", conceptE), ("ref-f-layers", conceptF)] as [(String, (CGContext) -> Void)] {
  for s in [1024, 128, 64, 32] { tileIcon("\(out)/\(n)\(s == 1024 ? "" : "-\(s)").png", size: CGFloat(s), content: f) }
}
print("ok")

// D2 — "Zero cut", refined: strict 5-column grid (equal gutters), dense enough that the zero reads
// from the cut alone; zero is an upright oval (a numeral, not a letter O); the counter is cleared;
// no glow inside the knockout, so edges stay crisp.
func crisp(_ ctx: CGContext, _ p: CGPath) {
  ctx.saveGState(); ctx.addPath(p); ctx.clip()
  ctx.drawLinearGradient(grad([c(255, 255, 255), c(246, 243, 255), c(206, 194, 255)], [0, 0.55, 1]),
                         start: CGPoint(x: 0, y: 840), end: CGPoint(x: 0, y: 200), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
  ctx.restoreGState()
}
func conceptD2(_ ctx: CGContext) {
  let gutter: CGFloat = 20
  let widths: [CGFloat] = [84, 110, 66, 110, 84]
  let spans: [(CGFloat, CGFloat)] = [(318, 712), (246, 788), (300, 832), (222, 752), (282, 726)]
  var x: CGFloat = 512 - (widths.reduce(0, +) + gutter * CGFloat(widths.count - 1)) / 2
  let bars = CGMutablePath()
  for (w, s) in zip(widths, spans) { bars.addRect(CGRect(x: x, y: s.0, width: w, height: s.1 - s.0)); x += w + gutter }
  bars.addRect(CGRect(x: 214, y: 507, width: 596, height: 22))           // crossing line, slightly wider than the grid
  let center = CGPoint(x: 512, y: 518)
  let outer = CGRect(x: center.x - 172, y: center.y - 232, width: 344, height: 464)
  let inner = outer.insetBy(dx: 64, dy: 64)
  let zero = CGMutablePath()
  zero.addPath(CGPath(ellipseIn: outer, transform: nil)); zero.addPath(CGPath(ellipseIn: inner, transform: nil))
  let gapW: CGFloat = 24, ringW: CGFloat = 54
  let hole = outer.insetBy(dx: -gapW, dy: -gapW)
  // bars, with an oval window cut out of them (crisp edges, no glow inside)
  ctx.saveGState()
  ctx.addRect(box); ctx.addPath(CGPath(ellipseIn: hole, transform: nil)); ctx.clip(using: .evenOdd)
  crisp(ctx, bars)
  ctx.restoreGState()
  // the numeral: a clean zero ring sitting inside the window
  let ringRect = outer.insetBy(dx: ringW / 2, dy: ringW / 2)
  let ring = CGPath(ellipseIn: ringRect, transform: nil).copy(strokingWithWidth: ringW, lineCap: .butt, lineJoin: .miter, miterLimit: 10)
  crisp(ctx, ring)
  // AI sparkles in the cleared counter
  crisp(ctx, star(center.x, center.y - 6, 78))
  crisp(ctx, star(center.x + 62, center.y + 104, 24))
}
for s in [1024, 128, 64, 32] { tileIcon("\(CommandLine.arguments[1])/ref-d2-zero-cut\(s == 1024 ? "" : "-\(s)").png", size: CGFloat(s), content: conceptD2) }

// D3 — rounder, wider zero; horizontal line only (no vertical bars). D3b — same, with tiny bar ticks on the line.
func conceptD3(_ ctx: CGContext, ticks: Bool) {
  let center = CGPoint(x: 512, y: 512)
  let ringW: CGFloat = 60, gapW: CGFloat = 26
  let outer = CGRect(x: center.x - 228, y: center.y - 262, width: 456, height: 524)   // rounder & wider than D2
  let hole = outer.insetBy(dx: -gapW, dy: -gapW)
  let line = CGMutablePath()
  line.addRect(CGRect(x: 158, y: center.y - 12, width: 708, height: 24))
  if ticks {   // small Swiss tick bars sitting on the line, outside the zero
    for (x, h) in [(212.0, 70.0), (242.0, 44.0), (782.0, 58.0), (808.0, 36.0)] as [(CGFloat, CGFloat)] {
      line.addRect(CGRect(x: x - 7, y: center.y - h / 2, width: 14, height: h))
    }
  }
  ctx.saveGState()
  ctx.addRect(box); ctx.addPath(CGPath(ellipseIn: hole, transform: nil)); ctx.clip(using: .evenOdd)
  ctx.setShadow(offset: .zero, blur: 30 * k, color: c(150, 120, 255, 0.35))
  ctx.addPath(line); ctx.setFillColor(c(235, 228, 255)); ctx.fillPath()
  ctx.restoreGState()
  ctx.saveGState(); ctx.addRect(box); ctx.addPath(CGPath(ellipseIn: hole, transform: nil)); ctx.clip(using: .evenOdd); crisp(ctx, line); ctx.restoreGState()
  let ring = CGPath(ellipseIn: outer.insetBy(dx: ringW / 2, dy: ringW / 2), transform: nil)
    .copy(strokingWithWidth: ringW, lineCap: .butt, lineJoin: .miter, miterLimit: 10)
  glyph(ctx, ring)
  glyph(ctx, star(center.x, center.y, 104))
  glyph(ctx, star(center.x + 70, center.y + 98, 30))
  glyph(ctx, star(center.x - 64, center.y - 94, 19))
}
for s in [1024, 128, 64, 32] {
  tileIcon("\(CommandLine.arguments[1])/ref-d3-zero\(s == 1024 ? "" : "-\(s)").png", size: CGFloat(s)) { conceptD3($0, ticks: false) }
  tileIcon("\(CommandLine.arguments[1])/ref-d3b-zero-ticks\(s == 1024 ? "" : "-\(s)").png", size: CGFloat(s)) { conceptD3($0, ticks: true) }
}
