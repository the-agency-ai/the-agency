---
type: seed
workstream: agency
date: 2026-04-10
subject: Workshop VM Setup Guide — Republic Polytechnic
---

# AI Augmented Development Workshop — Setup Guide

## Workshop: AI Augmented Development with Claude Code
**Date:** Monday 14 April 2026
**Location:** Republic Polytechnic

---

## What You Need

### 1. VMware Workstation Pro (free)

**Download:** https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware+Workstation+Pro

- Create a free Broadcom account if you don't have one
- Download **VMware Workstation Pro** for Windows
- Install with default settings

### 2. Ubuntu 24.04.4 Desktop ISO (x86_64)

**Download:** https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-desktop-amd64.iso

- ~5.8 GB download
- This is the **AMD64** (x86_64) version — the standard one for Windows/Intel/AMD machines

### 3. Claude Desktop (on your Windows machine)

**Download:** https://claude.ai/download

- Install the Windows version
- Sign up for a free account if you don't have one
- This runs on your Windows host, not inside the VM

### 4. Anthropic Account

- You will log in to Claude Code via the browser at the workshop
- You do NOT need to set this up in advance — we'll walk through it together

---

## Step-by-Step: Create the VM

### Step 1: Create a new VM in VMware Workstation

1. Open VMware Workstation
2. **File → New Virtual Machine** (or Ctrl+N)
3. Select **Typical** configuration → Next
4. **Installer disc image file (iso)** → Browse to your downloaded `ubuntu-24.04.4-desktop-amd64.iso` → Next
5. Enter your name, username, and password — your choice, just remember them!
6. VM name: `Agency-Workshop` → Next
7. Disk size: **40 GB**, store as single file → Next
8. Click **Customize Hardware**:
   - **Memory:** 4096 MB (4 GB)
   - **Processors:** 4
   - **Network:** NAT (default)
9. Click **Close** then **Finish**

### Step 2: Install Ubuntu

The VM will boot from the ISO automatically. The installer has several screens — here's exactly what to do at each one:

1. **Accessibility** — skip this unless you need it. Just close it.
2. **Install Ubuntu** — click **Install Ubuntu** (not "Try Ubuntu")
3. **Update installer?** — the installer may offer to update itself. Click **Update installer**, wait for it to finish, then **relaunch the installer**. This is normal — you'll start from step 1 again.
4. **Language & Keyboard** — pick your language and keyboard layout, click **Next**
5. **Internet connection** — select **Use wired connection** (this is the VMware virtual network adapter — it's correct). Click **Next**
6. **Type of installation** — select **Interactive installation**. Click **Next**
7. **Default or Extended?** — select **Default installation**. Click **Next**
8. **Proprietary software** — leave both checkboxes **unchecked** (you don't need GPU drivers or media codecs for this workshop). Click **Next**
9. **Disk setup** — select **Erase disk and install Ubuntu** (this is safe — it only erases the virtual disk, not your real hard drive!). Click **Next**
10. **Create your account** — enter your name, username, and password. Your choice — just remember them! Uncheck "Require my password to log in" if you want auto-login for convenience. Click **Next**
11. **Timezone** — select your timezone. Click **Next**
12. **Review your choices** — confirm everything looks right. Click **Install**
13. **Wait** ~10 minutes for the installation to complete
14. Click **Restart Now** when prompted
15. Press **Enter** when asked to remove installation media

### Step 3: First Boot & Run the Bootstrap Script

After Ubuntu boots and you log in:

1. Open a terminal: **press Ctrl+Alt+T**
2. Run this command:

```bash
curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/claude/workstreams/agency/seeds/workshop-bootstrap.sh | bash
```

3. The script will install everything you need:
   - Google Chrome browser
   - Homebrew, Node.js, Git, jq, sqlite3, and other dev tools
   - Claude Code
   - Docker & GitHub CLI

4. **When it finishes**, it will show a verification checklist. All items should show ✓.

**That's it for pre-workshop setup.** We'll do Claude Code login and workspace creation together at the start of the workshop.

---

## Troubleshooting

**VM won't start / slow performance:**
- Make sure **virtualization** is enabled in your BIOS/UEFI settings (VT-x / AMD-V)
- Close other heavy applications
- Try reducing VM memory to 3072 MB if your machine has only 8 GB RAM

**No internet in the VM:**
- Check VMware's virtual network: **Edit → Virtual Network Editor**
- Make sure NAT is configured
- Try switching network adapter to **Bridged** mode

**Bootstrap script fails:**
- Make sure you have internet connectivity: `ping google.com`
- Run the script again — it's idempotent (safe to re-run)
- If a specific package fails, note the error and ask at the workshop

**"Curl not found":**
- Run `sudo apt update && sudo apt install -y curl` first, then re-run the bootstrap command
