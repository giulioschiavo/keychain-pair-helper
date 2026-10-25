import Foundation

func localizedStatus(_ value: String, language: String) -> String {
    if language.lowercased().hasPrefix("it") { return value }
    return [
        "In attesa del codice Apple": "Waiting for the pairing code",
        "Serve autorizzazione Accessibilità": "Accessibility permission required",
        "Compilazione interrotta: popup chiuso o modificato": "Autofill stopped: popup closed or changed",
        "Codice compilato: seleziona l’ultimo campo e riscrivi l’ultima cifra": "Code filled: select the last field and retype its digit",
        "Codice inviato all’estensione Apple": "Code sent to iCloud Passwords",
        "Codice compilato; controlla l’esito nell’estensione Apple": "Code filled; check the result in iCloud Passwords",
        "Inserimento non riuscito: completa manualmente": "Autofill failed: complete pairing manually"
    ][value] ?? value
}
