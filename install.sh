#!/bin/bash
# gp-tray one-shot installer: downloads the latest release .deb and installs it.
#   wget -qO- https://raw.githubusercontent.com/tiratano/gp-tray/main/install.sh | bash
set -euo pipefail

url=$(wget -qO- https://api.github.com/repos/tiratano/gp-tray/releases/latest \
      | grep -om1 '"browser_download_url": *"[^"]*_all\.deb"' | cut -d'"' -f4)
if [ -z "$url" ]; then
    echo "error: could not find a .deb asset in the latest release" >&2
    exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo "Downloading $url"
wget -qO "$tmp/gp-tray.deb" "$url"
if ! sudo apt-get install -y "$tmp/gp-tray.deb"; then
    echo
    echo "apt failed — your system may already have packages with broken dependencies." >&2
    echo "Run 'sudo apt --fix-broken install' first, then re-run this script." >&2
    exit 1
fi

if ! command -v globalprotect >/dev/null; then
    echo
    echo "NOTE: the official GlobalProtect CLI is not installed."
    echo "      Get PanGPLinux.tgz from your organization and install GlobalProtect_deb-*.deb."
fi
echo
echo "Done. Log out and back in, or start it now with:  gp-tray &"
