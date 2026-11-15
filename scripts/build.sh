#!/bin/bash
# Build a universal (Apple Silicon + Intel) Junk0.app
#   ./scripts/build.sh            -> build/Junk0.app
#   ./scripts/build.sh --install  -> also copy to ~/Applications/Junk0.app
#   ./scripts/build.sh --zip      -> also create build/Junk0-<version>.zip for a GitHub Release
set -euo pipefail
LIPO() { if [ -x /Library/Developer/CommandLineTools/usr/bin/lipo ]; then DEVELOPER_DIR=/Library/Developer/CommandLineTools /Library/Developer/CommandLineTools/usr/bin/lipo "$@"; else lipo "$@"; fi; }
cd "$(dirname "$0")/.."

# Use Xcode's toolchain if present, otherwise whatever swiftc is on PATH.
XC=/Applications/Xcode.app/Contents/Developer
if [ -x "$XC/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc" ]; then
  SWIFTC="$XC/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
  SDK="$XC/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
else
  SWIFTC=$(command -v swiftc); SDK=$(xcrun --show-sdk-path)
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
APP="build/Junk0.app"
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

for ARCH in arm64 x86_64; do
  "$SWIFTC" -sdk "$SDK" -O -target "$ARCH-apple-macos14" Sources/*.swift -o "build/Junk0-$ARCH"
done
LIPO -create build/Junk0-arm64 build/Junk0-x86_64 -output "$APP/Contents/MacOS/Junk0"
rm build/Junk0-arm64 build/Junk0-x86_64

cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --deep -s - "$APP"     # ad-hoc signature (not notarized)
echo "Built $APP (v$VERSION, $(LIPO -archs "$APP/Contents/MacOS/Junk0"))"

for arg in "$@"; do
  case "$arg" in
    --install) rm -rf "$HOME/Applications/Junk0.app"; cp -R "$APP" "$HOME/Applications/Junk0.app"; echo "Installed to ~/Applications/Junk0.app";;
    --zip) (cd build && ditto -c -k --keepParent "Junk0.app" "Junk0-$VERSION.zip"); echo "Zipped build/Junk0-$VERSION.zip";;
  esac
done
