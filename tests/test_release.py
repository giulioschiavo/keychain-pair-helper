import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'downloads/KeychainPairHelper-macOS.zip'


@unittest.skipUnless(sys.platform == 'darwin' and ARCHIVE.exists(), 'Requires macOS and packaged release')
class ReadyMadeInstallerTests(unittest.TestCase):
    def test_zip_can_install_without_python_or_compiler_and_update(self):
        with tempfile.TemporaryDirectory(prefix="keychain pair's release ") as temp:
            base = Path(temp)
            subprocess.run(['/usr/bin/ditto', '-x', '-k', str(ARCHIVE), str(base)], check=True)
            package = base / 'KeychainPairHelper-macOS'
            script = package / 'Install.command'
            self.assertTrue(os.access(script, os.X_OK))
            self.assertNotIn('python', script.read_text().lower())
            self.assertNotIn('swiftc', script.read_text())
            install = base / 'installed helper'
            chrome = base / 'Chrome data'
            env = dict(os.environ, KPH_INSTALL_ROOT=str(install), KPH_CHROME_ROOT=str(chrome), KPH_NO_OPEN='1')
            for _ in range(2):
                subprocess.run(['/bin/bash', str(script)], check=True, env=env, capture_output=True, text=True)
                host_file = chrome / 'NativeMessagingHosts/io.github.giulioschiavo.keychain_pair_helper.json'
                host = json.loads(host_file.read_text())
                self.assertEqual(host['path'], str(install / 'KeychainPairHelper.app/Contents/MacOS/KeychainPairHelper'))
                subprocess.run(['/usr/bin/codesign', '--verify', '--strict', str(install / 'KeychainPairHelper.app')], check=True)
            for locale in ['en', 'it']:
                self.assertTrue((install / 'extension/_locales' / locale / 'messages.json').is_file())

    def test_archive_contains_no_personal_paths_or_private_keys(self):
        with zipfile.ZipFile(ARCHIVE) as archive:
            for name in archive.namelist():
                self.assertFalse(name.endswith(('.pem', '.key')))
                self.assertNotIn('__MACOSX', name)
                if not name.endswith('/'):
                    content = archive.read(name)
                    self.assertNotIn(b'/Users/giulio/', content, name)
                    self.assertNotIn(b'BEGIN PRIVATE KEY', content, name)


if __name__ == '__main__':
    unittest.main()
