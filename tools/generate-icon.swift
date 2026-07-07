import Foundation
import AppKit

/// Generates macOS app icons from the zombie figure drawing code.
/// Produces icns file with multiple resolutions for proper app icon display.

// MARK: - Zombie Kind Definition (matches in-game ZombieKind from PlayfieldView)
enum ZombieKind {
    case classic, ghoul, reaper

    var skin: (lit: NSColor, dark: NSColor) {
        switch self {
        case .classic: return (NSColor(red: 0.55, green: 0.61, blue: 0.47, alpha: 1.0),
                               NSColor(red: 0.27, green: 0.34, blue: 0.24, alpha: 1.0))
        case .ghoul:   return (NSColor(red: 0.64, green: 0.59, blue: 0.69, alpha: 1.0),
                               NSColor(red: 0.33, green: 0.29, blue: 0.41, alpha: 1.0))
        case .reaper:  return (NSColor(red: 0.82, green: 0.81, blue: 0.74, alpha: 1.0),
                               NSColor(red: 0.43, green: 0.43, blue: 0.40, alpha: 1.0))
        }
    }

    var cloth: (lit: NSColor, dark: NSColor) {
        switch self {
        case .classic: return (NSColor(red: 0.20, green: 0.24, blue: 0.24, alpha: 1.0),
                               NSColor(red: 0.08, green: 0.10, blue: 0.10, alpha: 1.0))
        case .ghoul:   return (NSColor(red: 0.22, green: 0.17, blue: 0.29, alpha: 1.0),
                               NSColor(red: 0.09, green: 0.07, blue: 0.13, alpha: 1.0))
        case .reaper:  return (NSColor(red: 0.14, green: 0.14, blue: 0.17, alpha: 1.0),
                               NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0))
        }
    }

    var eyeColor: NSColor {
        switch self {
        case .classic: return NSColor(red: 1.0, green: 0.15, blue: 0.15, alpha: 1.0)
        case .ghoul:   return NSColor(red: 1.0, green: 0.95, blue: 0.2, alpha: 1.0)
        case .reaper:  return NSColor(red: 1.0, green: 0.65, blue: 0.1, alpha: 1.0)
        }
    }

    var isHooded: Bool { self == .reaper }
    var hairStrands: Int { self == .ghoul ? 9 : 5 }
    var hairLength: CGFloat { self == .ghoul ? 0.18 : 0.05 }
}

// MARK: - Icon Generator
class IconGenerator {
    
    /// Generate zombie app icon at given size
    static func generateIcon(size: CGFloat, kind: ZombieKind = .classic, background: NSColor = .black) -> NSImage {
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let image = NSImage(size: rect.size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Draw background (slight gradient)
        let bgPath = NSBezierPath(rect: rect)
        background.setFill()
        bgPath.fill()
        
        // Draw subtle dark-to-darker gradient
        let gradient = NSGradient(starting: NSColor(white: 0.1, alpha: 1.0),
                                  ending: NSColor(white: 0.0, alpha: 1.0))
        gradient?.draw(in: rect, angle: 90)
        
        // Draw zombie figure
        drawZombie(in: rect, size: size, kind: kind)
        
        return image
    }
    
    /// Draws the zombie figure matching the in-game ZombieFigure from PlayfieldView.swift:
    /// shaded gradients, sunken brow, glowing eye sockets, teeth, claw fingers, sleeves, and hair.
    private static func drawZombie(in rect: NSRect, size: CGFloat, kind: ZombieKind) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let skin = kind.skin
        let cloth = kind.cloth

        // Helper: stroke a limb segment with a vertical gradient.
        func limb(_ a: CGPoint, _ b: CGPoint, width: CGFloat, lit: NSColor, dark: NSColor) {
            ctx.saveGState()
            let path = CGMutablePath()
            path.move(to: a)
            path.addLine(to: b)
            ctx.setLineWidth(width)
            ctx.setLineCap(.round)
            // Gradient along the limb direction.
            ctx.addPath(path.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 1))
            ctx.clip()
            let colors = [lit.cgColor, dark.cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.drawLinearGradient(grad, start: a, end: b, options: [])
            }
            ctx.restoreGState()
        }

        // Head / body geometry (matches PlayfieldView).
        let headTop = 0.07 * h
        let headH = 0.27 * h
        let headW = 0.225 * h
        let headCY = headTop + headH / 2
        let headBottom = headTop + headH
        let shoulderY = headBottom + 0.045 * h
        let shoulderHalf = 0.20 * h
        let hemY = 0.82 * h

        // Soft ground shadow.
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.35).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 0.26 * h, y: 0.95 * h, width: 0.52 * h, height: 0.07 * h))

        // Legs (staggered shambling stance).
        limb(CGPoint(x: cx - 0.07 * h, y: hemY - 0.02 * h),
             CGPoint(x: cx - 0.085 * h, y: 0.97 * h),
             width: 0.11 * h, lit: cloth.lit, dark: cloth.dark)
        limb(CGPoint(x: cx + 0.07 * h, y: hemY - 0.02 * h),
             CGPoint(x: cx + 0.075 * h, y: 0.995 * h),
             width: 0.11 * h, lit: cloth.lit, dark: cloth.dark)

        // Helper: fill a path with a vertical gradient.
        func fillGrad(_ path: CGPath, top: CGFloat, bottom: CGFloat, lit: NSColor, dark: NSColor) {
            ctx.saveGState()
            ctx.addPath(path)
            ctx.clip()
            let colors = [lit.cgColor, dark.cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.drawLinearGradient(grad, start: CGPoint(x: cx, y: top), end: CGPoint(x: cx, y: bottom), options: [])
            }
            ctx.restoreGState()
        }

        if kind.isHooded {
            // Reaper: wide cloak from hood to ground with tattered hem.
            let cloak = CGMutablePath()
            cloak.move(to: CGPoint(x: cx - 0.10 * h, y: headCY))
            cloak.addQuadCurve(to: CGPoint(x: cx - 0.30 * h, y: 0.99 * h),
                               control: CGPoint(x: cx - 0.34 * h, y: 0.6 * h))
            var x = cx - 0.30 * h; var up = true
            while x < cx + 0.30 * h {
                x += 0.075 * h
                cloak.addLine(to: CGPoint(x: min(x, cx + 0.30 * h), y: up ? 0.95 * h : 0.99 * h))
                up.toggle()
            }
            cloak.addQuadCurve(to: CGPoint(x: cx + 0.10 * h, y: headCY),
                               control: CGPoint(x: cx + 0.34 * h, y: 0.6 * h))
            cloak.closeSubpath()
            fillGrad(cloak, top: headCY, bottom: h, lit: cloth.lit, dark: cloth.dark)
        } else {
            // Torso with ragged hem.
            let torso = CGMutablePath()
            torso.move(to: CGPoint(x: cx - shoulderHalf, y: shoulderY))
            torso.addLine(to: CGPoint(x: cx - 0.17 * h, y: hemY))
            var x = cx - 0.17 * h; var up = true
            while x < cx + 0.17 * h {
                x += 0.057 * h
                torso.addLine(to: CGPoint(x: min(x, cx + 0.17 * h), y: up ? hemY - 0.03 * h : hemY))
                up.toggle()
            }
            torso.addLine(to: CGPoint(x: cx + shoulderHalf, y: shoulderY))
            torso.addQuadCurve(to: CGPoint(x: cx - shoulderHalf, y: shoulderY),
                               control: CGPoint(x: cx, y: shoulderY - 0.05 * h))
            torso.closeSubpath()
            fillGrad(torso, top: shoulderY, bottom: hemY, lit: cloth.lit, dark: cloth.dark)
        }

        // Arms with sleeves and claw fingers (matches PlayfieldView).
        func arm(shoulder: CGPoint, elbow: CGPoint, hand: CGPoint) {
            // Bare skin forearms.
            limb(shoulder, elbow, width: 0.10 * h, lit: skin.lit, dark: skin.dark)
            limb(elbow, hand, width: 0.085 * h, lit: skin.lit, dark: skin.dark)
            // Torn sleeve on upper arm.
            let midX = (shoulder.x + elbow.x) / 2
            let midY = (shoulder.y + elbow.y) / 2
            limb(shoulder, CGPoint(x: midX, y: midY), width: 0.12 * h, lit: cloth.lit, dark: cloth.dark)
            // Hand.
            ctx.setFillColor(skin.dark.cgColor)
            ctx.fillEllipse(in: CGRect(x: hand.x - 0.05 * h, y: hand.y - 0.05 * h,
                                       width: 0.10 * h, height: 0.10 * h))
            // Three claw fingers.
            for dx in [-0.03, 0.0, 0.03] as [CGFloat] {
                ctx.setStrokeColor(skin.dark.cgColor)
                ctx.setLineWidth(0.02 * h)
                ctx.setLineCap(.round)
                ctx.move(to: CGPoint(x: hand.x + dx * h, y: hand.y + 0.02 * h))
                ctx.addLine(to: CGPoint(x: hand.x + dx * h, y: hand.y + 0.08 * h))
                ctx.strokePath()
            }
        }
        arm(shoulder: CGPoint(x: cx - shoulderHalf, y: shoulderY + 0.01 * h),
            elbow: CGPoint(x: cx - shoulderHalf - 0.01 * h, y: 0.50 * h),
            hand: CGPoint(x: cx - 0.12 * h, y: 0.65 * h))
        arm(shoulder: CGPoint(x: cx + shoulderHalf, y: shoulderY + 0.01 * h),
            elbow: CGPoint(x: cx + shoulderHalf + 0.01 * h, y: 0.48 * h),
            hand: CGPoint(x: cx + 0.10 * h, y: 0.63 * h))

        // Neck.
        ctx.setFillColor(skin.dark.cgColor)
        ctx.fill(CGRect(x: cx - 0.05 * h, y: headBottom - 0.02 * h, width: 0.10 * h, height: 0.08 * h))

        if kind.isHooded {
            // Hood framing the skull.
            let hoodRect = CGRect(x: cx - headW * 0.95, y: headTop - 0.03 * h,
                                  width: headW * 1.9, height: headH * 1.25)
            let hoodPath = CGMutablePath()
            hoodPath.addEllipse(in: hoodRect)
            fillGrad(hoodPath, top: headTop, bottom: headBottom, lit: cloth.lit, dark: cloth.dark)
        }

        // Head / skull with radial gradient.
        let headRect = CGRect(x: cx - headW / 2, y: headTop, width: headW, height: headH)
        ctx.saveGState()
        ctx.addEllipse(in: headRect)
        ctx.clip()
        let headColors = [skin.lit.cgColor, skin.dark.cgColor] as CFArray
        if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: headColors, locations: [0, 1]) {
            let center = CGPoint(x: cx - headW * 0.12, y: headTop + headH * 0.32)
            ctx.drawRadialGradient(grad, startCenter: center, startRadius: 1,
                                   endCenter: center, endRadius: headH * 0.7, options: .drawsAfterEndLocation)
        }
        ctx.restoreGState()

        // Sunken brow shadow.
        ctx.setFillColor(skin.dark.withAlphaComponent(0.6).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - headW * 0.42, y: headTop + headH * 0.30,
                                   width: headW * 0.84, height: headH * 0.30))

        // Eyes: dark sockets with a glowing pupil (matches PlayfieldView).
        let eyeY = headTop + headH * 0.45
        let eyeDX = headW * 0.23
        let socketR = headW * 0.17
        let glow = kind.eyeColor
        for sx in [cx - eyeDX, cx + eyeDX] {
            // Dark socket.
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.85).cgColor)
            ctx.fillEllipse(in: CGRect(x: sx - socketR, y: eyeY - socketR,
                                       width: socketR * 2, height: socketR * 2))
            // Glowing iris (simulate blur with a larger semi-transparent fill).
            ctx.setFillColor(glow.withAlphaComponent(0.35).cgColor)
            ctx.fillEllipse(in: CGRect(x: sx - socketR * 0.9, y: eyeY - socketR * 0.9,
                                       width: socketR * 1.8, height: socketR * 1.8))
            ctx.setFillColor(glow.withAlphaComponent(0.7).cgColor)
            ctx.fillEllipse(in: CGRect(x: sx - socketR * 0.6, y: eyeY - socketR * 0.6,
                                       width: socketR * 1.2, height: socketR * 1.2))
            // Bright pupil center.
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
            ctx.fillEllipse(in: CGRect(x: sx - socketR * 0.32, y: eyeY - socketR * 0.32,
                                       width: socketR * 0.64, height: socketR * 0.64))
        }

        // Nose hollow.
        ctx.setFillColor(skin.dark.withAlphaComponent(0.8).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - headW * 0.06, y: headTop + headH * 0.55,
                                   width: headW * 0.12, height: headH * 0.12))

        // Mouth: dark gash with crude teeth.
        let mouthY = headTop + headH * 0.78
        let mouthW = headW * 0.5
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.8).cgColor)
        ctx.fill(CGRect(x: cx - mouthW / 2, y: mouthY, width: mouthW, height: headH * 0.10))
        var tx = cx - mouthW / 2
        while tx < cx + mouthW / 2 {
            ctx.setFillColor(skin.lit.withAlphaComponent(0.85).cgColor)
            ctx.fill(CGRect(x: tx, y: mouthY, width: mouthW * 0.10, height: headH * 0.05))
            tx += mouthW * 0.18
        }

        // Hair: sparse tufts (classic/ghoul) — not drawn for hooded reaper.
        if !kind.isHooded {
            let strands = kind.hairStrands
            let len = kind.hairLength * h
            for i in 0..<strands {
                let t = CGFloat(i) / CGFloat(strands - 1)
                let sx = cx - headW * 0.5 + t * headW
                ctx.setStrokeColor(cloth.dark.withAlphaComponent(0.95).cgColor)
                ctx.setLineWidth(0.015 * h)
                ctx.setLineCap(.round)
                let hairPath = CGMutablePath()
                hairPath.move(to: CGPoint(x: sx, y: headTop + 0.01 * h))
                hairPath.addQuadCurve(to: CGPoint(x: sx + (t - 0.5) * 0.06 * h, y: headTop - 0.02 * h + len),
                                      control: CGPoint(x: sx + (t - 0.5) * 0.12 * h, y: headTop))
                ctx.addPath(hairPath)
                ctx.strokePath()
            }
        }
    }
    
    /// Generate all required icon sizes and save as icns
    static func generateAppIcon(outputPath: String, kind: ZombieKind = .classic) {
        let sizes: [(CGFloat, String)] = [
            (16, "16x16"),
            (32, "32x32"),
            (64, "64x64"),
            (128, "128x128"),
            (256, "256x256"),
            (512, "512x512"),
            (1024, "1024x1024")
        ]
        
        // Create temporary directory for icon set
        let tempDir = "/tmp/WOTD.iconset"
        try? FileManager.default.removeItem(atPath: tempDir)
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        
        // Generate each size
        for (size, label) in sizes {
            let image = generateIcon(size: size, kind: kind)
            
            // Save PNG
            if let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                let fileName = "icon_\(label).png"
                let filePath = (tempDir as NSString).appendingPathComponent(fileName)
                try? pngData.write(to: URL(fileURLWithPath: filePath))
                print("✓ Generated \(label): \(filePath)")
            }
        }
        
        // Convert iconset to icns
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", "-o", outputPath, tempDir]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                print("✅ App icon created: \(outputPath)")
            } else {
                print("❌ Icon generation failed")
            }
        } catch {
            print("❌ Failed to run iconutil: \(error)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(atPath: tempDir)
    }
}

// MARK: - Main
if CommandLine.argc > 1 {
    let outputPath = CommandLine.arguments[1]
    IconGenerator.generateAppIcon(outputPath: outputPath, kind: .classic)
} else {
    IconGenerator.generateAppIcon(outputPath: "/tmp/AppIcon.icns", kind: .classic)
    print("Usage: swift generate-icon.swift <output-path>")
    print("Example: swift generate-icon.swift WordsOfTheDead/Resources/AppIcon.icns")
}
