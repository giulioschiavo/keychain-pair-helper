#!/bin/bash
set -euo pipefail
payload_dir="$(cd "$(dirname "$0")" && pwd)"
install_dir="${KPH_INSTALL_ROOT:-$HOME/Library/Application Support/KeychainPairHelper}"
chrome_dir="${KPH_CHROME_ROOT:-$HOME/Library/Application Support/Google/Chrome}"
host_name='io.github.giulioschiavo.keychain_pair_helper'
native_host="$chrome_dir/NativeMessagingHosts/$host_name.json"
language="$(/usr/bin/defaults read -g AppleLocale 2>/dev/null || true)"
italian=false
[[ "$language" == it* ]] && italian=true

if [[ ! -d "$payload_dir/KeychainPairHelper.app" || ! -f "$payload_dir/extension/manifest.json" ]]; then
  echo 'Incomplete download / Download incompleto. Extract the whole ZIP / Estrai tutto lo ZIP.' >&2
  exit 1
fi
if [[ -L "$install_dir" || -L "$native_host" ]]; then
  echo 'Refusing to overwrite symlinks / Impossibile sovrascrivere collegamenti simbolici.' >&2
  exit 1
fi
if [[ -e "$install_dir" && ! -f "$install_dir/.keychain-pair-helper-install.json" ]]; then
  echo 'Installation directory already exists and is not owned by this installer.' >&2
  echo 'La cartella esiste già e non appartiene a questo installer.' >&2
  exit 1
fi
/usr/bin/codesign --verify --strict "$payload_dir/KeychainPairHelper.app"
/bin/mkdir -p "$install_dir" "$chrome_dir/NativeMessagingHosts"
/bin/chmod 700 "$install_dir"
staging="$install_dir/.stage-$$"
/bin/mkdir "$staging"
trap '/bin/rm -rf "$staging"' EXIT
/usr/bin/ditto "$payload_dir/KeychainPairHelper.app" "$staging/KeychainPairHelper.app"
/usr/bin/ditto "$payload_dir/extension" "$staging/extension"
/bin/cp "$payload_dir/native-host-template.json" "$staging/host.json"
/usr/bin/plutil -replace path -string "$install_dir/KeychainPairHelper.app/Contents/MacOS/KeychainPairHelper" "$staging/host.json"
for component in KeychainPairHelper.app extension; do
  if [[ -e "$install_dir/$component" ]]; then
    backup="$install_dir/.previous-$component"
    /bin/rm -rf "$backup"
    /bin/mv "$install_dir/$component" "$backup"
  fi
  /bin/mv "$staging/$component" "$install_dir/$component"
done
/bin/mv "$staging/host.json" "$native_host"
/bin/chmod 600 "$native_host"
/usr/bin/printf '{"version":"0.1.1"}\n' > "$install_dir/.keychain-pair-helper-install.json"
if $italian; then
  echo 'Installazione completata. Nessuna compilazione necessaria.'
  echo '1. In Chrome attiva Modalità sviluppatore e scegli Carica estensione non pacchettizzata.'
  echo "2. Seleziona questa cartella: $install_dir/extension"
  echo '3. Apri Keychain Pair Helper e scegli Autorizza sul Mac.'
else
  echo 'Installed. No compilation required.'
  echo '1. In Chrome enable Developer mode, then choose Load unpacked.'
  echo "2. Select this folder: $install_dir/extension"
  echo '3. Open Keychain Pair Helper and choose Authorize on Mac.'
fi
if [[ "${KPH_NO_OPEN:-0}" != 1 ]]; then
  /usr/bin/open -R "$install_dir/extension"
  /usr/bin/open -a 'Google Chrome' 'chrome://extensions/'
  echo 'Press Return to close / Premi Invio per chiudere.'
  read -r
fi
