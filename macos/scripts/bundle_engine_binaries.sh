#!/bin/bash
# Xcode Run Script phase (Runner target): copies the engine binaries from
# Runner/Resources/bin/ into Contents/Resources/bin/ and signs each one ad-hoc
# so macOS lets them run. See docs/engine/macos_engine.md.
set -euo pipefail

SRC="$SRCROOT/Runner/Resources/bin"
DEST="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/bin"

if ! ls "$SRC"/yt-dlp_macos "$SRC"/ffmpeg >/dev/null 2>&1; then
  echo "warning: Engine binaries missing. Run macos/scripts/fetch_engine_binaries.sh; downloads won't work until then."
  exit 0
fi

mkdir -p "$DEST"
for src in "$SRC"/*; do
  name="$(basename "$src")"
  dest="$DEST/$name"
  # The bundled copy carries its source's mtime: skip unchanged binaries so
  # incremental builds stay fast.
  if [ -f "$dest" ] && [ "$(stat -f %m "$src")" = "$(stat -f %m "$dest")" ]; then
    continue
  fi
  cp -f "$src" "$dest"
  chmod 755 "$dest"
  xattr -c "$dest" 2>/dev/null || true
  codesign --force --sign - "$dest"
  touch -r "$src" "$dest"
done
