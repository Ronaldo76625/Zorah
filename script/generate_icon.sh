#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_IMAGE="${1:-$ROOT_DIR/Assets/AppIcon.png}"
OUTPUT_ICNS="${2:-$ROOT_DIR/.build/AppIcon.icns}"
ICONSET_DIR="$ROOT_DIR/.build/Zorah.iconset"

if [[ ! -f "$SOURCE_IMAGE" ]]; then
  echo "Icon source not found: $SOURCE_IMAGE" >&2
  exit 1
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR" "$(dirname "$OUTPUT_ICNS")"

make_icon() {
  local size="$1"
  local filename="$2"
  /usr/bin/sips -z "$size" "$size" "$SOURCE_IMAGE" --out "$ICONSET_DIR/$filename" >/dev/null
}

make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png

python3 "$ROOT_DIR/script/create_icns.py" "$OUTPUT_ICNS" "$ICONSET_DIR"
echo "$OUTPUT_ICNS"
