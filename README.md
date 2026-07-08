# gp-tray

**English** | [한국어](README.ko.md)

A tiny system-tray indicator for the **official GlobalProtect™ Linux CLI** — connect, disconnect, and see your VPN status without touching a terminal. No Qt, no WebKit, no `libqt5webkit5`.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/flow-dark.svg">
    <img alt="How gp-tray works: gray globe idle in the tray → Connect… and enter your portal address → SAML login in your browser → green globe, connected" src="docs/flow-light.svg" width="880">
  </picture>
</p>

> **What's SAML?** The single-sign-on standard most corporate VPN portals use. Instead of typing a VPN password into the client, your default browser opens your company's login page (usually with MFA); once you sign in, the portal hands the client a one-time credential (a prelogin cookie) and the tunnel comes up. Your credentials never touch gp-tray.

## Why this exists

The official GlobalProtect **UI** package for Linux (`GlobalProtect_UI_deb`, up to and including 6.2.9) `Pre-Depends` on **libqt5webkit5** — [Palo Alto's own install guide tells you to `apt-get install libqt5webkit5` first](https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA14u0000004NoDCAU). But QtWebKit was [archived upstream years ago](https://github.com/qtwebkit/qtwebkit) (last release: 5.212 alpha, 2020) and was finally **removed from Ubuntu starting with 25.04** — compare the package page for [Ubuntu 24.04](https://packages.ubuntu.com/noble/libqt5webkit5) with [Ubuntu 26.04](https://packages.ubuntu.com/resolute/libqt5webkit5), and see [this Ask Ubuntu question](https://askubuntu.com/q/1554893) from another user hitting exactly this wall.

So on Ubuntu 25.04, 25.10, and 26.04 LTS the UI package is simply uninstallable — and no, you can't just sideload the 24.04 `.deb`: it needs `libicu74`, the pre-2.14 `libxml2`, and the Qt 5.15.13 ABI, all of which are gone from these releases.

The good news: the official **CLI-only** package (`GlobalProtect_deb`) works perfectly on modern Ubuntu. Everything the UI did can be done with two commands:

```bash
globalprotect connect --portal vpn.example.com
globalprotect disconnect
```

gp-tray is just a very small AppIndicator (GTK 3 + Python, ~300 lines) that wraps those two commands, so you get the familiar tray-icon workflow back.

## What it does

- Sits in your tray as a gray globe when disconnected
- **Connect…** opens a small dialog asking for your portal address (remembered for next time), then runs `globalprotect connect --portal <address>` — if your portal uses SAML, the login opens in your default browser
- **Disconnect** runs `globalprotect disconnect`
- Polls `globalprotect show --status` every 5 seconds and updates the icon: gray (disconnected), amber (connecting), green ✓ (connected), red ✗ (GlobalProtect service not running)
- Middle-click the tray icon to connect/disconnect quickly
- Starts automatically at login (XDG autostart)

## What it does NOT do

gp-tray is **not a VPN client**. It contains no tunnel code, no authentication code, and never sees your credentials. It only shells out to the official `globalprotect` CLI, which you must install separately (your organization provides `PanGPLinux.tgz`; install `GlobalProtect_deb-*.deb` from it).

If you don't have access to the official CLI, look at [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect) instead — a full open-source client.

## Install

One command — downloads the latest release `.deb` and installs it via apt:

```bash
wget -qO- https://raw.githubusercontent.com/tiratano/gp-tray/main/install.sh | bash
```

Prefer not to pipe scripts into bash? Grab the `.deb` from [Releases](https://github.com/tiratano/gp-tray/releases) and `sudo apt install ./gp-tray_*_all.deb`, or build from source:

```bash
git clone https://github.com/tiratano/gp-tray.git && cd gp-tray && ./build-deb.sh
sudo apt install ./dist/gp-tray_*_all.deb
```

**Or just ask your AI agent.** Paste this into Claude Code, Cursor, or any agent with shell access:

> Install gp-tray from https://github.com/tiratano/gp-tray: download the latest release .deb and install it with apt. Also check that the official `globalprotect` CLI is installed — if not, remind me to get the GlobalProtect_deb package from my organization. Finally, run `gp-tray` so the tray icon appears.

Then log out/in (or run `gp-tray` once). Tested on Ubuntu 26.04 LTS with GNOME; should work on any distro with an AppIndicator-capable tray and the `globalprotect` CLI 6.x.

## Troubleshooting

- **"GlobalProtect service unavailable" (red ✗)** — the GlobalProtect daemon or user agent isn't running. Try:
  ```bash
  sudo systemctl restart gpd
  systemctl --user restart gpa
  ```
  Tip: on some systems the user agent (`PanGPA`) silently dies at login, which also breaks the plain CLI ("Cannot connect to local gpd service"). Making it self-healing fixes both the CLI and gp-tray:
  ```bash
  mkdir -p ~/.config/systemd/user/gpa.service.d
  printf '[Service]\nRestart=always\nRestartSec=3\n' > ~/.config/systemd/user/gpa.service.d/override.conf
  systemctl --user daemon-reload && systemctl --user restart gpa
  ```
- **Stuck at "Connecting…" and even `globalprotect disconnect` does nothing** — the PanGPS daemon can wedge itself (it keeps a broken session internally, believes a tunnel is "already established", and rejects every new request). Use **Restart GlobalProtect service** in the gp-tray menu, or manually:
  ```bash
  sudo systemctl restart gpd && systemctl --user restart gpa
  ```
- **"Unmet dependencies" during install** — your system already has another package with broken dependencies (e.g. VirtualBox installed via `dpkg -i`). Run `sudo apt --fix-broken install` first, then install gp-tray again.
- **No tray icon on GNOME** — make sure the AppIndicator extension is enabled (preinstalled on Ubuntu): `gnome-extensions enable ubuntu-appindicators@ubuntu.com`
- **Connect does nothing** — check that `globalprotect connect --portal <your-portal>` works in a terminal first; gp-tray can't fix portal-side auth issues.

## Trademark notice

GlobalProtect™ and Palo Alto Networks® are trademarks of Palo Alto Networks, Inc. This is an independent, unofficial project, **not affiliated with or endorsed by Palo Alto Networks**. The globe icons are original artwork created for this project (MIT-licensed like everything else here); they are deliberately generic and do not reproduce Palo Alto Networks' logos.

## License

[MIT](LICENSE)
