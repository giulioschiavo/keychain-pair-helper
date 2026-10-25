const HOST = 'io.github.giulioschiavo.keychain_pair_helper';
let port = null;
let status = {connected: false, trusted: false, enabled: true, status: chrome.i18n.getMessage('connecting')};

async function connect() {
  const {enabled = true} = await chrome.storage.local.get('enabled');
  status.enabled = enabled;
  if (!enabled || port) return;
  port = chrome.runtime.connectNative(HOST);
  const current = port;
  current.onMessage.addListener(message => {
    if (current !== port || typeof message.status !== 'string') return;
    status = {...status, status: message.status, trusted: message.trusted === true, connected: true};
    chrome.action.setBadgeText({text: status.trusted ? '' : '!'});
    chrome.action.setBadgeBackgroundColor({color: '#925200'});
  });
  current.onDisconnect.addListener(() => {
    const error = chrome.runtime.lastError?.message;
    if (current !== port) return;
    port = null;
    status.connected = false;
    status.status = error ? chrome.i18n.getMessage('hostUnavailable') : chrome.i18n.getMessage('hostStopped');
    chrome.action.setBadgeText({text: '!'});
    // No background retry loop: retry on popup opening or browser startup.
  });
  port.postMessage({action: 'status', locale: chrome.i18n.getUILanguage()});
}

chrome.runtime.onInstalled.addListener(connect);
chrome.runtime.onStartup.addListener(connect);
chrome.runtime.onMessage.addListener((message, sender, respond) => {
  if (sender.id !== chrome.runtime.id || !sender.url?.startsWith(chrome.runtime.getURL('popup.html'))) return;
  (async () => {
    if (message.action === 'toggle') {
      const enabled = !status.enabled;
      await chrome.storage.local.set({enabled});
      status.enabled = enabled;
      if (!enabled) {
        const old = port; port = null; old?.disconnect();
        status.connected = false; status.status = chrome.i18n.getMessage('paused');
        await chrome.action.setBadgeText({text: ''});
      }
    }
    await connect();
    if (message.action === 'authorize') port?.postMessage({action: 'authorize', locale: chrome.i18n.getUILanguage()});
    else port?.postMessage({action: 'status', locale: chrome.i18n.getUILanguage()});
    respond({...status});
  })().catch(() => respond({...status, status: chrome.i18n.getMessage('connectionFailed')}));
  return true;
});
connect();
