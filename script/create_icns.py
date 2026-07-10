#!/usr/bin/env python3

import struct
import sys
from pathlib import Path


def build_icns(output_path: Path, iconset_path: Path) -> None:
    icon_chunks = [
        (b"icp4", "icon_16x16.png"),
        (b"icp5", "icon_16x16@2x.png"),
        (b"icp6", "icon_32x32@2x.png"),
        (b"ic07", "icon_128x128.png"),
        (b"ic08", "icon_256x256.png"),
        (b"ic09", "icon_512x512.png"),
        (b"ic10", "icon_512x512@2x.png"),
    ]

    chunks = []
    for chunk_type, filename in icon_chunks:
        png_data = (iconset_path / filename).read_bytes()
        chunks.append(chunk_type + struct.pack(">I", len(png_data) + 8) + png_data)

    body = b"".join(chunks)
    output_path.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: create_icns.py OUTPUT.icns INPUT.iconset")

    build_icns(Path(sys.argv[1]), Path(sys.argv[2]))
