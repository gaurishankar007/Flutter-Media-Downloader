#!/bin/bash
# Downloads the Linux engine binaries into linux/engine/bin/ (not committed).
# Run once after cloning, and again to refresh them. The build copies them
# into the bundle's bin/ folder. See docs/engine/desktop_engine.md.
#
#   linux/scripts/fetch_engine_binaries.sh               # this machine's arch (x86_64 or aarch64)
#   linux/scripts/fetch_engine_binaries.sh --with-deno   # also bundle deno (YouTube JS challenges)
set -euo pipefail

cd "$(dirname "$0")/.."
BIN="engine/bin"
mkdir -p "$BIN"

WITH_DENO=0
for arg in "$@"; do
  case "$arg" in
    --with-deno) WITH_DENO=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 64 ;;
  esac
done

case "$(uname -m)" in
  x86_64) YTDLP_NAME=yt-dlp_linux; FFMPEG_ARCH=linux64; DENO_TARGET=x86_64-unknown-linux-gnu ;;
  aarch64|arm64) YTDLP_NAME=yt-dlp_linux_aarch64; FFMPEG_ARCH=linuxarm64; DENO_TARGET=aarch64-unknown-linux-gnu ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# yt-dlp: official standalone build, checked against SHA2-256SUMS. Saved as
# yt-dlp_linux on every arch, the name the app runs.
YTDLP_BASE="https://github.com/yt-dlp/yt-dlp/releases/latest/download"
echo "Downloading $YTDLP_NAME..."
curl -fL --progress-bar -o "$TMP/$YTDLP_NAME" "$YTDLP_BASE/$YTDLP_NAME"
curl -fsSL -o "$TMP/SHA2-256SUMS" "$YTDLP_BASE/SHA2-256SUMS"
expected="$(awk -v name="$YTDLP_NAME" '$2 == name { print $1 }' "$TMP/SHA2-256SUMS")"
actual="$(sha256sum "$TMP/$YTDLP_NAME" | awk '{ print $1 }')"
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
  echo "$YTDLP_NAME checksum mismatch" >&2
  exit 1
fi
mv "$TMP/$YTDLP_NAME" "$BIN/yt-dlp_linux"

# ffmpeg / ffprobe: static GPL builds from BtbN/FFmpeg-Builds (libx264, x265,
# libmp3lame, libwebp, VAAPI / NVENC encoders).
echo "Downloading ffmpeg..."
FFMPEG_DIR="ffmpeg-master-latest-$FFMPEG_ARCH-gpl"
curl -fL --progress-bar -o "$TMP/ffmpeg.tar.xz" \
  "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/$FFMPEG_DIR.tar.xz"
tar -xJf "$TMP/ffmpeg.tar.xz" -C "$TMP"
mv "$TMP/$FFMPEG_DIR/bin/ffmpeg" "$TMP/$FFMPEG_DIR/bin/ffprobe" "$BIN/"

if [ "$WITH_DENO" = 1 ]; then
  echo "Downloading deno..."
  curl -fL --progress-bar -o "$TMP/deno.zip" \
    "https://github.com/denoland/deno/releases/latest/download/deno-$DENO_TARGET.zip"
  unzip -oq "$TMP/deno.zip" -d "$TMP"
  mv "$TMP/deno" "$BIN/deno"
fi

chmod +x "$BIN"/yt-dlp_linux "$BIN"/ffmpeg "$BIN"/ffprobe
[ -f "$BIN/deno" ] && chmod +x "$BIN/deno"

echo
"$BIN/yt-dlp_linux" --version | sed 's/^/yt-dlp  /'
"$BIN/ffmpeg" -hide_banner -version | head -1
echo "Done: $(pwd)/$BIN"
