import AppKit

// Merges the Vision cutout with any coloured marks drawn on the white background,
// recovering their alpha by un-mixing them from white.
let original = CommandLine.arguments[1], cutout = CommandLine.arguments[2], dst = CommandLine.arguments[3]
let size = 720

func pixels(_ path: String) -> [UInt8] {
    let image = NSImage(contentsOfFile: path)!
    var data = [UInt8](repeating: 0, count: size * size * 4)
    let ctx = CGContext(data: &data, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.draw(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, in: CGRect(x: 0, y: 0, width: size, height: size))
    return data
}

let src = pixels(original)
var out = pixels(cutout)
let bg: [Double] = [253, 254, 254]
for i in stride(from: 0, to: out.count, by: 4) {
    let subjectAlpha = Double(out[i + 3]) / 255
    guard subjectAlpha < 0.5 else { continue }
    let c = (0..<3).map { Double(src[i + $0]) }
    let alpha = (0..<3).map { (bg[$0] - c[$0]) / bg[$0] }.max()!
    let a = alpha < 0.08 ? 0 : min(1, (alpha - 0.08) / 0.92 * 1.1)
    guard a > subjectAlpha else { continue }
    for k in 0..<3 {
        let unmixed = (c[k] - (1 - a) * bg[k]) / max(a, 0.001)
        out[i + k] = UInt8(max(0, min(255, unmixed * a)))
    }
    out[i + 3] = UInt8(a * 255)
}

let ctx = CGContext(data: &out, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// One shared crop for every pose keeps their scale identical and puts the feet on the bottom edge.
let shared = CGRect(x: 60, y: 88, width: 600, height: 570)
try NSBitmapImageRep(cgImage: ctx.makeImage()!.cropping(to: shared)!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: dst))
