import AppKit

// Symbol-based icon concepts for Junk0 — no letters. Each keeps the AI sparkles.
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
/// White glyph with soft ice gradient and drop shadow.
func glyph(_ ctx: CGContext, _ p: CGPath, alpha: CGFloat = 1, shadow: Bool = true) {
  ctx.saveGState()
  if shadow { ctx.setShadow(offset: CGSize(width: 0, height: -10 * k), blur: 24 * k, color: c(0, 25, 90, 0.32 * alpha)) }
  ctx.addPath(p); ctx.setFillColor(c(255, 255, 255, alpha)); ctx.fillPath()
  ctx.restoreGState()
  ctx.saveGState(); ctx.addPath(p); ctx.clip(); ctx.setAlpha(alpha)
  ctx.drawLinearGradient(grad([c(255, 255, 255), c(228, 243, 255)], [0, 1]), start: CGPoint(x: 0, y: 800), end: CGPoint(x: 0, y: 220), options: [])
  ctx.restoreGState()
}
func sparkles(_ ctx: CGContext, _ list: [(CGFloat, CGFloat, CGFloat)]) {
  let p = CGMutablePath(); for (x, y, r) in list { p.addPath(star(x, y, r)) }
  glyph(ctx, p)
}

func tileIcon(_ file: String, size: CGFloat, bg: [CGColor], content: (CGContext) -> Void) {
  k = size / S
  let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.scaleBy(x: k, y: k)
  let tile = CGPath(roundedRect: box, cornerWidth: corner, cornerHeight: corner, transform: nil)
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -14 * k), blur: 34 * k, color: c(0, 30, 60, 0.35))
  ctx.addPath(tile); ctx.setFillColor(bg.last!); ctx.fillPath()
  ctx.restoreGState()
  ctx.saveGState(); ctx.addPath(tile); ctx.clip()
  ctx.drawLinearGradient(grad(bg, (0..<bg.count).map { CGFloat($0) / CGFloat(bg.count - 1) }),
                         start: CGPoint(x: 230, y: 940), end: CGPoint(x: 800, y: 80), options: [])
  ctx.drawRadialGradient(grad([c(255, 255, 255, 0.28), c(255, 255, 255, 0)], [0, 1]),
                         startCenter: CGPoint(x: 300, y: 870), startRadius: 0, endCenter: CGPoint(x: 300, y: 870), endRadius: 640, options: [])
  ctx.drawRadialGradient(grad([c(10, 20, 80, 0), c(10, 20, 80, 0.20)], [0.55, 1]),
                         startCenter: mid, startRadius: 0, endCenter: mid, endRadius: 660, options: [])
  content(ctx)
  ctx.restoreGState()
  // edge bevel
  ctx.saveGState(); ctx.addPath(tile); ctx.clip(); ctx.addPath(tile); ctx.setLineWidth(6); ctx.replacePathWithStrokedPath(); ctx.clip()
  ctx.drawLinearGradient(grad([c(255, 255, 255, 0.55), c(255, 255, 255, 0.05), c(0, 0, 40, 0.18)], [0, 0.5, 1]),
                         start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])
  ctx.restoreGState()
  try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: file))
}

let mint = [c(92, 236, 196), c(28, 186, 214), c(30, 104, 236), c(44, 64, 200)]
let night = [c(70, 92, 255), c(52, 58, 210), c(34, 28, 120), c(20, 16, 70)]
let aqua = [c(120, 220, 255), c(40, 150, 255), c(30, 90, 230), c(40, 50, 190)]

// A — "Zero gauge": a storage ring emptied to zero; sparkles where the junk used to be.
func conceptA(_ ctx: CGContext) {
  let track = CGMutablePath(); track.addArc(center: mid, radius: 262, startAngle: 0, endAngle: .pi * 2, clockwise: false)
  ctx.saveGState(); ctx.addPath(track.copy(strokingWithWidth: 78, lineCap: .round, lineJoin: .round, miterLimit: 10))
  ctx.setFillColor(c(255, 255, 255, 0.16)); ctx.fillPath(); ctx.restoreGState()
  let arc = CGMutablePath()
  arc.addArc(center: mid, radius: 262, startAngle: .pi / 4 - 0.36, endAngle: .pi / 4 + 0.36 - .pi * 2, clockwise: true)
  glyph(ctx, arc.copy(strokingWithWidth: 78, lineCap: .round, lineJoin: .round, miterLimit: 10))
  sparkles(ctx, [(512, 512, 112), (712, 712, 50), (800, 800, 26)])
}
// B — "Layers clear": stacked cache layers; the top layer dissolves into sparkles.
func diamond(_ cy: CGFloat, _ w: CGFloat) -> CGPath {
  var t = CGAffineTransform(translationX: 512, y: cy).scaledBy(x: 1, y: 0.56).rotated(by: .pi / 4)
  return CGPath(roundedRect: CGRect(x: -w / 2, y: -w / 2, width: w, height: w), cornerWidth: w * 0.16, cornerHeight: w * 0.16, transform: &t)
}
func conceptB(_ ctx: CGContext) {
  glyph(ctx, diamond(350, 380), alpha: 1)
  glyph(ctx, diamond(470, 380), alpha: 0.55)
  let ghost = diamond(590, 380)
  ctx.saveGState(); ctx.addPath(ghost.copy(strokingWithWidth: 10, lineCap: .round, lineJoin: .round, miterLimit: 10))
  ctx.setFillColor(c(255, 255, 255, 0.45)); ctx.fillPath(); ctx.restoreGState()
  sparkles(ctx, [(512, 720, 96), (630, 650, 40), (400, 780, 30)])
}
// C — "Clean disk": a storage platter with a bright sweep clearing it; sparkles trail the sweep.
func conceptC(_ ctx: CGContext) {
  let disk = CGPath(ellipseIn: CGRect(x: 512 - 300, y: 512 - 300, width: 600, height: 600), transform: nil)
  glyph(ctx, disk, alpha: 0.18, shadow: false)
  for r in [230.0, 170.0] as [CGFloat] {
    let ring = CGPath(ellipseIn: CGRect(x: 512 - r, y: 512 - r, width: 2 * r, height: 2 * r), transform: nil)
    ctx.saveGState(); ctx.addPath(ring.copy(strokingWithWidth: 8, lineCap: .round, lineJoin: .round, miterLimit: 10))
    ctx.setFillColor(c(255, 255, 255, 0.30)); ctx.fillPath(); ctx.restoreGState()
  }
  glyph(ctx, CGPath(ellipseIn: CGRect(x: 512 - 58, y: 512 - 58, width: 116, height: 116), transform: nil))
  let sweep = CGMutablePath(); sweep.addArc(center: mid, radius: 300, startAngle: .pi * 0.95, endAngle: .pi * 0.40, clockwise: true)
  glyph(ctx, sweep.copy(strokingWithWidth: 56, lineCap: .round, lineJoin: .round, miterLimit: 10))
  sparkles(ctx, [(712, 760, 74), (790, 668, 30), (640, 836, 24)])
}

let out = CommandLine.arguments[1]
for (name, bg, f) in [("concept-a-zero-gauge", mint, conceptA), ("concept-b-layers", night, conceptB), ("concept-c-disk", aqua, conceptC)] as [(String, [CGColor], (CGContext) -> Void)] {
  for s in [1024, 128, 64, 32] { tileIcon("\(out)/\(name)\(s == 1024 ? "" : "-\(s)").png", size: CGFloat(s), bg: bg, content: f) }
}
print("ok")
