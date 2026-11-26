#!/bin/bash
# Downloads the macOS engine binaries into macos/Runner/Resources/bin/ (not
# committed). Run once after cloning, and again to refresh them.
# See docs/engine/macos_engine.md.
#
#   macos/scripts/fetch_engine_binaries.sh               # this Mac's arch
#   macos/scripts/fetch_engine_binaries.sh --universal   # arm64 + x86_64 ffmpeg
#   macos/scripts/fetch_engine_binaries.sh --with-deno   # also bundle deno (YouTube JS challenges)
set -euo pipefail

cd "$(dirname "$0")/.."
BIN="Runner/Resources/bin"
mkdir -p "$BIN"

UNIVERSAL=0
WITH_DENO=0
for arg in "$@"; do
  case "$arg" in
    --universal) UNIVERSAL=1 ;;
    --with-deno) WITH_DENO=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 64 ;;
  esac
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# yt-dlp: official standalone universal2 build, checked against SHA2-256SUMS.
YTDLP_BASE="https://github.com/yt-dlp/yt-dlp/releases/latest/download"
echo "Downloading yt-dlp_macos..."
curl -fL --progress-bar -o "$TMP/yt-dlp_macos" "$YTDLP_BASE/yt-dlp_macos"
curl -fsSL -o "$TMP/SHA2-256SUMS" "$YTDLP_BASE/SHA2-256SUMS"
expected="$(awk '$2 == "yt-dlp_macos" { print $1 }' "$TMP/SHA2-256SUMS")"
actual="$(shasum -a 256 "$TMP/yt-dlp_macos" | awk '{ print $1 }')"
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
  echo "yt-dlp_macos checksum mismatch" >&2
  exit 1
fi
mv "$TMP/yt-dlp_macos" "$BIN/yt-dlp_macos"

# ffmpeg / ffprobe: static builds (VideoToolbox, libmp3lame, libx264, x265)
# from ffmpeg.martin-riedl.de.
ffmpeg_arch() {
  case "$1" in
    arm64) echo arm64 ;;
    x86_64) echo amd64 ;;
  esac
}

fetch_tool() { # tool arch -> $TMP/<arch>/<tool>
  local tool="$1" arch="$2"
  mkdir -p "$TMP/$arch"
  curl -fL --progress-bar -o "$TMP/$arch/$tool.zip" \
    "https://ffmpeg.martin-riedl.de/redirect/latest/macos/$(ffmpeg_arch "$arch")/release/$tool.zip"
  unzip -oq "$TMP/$arch/$tool.zip" -d "$TMP/$arch"
}

for tool in ffmpeg ffprobe; do
  echo "Downloading $tool..."
  if [ "$UNIVERSAL" = 1 ]; then
    fetch_tool "$tool" arm64
    fetch_tool "$tool" x86_64
    lipo -create "$TMP/arm64/$tool" "$TMP/x86_64/$tool" -output "$BIN/$tool"
  else
    arch="$(uname -m)"
    fetch_tool "$tool" "$arch"
    mv "$TMP/$arch/$tool" "$BIN/$tool"
  fi
done

if [ "$WITH_DENO" = 1 ]; then
  echo "Downloading deno..."
  case "$(uname -m)" in
    arm64) target=aarch64-apple-darwin ;;
    *) target=x86_64-apple-darwin ;;
  esac
  curl -fL --progress-bar -o "$TMP/deno.zip" \
    "https://github.com/denoland/deno/releases/latest/download/deno-$target.zip"
  unzip -oq "$TMP/deno.zip" -d "$TMP"
  mv "$TMP/deno" "$BIN/deno"
fi

chmod +x "$BIN"/*
touch "$BIN"/*
xattr -cr "$BIN" 2>/dev/null || true

echo
"$BIN/yt-dlp_macos" --version | sed 's/^/yt-dlp  /'
"$BIN/ffmpeg" -hide_banner -version | head -1
echo "Done: $(pwd)/$BIN"
