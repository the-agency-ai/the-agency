import type { NextConfig } from 'next';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

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
};

export default nextConfig;
