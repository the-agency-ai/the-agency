import type { NextConfig } from 'next';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import { readFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Read version from package.json at build time
const packageJson = JSON.parse(
  readFileSync(resolve(__dirname, 'package.json'), 'utf-8')
);
const appVersion = packageJson.version || '0.0.0';

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  // For Tauri, we need static export
  trailingSlash: true,
  // Transpile Tauri plugins for proper bundling
  transpilePackages: ['@tauri-apps/plugin-dialog'],
  // Silence warning about multiple lockfiles - point to this app's directory
  outputFileTracingRoot: resolve(__dirname),
  // Expose version as environment variable
  env: {
    NEXT_PUBLIC_APP_VERSION: appVersion,
  },
};

export default nextConfig;
