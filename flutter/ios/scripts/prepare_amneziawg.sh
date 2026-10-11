#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/amneziawg-apple"
PIN="9d5ee60edefa95b933a738dd7cda671dd18021fc"
REPO="https://github.com/amnezia-vpn/amneziawg-apple.git"
WG="$DEST/Sources/WireGuardKitGo"

mkdir -p "$DEST"
if [ ! -d "$DEST/.git" ]; then
  git -C "$DEST" init
  git -C "$DEST" remote add origin "$REPO"
fi
git -C "$DEST" fetch --depth 1 origin "$PIN"
git -C "$DEST" checkout --force "$PIN"

python3 - "$DEST" <<'PY'
import sys
from pathlib import Path

dest = Path(sys.argv[1])
pkg = dest / "Package.swift"
text = pkg.read_text()
out = (dest / "Sources" / "WireGuardKitGo" / "out").as_posix()
old = '.unsafeFlags(["-L", "Sources/WireGuardKitGo/out"]),'
new = f'.unsafeFlags(["-L", "{out}"]),'
if old in text:
    pkg.write_text(text.replace(old, new, 1))
elif out not in text:
    raise SystemExit("WireGuardKitGo linker path was not found in Package.swift")
print("linker path", out)
PY

if ! command -v go >/dev/null 2>&1; then
  brew install go
fi

rm -rf "$WG/out" "$WG/.tmp"
make -C "$WG" \
  PLATFORM_NAME=iphoneos \
  ARCHS=arm64 \
  CONFIGURATION_BUILD_DIR="$WG/out" \
  CONFIGURATION_TEMP_DIR="$WG/.tmp"
make -C "$WG" version-header \
  PLATFORM_NAME=iphoneos \
  ARCHS=arm64 \
  CONFIGURATION_BUILD_DIR="$WG/out" \
  CONFIGURATION_TEMP_DIR="$WG/.tmp"
test -s "$WG/out/libwg-go.a"
echo "AmneziaWG library ready"
