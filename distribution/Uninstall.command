#!/bin/bash
set -euo pipefail
install_dir="$HOME/Library/Application Support/KeychainPairHelper"
native_host="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/io.github.giulioschiavo.keychain_pair_helper.json"
if [[ -L "$install_dir" || ! -f "$install_dir/.keychain-pair-helper-install.json" ]]; then
  echo 'No installation found / Nessuna installazione trovata.'
  exit 1
fi
echo 'Remove Keychain Pair Helper from Chrome first. Continue? [y/N]'
echo 'Prima rimuovi Keychain Pair Helper da Chrome. Continuare? [y/N]'
read -r answer
[[ "$answer" == y || "$answer" == Y ]] || exit 0
suffix="$(/usr/bin/uuidgen)"
/bin/mkdir -p "$HOME/.Trash"
[[ ! -e "$native_host" ]] || /bin/mv "$native_host" "$HOME/.Trash/io.github.giulioschiavo.keychain_pair_helper-$suffix.json"
/bin/mv "$install_dir" "$HOME/.Trash/KeychainPairHelper-$suffix"
echo 'Moved to Trash. Remove its Accessibility entry in System Settings.'
echo 'Spostato nel Cestino. Rimuovi anche la voce da Accessibilità nelle Impostazioni di Sistema.'
read -r
