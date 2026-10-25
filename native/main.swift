import AppKit
import ApplicationServices

let helperID = "com.apple.PasswordManagerBrowserExtensionHelper"
let chromeID = "com.google.Chrome"
let popupURL = "chrome-extension://pejdijmoenmkgeppbflobdenhhabjlaj/page_popup.html"

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var result: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else { return nil }
    return result
}
func string(_ element: AXUIElement, _ name: String) -> String {
    if let value = attribute(element, name) as? String { return value }
    if let value = attribute(element, name) as? URL { return value.absoluteString }
    return ""
}
func elements(_ element: AXUIElement, _ name: String) -> [AXUIElement] {
    return attribute(element, name) as? [AXUIElement] ?? []
}
func descendants(_ root: AXUIElement, limit: Int = 2500) -> [AXUIElement] {
    var result: [AXUIElement] = []
    var queue = [root]
    var offset = 0
    while offset < queue.count && result.count < limit {
        let item = queue[offset]; offset += 1
        result.append(item)
        queue.append(contentsOf: elements(item, kAXChildrenAttribute))
    }
    return result
}
func parseCode(_ text: String) -> String? {
    // Only a standalone six-digit label, optionally split into two groups.
    guard text.range(of: #"^[0-9]{3}[\s\u00a0\u202f]?[0-9]{3}$"#,
                     options: .regularExpression) != nil else { return nil }
    return text.filter { $0.isASCII && $0.isNumber }
}
func fieldsInPopup(_ app: AXUIElement) -> [AXUIElement]? {
    // Inspect extension popup windows only; never walk a website's DOM.
    for window in elements(app, kAXWindowsAttribute) where string(window, kAXTitleAttribute).isEmpty {
        for item in descendants(window, limit: 1200) where
            string(item, kAXRoleAttribute) == "AXWebArea" &&
            string(item, kAXURLAttribute) == popupURL {
            let fields = descendants(item, limit: 150).filter {
                string($0, kAXRoleAttribute) == kAXTextFieldRole &&
                (attribute($0, kAXEnabledAttribute) as? Bool ?? true)
            }
            if fields.count == 6 { return fields }
        }
    }
    return nil
}

final class PairHelper: NSObject, NSApplicationDelegate {
    var language = Locale.preferredLanguages.first ?? "en"
    var timer: Timer?
    var paused = false
    var attemptedWindow: String?
    var busy = false
    // Focus changes cross process boundaries and may settle on a later run loop.
    func submitWhenReady(_ chrome: NSRunningApplication, _ chromeAX: AXUIElement,
                         _ target: AXUIElement, _ digits: [Character], attempt: Int = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempt == 0 ? 0.18 : 0.30)) { [weak self] in
            guard let self else { return }
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == chrome.processIdentifier,
                  let current = fieldsInPopup(chromeAX), CFEqual(current[5], target),
                  zip(current, digits).allSatisfy({ string($0.0, kAXValueAttribute) == String($0.1) }) else {
                self.busy = false
                self.status = "Compilazione interrotta: popup chiuso o modificato"
                return
            }
            guard let focused = attribute(chromeAX, kAXFocusedUIElementAttribute), CFEqual(focused, target) else {
                if attempt < 3 {
                    AXUIElementSetAttributeValue(target, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                    self.submitWhenReady(chrome, chromeAX, target, digits, attempt: attempt + 1)
                } else {
                    self.busy = false
                    self.status = "Codice compilato: seleziona l’ultimo campo e riscrivi l’ultima cifra"
                }
                return
            }
            let keyCodes: [Character: CGKeyCode] = ["0":29,"1":18,"2":19,"3":20,"4":21,"5":23,"6":22,"7":26,"8":28,"9":25]
            guard let keyCode = keyCodes[digits[5]],
                  let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
                self.busy = false; return
            }
            down.flags = []; up.flags = []
            var character = String(digits[5]).utf16.first!
            down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
            up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
            down.postToPid(chrome.processIdentifier)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                up.postToPid(chrome.processIdentifier)
            }
            self.status = "Codice inviato all’estensione Apple"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self else { return }
                // Retry only this same unsubmitted six-digit form, at most twice.
                // Never send another key to a closed/replaced popup or website.
                if attempt < 2, NSWorkspace.shared.frontmostApplication?.processIdentifier == chrome.processIdentifier,
                   let remaining = fieldsInPopup(chromeAX), CFEqual(remaining[5], target),
                   zip(remaining, digits).allSatisfy({ string($0.0, kAXValueAttribute) == String($0.1) }) {
                    self.submitWhenReady(chrome, chromeAX, target, digits, attempt: attempt + 1)
                } else {
                    self.busy = false
                    self.status = "Codice compilato; controlla l’esito nell’estensione Apple"
                }
            }
        }
    }
    var status = "In attesa del codice Apple" {
        didSet { sendStatus() }
    }
    func sendStatus() {
        let trusted = AXIsProcessTrusted()
        let text = trusted && status == "Serve autorizzazione Accessibilità" ? "In attesa del codice Apple" : status
        let message: [String: Any] = ["status": localizedStatus(text, language: language), "trusted": trusted]
        guard let data = try? JSONSerialization.data(withJSONObject: message), data.count < 65536 else { return }
        var size = UInt32(data.count).littleEndian
        FileHandle.standardOutput.write(Data(bytes: &size, count: 4))
        FileHandle.standardOutput.write(data)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in self?.tick() }
        status = AXIsProcessTrusted() ? "In attesa del codice Apple" : "Serve autorizzazione Accessibilità"
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let input = FileHandle.standardInput
            func readExactly(_ count: Int) -> Data? {
                var data = Data()
                while data.count < count {
                    guard let part = try? input.read(upToCount: count - data.count), !part.isEmpty else { return nil }
                    data.append(part)
                }
                return data
            }
            while let header = readExactly(4) {
                let count = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).littleEndian }
                guard count > 0, count <= 4096, let data = readExactly(Int(count)),
                      let message = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                      let action = message["action"] as? String else { break }
                DispatchQueue.main.async {
                    if let locale = message["locale"] as? String { self?.language = locale }
                    if action == "authorize" {
                        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                    self?.sendStatus()
                }
            }
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
    func tick() {
        guard !paused, !busy, AXIsProcessTrusted() else { return }
        guard let chrome = NSRunningApplication.runningApplications(withBundleIdentifier: chromeID).first,
              NSWorkspace.shared.frontmostApplication?.processIdentifier == chrome.processIdentifier else { return }
        let chromeAX = AXUIElementCreateApplication(chrome.processIdentifier)
        AXUIElementSetMessagingTimeout(chromeAX, 0.25)
        for helper in NSRunningApplication.runningApplications(withBundleIdentifier: helperID) {
            let helperAX = AXUIElementCreateApplication(helper.processIdentifier)
            AXUIElementSetMessagingTimeout(helperAX, 0.25)
            for window in elements(helperAX, kAXWindowsAttribute) {
                let identity = "\(helper.processIdentifier):\(CFHash(window))"
                if attemptedWindow == identity { continue }
                let nodes = descendants(window, limit: 100)
                let labels = nodes.filter { string($0, kAXRoleAttribute) == kAXStaticTextRole }.map {
                    string($0, kAXValueAttribute)
                }
                guard labels.contains(where: { $0.contains("Chrome") }),
                      let code = labels.compactMap(parseCode).first,
                      let fields = fieldsInPopup(chromeAX),
                      fields.allSatisfy({ string($0, kAXValueAttribute).isEmpty }) else { continue }
                busy = true
                attemptedWindow = identity
                // Populate ALL six fields, then wait for Chrome to focus the last.
                // Apple's keydown handler still needs one real final-digit event.
                let digits = Array(code)
                var filled = true
                for index in 0..<6 {
                    if AXUIElementSetAttributeValue(fields[index], kAXValueAttribute as CFString,
                                                    String(digits[index]) as CFString) != .success { filled = false; break }
                }
                guard filled else {
                    busy = false
                    status = "Inserimento non riuscito: completa manualmente"; return
                }
                AXUIElementSetAttributeValue(fields[5], kAXFocusedAttribute as CFString, kCFBooleanTrue)
                submitWhenReady(chrome, chromeAX, fields[5], digits)
                return
            }
        }
    }
}

if CommandLine.arguments.contains("--self-test") {
    precondition(parseCode("123456") == "123456")
    precondition(parseCode("123\u{00a0}456") == "123456")
    precondition(parseCode("123\u{202f}456") == "123456")
    for invalid in ["12345", "1234567", "codice 123456", "１２３４５６", "123-456"] {
        precondition(parseCode(invalid) == nil)
    }
    precondition(localizedStatus("Serve autorizzazione Accessibilità", language: "en-US") == "Accessibility permission required")
    precondition(localizedStatus("Serve autorizzazione Accessibilità", language: "it-IT") == "Serve autorizzazione Accessibilità")
    print("PASS: code parsing, invalid inputs and English/Italian localization")
} else if CommandLine.arguments.contains("--check-permission") {
    print(AXIsProcessTrusted() ? "Accessibility: granted" : "Accessibility: not granted")
} else if CommandLine.arguments.dropFirst().contains(expectedExtensionOrigin) {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = PairHelper()
    app.delegate = delegate
    app.run()
}

else { print("Questo helper viene avviato dall’estensione Keychain Pair Helper per Chrome.") }
