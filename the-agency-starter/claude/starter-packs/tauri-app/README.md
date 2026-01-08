# Tauri App Starter Pack

A starter template for building desktop applications with Tauri + Next.js for The Agency.

## What's Included

- **Tauri 2.x** - Rust-based desktop application framework
- **Next.js 15** - React framework with App Router
- **Tailwind CSS** - Utility-first CSS
- **SQLite + Drizzle** - Local database (optional)
- **TypeScript** - Type safety

## Quick Start

```bash
# Copy this starter to your project
cp -r claude/starter-packs/tauri-app apps/my-app

# Install dependencies
cd apps/my-app
npm install

# Run in development
npm run dev          # Web only
npm run tauri:dev    # Desktop app
```

## Prerequisites

### For Web Development
- Node.js 18+

### For Desktop Builds
- Rust toolchain (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- Platform-specific dependencies:
  - **macOS**: Xcode Command Line Tools
  - **Linux**: `sudo apt install libwebkit2gtk-4.1-dev build-essential curl wget file libssl-dev libayatana-appindicator3-dev librsvg2-dev`
  - **Windows**: Microsoft Visual Studio C++ Build Tools

## Project Structure

```
my-app/
├── src/                    # Next.js frontend
│   ├── app/               # App router pages
│   ├── components/        # React components
│   └── lib/               # Utilities
├── src-tauri/             # Tauri backend (Rust)
│   ├── src/
│   │   └── main.rs        # Tauri commands
│   ├── Cargo.toml         # Rust dependencies
│   └── tauri.conf.json    # Tauri configuration
└── public/                # Static assets
```

## Adding Tauri Commands

Expose Rust functions to the frontend:

```rust
// src-tauri/src/main.rs
#[tauri::command]
async fn my_command(arg: String) -> Result<String, String> {
    Ok(format!("Hello, {}!", arg))
}

// Register in main()
.invoke_handler(tauri::generate_handler![my_command])
```

Call from React:

```typescript
import { invoke } from '@tauri-apps/api/core';

const result = await invoke('my_command', { arg: 'World' });
```

## File System Access

Tauri provides secure file system access:

```typescript
import { readTextFile, writeTextFile } from '@tauri-apps/plugin-fs';

// Read file
const content = await readTextFile('path/to/file.md');

// Write file
await writeTextFile('path/to/file.md', content);
```

## Building for Distribution

```bash
# Build for current platform
npm run tauri:build

# Output in src-tauri/target/release/bundle/
```

## Resources

- [Tauri Documentation](https://tauri.app/v2/guides/)
- [Next.js Documentation](https://nextjs.org/docs)
- [The Agency Documentation](../../docs/)
