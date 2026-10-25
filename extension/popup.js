document.documentElement.lang = chrome.i18n.getUILanguage();
for (const element of document.querySelectorAll('[data-i18n]')) {
  element.textContent = chrome.i18n.getMessage(element.dataset.i18n);
}
const statusElement = document.getElementById('status');
const authorize = document.getElementById('authorize');
const toggle = document.getElementById('toggle');
async function refresh(action = 'status') {
  try {
    const state = await chrome.runtime.sendMessage({action});
    statusElement.textContent = state.status;
    authorize.hidden = !state.enabled || !state.connected || state.trusted;
    toggle.textContent = chrome.i18n.getMessage(state.enabled ? 'pause' : 'enable');
    toggle.disabled = false;
  } catch {
    statusElement.textContent = chrome.i18n.getMessage('notReady');
  }
}
authorize.addEventListener('click', () => refresh('authorize'));
toggle.addEventListener('click', () => refresh('toggle'));
refresh();
setInterval(() => refresh(), 1200);
