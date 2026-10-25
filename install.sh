#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'Keychain Pair Helper requires macOS 14 or later.' >&2
  exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
  echo 'Install Apple Command Line Tools first: xcode-select --install' >&2
  exit 1
fi
bash "$repo_dir/scripts/build.sh"
/usr/bin/python3 "$repo_dir/scripts/package.py" install "$repo_dir" "$repo_dir/build"
