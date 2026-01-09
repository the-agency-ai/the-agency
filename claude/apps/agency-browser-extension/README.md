# Agency Browser Extension

Browser integration for The Agency multi-agent framework.

## Features

- **Context Menu**: Right-click to send selection, page content, or screenshot to Agency
- **Keyboard Shortcut**: `Cmd+Shift+A` to quickly capture selected text
- **Queue System**: Captures are queued if AgencyBench isn't running
- **Direct Integration**: Sends directly to AgencyBench when available

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select this directory: `claude/apps/agency-browser-extension/`

## Setup Icons

Create PNG icons at these sizes in the `icons/` directory:
- `icon16.png` (16x16)
- `icon48.png` (48x48)
- `icon128.png` (128x128)

Or use a placeholder icon generator to create them.

## Usage

### Context Menu
Right-click on any page to access:
- **Send to Agency** - Send selected text
- **Send Page to Agency** - Send full page content
- **Capture for Agency** - Take screenshot

### Keyboard Shortcut
Select text and press `Cmd+Shift+A` (Mac) or `Ctrl+Shift+A` (Windows/Linux)

### Popup
Click the extension icon to:
- Check AgencyBench connection status
- View queued captures
- Manually trigger captures
- Clear the queue

## AgencyBench Integration

The extension sends captures to `http://localhost:3010/api/browser-capture`.
Add this API endpoint to AgencyBench to receive captures.

## Development

The extension consists of:
- `manifest.json` - Extension configuration (Manifest V3)
- `background.js` - Service worker for context menus and messaging
- `content.js` - Content script for keyboard shortcuts
- `popup.html/js` - Extension popup UI
