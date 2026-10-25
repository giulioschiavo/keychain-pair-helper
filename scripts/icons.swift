// Original geometric icon: two interlocking chain links. No vendor assets.
import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let sizes = [16, 32, 48, 64, 128, 256, 512, 1024]
for size in sizes {
    let image = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: image)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: CGFloat(size) / 128, y: CGFloat(size) / 128)
    NSColor(calibratedRed: 0.08, green: 0.30, blue: 0.65, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 128, height: 128), xRadius: 29, yRadius: 29).fill()
    ctx.translateBy(x: 64, y: 64)
    ctx.rotate(by: .pi * 35 / 180)
    let first = NSBezierPath(roundedRect: NSRect(x: -39, y: -17, width: 53, height: 34), xRadius: 17, yRadius: 17)
    first.lineWidth = 9
    NSColor.white.setStroke(); first.stroke()
    let second = NSBezierPath(roundedRect: NSRect(x: -14, y: -17, width: 53, height: 34), xRadius: 17, yRadius: 17)
    second.lineWidth = 9
    NSColor(calibratedRed: 0.48, green: 0.84, blue: 0.95, alpha: 1).setStroke(); second.stroke()
    NSGraphicsContext.restoreGraphicsState()
    let data = image.representation(using: .png, properties: [:])!
    try data.write(to: output.appendingPathComponent("icon\(size).png"))
}
