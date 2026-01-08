import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  // For Tauri, we need static export
  trailingSlash: true,
};

export default nextConfig;
