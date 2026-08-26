#!/bin/bash
# Build EyeBreak from source and install it to /Applications as your daily app.
#
# This replaces the Homebrew cask install. Run it after each change you want to
# live with. The bundle identifier is unchanged (com.eyebreak.app), so your
# settings and statistics in ~/Library/Preferences/com.eyebreak.app.plist carry
# straight over.
#
# Run scripts/create-cert.sh once before the first use.

set -euo pipefail

IDENTITY="EyeBreak Local Signing"
CONFIGURATION="${1:-Release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="$ROOT/build/DerivedData"
BUILT="$DERIVED/Build/Products/$CONFIGURATION/EyeBreak.app"
INSTALLED="/Applications/EyeBreak.app"

# The project pins DEVELOPMENT_TEAM = SM4A6Z8B5H for release builds. A
# self-signed certificate belongs to no team, so the build below clears the team
# and the provisioning profile. Without that, xcodebuild rejects the identity
# with "No certificate for team ... matching".
if ! security find-identity -v -p codesigning | grep -qF "$IDENTITY"; then
    echo "No code-signing identity named \"$IDENTITY\"." >&2
    echo "Create one first:  ./scripts/create-cert.sh" >&2
    exit 1
fi

echo "Building $CONFIGURATION..."
# xcodebuild creates $DERIVED itself, but the build log sits beside it and needs
# the parent directory to exist first.
mkdir -p "$(dirname "$DERIVED")"
xcodebuild -project "$ROOT/EyeBreak.xcodeproj" \
    -scheme EyeBreak \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED" \
    -destination 'platform=macOS' \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$IDENTITY" \
    DEVELOPMENT_TEAM="" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    build > "$DERIVED.log" 2>&1 || {
        echo "Build failed. Last errors:" >&2
        grep -E "error:" "$DERIVED.log" | tail -20 >&2
        exit 1
    }

# Sparkle checks the public appcast once a day. A local build almost always
# reports an older version than the published release, so Sparkle would offer to
# "update" it and quietly replace your build with the shipped one. Turn the
# automatic check off in the installed copy only; the source tree keeps it on.
/usr/libexec/PlistBuddy -c "Set :SUEnableAutomaticChecks false" \
    "$BUILT/Contents/Info.plist"

# Mark the build so you can tell it apart from a release in the About window and
# in Finder's Get Info panel.
SHORT_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$BUILT/Contents/Info.plist")"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(git -C "$ROOT" rev-parse --short HEAD)-dev" \
    "$BUILT/Contents/Info.plist"

# xcodebuild already signed the app and the nested Sparkle framework, in the
# order codesign requires. Editing Info.plist above invalidated the outer
# signature, so re-sign the outer bundle only. Do not pass --deep: it would
# re-sign the nested Sparkle XPC services out of order and break them.
#
# No --options runtime. The shipped release runs without the hardened runtime,
# and enabling it here would make the dev build behave differently from what
# users get.
echo "Re-signing the outer bundle with \"$IDENTITY\"..."
codesign --force \
    --sign "$IDENTITY" \
    --entitlements "$ROOT/EyeBreak/EyeBreak.entitlements" \
    "$BUILT"

codesign --verify --strict --verbose=2 "$BUILT"

echo "Quitting the running instance..."
osascript -e 'tell application "EyeBreak" to quit' 2>/dev/null || true
# Give the app a moment to release its menu bar item and save state.
for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x EyeBreak > /dev/null || break
    /bin/sleep 0.2
done
pkill -x EyeBreak 2>/dev/null || true

echo "Installing to $INSTALLED..."
rm -rf "$INSTALLED"
ditto "$BUILT" "$INSTALLED"

open "$INSTALLED"

echo
echo "Installed $SHORT_VERSION ($(git -C "$ROOT" rev-parse --short HEAD)-dev) to $INSTALLED"
echo
echo "The menu bar icon should be back. If macOS asks for Accessibility or"
echo "Screen Recording again, grant it once; the stable certificate keeps the"
echo "grant across later runs of this script."
