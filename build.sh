#!/bin/zsh
# Builds "Clawd Wars.app", installs it to /Applications, refreshes the hooks of the AIs you've connected and launches it.
# It never connects a new AI: the app offers that, and Settings in its menu does it.
#   ./build.sh                     build + install + refresh connected hooks + launch
#   ./build.sh --no-hooks          build + install + launch (leave every AI's settings alone)
#   ./build.sh --no-install        build + launch the copy in build/ (nothing copied to /Applications, hooks left alone)
#   ./build.sh --release <version> universal (arm64 + x86_64) build into build/, signed for distribution;
#                                  no install, no hooks (used by release.sh)
set -euo pipefail
cd "${0:A:h}"

MODE=install
HOOKS=1
VERSION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-hooks) HOOKS=0 ;;
        --no-install) MODE=local; HOOKS=0 ;;
        --release) MODE=release; VERSION="${2:?--release needs a version}"; shift ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
# Default version: the newest entry in the CHANGELOG.
if [[ -z "$VERSION" ]]; then
    VERSION=$(grep -m1 -oE '^## [0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md | cut -c4- || true)
    [[ -n "$VERSION" ]] || { echo "error: no '## X.Y.Z' version heading found in CHANGELOG.md" >&2; exit 1; }
fi

APP="build/Clawd Wars.app"
DEST="/Applications/Clawd Wars.app"
OLD_DESTS=("$HOME/Applications/Clawd Wars.app" "$HOME/Applications/VaderClaude.app")   # earlier installs
FLAGS=(-O -swift-version 5)

rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# compile <output> <sources…>: native arch for installs, a universal binary for releases
compile() {
    local out=$1; shift
    if [[ $MODE == release ]]; then
        swiftc "${FLAGS[@]}" -target arm64-apple-macos13.0 "$@" -o "$out.arm64"
        swiftc "${FLAGS[@]}" -target x86_64-apple-macos13.0 "$@" -o "$out.x86_64"
        lipo -create "$out.arm64" "$out.x86_64" -output "$out"
        rm "$out.arm64" "$out.x86_64"
    else
        local arch=arm64; [[ "$(uname -m)" == "x86_64" ]] && arch=x86_64
        swiftc "${FLAGS[@]}" -target $arch-apple-macos13.0 "$@" -o "$out"
    fi
}

echo "→ compiling app"
# The app carries the screen saver's view too: the window's third view is the screen saver itself.
compile "$APP/Contents/MacOS/ClawdWars" -framework ScreenSaver Sources/Shared/*.swift Sources/App/*.swift Sources/Saver/*.swift
echo "→ compiling hook"
compile "$APP/Contents/MacOS/clawd-wars-hook" Sources/Shared/*.swift Sources/Hook/main.swift

# The screen saver: a plug-in bundle macOS's screen saver host loads, carried inside the app, which installs it
# (Settings → Install Screen Saver) and keeps the installed copy up to date. It shares the sprite and location code.
echo "→ compiling screen saver"
SAVER="$APP/Contents/Resources/Clawd Wars.saver"
mkdir -p "$SAVER/Contents/MacOS"
compile "$SAVER/Contents/MacOS/ClawdWarsSaver" -module-name ClawdWarsSaver -emit-library -framework ScreenSaver \
    -Xlinker -install_name -Xlinker @rpath/ClawdWarsSaver \
    Sources/Shared/*.swift Sources/App/{Pixel,Characters,Recruits,Leaders,Cantina,Locations,Cast,Accents,Habits}.swift Sources/Saver/*.swift
# Its picture under "Other" in System Settings: the title card at 0:04 of promo/clawd-wars-promo.mp4, cropped to 180×116.
mkdir -p "$SAVER/Contents/Resources"
cp Resources/SaverThumbnail.png "$SAVER/Contents/Resources/thumbnail@2x.png"
sips -z 58 90 Resources/SaverThumbnail.png --out "$SAVER/Contents/Resources/thumbnail.png" >/dev/null
# Both sizes in one file too, as Xcode packages them ("combine high resolution artwork").
tiffutil -cathidpicheck "$SAVER/Contents/Resources/thumbnail.png" "$SAVER/Contents/Resources/thumbnail@2x.png" \
    -out "$SAVER/Contents/Resources/thumbnail.tiff" >/dev/null
cat > "$SAVER/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
    <key>CFBundleIdentifier</key><string>com.rodclemen.vaderclaude.saver</string>
    <key>CFBundleName</key><string>Clawd Wars</string>
    <key>CFBundleDisplayName</key><string>Clawd Wars</string>
    <key>CFBundleExecutable</key><string>ClawdWarsSaver</string>
    <key>CFBundlePackageType</key><string>BNDL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>NSPrincipalClass</key><string>ClawdWarsSaverView</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict>
</plist>
PLIST

echo "→ icon"
ICONSET=build/AppIcon.iconset
mkdir -p "$ICONSET"
for px in 16 32 128 256 512; do
    sips -z $px $px Resources/AppIcon.png --out "$ICONSET/icon_${px}x${px}.png" >/dev/null
    sips -z $((px * 2)) $((px * 2)) Resources/AppIcon.png --out "$ICONSET/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>com.rodclemen.vaderclaude</string>
    <key>CFBundleName</key><string>Clawd Wars</string>
    <key>CFBundleDisplayName</key><string>Clawd Wars</string>
    <key>CFBundleExecutable</key><string>ClawdWars</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT licensed. A Star Wars fan project for Claude Code.</string>
    <key>NSAppleEventsUsageDescription</key><string>Clicking a character (hero or villain) selects the Terminal or iTerm tab running that AI session.</string>
</dict>
</plist>
PLIST

# Sign. Releases need a Developer ID (for distribution) and fail without one; local builds take any real
# identity so macOS keeps the Accessibility grant across rebuilds, and fall back to ad-hoc.
# No --deep (deprecated): the nested hook binary is signed on its own first, then the bundle.
IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null || true)
if [[ $MODE == release ]]; then
    IDENTITY=$(echo "$IDENTITIES" | grep -m1 -oE '"Developer ID Application[^"]*"' | tr -d '"' || true)
    [[ -n "$IDENTITY" ]] || { echo "error: no 'Developer ID Application' signing identity in the keychain" >&2; exit 1; }
    # Hardened runtime + secure timestamp: what notarization requires. Apple Events entitlement keeps
    # click-to-jump working for Terminal and iTerm2.
    cat > build/entitlements.plist <<'ENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.automation.apple-events</key><true/></dict></plist>
ENT
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP/Contents/MacOS/clawd-wars-hook"
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$SAVER"
    codesign --force --options runtime --timestamp --entitlements build/entitlements.plist \
        --sign "$IDENTITY" "$APP"
else
    IDENTITY=$(echo "$IDENTITIES" | grep -m1 -oE '"(Developer ID Application|Apple Development)[^"]*"' | tr -d '"' || true)
    sign_local() {
        codesign --force --timestamp=none --sign "$1" "$APP/Contents/MacOS/clawd-wars-hook" \
            && codesign --force --timestamp=none --sign "$1" "$SAVER" \
            && codesign --force --timestamp=none --sign "$1" "$APP"
    }
    if [[ -z "$IDENTITY" ]] || ! sign_local "$IDENTITY" >/dev/null 2>&1; then
        IDENTITY=""
        sign_local - >/dev/null
    fi
fi
echo "→ signed with: ${IDENTITY:-ad-hoc} (version $VERSION)"

if [[ $MODE == release ]]; then
    echo "✓ release build ready: $APP"
    exit 0
fi

# Only one Clawd Wars runs at a time (a second copy quits at launch), so stop whichever one is running.
pkill -x VaderClaude 2>/dev/null || true
pkill -x ClawdWars 2>/dev/null || true

if [[ $MODE == local ]]; then
    # Not installed: the build/ copy never takes over hooks that still point at a working app (HookInstaller.repairMoved).
    open "$APP"
    echo "✓ Clawd Wars is running from $APP (not installed). Right-click any villain for options."
    exit 0
fi

echo "→ installing to $DEST"
rm -rf "$DEST" "${OLD_DESTS[@]}" && cp -R "$APP" "$DEST"

if [[ $HOOKS == 1 ]]; then
    "$DEST/Contents/MacOS/ClawdWars" --update-hooks
fi

open "$DEST"
echo "✓ Clawd Wars is running. Right-click any villain for options."
