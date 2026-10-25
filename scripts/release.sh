#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
bash "$repo_dir/scripts/build.sh"
package_dir="$repo_dir/build/KeychainPairHelper-macOS"
mkdir -p "$package_dir" "$repo_dir/downloads"
ditto "$repo_dir/build/KeychainPairHelper.app" "$package_dir/KeychainPairHelper.app"
ditto "$repo_dir/extension" "$package_dir/extension"
cp "$repo_dir/distribution/Install.command" "$repo_dir/distribution/Uninstall.command" "$package_dir/"
cp "$repo_dir/distribution/READ-ME-en.txt" "$repo_dir/distribution/LEGGIMI-it.txt" "$package_dir/"
cp "$repo_dir/LICENSE" "$package_dir/LICENSE.txt"
chmod +x "$package_dir/Install.command" "$package_dir/Uninstall.command"
/usr/bin/python3 - "$repo_dir" "$package_dir" <<'PY'
import importlib.util,json,sys
from pathlib import Path
root, package = map(Path, sys.argv[1:])
spec=importlib.util.spec_from_file_location('package', root/'scripts/package.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
manifest=json.loads((root/'extension/manifest.json').read_text())
host=dict(name=module.HOST,description='Keychain Pair Helper',path='__INSTALL_PATH__',type='stdio',allowed_origins=['chrome-extension://'+module.extension_id(manifest)+'/'])
(package/'native-host-template.json').write_text(json.dumps(host,indent=2)+'\n')
PY
archive="$repo_dir/downloads/KeychainPairHelper-macOS.zip"
rm -f "$archive"
ditto -c -k --norsrc --noextattr --keepParent "$package_dir" "$archive"
(cd "$repo_dir/downloads" && shasum -a 256 KeychainPairHelper-macOS.zip > SHA256SUMS.txt)
printf 'Ready: %s\n' "$archive"
