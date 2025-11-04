# Midnight Miner Releases

Installation scripts and runners for the midnight-miner binary.

## Quick Install

### Bash (Linux/macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/mgpai22/midnight-miner-releases/main/install.sh | bash -s -- --url <SERVER_URL>
```

### PowerShell (Windows/Linux/macOS)
```powershell
irm https://raw.githubusercontent.com/mgpai22/midnight-miner-releases/main/install.ps1 | iex
```

## Installation

### Option 1: Install to PATH

**Bash:**
```bash
# Download scripts
curl -fsSL https://raw.githubusercontent.com/mgpai22/midnight-miner-releases/main/install.sh -o install.sh
curl -fsSL https://raw.githubusercontent.com/mgpai22/midnight-miner-releases/main/run.sh -o run.sh
chmod +x install.sh run.sh

# Install binary to ~/.local/bin
./install.sh --url <SERVER_URL>
```

**PowerShell:**
```powershell
# Download scripts
Invoke-WebRequest -Uri https://raw.githubusercontent.com/mgpai22/midnight-miner-releases/main/install.ps1 -OutFile install.ps1
Invoke-WebRequest -Uri https://raw.githubusercontent.com/mgpai22/midnight-miner-releases/main/run.ps1 -OutFile run.ps1

# Install binary to PATH
.\install.ps1 -Url <SERVER_URL>
```

**Default install locations:**
- Linux/macOS: `~/.local/bin/midnight-miner`
- Windows: `%USERPROFILE%\AppData\Local\Programs\midnight-miner.exe`

### Option 2: Install to Current Directory

Use the `--local` flag (bash) or `-Local` flag (PowerShell) to download the binary to the current directory instead of installing to PATH.

**Bash:**
```bash
./install.sh --url <SERVER_URL> --local
```

**PowerShell:**
```powershell
.\install.ps1 -Url <SERVER_URL> -Local
```

This is useful for:
- Running the miner in a specific directory
- Testing without modifying your PATH
- Portable installations

## Usage

### Running the Miner

**Direct execution:**
```bash
# If installed to PATH
midnight-miner [args]

# If installed locally
./midnight-miner [args]
```

### Auto-Restart Runner

The included `run.sh` / `run.ps1` scripts automatically restart the miner if it exits or crashes.

**Bash:**
```bash
./run.sh [miner-args]

# Custom restart delay (default: 2 seconds)
./run.sh -d 5 [miner-args]
```

**PowerShell:**
```powershell
.\run.ps1 [miner-args]

# Custom restart delay (default: 2 seconds)
.\run.ps1 -Delay 5 [miner-args]
```

**Features:**
- Automatically restarts on crash or exit
- Exponential backoff for rapid failures (prevents tight crash loops)
- Tracks launch count and runtime statistics
- Graceful shutdown with Ctrl+C
- **Automatically detects and uses local binary** (`./midnight-miner`) if present, otherwise uses PATH installation

## Examples

### Install and run with auto-restart
```bash
# Bash
./install.sh --url https://example.com/releases --local
./run.sh --wallet YOUR_WALLET_ADDRESS

# PowerShell
.\install.ps1 -Url https://example.com/releases -Local
.\run.ps1 --wallet YOUR_WALLET_ADDRESS
```

### Install globally and run
```bash
# Bash
./install.sh --url https://example.com/releases
midnight-miner --wallet YOUR_WALLET_ADDRESS

# PowerShell
.\install.ps1 -Url https://example.com/releases
midnight-miner --wallet YOUR_WALLET_ADDRESS
```

## Environment Variables

Customize installation paths:

```bash
# Bash
export BIN_DIR="$HOME/my-custom-path"
export NAME="my-miner"
./install.sh --url <SERVER_URL>

# PowerShell
$env:BIN_DIR = "$env:USERPROFILE\my-custom-path"
$env:NAME = "my-miner"
.\install.ps1 -Url <SERVER_URL>
```

## Help

**Bash:**
```bash
./install.sh --help
```

**PowerShell:**
```powershell
.\install.ps1 -Help
```

## Supported Platforms

The install scripts automatically detect your platform and download the correct binary:

- **Linux:** x64, arm64 (glibc and musl)
- **macOS:** x64, arm64 (with Rosetta detection)
- **Windows:** x64, arm64
