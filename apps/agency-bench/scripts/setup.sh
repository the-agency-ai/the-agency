#!/bin/bash
#
# AgencyBench Setup Script
# Installs all dependencies needed to build and run AgencyBench
#

set -e

echo "=== AgencyBench Setup ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Node.js
echo "Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓ Node.js $NODE_VERSION${NC}"
else
    echo -e "${RED}✗ Node.js not found${NC}"
    echo "  Install from: https://nodejs.org/"
    exit 1
fi

# Check npm
echo "Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓ npm $NPM_VERSION${NC}"
else
    echo -e "${RED}✗ npm not found${NC}"
    exit 1
fi

# Check Rust (for Tauri)
echo "Checking Rust..."
if command -v rustc &> /dev/null; then
    RUST_VERSION=$(rustc --version)
    echo -e "${GREEN}✓ Rust: $RUST_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Rust not found (needed for desktop builds)${NC}"
    echo "  Install with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "  Continuing with web-only setup..."
fi

# Check Tauri CLI
echo "Checking Tauri CLI..."
if npm list @tauri-apps/cli &> /dev/null; then
    echo -e "${GREEN}✓ Tauri CLI (local)${NC}"
else
    echo -e "${YELLOW}⚠ Tauri CLI will be installed with npm dependencies${NC}"
fi

echo ""
echo "=== Installing Dependencies ==="
echo ""

# Install npm dependencies
echo "Installing npm packages..."
npm install

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Available commands:"
echo "  npm run dev        - Start web development server"
echo "  npm run tauri:dev  - Start Tauri development (requires Rust)"
echo "  npm run tauri:build - Build desktop app (requires Rust)"
echo ""
echo "Web app: http://localhost:3010"
