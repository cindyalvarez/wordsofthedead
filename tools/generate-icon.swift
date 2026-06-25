import Foundation
import AppKit

/// Generates macOS app icons from the zombie figure drawing code.
/// Produces icns file with multiple resolutions for proper app icon display.

// MARK: - Zombie Kind Definition
enum ZombieKind {
    case standard, hooded
    
    var skin: (lit: NSColor, dark: NSColor) {
        let lit = NSColor(red: 0.65, green: 0.73, blue: 0.50, alpha: 1.0)
        let dark = NSColor(red: 0.42, green: 0.51, blue: 0.28, alpha: 1.0)
        return (lit, dark)
    }
    
    var cloth: (lit: NSColor, dark: NSColor) {
        switch self {
        case .standard:
            return (NSColor(red: 0.40, green: 0.30, blue: 0.25, alpha: 1.0),
                    NSColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 1.0))
        case .hooded:
            return (NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0),
                    NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0))
        }
    }
    
    var isHooded: Bool {
        self == .hooded
    }
}

// MARK: - Icon Generator
class IconGenerator {
    
    /// Generate zombie app icon at given size
    static func generateIcon(size: CGFloat, kind: ZombieKind = .standard, background: NSColor = .black) -> NSImage {
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
    
    private static func drawZombie(in rect: NSRect, size: CGFloat, kind: ZombieKind) {
        guard let ctx = NSGraphicsContext.current else { return }
        ctx.saveGraphicsState()
        defer { ctx.restoreGraphicsState() }
        
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let skin = kind.skin
        let cloth = kind.cloth
        
        // Head / body geometry
        let headTop = 0.07 * h
        let headH = 0.27 * h
        let headW = 0.225 * h
        let headCY = headTop + headH / 2
        let headBottom = headTop + headH
        let shoulderY = headBottom + 0.045 * h
        let shoulderHalf = 0.20 * h
        let hemY = 0.82 * h
        
        // Soft ground shadow
        let shadowPath = NSBezierPath(ovalIn: NSRect(x: cx - 0.26 * h, y: 0.95 * h, 
                                                      width: 0.52 * h, height: 0.07 * h))
        NSColor.black.withAlphaComponent(0.35).setFill()
        shadowPath.fill()
        
        // Legs (staggered)
        func limb(_ a: CGPoint, _ b: CGPoint, width: CGFloat, lit: NSColor, dark: NSColor) {
            let path = NSBezierPath()
            path.move(to: a)
            path.line(to: b)
            path.lineWidth = width
            path.lineCapStyle = .round
            
            // Simple gradient simulation with shadow
            dark.setStroke()
            path.stroke()
        }
        
        limb(CGPoint(x: cx - 0.07 * h, y: hemY - 0.02 * h), 
             CGPoint(x: cx - 0.085 * h, y: 0.97 * h),
             width: 0.11 * h, lit: cloth.lit, dark: cloth.dark)
        limb(CGPoint(x: cx + 0.07 * h, y: hemY - 0.02 * h), 
             CGPoint(x: cx + 0.075 * h, y: 0.995 * h),
             width: 0.11 * h, lit: cloth.lit, dark: cloth.dark)
        
        if kind.isHooded {
            // Reaper cloak
            let cloak = NSBezierPath()
            cloak.move(to: CGPoint(x: cx - 0.10 * h, y: headCY))
            cloak.curve(to: CGPoint(x: cx - 0.30 * h, y: 0.99 * h),
                       controlPoint1: CGPoint(x: cx - 0.34 * h, y: 0.6 * h),
                       controlPoint2: CGPoint(x: cx - 0.34 * h, y: 0.6 * h))
            
            // Tattered hem
            var x = cx - 0.30 * h
            var up = true
            while x < cx + 0.30 * h {
                x += 0.075 * h
                cloak.line(to: CGPoint(x: min(x, cx + 0.30 * h), y: up ? 0.95 * h : 0.99 * h))
                up.toggle()
            }
            
            cloak.curve(to: CGPoint(x: cx + 0.10 * h, y: headCY),
                       controlPoint1: CGPoint(x: cx + 0.34 * h, y: 0.6 * h),
                       controlPoint2: CGPoint(x: cx + 0.34 * h, y: 0.6 * h))
            cloak.close()
            
            cloth.dark.setFill()
            cloak.fill()
        } else {
            // Torso with ragged hem
            let torso = NSBezierPath()
            torso.move(to: CGPoint(x: cx - shoulderHalf, y: shoulderY))
            torso.line(to: CGPoint(x: cx - 0.17 * h, y: hemY))
            
            var x = cx - 0.17 * h
            var up = true
            while x < cx + 0.17 * h {
                x += 0.057 * h
                torso.line(to: CGPoint(x: min(x, cx + 0.17 * h), y: up ? hemY - 0.03 * h : hemY))
                up.toggle()
            }
            
            torso.line(to: CGPoint(x: cx + shoulderHalf, y: shoulderY))
            torso.curve(to: CGPoint(x: cx - shoulderHalf, y: shoulderY),
                       controlPoint1: CGPoint(x: cx, y: shoulderY - 0.05 * h),
                       controlPoint2: CGPoint(x: cx, y: shoulderY - 0.05 * h))
            torso.close()
            
            cloth.dark.setFill()
            torso.fill()
        }
        
        // Head with eyes and mouth
        let head = NSBezierPath(ovalIn: NSRect(x: cx - headW, y: headTop, width: headW * 2, height: headH))
        skin.dark.setFill()
        head.fill()
        
        // Eyes
        let eyeRadius = 0.035 * h
        let eyeY = headCY - 0.03 * h
        let leftEye = NSBezierPath(ovalIn: NSRect(x: cx - 0.08 * h - eyeRadius, y: eyeY - eyeRadius, 
                                                   width: eyeRadius * 2, height: eyeRadius * 2))
        let rightEye = NSBezierPath(ovalIn: NSRect(x: cx + 0.08 * h - eyeRadius, y: eyeY - eyeRadius, 
                                                    width: eyeRadius * 2, height: eyeRadius * 2))
        NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0).setFill()
        leftEye.fill()
        rightEye.fill()
        
        // Mouth (simple line)
        let mouth = NSBezierPath()
        mouth.move(to: CGPoint(x: cx - 0.06 * h, y: headCY + 0.04 * h))
        mouth.line(to: CGPoint(x: cx + 0.06 * h, y: headCY + 0.04 * h))
        mouth.lineWidth = 0.01 * h
        NSColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 1.0).setStroke()
        mouth.stroke()
        
        // Arms
        func arm(shoulderX: CGFloat, elbowX: CGFloat, elbowY: CGFloat, handX: CGFloat, handY: CGFloat) {
            let armPath = NSBezierPath()
            armPath.move(to: CGPoint(x: shoulderX, y: shoulderY))
            armPath.line(to: CGPoint(x: elbowX, y: elbowY))
            armPath.line(to: CGPoint(x: handX, y: handY))
            armPath.lineWidth = 0.08 * h
            armPath.lineCapStyle = .round
            skin.dark.setStroke()
            armPath.stroke()
            
            // Hands (claws)
            let hand = NSBezierPath(ovalIn: NSRect(x: handX - 0.05 * h, y: handY - 0.05 * h,
                                                    width: 0.10 * h, height: 0.10 * h))
            skin.dark.setFill()
            hand.fill()
        }
        
        // Left arm reaching up-left
        arm(shoulderX: cx - shoulderHalf, elbowX: cx - 0.22 * h, elbowY: shoulderY - 0.08 * h,
            handX: cx - 0.28 * h, handY: shoulderY - 0.15 * h)
        
        // Right arm reaching up-right
        arm(shoulderX: cx + shoulderHalf, elbowX: cx + 0.22 * h, elbowY: shoulderY - 0.08 * h,
            handX: cx + 0.28 * h, handY: shoulderY - 0.15 * h)
    }
    
    /// Generate all required icon sizes and save as icns
    static func generateAppIcon(outputPath: String, kind: ZombieKind = .standard) {
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
    IconGenerator.generateAppIcon(outputPath: outputPath, kind: .standard)
} else {
    IconGenerator.generateAppIcon(outputPath: "/tmp/AppIcon.icns", kind: .standard)
    print("Usage: swift generate-icon.swift <output-path>")
    print("Example: swift generate-icon.swift WordsOfTheDead/Resources/AppIcon.icns")
}
