import AppKit

// Junk0 icon, refined: monoline J + slashed zero drawn as true geometry (equal stroke weight),
// soft white-to-ice glyph gradient, layered mint→blue background with light falloff and edge bevel,
// and the AI sparkles as crafted 4-point stars (concave sides, like Apple's sparkle).
let S: CGFloat = 1024
let inset: CGFloat = 100, R = S - inset * 2
let box = CGRect(x: inset, y: inset, width: R, height: R)
let corner = R * 0.2237

func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a) }
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func grad(_ cols: [CGColor], _ locs: [CGFloat]) -> CGGradient { CGGradient(colorsSpace: cs, colors: cols as CFArray, locations: locs)! }

func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, pinch: CGFloat = 0.18) -> CGPath {
  let p = CGMutablePath()
  let pts = [CGPoint(x: cx, y: cy + r), CGPoint(x: cx + r, y: cy), CGPoint(x: cx, y: cy - r), CGPoint(x: cx - r, y: cy)]
  p.move(to: pts[0])
  for i in 0..<4 {
    let a = pts[i], b = pts[(i + 1) % 4]
    let ctrl = CGPoint(x: cx + ((a.x - cx) + (b.x - cx)) * pinch, y: cy + ((a.y - cy) + (b.y - cy)) * pinch)
    p.addQuadCurve(to: b, control: ctrl)
  }
  p.closeSubpath()
  return p
}

var k: CGFloat = 1
func render(_ file: String, size: CGFloat) {
  k = size / S
  let px = Int(size)
  let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.scaleBy(x: size / S, y: size / S)
  let tile = CGPath(roundedRect: box, cornerWidth: corner, cornerHeight: corner, transform: nil)

  // drop shadow of the tile
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -14 * k), blur: 34 * k, color: c(0, 30, 60, 0.35))
  ctx.addPath(tile); ctx.setFillColor(c(30, 120, 200)); ctx.fillPath()
  ctx.restoreGState()

  // background: mint → teal → deep blue, plus light falloff from top-left
  ctx.saveGState()
  ctx.addPath(tile); ctx.clip()
  ctx.drawLinearGradient(grad([c(92, 236, 196), c(28, 186, 214), c(30, 104, 236), c(44, 64, 200)], [0, 0.38, 0.78, 1]),
                         start: CGPoint(x: 220, y: 930), end: CGPoint(x: 820, y: 80), options: [])
  ctx.drawRadialGradient(grad([c(255, 255, 255, 0.30), c(255, 255, 255, 0)], [0, 1]),
                         startCenter: CGPoint(x: 300, y: 860), startRadius: 0, endCenter: CGPoint(x: 300, y: 860), endRadius: 620, options: [])
  ctx.drawRadialGradient(grad([c(10, 20, 90, 0), c(10, 20, 90, 0.22)], [0.55, 1]),
                         startCenter: CGPoint(x: 512, y: 560), startRadius: 0, endCenter: CGPoint(x: 512, y: 560), endRadius: 640, options: [])

  // glyph geometry (shared stroke weight)
  let W: CGFloat = 92
  let glyph = CGMutablePath()
  // J: stem + hook
  glyph.move(to: CGPoint(x: 392, y: 708))
  glyph.addLine(to: CGPoint(x: 392, y: 440))
  glyph.addArc(center: CGPoint(x: 300, y: 440), radius: 92, startAngle: 0, endAngle: -.pi * 0.98, clockwise: true)
  // Ø: slightly squarish zero (superellipse feel via rounded rect)
  let zero = CGRect(x: 498, y: 300, width: 262, height: 408)
  glyph.addPath(CGPath(roundedRect: zero, cornerWidth: 131, cornerHeight: 150, transform: nil))
  let stroked = glyph.copy(strokingWithWidth: W, lineCap: .round, lineJoin: .round, miterLimit: 10)
  // slash, thinner, kept inside the zero
  let slash = CGMutablePath()
  slash.move(to: CGPoint(x: 560, y: 382)); slash.addLine(to: CGPoint(x: 698, y: 626))
  let slashS = slash.copy(strokingWithWidth: W * 0.62, lineCap: .round, lineJoin: .round, miterLimit: 10)
  let raw = CGMutablePath(); raw.addPath(stroked); raw.addPath(slashS)
  var t = CGAffineTransform(translationX: 500, y: 492).scaledBy(x: 0.84, y: 0.84).translatedBy(x: -530, y: -505)
  let all = raw.copy(using: &t)!

  // glyph shadow + fill
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -10 * k), blur: 22 * k, color: c(0, 30, 90, 0.35))
  ctx.addPath(all); ctx.setFillColor(c(255, 255, 255)); ctx.fillPath()
  ctx.restoreGState()
  ctx.saveGState()
  ctx.addPath(all); ctx.clip()
  ctx.drawLinearGradient(grad([c(255, 255, 255), c(234, 246, 255)], [0, 1]),
                         start: CGPoint(x: 0, y: 720), end: CGPoint(x: 0, y: 290), options: [])
  ctx.restoreGState()

  // AI sparkles, top-right, echoing the slash direction
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -6 * k), blur: 16 * k, color: c(0, 30, 90, 0.30))
  ctx.addPath(star(752, 746, 60)); ctx.addPath(star(818, 668, 27)); ctx.addPath(star(690, 812, 20))
  ctx.setFillColor(c(255, 255, 255)); ctx.fillPath()
  ctx.restoreGState()
  ctx.restoreGState()

  // bevel: thin light edge on top, faint dark edge on bottom
  ctx.saveGState()
  ctx.addPath(tile); ctx.clip()
  ctx.addPath(tile); ctx.setLineWidth(6)
  ctx.replacePathWithStrokedPath(); ctx.clip()
  ctx.drawLinearGradient(grad([c(255, 255, 255, 0.55), c(255, 255, 255, 0.05), c(0, 0, 40, 0.18)], [0, 0.5, 1]),
                         start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])
  ctx.restoreGState()

  let img = ctx.makeImage()!
  let rep = NSBitmapImageRep(cgImage: img)
  try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: file))
}

let out = CommandLine.arguments[1]
render("\(out)/junk0-pro.png", size: 1024)
for s in [256, 128, 64, 32] { render("\(out)/junk0-pro-\(s).png", size: CGFloat(s)) }
print("ok")
