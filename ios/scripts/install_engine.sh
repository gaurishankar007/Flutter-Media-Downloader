#!/bin/bash
# Xcode build phase ("Install Python engine", after Resources): copies Python's
# standard library, the engine shim, yt-dlp and certifi into the app, and turns
# Python's binary modules into signed frameworks (an iOS requirement), following
# BeeWare's Python.xcframework/build/utils.sh (reimplemented: it breaks on paths
# with spaces and on multi-arch simulator builds).
# See docs/engine/ios_engine.md#packaging.
set -euo pipefail

FRAMEWORKS="Frameworks"
if [ ! -d "$PROJECT_DIR/$FRAMEWORKS/Python.xcframework" ] || [ ! -f "$PROJECT_DIR/$FRAMEWORKS/python-packages/yt-dlp.zip" ]; then
  echo "error: The iOS engine is missing. Run ios/scripts/fetch_engine.sh first."
  exit 1
fi

# Unsigned builds (--no-codesign, simulator) still need valid framework
# signatures to load: sign those ad hoc.
if [ -z "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] || [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ]; then
  export EXPANDED_CODE_SIGN_IDENTITY="-"
  export EXPANDED_CODE_SIGN_IDENTITY_NAME="ad hoc"
fi

# BeeWare's install_stdlib, extended to multi-arch simulator builds
# (ARCHS="arm64 x86_64"): the per-arch binary modules are merged with lipo.
XCFRAMEWORK="$PROJECT_DIR/$FRAMEWORKS/Python.xcframework"
case "$EFFECTIVE_PLATFORM_NAME" in
  -iphonesimulator) SLICE="ios-arm64_x86_64-simulator" ;;
  -iphoneos) SLICE="ios-arm64" ;;
  *) echo "error: Unsupported platform $EFFECTIVE_PLATFORM_NAME"; exit 1 ;;
esac
mkdir -p "$CODESIGNING_FOLDER_PATH/python/lib"
rsync -a --delete "$XCFRAMEWORK/lib/" "$CODESIGNING_FOLDER_PATH/python/lib/" --exclude 'libpython*.dylib'
first_arch=""
for arch in $ARCHS; do
  if [ -z "$first_arch" ]; then
    first_arch="$arch"
    rsync -a "$XCFRAMEWORK/$SLICE/lib-$arch/" "$CODESIGNING_FOLDER_PATH/python/lib/" --exclude 'libpython*.dylib'
    continue
  fi
  rsync -a --exclude '*.so' "$XCFRAMEWORK/$SLICE/lib-$arch/" "$CODESIGNING_FOLDER_PATH/python/lib/"
  (cd "$XCFRAMEWORK/$SLICE/lib-$arch" && find . -name "*.so") | while IFS= read -r so; do
    lipo -create "$CODESIGNING_FOLDER_PATH/python/lib/$so" "$XCFRAMEWORK/$SLICE/lib-$arch/$so" \
      -output "$CODESIGNING_FOLDER_PATH/python/lib/$so"
  done
done

# Drop what the app never imports (the test suite alone is ~35 MB).
PYTHON_LIB="$CODESIGNING_FOLDER_PATH/python/lib"
PYTHON_VER=$(ls -1 "$PYTHON_LIB" | grep -E "^python3\.[0-9]+$")
STDLIB="$PYTHON_LIB/$PYTHON_VER"
rm -rf "$STDLIB/test" "$STDLIB/idlelib" "$STDLIB/tkinter" "$STDLIB/turtledemo" "$STDLIB/ensurepip" \
  "$STDLIB/pydoc_data" "$STDLIB/config-"*
find "$STDLIB/lib-dynload" \( -name "_test*" -o -name "_ctypes_test*" -o -name "xxlimited*" -o -name "_xxtestfuzz*" \) -delete

# BeeWare's install_dylib, quoted: its own breaks on paths with spaces.
install_dylib_quoted() {
  local install_base="$1" full_ext="$2"
  local ext module_path module_name relative_ext python_ext full_module_name bundle_id framework_folder
  ext=$(basename "$full_ext")
  module_path=$(dirname "$full_ext")
  module_name=$(echo "$ext" | cut -d "." -f 1)
  relative_ext=${full_ext#"$CODESIGNING_FOLDER_PATH"/}
  python_ext=${relative_ext/"$install_base"/}
  full_module_name=$(echo "$python_ext" | cut -d "." -f 1 | tr "/" ".")
  bundle_id=$(echo "$PRODUCT_BUNDLE_IDENTIFIER.$full_module_name" | tr "_" "-")
  framework_folder="Frameworks/$full_module_name.framework"

  mkdir -p "$CODESIGNING_FOLDER_PATH/$framework_folder"
  cp "$PROJECT_DIR/$FRAMEWORKS/Python.xcframework/build/$PLATFORM_FAMILY_NAME-dylib-Info-template.plist" \
    "$CODESIGNING_FOLDER_PATH/$framework_folder/Info.plist"
  plutil -replace CFBundleExecutable -string "$full_module_name" "$CODESIGNING_FOLDER_PATH/$framework_folder/Info.plist"
  plutil -replace CFBundleIdentifier -string "$bundle_id" "$CODESIGNING_FOLDER_PATH/$framework_folder/Info.plist"
  mv "$full_ext" "$CODESIGNING_FOLDER_PATH/$framework_folder/$full_module_name"
  # Python finds the moved binary through this placeholder.
  echo "$framework_folder/$full_module_name" > "${full_ext%.so}.fwork"
  echo "${relative_ext%.so}.fwork" > "$CODESIGNING_FOLDER_PATH/$framework_folder/$full_module_name.origin"
  if [ -e "$module_path/$module_name.xcprivacy" ]; then
    mv "$module_path/$module_name.xcprivacy" "$CODESIGNING_FOLDER_PATH/$framework_folder/PrivacyInfo.xcprivacy"
  fi
  /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" ${OTHER_CODE_SIGN_FLAGS:-} -o runtime --timestamp=none \
    --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der "$CODESIGNING_FOLDER_PATH/$framework_folder"
}

DYLOAD="python/lib/$PYTHON_VER/lib-dynload"
find "$CODESIGNING_FOLDER_PATH/$DYLOAD" -name "*.so" -print0 | while IFS= read -r -d '' so; do
  install_dylib_quoted "$DYLOAD/" "$so"
done

# The engine: our shim, the yt-dlp zipapp and pure-Python packages.
ENGINE="$CODESIGNING_FOLDER_PATH/engine"
mkdir -p "$ENGINE"
rsync -a --delete "$PROJECT_DIR/$FRAMEWORKS/python-packages/" "$ENGINE/"
cp "$PROJECT_DIR/Runner/Engine/python/engine_shim.py" "$ENGINE/engine_shim.py"
