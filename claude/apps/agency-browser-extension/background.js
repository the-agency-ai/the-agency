// Agency Browser Extension - Background Service Worker
// Handles communication between content scripts and AgencyBench

const AGENCY_BENCH_URL = 'http://localhost:3010';

// Create context menu for sending content to Agency
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'agency-send-selection',
    title: 'Send to Agency',
    contexts: ['selection']
  });

  chrome.contextMenus.create({
    id: 'agency-send-page',
    title: 'Send Page to Agency',
    contexts: ['page']
  });

  chrome.contextMenus.create({
    id: 'agency-capture-screenshot',
    title: 'Capture for Agency',
    contexts: ['page']
  });
});

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  switch (info.menuItemId) {
    case 'agency-send-selection':
      await sendToAgency({
        type: 'selection',
        content: info.selectionText,
        url: tab.url,
        title: tab.title,
        timestamp: new Date().toISOString()
      });
      break;

    case 'agency-send-page':
      // Get page content via content script
      const [result] = await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: () => ({
          content: document.body.innerText,
          html: document.documentElement.outerHTML
        })
      });
      await sendToAgency({
        type: 'page',
        content: result.result.content,
        html: result.result.html,
        url: tab.url,
        title: tab.title,
        timestamp: new Date().toISOString()
      });
      break;

    case 'agency-capture-screenshot':
      const dataUrl = await chrome.tabs.captureVisibleTab(tab.windowId, { format: 'png' });
      await sendToAgency({
        type: 'screenshot',
        dataUrl,
        url: tab.url,
        title: tab.title,
        timestamp: new Date().toISOString()
      });
      break;
  }
});

// Send data to AgencyBench
async function sendToAgency(data) {
  try {
    // Store in extension storage for AgencyBench to pick up
    const items = await chrome.storage.local.get('agencyQueue') || { agencyQueue: [] };
    const queue = items.agencyQueue || [];
    queue.push(data);
    await chrome.storage.local.set({ agencyQueue: queue });

    // Also try to send directly to AgencyBench if running
    try {
      await fetch(`${AGENCY_BENCH_URL}/api/browser-capture`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
    } catch (e) {
      // AgencyBench not running, data is queued
      console.log('AgencyBench not available, data queued');
    }

    // Notify user
    chrome.action.setBadgeText({ text: String(queue.length) });
    chrome.action.setBadgeBackgroundColor({ color: '#4F46E5' });
  } catch (error) {
    console.error('Failed to send to Agency:', error);
  }
}

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'agency-capture') {
    sendToAgency(message.data).then(() => sendResponse({ success: true }));
    return true; // Keep channel open for async response
  }
});

// Clear badge when queue is emptied
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'local' && changes.agencyQueue) {
    const queue = changes.agencyQueue.newValue || [];
    if (queue.length === 0) {
      chrome.action.setBadgeText({ text: '' });
    }
  }
});
