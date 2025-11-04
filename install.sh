#!/usr/bin/env bash
set -euo pipefail

# install.sh — download & install the right midnight-miner binary for this machine.
# Usage: ./install.sh --url <SERVER_URL>
#   env: BIN_DIR=~/.local/bin (default)
#        NAME=midnight-miner (installed executable name, default)
#
# Expected server files at <SERVER_URL>/:
#   midnight-miner-rs-linux-x64.tar.gz
#   midnight-miner-rs-linux-arm64.tar.gz
#   midnight-miner-rs-linux-musl-x64.tar.gz
#   midnight-miner-rs-linux-musl-arm64.tar.gz
#   midnight-miner-rs-macos-x64.tar.gz
#   midnight-miner-rs-macos-arm64.tar.gz

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
NAME="${NAME:-midnight-miner}"

die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

SERVER_URL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) SERVER_URL="${2:-}"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $0 --url <SERVER_URL>

Downloads the correct archive for this machine and installs to:
  BIN_DIR=${BIN_DIR}

Options:
  --url URL      Base URL hosting the release tarballs (required)
Env:
  BIN_DIR        Installation directory (default: ${BIN_DIR})
  NAME           Installed executable name (default: ${NAME})
EOF
      exit 0
      ;;
    *) die "unknown arg: $1 (use --help)";;
  endac
done

[[ -n "$SERVER_URL" ]] || die "--url is required (e.g. --url https://example.com/releases/bins)"

need curl
need tar
mkdir -p "$BIN_DIR"

uname_s=$(uname -s)
uname_m=$(uname -m)

# Determine OS target
case "$uname_s" in
  Linux)   os="linux" ;;
  Darwin)  os="macos" ;;
  *)       die "unsupported OS: $uname_s" ;;
esac

# Determine arch (normalize common aliases)
case "$uname_m" in
  x86_64|amd64) arch="x64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) die "unsupported CPU arch: $uname_m" ;;
esac

# On macOS, if running under Rosetta, prefer arm64 build
if [[ "$os" == "macos" && "$arch" == "x64" ]]; then
  if sysctl -n sysctl.proc_translated 2>/dev/null | grep -q '^1$'; then
    echo "info: Rosetta detected; using macos-arm64 build"
    arch="arm64"
  fi
fi

# musl vs glibc detection for Linux
libc_suffix=""
if [[ "$os" == "linux" ]]; then
  if [[ -f /etc/alpine-release ]] || ldd --version 2>&1 | grep -qi musl; then
    libc_suffix="-musl"
  fi
fi

target="${os}${libc_suffix}-${arch}"
file="midnight-miner-rs-${target}.tar.gz"
url="${SERVER_URL%/}/${file}"

echo "info: OS=${os} ARCH=${arch} MUSL=${libc_suffix:+yes} -> target=${target}"
echo "info: downloading ${url}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

archive="$tmpdir/${file}"
curl -fL --retry 3 --retry-delay 2 -o "$archive" "$url" \
  || die "failed to download: $url (wrong URL or unsupported target?)"

echo "info: extracting ${file}"
tar -xzf "$archive" -C "$tmpdir"

# Try to find an executable that looks like midnight-miner
bin_src="$(find "$tmpdir" -maxdepth 3 -type f -perm -111 -name 'midnight-miner*' | head -n1 || true)"
[[ -n "$bin_src" ]] || die "could not locate executable inside archive"

install_path="${BIN_DIR}/${NAME}"
mv "$bin_src" "$install_path"
chmod +x "$install_path"

echo "success: installed ${NAME} -> ${install_path}"

# PATH hint
case ":$PATH:" in
  *:"$BIN_DIR":*) ;;
  *) echo "note: ${BIN_DIR} is not in PATH. Add this to your shell rc:"; echo "      export PATH=\"$BIN_DIR:\$PATH\"";;
esac