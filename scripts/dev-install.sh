#!/bin/bash
# Build EyeBreak from source and install it to /Applications as your daily app.
#
# This is the only way EyeBreak gets installed. Run it after each change you
# want to live with. The bundle identifier is com.eyebreak.app, so settings and
# statistics in ~/Library/Preferences/com.eyebreak.app.plist carry across runs.
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

# Stamp the version from the nearest git tag.
#
# The committed CFBundleShortVersionString is deliberately stale. This block
# derives the real version at build time without committing the result, so
# without it the app would report whatever the checked-in value happens to be
# (2.2.0 since v2.3.0).
#
# The tag has to be reachable. Tag before you build, so the stamped version
# matches the tag you are releasing.
TAG="$(git -C "$ROOT" describe --tags --abbrev=0 2>/dev/null || true)"
if [ -z "$TAG" ]; then
    echo "No reachable git tag, so the version would be wrong." >&2
    echo "Tag a version first, or fetch tags:  git fetch origin --tags" >&2
    exit 1
fi

SHORT_VERSION="${TAG#v}"

# CFBundleVersion has to be numeric and monotonic, so pack the semver into one
# integer. Nothing reads it now that Sparkle is gone, but macOS still wants it
# to increase.
IFS='.' read -r MAJ MIN PAT <<< "${SHORT_VERSION%%-*}"
BUILD=$(( 10#${MAJ:-0} * 10000 + 10#${MIN:-0} * 100 + 10#${PAT:-0} ))

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $SHORT_VERSION" \
    "$BUILT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" \
    "$BUILT/Contents/Info.plist"

# xcodebuild already signed the app. Editing Info.plist above invalidated that
# signature, so re-sign the bundle. There are no nested bundles left to order
# around now that Sparkle is gone.
#
# No --options runtime. Nothing here is notarized, and the hardened runtime
# would only add ways for the ad-hoc signature to be rejected.
echo "Re-signing with \"$IDENTITY\"..."
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
echo "Installed $SHORT_VERSION (build $BUILD) to $INSTALLED"
echo
echo "The menu bar icon should be back. If macOS asks for Accessibility, grant"
echo "it once; the stable certificate keeps the grant across later runs of this"
echo "script."
