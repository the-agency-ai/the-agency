---
type: reference
date: 2026-04-10
subject: Workshop VM Build — Experience Report
---

# Workshop VM Build — Experience Report

## Context

Building a Ubuntu 24.04 VM for the Republic Polytechnic workshop (Monday 14 April 2026). Goal was to script the entire process via VMware Fusion CLI (`vmrun`, `vmware-vdiskmanager`, `ovftool`). Target: students on Windows x86 machines with VMware Workstation Pro.

## Architecture Mistake

Downloaded `ubuntu-24.04.4-desktop-arm64.iso` (3.3 GB) — correct for our Apple Silicon Mac but **wrong for the students**. They're on Windows x86 machines. An ARM64 OVA won't run on x86 VMware Workstation. Can't cross-build either — Fusion on Apple Silicon cannot run x86 guests (no emulation, no Rosetta passthrough for VMs).

**Resolution:** Pivoted to a bootstrap script model. Students create their own x86 VM from `ubuntu-24.04.4-desktop-amd64.iso`, then run our bootstrap script inside it. We test the script on our ARM64 VM — the script is architecture-independent.

## Hand-Crafted VMX Failures

Attempted to create the VM entirely via CLI with a hand-written `.vmx` file. Failed three times:

### Failure 1: `lsilogic` not supported on ARM64

```
The device type "lsilogic" specified for "scsi0" is not supported by VMware Fusion 25.0.0.
```

**Fix:** ARM64 requires NVMe, not SCSI. Changed to `nvme0.present = "TRUE"`.

### Failure 2: `e1000e` PCIe slot conflict

```
No PCIe slot available for Ethernet0. Remove Ethernet0 and try again.
```

Initially thought `e1000e` wasn't supported on ARM64, switched to `vmxnet3`. Same error. The real issue was **missing PCIe bridge configuration**, not the NIC type. Fusion's wizard-created VMX has `e1000e` and it works fine.

### Failure 3: VMX panic — "monitor not available"

```
E1000PCI: failed to register e1000e device.
PANIC: Unexpected signal: 11.
Panic: monitor not available, skipping monitor coredump.
```

Cascading failure from the PCIe slot issue. Without proper bridge entries, devices can't register, the VMX process panics.

### Root Cause: Missing PCIe Bridge Entries

Fusion's wizard generates **6 PCIe bridge entries** that are required for ARM64 VMs:

```
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
```

Without these, no PCIe device (NIC, USB, SATA, NVMe) can claim a slot. The error message ("No PCIe slot available") is accurate but misleading — it's not a slot numbering conflict, it's a missing bus topology.

Additionally, Fusion auto-assigns `pciSlotNumber` values and writes them back to the `.vmx` on first boot. Hand-assigning slot numbers is futile — Fusion overwrites them. The correct approach is to provide the bridge entries and let Fusion assign slots.

### Other Required Entries

Fusion's wizard also adds `vmci0.present`, `hpet0.present`, and `sound.*` entries. The `vmci0` (Virtual Machine Communication Interface) and `hpet0` (High Precision Event Timer) may not be strictly required but are part of the standard ARM64 VM profile.

## What Works: Fusion GUI Wizard + CLI Post-Config

The working approach:

1. **Fusion GUI wizard** creates the VM with correct hardware profile (~2 min)
2. **CLI post-config** via `.vmx` edits: attach ISO, bump CPUs/RAM/disk
3. **`vmrun start`** boots the VM
4. **`vmrun snapshot`** for rollback points
5. **`ovftool`** for OVA export

The wizard handles the platform-specific hardware topology that's underdocumented for ARM64. Everything after creation is scriptable.

## ARM64 VMX Template (for future scripting)

If we ever need to create ARM64 VMs from scratch via CLI, this is the minimum viable `.vmx`:

```
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "22"
virtualHW.productCompatibility = "hosted"

# PCIe bridges — REQUIRED for ARM64
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"

vmci0.present = "TRUE"
hpet0.present = "TRUE"
firmware = "efi"
guestOS = "arm-ubuntu-64"
numvcpus = "4"
memsize = "4096"

# Disk — NVMe required for ARM64
nvme0.present = "TRUE"
nvme0:0.present = "TRUE"
nvme0:0.fileName = "disk.vmdk"

# CD/DVD
sata0.present = "TRUE"
sata0:0.present = "TRUE"
sata0:0.deviceType = "cdrom-image"
sata0:0.fileName = "/path/to/ubuntu.iso"
sata0:0.startConnected = "TRUE"

# Network — e1000e works on ARM64 (with bridges)
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "e1000e"
ethernet0.addressType = "generated"

# USB
usb.present = "TRUE"
usb_xhci.present = "TRUE"

# Misc
tools.syncTime = "TRUE"
displayName = "My ARM64 VM"
```

## Action Log — VM Test Build

| # | Action | Result |
|---|--------|--------|
| 1 | Downloaded `ubuntu-24.04.4-desktop-arm64.iso` (3.3 GB) | ✅ Complete |
| 2 | Hand-crafted .vmx — `lsilogic` disk controller | ❌ Not supported on ARM64 |
| 3 | Switched to NVMe disk | ❌ PCIe slot error for Ethernet0 |
| 4 | Switched NIC from `e1000e` to `vmxnet3` | ❌ Same PCIe slot error |
| 5 | Diagnosed root cause: missing PCIe bridge entries | 💡 Key learning |
| 6 | Realized ARM64 OVA can't run on x86 student machines | 💡 Pivoted to bootstrap script model |
| 7 | Created VM via Fusion GUI wizard | ✅ Correct hardware profile |
| 8 | Post-configured: 4 CPUs, 4GB RAM, 40GB disk, attached ISO | ✅ vmx edits + vdiskmanager |
| 9 | Booted VM, walked through Ubuntu installer | ✅ Captured every screen |
| 10 | Installer offered "Update installer" mid-wizard | 💡 Captured for guide — requires relaunch |
| 11 | Ubuntu installed, rebooted, snapshot "clean-install" | ✅ Rollback point |
| 12 | Installed open-vm-tools + openssh-server | ✅ Clipboard + SSH access |
| 13 | Switched to bridged networking for SSH | ✅ IP: 192.168.1.115 |
| 14 | Added SSH key, set up passwordless sudo | ✅ Remote access working |
| 15 | Disabled lock screen, screensaver, idle sleep | ✅ gsettings |
| 16 | Snapshot "pre-bootstrap" | ✅ Second rollback point |
| 17 | Ran bootstrap script — system packages | ✅ All installed |
| 18 | Bootstrap — Google Chrome | ❌ No ARM64 .deb — fell back to Chromium snap |
| 19 | Bootstrap — Ghostty | ❌ No PPA, no snap, no flatpak, no .deb for Linux |
| 20 | Decision: drop Ghostty, use default GNOME Terminal | ✅ Simpler for students |
| 21 | Bootstrap — Homebrew | ✅ Installed |
| 22 | Bootstrap — Node.js (via system, not brew) | ✅ v25.9.0 |
| 23 | Bootstrap — Claude Code | ✅ v2.1.100 |
| 24 | Bootstrap — Docker | ✅ Installed |
| 25 | Bootstrap — GitHub CLI | ✅ v2.89.0 |
| 26 | Fixed: `CHROME_CMD` unbound variable in verification | ✅ Script bug |
| 27 | Fixed: Chrome install — architecture-aware (amd64→Chrome, arm64→Chromium) | ✅ Script fix |

## Software Manifest

### Host Machine (Students — Windows x86)

| Software | Version | Source |
|----------|---------|--------|
| VMware Workstation Pro | Latest (free) | https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware+Workstation+Pro |
| Claude Desktop | Latest | https://claude.ai/download |

### VM — Ubuntu 24.04.4 Desktop

#### Pre-installed (Ubuntu default)
| Software | Purpose |
|----------|---------|
| Firefox | Default browser (pre-installed) |
| GNOME Terminal | Default terminal |
| Python 3.12 | System Python |

#### Installed by bootstrap script — system packages (apt)
| Package | Purpose |
|---------|---------|
| curl | HTTP client |
| wget | HTTP downloads |
| git | Version control |
| build-essential | C/C++ compiler toolchain |
| jq | JSON processor |
| sqlite3 | Database (used by ISCP) |
| tree | Directory visualization |
| unzip | Archive extraction |
| ca-certificates | TLS certificates |
| gnupg | GPG for package signing |
| lsb-release | OS identification |
| software-properties-common | PPA management |
| python3-pip | Python package manager |
| ripgrep | Fast search (rg) |
| fd-find | Fast file finder (fd) |

#### Installed by bootstrap script — applications
| Software | Version (tested) | Install method | Purpose |
|----------|-----------------|----------------|---------|
| Google Chrome | Latest | apt (.deb from Google) | Browser for OAuth (x86 only) |
| Chromium | 146.x | snap (ARM64 fallback) | Browser for OAuth (ARM64 only) |
| Homebrew | Latest | Official installer | Package manager (macOS parity) |
| Node.js | v25.9.0 | brew | JavaScript runtime |
| Claude Code | v2.1.100 | npm (`@anthropic-ai/claude-code`) | AI coding assistant |
| Docker CE | Latest | Official Docker repo | Container runtime |
| GitHub CLI | v2.89.0 | brew | GitHub operations |
| open-vm-tools | Latest | apt | VMware guest integration |
| openssh-server | Latest | apt | SSH access |

### NOT Installed (dropped)
| Software | Reason |
|----------|--------|
| Ghostty | No prebuilt packages for Linux. No PPA, snap, flatpak, or .deb. Build-from-source requires Zig compiler — too complex for workshop. Students use GNOME Terminal instead. |

## Workshop Runtime Architecture

### Student Setup

```
┌──────────────────────────────────────────────────────────────┐
│  Windows Host                                                │
│                                                              │
│  ┌─────────────────────────┐                                 │
│  │  Chrome                 │                                 │
│  │  └─ claude.ai/code      │───── outbound HTTPS ──────┐    │
│  │     (Remote Control UI) │                            │    │
│  └─────────────────────────┘                            │    │
│                                                         │    │
│  ┌─────────────────────────┐                            │    │
│  │  Claude Desktop         │                            │    │
│  │  (research / chat)      │                            │    │
│  └─────────────────────────┘                            │    │
│                                                         │    │
│  ┌──────────────────────────────────────────────────┐   │    │
│  │  Ubuntu VM (VMware Workstation, NAT)             │   │    │
│  │                                                  │   │    │
│  │  ┌─────────────────┐  ┌─────────────────┐       │   │    │
│  │  │ GNOME Terminal  │  │ GNOME Terminal  │       │   │    │
│  │  │ claude session 1│  │ claude session 2│       │   │    │
│  │  │ /remote-control │  │ /remote-control │       │   │    │
│  │  └────────┬────────┘  └────────┬────────┘       │   │    │
│  │           │                    │                 │   │    │
│  └───────────┼────────────────────┼─────────────────┘   │    │
│              │                    │                      │    │
└──────────────┼────────────────────┼──────────────────────┘    │
               │                    │                           │
               └─── outbound HTTPS ─┴───── Anthropic relay ────┘
                    (port 443 only)        servers
```

### Networking

- **VM network mode: NAT** — simplest, works everywhere, no bridging needed
- **Remote Control** goes through Anthropic's relay servers — both the browser (claude.ai/code) and the CLI (Claude Code in VM) connect **outbound** to Anthropic. They never talk to each other directly.
- **No inbound ports** need to be opened on the VM or the host
- **Port 443 (HTTPS)** is the only requirement — outbound from both host and VM

### How Remote Control Works

1. Student opens **two GNOME Terminal windows** in the VM
2. In each, runs `claude` then `/remote-control` (or `claude --remote-control`)
3. Claude Code displays a QR code or URL
4. Student opens **Chrome on Windows host** → navigates to `claude.ai/code`
5. Scans QR code or enters the session code
6. Chrome tab now controls the Claude Code session in the VM
7. Repeat for second session in another Chrome tab

### Why This Setup

- **Claude Desktop on Windows** — for research, chat, general Claude usage (no coding)
- **Claude Code in VM** — for hands-on coding, agency framework, terminal access
- **Remote Control bridge** — lets them see and interact with Claude Code sessions from the comfortable Chrome UI while the actual execution happens in the Linux VM
- **Two sessions** — one for the main project, one for exploration/experiments

## Deliverables Produced

1. **Workshop Setup Guide** — `agency/workstreams/agency/seeds/workshop-setup-guide-20260410.md`
   - Students download VMware Workstation + Ubuntu AMD64 ISO + Claude Desktop
   - Create VM via Workstation wizard, install Ubuntu
   - Detailed installer walk-through (every screen documented)
   - Bootstrap script runs at the workshop, not at home

2. **Bootstrap Script** — `agency/workstreams/agency/seeds/workshop-bootstrap.sh`
   - Idempotent, architecture-independent
   - Installs: Chrome/Chromium, Homebrew, Node.js, Claude Code, Docker, GitHub CLI
   - Tested on ARM64 VM

## Lessons

- **ARM64 VMware is underdocumented.** The PCIe bridge requirement is not in any official VMware CLI docs. You discover it by diffing a wizard-created VMX against a hand-crafted one.
- **Fusion overwrites your .vmx.** It auto-assigns PCI slots, UUIDs, and adds entries on every boot attempt. Fighting it is pointless — let the wizard or Fusion itself handle hardware topology.
- **Architecture matters for VM distribution.** OVA built on ARM can't run on x86. The bootstrap script model (students build their own VM, script provisions it) is more portable than shipping an image.
- **"Too Lazy to Fail" applies here.** The bootstrap script is the durable artifact. The VM image was a one-shot; the script is reusable, testable, and architecture-independent.
- **Ghostty is macOS-only in practice.** No prebuilt Linux packages. Drop it for Linux workshops — GNOME Terminal is fine for Claude Code.
- **Google Chrome has no ARM64 Linux .deb.** Use Chromium as fallback. Script needs architecture-aware branching.
- **Ubuntu installer has a mid-wizard "update installer" prompt** that restarts the wizard. Must be documented for non-sysadmin users.
