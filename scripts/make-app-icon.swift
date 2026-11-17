#!/usr/bin/env swift
// Renders the 1024×1024 app icon: blue gradient field with a white SF Symbols lock.
// Usage: swift scripts/make-app-icon.swift <output.png>

import AppKit

let size = 1024
let output = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"

guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("Could not create context") }

let top = CGColor(srgbRed: 0x4F / 255, green: 0x7D / 255, blue: 0xFF / 255, alpha: 1)
let bottom = CGColor(srgbRed: 0x1D / 255, green: 0x3F / 255, blue: 0xD8 / 255, alpha: 1)
let gradient = CGGradient(colorsSpace: nil, colors: [top, bottom] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: CGFloat(size)), end: CGPoint(x: CGFloat(size), y: 0), options: [])

let configuration = NSImage.SymbolConfiguration(pointSize: 470, weight: .semibold)
    .applying(.init(paletteColors: [.white]))
guard let symbol = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(configuration),
    let symbolImage = symbol.cgImage(forProposedRect: nil, context: nil, hints: nil)
else { fatalError("Could not render symbol") }

let width = CGFloat(symbolImage.width), height = CGFloat(symbolImage.height)
let scale = 540 / max(width, height)
let rect = CGRect(
    x: (CGFloat(size) - width * scale) / 2,
    y: (CGFloat(size) - height * scale) / 2 + 10,
    width: width * scale,
    height: height * scale
)
context.draw(symbolImage, in: rect)

let keyhole = CGColor(srgbRed: 0x34 / 255, green: 0x5A / 255, blue: 0xEE / 255, alpha: 1)
context.setFillColor(keyhole)
let holeCenter = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.33)
context.fillEllipse(in: CGRect(x: holeCenter.x - 42, y: holeCenter.y - 18, width: 84, height: 84))
context.fill(CGRect(x: holeCenter.x - 18, y: holeCenter.y - 78, width: 36, height: 90))

guard let image = context.makeImage(),
      let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
else { fatalError("Could not encode PNG") }
try data.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
