#!/bin/bash
# Downloads the iOS engine into ios/Frameworks/ (not committed). Run once after
# cloning, and again to refresh it. See docs/engine/ios_engine.md.
#
#   ios/scripts/fetch_engine.sh
#
# - Python.xcframework: BeeWare Python-Apple-support (CPython for iOS).
# - ffmpegkit + libav* xcframeworks: FFmpegKit "full-gpl" (videotoolbox,
#   libmp3lame, libx264, libvpx), from the maintained sk3llo/ffmpeg_kit_flutter
#   fork (the original ffmpeg-kit was retired in 2025).
# - python-packages/: the official yt-dlp zipapp (pure Python) and certifi
#   (Python on iOS has no CA bundle of its own).
set -euo pipefail

PYTHON_RELEASE="3.13-b18"
PYTHON_ARCHIVE="Python-3.13-iOS-support.b18.tar.gz"
FFMPEG_KIT_RELEASE="8.1.3-full-gpl"
FFMPEG_LIBS="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"
CERTIFI_VERSION="2026.11.20"

cd "$(dirname "$0")/.."
OUT="Frameworks"
mkdir -p "$OUT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Python.
echo "Downloading Python ($PYTHON_RELEASE)..."
curl -fL --progress-bar -o "$TMP/python.tar.gz" \
  "https://github.com/beeware/Python-Apple-support/releases/download/$PYTHON_RELEASE/$PYTHON_ARCHIVE"
mkdir -p "$TMP/python"
tar -xzf "$TMP/python.tar.gz" -C "$TMP/python"
rm -rf "$OUT/Python.xcframework"
mv "$TMP/python/Python.xcframework" "$OUT/Python.xcframework"

# FFmpegKit, each archive checked against the release's checksums.json.
FFMPEG_BASE="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/$FFMPEG_KIT_RELEASE"
curl -fsSL -o "$TMP/checksums.json" "$FFMPEG_BASE/checksums.json"
for lib in $FFMPEG_LIBS; do
  echo "Downloading $lib.xcframework..."
  curl -fL --progress-bar --retry 3 -o "$TMP/$lib.zip" "$FFMPEG_BASE/$lib.xcframework.zip"
  expected="$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$TMP/checksums.json" "$lib")"
  actual="$(shasum -a 256 "$TMP/$lib.zip" | awk '{ print $1 }')"
  if [ "$expected" != "$actual" ]; then
    echo "$lib checksum mismatch" >&2
    exit 1
  fi
  rm -rf "$OUT/$lib.xcframework"
  unzip -q "$TMP/$lib.zip" -d "$OUT"
done

# yt-dlp zipapp, checked against SHA2-256SUMS. It runs from the zip (zipimport).
PACKAGES="$OUT/python-packages"
rm -rf "$PACKAGES"
mkdir -p "$PACKAGES/site-packages"
YTDLP_BASE="https://github.com/yt-dlp/yt-dlp/releases/latest/download"
echo "Downloading yt-dlp..."
curl -fL --progress-bar -o "$TMP/yt-dlp" "$YTDLP_BASE/yt-dlp"
curl -fsSL -o "$TMP/SHA2-256SUMS" "$YTDLP_BASE/SHA2-256SUMS"
expected="$(awk '$2 == "yt-dlp" { print $1 }' "$TMP/SHA2-256SUMS")"
actual="$(shasum -a 256 "$TMP/yt-dlp" | awk '{ print $1 }')"
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
  echo "yt-dlp checksum mismatch" >&2
  exit 1
fi
mv "$TMP/yt-dlp" "$PACKAGES/yt-dlp.zip"

# certifi (pure Python wheel).
echo "Downloading certifi $CERTIFI_VERSION..."
/usr/bin/python3 -m pip download --quiet --no-deps --only-binary=:all: \
  --dest "$TMP/wheels" "certifi==$CERTIFI_VERSION"
unzip -q "$TMP"/wheels/certifi-*.whl -d "$PACKAGES/site-packages"

echo "Done. iOS engine is in ios/$OUT/."
