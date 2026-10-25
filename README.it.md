# Keychain Pair Helper

<img src="extension/icons/icon128.png" width="72" height="72" alt="Icona di Keychain Pair Helper">

[English](README.md) · **Italiano**

Un piccolo componente macOS che compila il codice di abbinamento a sei cifre nell’**estensione ufficiale Password di iCloud per Google Chrome**.

Mantieni il funzionamento nativo delle password: l’estensione ufficiale continua a compilare, salvare e gestire le credenziali. Questo progetto automatizza solo il codice iniziale.

**Sperimentale · v0.1.1 · macOS + Google Chrome**

## Scarica e installa — senza compilazione

**[Scarica KeychainPairHelper-macOS.zip](https://github.com/giulioschiavo/keychain-pair-helper/raw/refs/heads/main/downloads/KeychainPairHelper-macOS.zip)** · [SHA-256](downloads/SHA256SUMS.txt)

Lo stesso ZIP funziona sui Mac **Apple Silicon e Intel**, con macOS 14 o successivo. Mantieni installata l’[estensione ufficiale Password di iCloud](https://chromewebstore.google.com/detail/icloud-passwords/pejdijmoenmkgeppbflobdenhhabjlaj).

1. Estrai tutto lo ZIP e fai doppio clic su **Install.command**. L’installer copia l’helper nella tua cartella utente e apre la pagina Estensioni di Chrome.
2. Attiva **Modalità sviluppatore**, scegli **Carica estensione non pacchettizzata**, premi **Comando–Maiuscole–G** e inserisci `~/Library/Application Support/KeychainPairHelper/extension`.
3. Apri **Keychain Pair Helper** dal menu Estensioni di Chrome. Scegli **Autorizza sul Mac**, poi abilita **Keychain Pair Helper** in **Impostazioni di Sistema → Privacy e sicurezza → Accessibilità**.
4. Apri Password di iCloud come sempre e lascia Chrome in primo piano durante l’abbinamento.

Chrome non installa uno ZIP di GitHub direttamente come un’estensione del Web Store: serve il passaggio manuale **Carica estensione non pacchettizzata**. Il pannello e i messaggi dell’helper scelgono automaticamente **italiano o inglese** in base alla lingua di Chrome.

**Messaggio di sicurezza di macOS:** questa versione è firmata ad hoc ma **non è notarizzata**. macOS potrebbe bloccare installer o helper: controlla il sorgente e segui le [indicazioni Apple per un’app di cui ti fidi](https://support.apple.com/102445). L’installer non elimina la quarantena e non disattiva Gatekeeper. Se viene bloccato l’helper, prova ad aprire direttamente `KeychainPairHelper.app` nella cartella installata per visualizzare il messaggio di macOS. Accessibilità richiede un’autorizzazione separata.

Non servono compilatore, Python, strumenti di sviluppo o password amministratore per eseguire l’installer. macOS può richiedere separatamente l’autenticazione nei propri pannelli di sicurezza. Le istruzioni in entrambe le lingue sono incluse nello ZIP.

**Se usavi il precedente prototipo locale:** disabilita/rimuovi il vecchio componente prima di caricare questo. Condividono lo stesso ID dell’estensione. Mantieni Password di iCloud ufficiale.

## Cosa viene installato

L’helper e l’estensione vengono copiati in `~/Library/Application Support/KeychainPairHelper/`. Viene registrato un solo host Native Messaging nella cartella utente di Chrome. Nessun profilo di sistema, icona nella barra menu, elemento al login o servizio permanente.

Chrome avvia l’helper. Il comando **Metti in pausa** chiude il collegamento; l’helper termina quando Chrome chiude la connessione.

## Permessi e comportamento

Accessibilità è un **permesso di sistema ampio**: macOS non lo limita a una finestra. Controlla il sorgente prima di concederlo. Il codice cerca la finestra di abbinamento del componente Password di macOS e il popup esatto dell’estensione ufficiale. Invia la conferma solo con Chrome in primo piano, il campo corretto a fuoco e tutte le cifre ancora corrispondenti.

- Nessun accesso ai siti visitati o script inserito nelle pagine.
- Nessun database password o motore di autofill alternativo.
- I codici restano temporaneamente in memoria: non vengono intenzionalmente salvati, registrati nei log o copiati negli appunti.
- Nessuna richiesta a server esterni, telemetria o registrazione account nel codice del progetto.
- Nei messaggi con Chrome passano solo stato e comandi, mai il codice.

Il progetto mantiene il protocollo di abbinamento esistente e automatizza la trascrizione manuale. Non aggira login del Mac, Touch ID, autenticazione Apple ID o altri avvisi. Se preferisci la trascrizione manuale, metti in pausa o disinstalla il componente.

## Limiti e stato delle prove

Il prototipo iniziale è stato provato localmente con Password di iCloud **3.4.0**. In alcuni primi tentativi mancava l’ultima cifra. La versione **0.1.1** compila tutti i campi, attende il focus e limita i tentativi di conferma allo stesso popup invariato. La correzione richiede ancora prove più ampie: i controlli automatici non dimostrano l’affidabilità dell’abbinamento reale.

Aggiornamenti di macOS, Chrome o dell’estensione possono cambiare l’interfaccia e interrompere il funzionamento. Viene usata l’automazione dell’interfaccia, non un’API pubblica di abbinamento. Altri browser Chromium e più profili Chrome contemporanei non sono supportati/provati.

Se la conferma non parte, seleziona l’ultimo campo e scrivi a mano l’ultima cifra. Puoi anche mettere in pausa il componente e abbinare normalmente. Il progetto non imposta regole per nascondere il gestore password di Chrome.

Una nuova compilazione modifica la firma ad hoc: potrebbe essere necessario spegnere/riaccendere o aggiungere di nuovo l’helper in Accessibilità. Non c’è ancora una firma Developer ID stabile.

## Aggiornamento e rimozione

Per aggiornare: metti in pausa il componente, scarica il nuovo ZIP, esegui `Install.command`, ricarica l’estensione da `chrome://extensions` e rinnova Accessibilità se richiesto.

Per rimuovere: elimina **Keychain Pair Helper** da Chrome e apri **Uninstall.command** dal pacchetto scaricato. I file installati vengono spostati nel Cestino. Rimuovi manualmente anche la voce da Accessibilità. Password di iCloud ufficiale e le password salvate restano intatte.

## Sorgente

Per compilare autonomamente servono Apple Command Line Tools (`xcode-select --install`), Swift e Python 3:

```sh
git clone https://github.com/giulioschiavo/keychain-pair-helper.git
cd keychain-pair-helper
bash install.sh
```

Istruzioni di sviluppo e modello di sicurezza completo nel [README inglese](README.md). Il repository include l’icona geometrica originale e il suo generatore. Nessuna chiave privata o percorso personale è incluso nel sorgente.

## Progetto indipendente

Non affiliato, approvato o mantenuto da Apple o Google. I nomi dei prodotti indicano la compatibilità. Non vengono distribuiti codici, loghi o risorse delle estensioni di Apple o Google.

Licenza MIT.
