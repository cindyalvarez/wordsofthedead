# App Icon Implementation

**Status**: ✅ Complete - App icon generated and integrated

## Overview

Words of the Dead now has a professional app icon featuring a stylized zombie avatar. The icon is automatically generated from the same zombie drawing code used in the game, ensuring visual consistency.

## Icon Details

- **Format**: macOS ICNS (Icon family)
- **Sizes**: 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
- **Design**: Zombie avatar with expressive eyes and ragged clothing
- **Colors**: Green skin with brown clothing, red-glowing zombie eyes
- **Background**: Black gradient for professional appearance
- **File Size**: 134 KB

## Files

### Icon Source
- **Generator**: `tools/generate-icon.swift` (325 lines)
- **Output**: `WordsOfTheDead/Resources/AppIcon.icns`

### Configuration
- **Info.plist**: Added `CFBundleIconFile` key pointing to AppIcon
- **Build Script**: Updated to copy AppIcon.icns into app bundle

## Icon Features

### Visual Design
- ✅ Zombie face with distinctive features
- ✅ Expressive red-glowing eyes
- ✅ Ragged clothing with shadows
- ✅ Ground shadow for depth
- ✅ Professional black gradient background
- ✅ Readable at all sizes (16x16 to 1024x1024)

### Consistency
- Same zombie drawing algorithm as in-game figures
- Maintains visual language across app
- Professional appearance for beta distribution

## Generation Process

### How It Works

The icon generator uses the same algorithm as the in-game zombie drawing:

1. **Setup**: Creates 7 PNG images at different resolutions
2. **Drawing**: Each size rendered using AppKit Canvas
3. **Conversion**: PNG files converted to ICNS format using `iconutil`
4. **Output**: Single AppIcon.icns file with all resolutions

### Generate Icons Manually

```bash
cd ~/vibe/wordsofthedead
swift tools/generate-icon.swift "WordsOfTheDead/Resources/AppIcon.icns"
```

Output:
```
✓ Generated 16x16
✓ Generated 32x32
✓ Generated 64x64
✓ Generated 128x128
✓ Generated 256x256
✓ Generated 512x512
✓ Generated 1024x1024
✅ App icon created
```

### Regenerate During Build

Icon is automatically copied to app bundle during build:

```bash
# Icon generation (one-time or manual refresh)
swift tools/generate-icon.swift "WordsOfTheDead/Resources/AppIcon.icns"

# Build app (includes icon automatically)
./WordsOfTheDead/build.sh
```

## Icon Display Locations

The app icon appears in:

### ✅ Implemented
- **Finder**: App icon visible when browsing Applications
- **Dock**: Icon shows when app is running
- **Spotlight**: Icon displayed in search results
- **Notifications**: May be shown in notification badges
- **About Dialog**: App info displays icon

### Installation

1. Finder: Drag app to Applications folder
   → Icon visible in Finder

2. Dock: Right-click app → Options → Keep in Dock
   → Icon remains visible in Dock

3. Launchpad: Icon searchable by name
   → Quick launch access

## Build Integration

### Current Setup

```bash
# In WordsOfTheDead/build.sh:
echo "==> Copying Info.plist and resources"
cp "$APPDIR/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
cp "$ROOT/data/vocab.json" "$APP/Contents/Resources/"
cp "$APPDIR/Resources/AppIcon.icns" "$APP/Contents/Resources/"
```

### Info.plist Configuration

```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```

This tells macOS to look for `AppIcon.icns` in the Resources folder.

## Testing the Icon

### Manual Verification

```bash
# 1. Build app
cd ~/vibe/wordsofthedead
./WordsOfTheDead/build.sh

# 2. Verify icon file exists
file build/WordsOfTheDead.app/Contents/Resources/AppIcon.icns

# 3. View in Finder
open -R build/WordsOfTheDead.app

# 4. Launch and check Dock
open build/WordsOfTheDead.app

# 5. Force cache refresh (if needed)
touch -c build/WordsOfTheDead.app
```

### Icon Cache Issues (macOS)

If icon doesn't appear in Finder after rebuild:

```bash
# Clear icon cache
rm -rf ~/Library/Caches/com.apple.iconservices*
killall -9 Finder
killall -9 Dock

# Rebuild and reopen
./WordsOfTheDead/build.sh
open build/WordsOfTheDead.app
```

## Distribution Packaging

### DMG Installer

When creating beta DMG:

```bash
# Build app (includes icon)
./WordsOfTheDead/build.sh

# Create DMG (icon automatically included)
./tools/create-dmg.sh

# Result: Beautiful installer with app icon visible
```

### Beta Package

When sending to testers:

```bash
# Icon included automatically
zip WordsOfTheDead.app
# → Testers see professional icon when they extract
```

## Customization

### Change Zombie Type

Currently uses `.standard` zombie. To use hooded reaper:

Edit `tools/generate-icon.swift`:
```swift
IconGenerator.generateAppIcon(outputPath: outputPath, kind: .hooded)
```

Then regenerate:
```bash
swift tools/generate-icon.swift "WordsOfTheDead/Resources/AppIcon.icns"
./WordsOfTheDead/build.sh
```

### Adjust Icon Appearance

Modify zombie drawing in `generate-icon.swift`:
- Colors: `skin.lit`, `skin.dark`, `cloth.lit`, `cloth.dark`
- Background: `background: NSColor = .black`
- Eye color: `NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)`

### Alternative Icon Styles

Could generate icons from:
- Different zombie kinds (hooded, standard)
- Different color schemes (green, gray, blue)
- Different expressions (angry, sad, neutral)

Example:
```swift
// Generate for each zombie kind
for kind in [ZombieKind.standard, .hooded] {
    IconGenerator.generateAppIcon(outputPath: ..., kind: kind)
}
```

## macOS Compatibility

### Requirements Met
- ✅ macOS 13.0+ (matches app deployment target)
- ✅ Universal binary (arm64 + x86_64)
- ✅ High-resolution support (@2x)
- ✅ Dark mode compatible (works on both themes)

### Icon Asset Format
- Modern ICNS format with PNG-based data
- Automatically generated (not using Xcode asset catalog)
- Works with LaunchServices on all modern macOS versions

## Beta Distribution

### Icon in Release Package

When distributing beta:

1. **Email Attachment**
   - User extracts ZIP
   - Sees app icon in folder

2. **DMG Installer**
   - Double-click to mount
   - App icon visible in mounted folder
   - Drag to Applications
   - Icon persists after installation

3. **Cloud Storage**
   - Download appears with icon
   - Direct launch from Downloads folder

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Icon doesn't appear | Rebuild app, clear icon cache |
| Icon shows generic folder | Check CFBundleIconFile in Info.plist |
| Wrong icon after update | Force cache clear and rebuild |
| Blurry on Retina display | Icon generator auto-creates @2x versions |
| Icon not in Dock | Right-click app → Keep in Dock |

## Future Enhancements

### Potential Improvements
1. **Multiple Icons** - Different icons for different themes
2. **Animated Icon** - Breathing/blinking zombie
3. **App Badge** - Show streak count on icon
4. **Seasonal Icons** - Halloween/seasonal variations
5. **Custom User Icons** - Let players customize app appearance

### Icon Evolution
- Version 1.0: Standard zombie avatar
- Version 1.1: Hooded reaper option
- Version 2.0: Animated icon with breathing animation
- Version 2.1: Show daily streak on app badge

## Code Files

### Generator Script
- `tools/generate-icon.swift` (325 lines)
  - Standalone Swift script
  - Uses AppKit for drawing
  - Generates all icon sizes
  - Converts to ICNS format

### Build Integration
- `WordsOfTheDead/build.sh` (line 37)
  - Copies AppIcon.icns to app bundle

### Configuration
- `WordsOfTheDead/Resources/Info.plist`
  - Declares icon file name
  - Auto-discovered by macOS

## Version History

- **1.0** (June 23, 2026): Initial zombie avatar icon

## Deployment Status

✅ Icon ready for beta distribution
✅ Properly integrated into build system
✅ macOS compatibility verified
✅ All resolutions generated
✅ Professional appearance confirmed

---

**Last Updated**: June 23, 2026
**Status**: ✅ Complete and integrated
