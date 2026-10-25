#!/usr/bin/env python3
"""Portable build configuration and user-only installation. No code downloads."""
import base64
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import sys
import uuid

HOST = 'io.github.giulioschiavo.keychain_pair_helper'
BUNDLE = 'io.github.giulioschiavo.KeychainPairHelper'
MARKER = '.keychain-pair-helper-install.json'


def extension_id(manifest):
    digest = hashlib.sha256(base64.b64decode(manifest['key'], validate=True)).hexdigest()[:32]
    return ''.join(chr(ord('a') + int(nibble, 16)) for nibble in digest)


def configure(repo, build):
    manifest = json.loads((repo / 'extension/manifest.json').read_text())
    origin = 'chrome-extension://' + extension_id(manifest) + '/'
    (build / 'BuildConfig.swift').write_text('let expectedExtensionOrigin = ' + json.dumps(origin) + '\n')
    plist = dict(CFBundleIdentifier=BUNDLE, CFBundleName='Keychain Pair Helper',
                 CFBundleDisplayName='Keychain Pair Helper', CFBundleExecutable='KeychainPairHelper',
                 CFBundlePackageType='APPL', CFBundleShortVersionString=manifest['version'],
                 CFBundleIconFile='AppIcon',
                 CFBundleVersion='2', LSMinimumSystemVersion='14.0', LSUIElement=True,
                 NSHighResolutionCapable=True)
    dest = build / 'KeychainPairHelper.app/Contents/Info.plist'
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(plistlib.dumps(plist))


def install(repo, build, data_dir=None, chrome_dir=None):
    data_dir = data_dir or Path.home() / 'Library/Application Support/KeychainPairHelper'
    chrome_dir = chrome_dir or Path.home() / 'Library/Application Support/Google/Chrome'
    data_dir = data_dir.expanduser().absolute()
    if data_dir.is_symlink() or (data_dir.exists() and not (data_dir / MARKER).is_file()):
        raise RuntimeError('Refusing to overwrite a directory not created by this installer: ' + str(data_dir))
    data_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(data_dir, 0o700)
    manifest = json.loads((repo / 'extension/manifest.json').read_text())
    stage = data_dir / ('.stage-' + uuid.uuid4().hex)
    stage.mkdir()
    try:
        shutil.copytree(build / 'KeychainPairHelper.app', stage / 'KeychainPairHelper.app')
        shutil.copytree(repo / 'extension', stage / 'extension')
        for name in ['KeychainPairHelper.app', 'extension']:
            target = data_dir / name
            if target.exists():
                shutil.rmtree(target)
            (stage / name).rename(target)
    finally:
        shutil.rmtree(stage, ignore_errors=True)
    host = dict(name=HOST, description='Keychain Pair Helper', type='stdio',
                path=str(data_dir / 'KeychainPairHelper.app/Contents/MacOS/KeychainPairHelper'),
                allowed_origins=['chrome-extension://' + extension_id(manifest) + '/'])
    host_dir = chrome_dir / 'NativeMessagingHosts'
    host_dir.mkdir(parents=True, exist_ok=True)
    host_file = host_dir / (HOST + '.json')
    if host_file.is_symlink():
        raise RuntimeError('Refusing to replace a symlink: ' + str(host_file))
    if host_file.exists() and json.loads(host_file.read_text()).get('name') != HOST:
        raise RuntimeError('Refusing to overwrite a different native host')
    host_file.write_text(json.dumps(host, indent=2) + '\n')
    os.chmod(host_file, 0o600)
    (data_dir / MARKER).write_text(json.dumps({'host_file': str(host_file), 'version': manifest['version']}) + '\n')
    print('Installed helper: ' + str(data_dir / 'KeychainPairHelper.app'))
    print('In chrome://extensions, load this unpacked extension directory:')
    print(data_dir / 'extension')
    return data_dir, host_file


def uninstall():
    data_dir = Path.home() / 'Library/Application Support/KeychainPairHelper'
    marker = data_dir / MARKER
    if data_dir.is_symlink() or not marker.is_file():
        raise RuntimeError('No installation owned by this project was found')
    host_file = Path.home() / 'Library/Application Support/Google/Chrome/NativeMessagingHosts' / (HOST + '.json')
    trash = Path.home() / '.Trash'
    trash.mkdir(exist_ok=True)
    for item in [host_file, data_dir]:
        if item.exists():
            item.rename(trash / (item.name + '-' + uuid.uuid4().hex[:8]))
    print('Moved helper and native host registration to Trash.')
    print('Also remove the Chrome extension and its Accessibility permission in System Settings.')


if __name__ == '__main__':
    command = sys.argv[1]
    if command == 'configure':
        configure(Path(sys.argv[2]), Path(sys.argv[3]))
    elif command == 'install':
        install(Path(sys.argv[2]), Path(sys.argv[3]))
    elif command == 'uninstall':
        uninstall()
    else:
        raise SystemExit('Unknown command')
