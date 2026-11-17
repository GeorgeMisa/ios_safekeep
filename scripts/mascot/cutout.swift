import AppKit
import Vision
import CoreImage

let src = CommandLine.arguments[1], dst = CommandLine.arguments[2], size = 720
let ci = CIImage(contentsOf: URL(fileURLWithPath: src))!
let handler = VNImageRequestHandler(ciImage: ci)
let request = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([request])
guard let result = request.results?.first else { fatalError("no subject in \(src)") }
let buffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: false)
let masked = CIImage(cvPixelBuffer: buffer)
let scale = CGFloat(size) / masked.extent.width
let scaled = masked.transformed(by: .init(scaleX: scale, y: scale))
let context = CIContext()
let cg = context.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: size, height: size), format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)!
try NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: dst))
print("ok", dst, result.allInstances.count, "instances")
