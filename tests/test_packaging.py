import importlib.util
import json
from pathlib import Path
import plistlib
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('package', ROOT / 'scripts/package.py')
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class PackagingTests(unittest.TestCase):
    def test_extension_id_is_stable_and_has_no_site_permissions(self):
        manifest = json.loads((ROOT / 'extension/manifest.json').read_text())
        self.assertEqual(package.extension_id(manifest), 'adbkdecjkchapapdbdhiidkfaafpemci')
        self.assertNotIn('host_permissions', manifest)
        self.assertNotIn('content_scripts', manifest)
        self.assertEqual(set(manifest['permissions']), {'nativeMessaging', 'storage'})

    def test_install_into_path_with_spaces_and_update(self):
        with tempfile.TemporaryDirectory(prefix='keychain pair ') as temp:
            base = Path(temp)
            build = base / 'build'
            build.mkdir()
            package.configure(ROOT, build)
            app = build / 'KeychainPairHelper.app/Contents'
            (app / 'MacOS').mkdir()
            binary = app / 'MacOS/KeychainPairHelper'
            binary.write_text('fixture')
            binary.chmod(0o755)
            data, host = package.install(ROOT, build, base / 'installed helper', base / 'Chrome data')
            record = json.loads(host.read_text())
            self.assertEqual(record['path'], str(data / 'KeychainPairHelper.app/Contents/MacOS/KeychainPairHelper'))
            self.assertEqual(record['allowed_origins'], ['chrome-extension://adbkdecjkchapapdbdhiidkfaafpemci/'])
            self.assertEqual(plistlib.loads((app / 'Info.plist').read_bytes())['LSUIElement'], True)
            (data / 'extension/stale-file.js').write_text('stale')
            package.install(ROOT, build, data, base / 'Chrome data')
            self.assertFalse((data / 'extension/stale-file.js').exists())
            self.assertTrue((data / 'KeychainPairHelper.app/Contents/MacOS/KeychainPairHelper').stat().st_mode & 0o111)

    def test_installer_refuses_unowned_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaises(RuntimeError):
                package.install(ROOT, Path(temp) / 'build', Path(temp), Path(temp) / 'Chrome')


if __name__ == '__main__':
    unittest.main()
