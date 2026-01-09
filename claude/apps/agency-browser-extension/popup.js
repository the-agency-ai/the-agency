// Agency Browser Extension - Popup Script

const AGENCY_BENCH_URL = 'http://localhost:3010';

document.addEventListener('DOMContentLoaded', async () => {
  // Check connection to AgencyBench
  const statusEl = document.getElementById('status');
  try {
    const response = await fetch(`${AGENCY_BENCH_URL}/api/health`, { mode: 'no-cors' });
    statusEl.textContent = 'Connected to AgencyBench';
    statusEl.className = 'status connected';
  } catch (e) {
    statusEl.textContent = 'AgencyBench not running';
    statusEl.className = 'status disconnected';
  }

  // Update queue count
  updateQueueCount();

  // Button handlers
  document.getElementById('capture-selection').addEventListener('click', async () => {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => window.__agencyExtension?.capture()
    });
    window.close();
  });

  document.getElementById('capture-page').addEventListener('click', async () => {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    const [result] = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => ({
        content: document.body.innerText,
        html: document.documentElement.outerHTML
      })
    });

    await sendToQueue({
      type: 'page',
      content: result.result.content,
      html: result.result.html,
      url: tab.url,
      title: tab.title,
      timestamp: new Date().toISOString()
    });
    window.close();
  });

  document.getElementById('capture-screenshot').addEventListener('click', async () => {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    const dataUrl = await chrome.tabs.captureVisibleTab(tab.windowId, { format: 'png' });

    await sendToQueue({
      type: 'screenshot',
      dataUrl,
      url: tab.url,
      title: tab.title,
      timestamp: new Date().toISOString()
    });
    window.close();
  });

  document.getElementById('clear-queue').addEventListener('click', async () => {
    await chrome.storage.local.set({ agencyQueue: [] });
    chrome.action.setBadgeText({ text: '' });
    updateQueueCount();
  });
});

async function updateQueueCount() {
  const items = await chrome.storage.local.get('agencyQueue');
  const count = (items.agencyQueue || []).length;
  document.getElementById('queue-count').textContent = count;
}

async function sendToQueue(data) {
  const items = await chrome.storage.local.get('agencyQueue');
  const queue = items.agencyQueue || [];
  queue.push(data);
  await chrome.storage.local.set({ agencyQueue: queue });
  chrome.action.setBadgeText({ text: String(queue.length) });
  chrome.action.setBadgeBackgroundColor({ color: '#4F46E5' });

  // Try to send to AgencyBench
  try {
    await fetch(`${AGENCY_BENCH_URL}/api/browser-capture`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
  } catch (e) {
    console.log('AgencyBench not available, data queued');
  }
}
