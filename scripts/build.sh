#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${1:-$repo_dir/build}"
mkdir -p "$build_dir"
build_dir="$(cd "$build_dir" && pwd)"
app_dir="$build_dir/KeychainPairHelper.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources" "$build_dir/module-cache"
/usr/bin/python3 "$repo_dir/scripts/package.py" configure "$repo_dir" "$build_dir"
for architecture in arm64 x86_64; do
  xcrun swiftc "$repo_dir/native/main.swift" "$repo_dir/native/Localization.swift" "$build_dir/BuildConfig.swift" \
    -target "$architecture-apple-macos14.0" -o "$build_dir/helper-$architecture" -O \
    -module-cache-path "$build_dir/module-cache" \
    -framework AppKit -framework ApplicationServices
done
lipo -create "$build_dir/helper-arm64" "$build_dir/helper-x86_64" -output "$app_dir/Contents/MacOS/KeychainPairHelper"
cp "$repo_dir/assets/KeychainPairHelper.icns" "$app_dir/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app_dir"
codesign --verify --strict "$app_dir"
"$app_dir/Contents/MacOS/KeychainPairHelper" --self-test
printf 'Built: %s\n' "$app_dir"
