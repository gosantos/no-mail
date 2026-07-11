#!/usr/bin/env bash
set -euo pipefail

# Builds noMail.app from source and (optionally) zips it for distribution.
#
#   ./build.sh            -> builds build/noMail.app
#   ./build.sh 1.2.0      -> builds with version 1.2.0 and creates build/noMail-1.2.0.zip

APP_NAME="noMail"
VERSION="${1:-1.0.0}"

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"

echo "==> Cleaning previous build"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

echo "==> Compiling ($APP_NAME $VERSION)"
swiftc -O \
	-o "$MACOS_DIR/$APP_NAME" \
	"$ROOT/Sources/noMail/main.swift" \
	-framework Cocoa

echo "==> Assembling bundle"
sed "s/__VERSION__/$VERSION/g" "$ROOT/Resources/Info.plist" > "$APP_DIR/Contents/Info.plist"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_DIR"

echo "==> Built $APP_DIR"

if [[ -n "${1:-}" ]]; then
	ZIP_PATH="$BUILD_DIR/$APP_NAME-$VERSION.zip"
	echo "==> Zipping -> $ZIP_PATH"
	rm -f "$ZIP_PATH"
	# ditto preserves the bundle so Gatekeeper/Homebrew are happy.
	( cd "$BUILD_DIR" && ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME-$VERSION.zip" )
	echo "==> sha256:"
	shasum -a 256 "$ZIP_PATH"
fi

echo "==> Done"
