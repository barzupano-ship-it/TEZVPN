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

IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
IOS_MIN="15.0"
IOS_CC="$(xcrun --sdk iphoneos --find clang)"

rm -rf "$WG/out" "$WG/.tmp"
for goal in build version-header; do
  env -u SDKROOT -u MACOSX_DEPLOYMENT_TARGET \
    IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN" \
    make -C "$WG" "$goal" \
      PLATFORM_NAME=iphoneos \
      ARCHS=arm64 \
      SDKROOT="$IOS_SDK" \
      CC="$IOS_CC" \
      DEPLOYMENT_TARGET_CLANG_FLAG_NAME=miphoneos-version-min \
      DEPLOYMENT_TARGET_CLANG_ENV_NAME=IPHONEOS_DEPLOYMENT_TARGET \
      CONFIGURATION_BUILD_DIR="$WG/out" \
      CONFIGURATION_TEMP_DIR="$WG/.tmp"
done
test -s "$WG/out/libwg-go.a"

PLATFORMS="$(otool -arch arm64 -l "$WG/out/libwg-go.a" \
  | awk '/LC_BUILD_VERSION/{f=1} f&&$1=="platform"{print $2; f=0}' | sort -u)"
echo "libwg-go.a platforms: $PLATFORMS"
if printf '%s\n' "$PLATFORMS" | grep -Eqx '1|MACOS|macos'; then
  echo "libwg-go.a contains macOS objects"
  exit 1
fi
echo "AmneziaWG library ready"
