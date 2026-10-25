#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")" && pwd)"
/usr/bin/python3 "$repo_dir/scripts/package.py" uninstall
