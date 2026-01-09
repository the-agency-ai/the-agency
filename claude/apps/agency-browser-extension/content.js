// Agency Browser Extension - Content Script
// Runs on all pages to enable Agency integration

(function() {
  // Add keyboard shortcut for quick capture (Ctrl/Cmd + Shift + A)
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'A') {
      e.preventDefault();
      captureSelection();
    }
  });

  // Capture current selection
  function captureSelection() {
    const selection = window.getSelection();
    const selectedText = selection.toString().trim();

    if (selectedText) {
      chrome.runtime.sendMessage({
        type: 'agency-capture',
        data: {
          type: 'selection',
          content: selectedText,
          url: window.location.href,
          title: document.title,
          timestamp: new Date().toISOString()
        }
      });
      showNotification('Selection sent to Agency');
    } else {
      showNotification('No text selected');
    }
  }

  // Show brief notification
  function showNotification(message) {
    const notification = document.createElement('div');
    notification.textContent = message;
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: #4F46E5;
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      font-family: system-ui, sans-serif;
      font-size: 14px;
      z-index: 999999;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      animation: agency-slide-in 0.3s ease;
    `;

    // Add animation keyframes
    const style = document.createElement('style');
    style.textContent = `
      @keyframes agency-slide-in {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
      }
    `;
    document.head.appendChild(style);

    document.body.appendChild(notification);
    setTimeout(() => {
      notification.style.animation = 'agency-slide-in 0.3s ease reverse';
      setTimeout(() => notification.remove(), 300);
    }, 2000);
  }

  // Expose API for programmatic access
  window.__agencyExtension = {
    capture: captureSelection,
    sendToAgency: (data) => {
      chrome.runtime.sendMessage({
        type: 'agency-capture',
        data: { ...data, timestamp: new Date().toISOString() }
      });
    }
  };
})();
