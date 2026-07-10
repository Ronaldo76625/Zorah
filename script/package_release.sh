#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.0}"
ARCHITECTURE="$(uname -m)"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$ROOT_DIR/.build/dmg-staging"
DMG_NAME="Zorah-$VERSION-$ARCHITECTURE.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
CHECKSUM_PATH="$DMG_PATH.sha256"

cd "$ROOT_DIR"

APP_VERSION="$VERSION" BUILD_CONFIGURATION=release ./script/build_and_run.sh --package

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
/usr/bin/ditto "$DIST_DIR/Zorah.app" "$STAGING_DIR/Zorah.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH" "$CHECKSUM_PATH"
/usr/bin/hdiutil create \
  -volname "Zorah $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

/usr/bin/hdiutil verify "$DMG_PATH"
(
  cd "$DIST_DIR"
  /usr/bin/shasum -a 256 "$DMG_NAME" >"$DMG_NAME.sha256"
)

echo "DMG: $DMG_PATH"
echo "SHA-256: $CHECKSUM_PATH"
