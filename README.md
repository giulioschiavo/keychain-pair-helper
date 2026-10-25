# Keychain Pair Helper

<img src="extension/icons/icon128.png" width="72" height="72" alt="Keychain Pair Helper icon">

**English** · [Italiano](README.it.md)

A small macOS companion that enters the six-digit pairing code in the **official iCloud Passwords extension for Google Chrome**.

Keep the native password experience. This project automates the initial pairing interaction; Apple's extension continues to fill, save and manage passwords.

**Experimental · v0.1.1 · macOS + Google Chrome**

## How it works

1. Open the official Passwords extension in Chrome as usual.
2. macOS displays a six-digit pairing code.
3. The local helper reads that label through Accessibility, locates the official extension's popup, fills the six fields and sends the final confirmation keystroke.

No extra macOS menu bar or Dock icon. Chrome starts the helper through Native Messaging. Pausing the companion extension disconnects it; closing the native connection stops the helper. There is no login item or launch daemon.

The companion is controlled from Chrome's Extensions menu. It does not replace or modify the official extension and does not install configuration profiles.

## Requirements

- macOS 14 or later and Google Chrome.
- The official [iCloud Passwords extension](https://chromewebstore.google.com/detail/icloud-passwords/pejdijmoenmkgeppbflobdenhhabjlaj) installed and working with your iCloud Keychain.
- Accessibility permission for **Keychain Pair Helper**, granted manually in System Settings.

A precompiled universal macOS package is available below. It is ad-hoc signed, **not notarized**. There is no Chrome Web Store release.

## Download and install — no compilation

**[Download KeychainPairHelper-macOS.zip](https://github.com/giulioschiavo/keychain-pair-helper/raw/refs/heads/main/downloads/KeychainPairHelper-macOS.zip)** · [SHA-256](downloads/SHA256SUMS.txt)

The same ZIP supports **Apple Silicon and Intel** Macs. Extract the whole archive before installing.

1. Double-click **Install.command**. It copies the precompiled helper to your user folder and opens Chrome's Extensions page.
2. Enable **Developer mode**, choose **Load unpacked**, press **Command–Shift–G**, and enter `~/Library/Application Support/KeychainPairHelper/extension`.
3. Open **Keychain Pair Helper** from Chrome's Extensions menu. Click **Authorize on Mac**, then enable **Keychain Pair Helper** in **System Settings → Privacy & Security → Accessibility**.
4. Open the official iCloud Passwords extension as usual and keep Chrome in the foreground while it pairs.

Chrome does not install a GitHub ZIP directly as a store extension. The manual **Load unpacked** step is required. The popup and helper messages automatically use **English or Italian**, following Chrome's language.

**macOS security prompt:** this experimental build is not notarized. macOS may block the installer or helper; review the source and use [Apple's guidance for an app you trust](https://support.apple.com/102445). The installer does not remove quarantine attributes or disable Gatekeeper. If the helper itself is blocked, try opening the installed `KeychainPairHelper.app` directly to show macOS's prompt. Accessibility is a separate permission.

The installer requires **no compiler, Python, developer tools or admin password**. macOS may separately request authentication for its security/permission dialogs. Installation is user-only under `~/Library/Application Support/KeychainPairHelper/`; one native-host JSON is registered in Chrome's user directory. Full instructions in both languages are included in the ZIP.

**Earlier local prototype users:** remove/disable the previous companion before loading this one; it shares the same extension ID. Keep the official iCloud Passwords extension installed.

### Build from source instead

Install Apple Command Line Tools (`xcode-select --install`), then:

```sh
git clone https://github.com/giulioschiavo/keychain-pair-helper.git
cd keychain-pair-helper
bash install.sh
```

Follow steps 2–4 above. Development builds use Swift and Python 3; the downloadable installer does not.

## Permissions and security model

Accessibility is a **broad system permission**: macOS does not restrict it to one window. Review the source before granting it. The implementation targets the Apple Passwords helper's Chrome pairing window and the exact popup URL of the official extension; it only sends a keystroke when Chrome is foreground, the intended field is focused, and all six values match the pending code.

- No website permissions or content scripts.
- No password database, password capture or website autofill implementation.
- Pairing codes remain transiently in process memory, never intentionally written to files, logs or the clipboard.
- No network requests, telemetry or account registration in this project's code.
- Native messages carry status and control commands, not the pairing code.
- The native host accepts the companion extension's exact origin, derived from its public manifest key.

This automates a security interaction. It preserves the existing pairing protocol but removes the manual transcription step. If you want that manual step, pause or uninstall the companion. It does not bypass Mac login, Touch ID, Apple ID authentication or other prompts.

## Status and known limitations

- The initial prototype was exercised locally against iCloud Passwords **3.4.0**. It could miss the final digit on the first attempt.
- Version **0.1.1** fills all six fields, waits for focus to settle, and bounds retries of the final confirmation to the same unchanged popup. The corrected behavior still needs broader real-world testing; automated checks do **not** prove successful pairing.
- macOS/Chrome/extension updates may change Accessibility structure, key handling or the popup path. This relies on UI automation, not a supported Apple pairing API.
- Google Chrome is the only configured browser. Other Chromium browsers and multiple concurrent Chrome profiles are not supported/tested.
- Keep Chrome foreground during pairing. Changes to the popup, field values or focus stop the submission rather than redirect it elsewhere.
- If pairing does not finish, select the last field and type the final digit manually. You can also pause the companion and pair normally.
- If Chrome opens its own password-manager suggestions, change Chrome preferences manually if desired; this project does not set a managed policy.
- Rebuilding changes the ad-hoc code signature. macOS may require toggling or re-adding the helper in Accessibility. There is no stable Developer ID signature yet.

## Update

Pause the companion first. Download the new ZIP and run `Install.command` again (or pull source and run `bash install.sh`). Reload it in `chrome://extensions`, then renew Accessibility if prompted. The installer replaces only its own marked installation directory and native-host registration.

## Uninstall

Remove **Keychain Pair Helper** from Chrome, then double-click **Uninstall.command** in the downloaded package. Source users can run `bash uninstall.sh`.

This moves the installed helper directory and native-host registration to Trash. Remove its Accessibility entry manually. The official iCloud Passwords extension and your saved passwords remain untouched.

## Development

```sh
bash scripts/build.sh
python3 -m unittest discover -s tests -v
node --check extension/background.js
node --check extension/popup.js
```

Build output is excluded from Git. The build generates `BuildConfig.swift` from the public manifest key, so there are no user-specific absolute paths or private signing keys in the source tree. Installer tests use temporary directories, including paths with spaces; they do not modify the real Chrome installation.

For a manual regression check, use a fresh pairing session, verify all six digits and completion on the **first** attempt, and repeat after restarting Chrome. Also verify that pausing stops the helper and closing the popup cannot send a digit to a website. Do not include real pairing codes, passwords or account details in issue reports.

## Independent project

Not affiliated with, endorsed by, or maintained by Apple or Google. Product names identify compatibility; no Apple or Google code, logos or bundled extension assets are distributed here.

Original geometric icon and source code are included. MIT licensed. This project provides a narrow companion workflow rather than an alternative password manager.
