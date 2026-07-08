# gp-tray

A tiny system-tray indicator for the **official GlobalProtect™ Linux CLI** — connect, disconnect, and see your VPN status without touching a terminal. No Qt, no WebKit, no `libqt5webkit5`.

```
tray icon (gray globe)  →  Connect…  →  enter portal  →  SAML login in your browser  →  green globe ✓
```

## Why this exists

The official GlobalProtect **UI** package for Linux (`GlobalProtect_UI_deb`, up to and including 6.2.9) `Pre-Depends` on **libqt5webkit5** — a library that was abandoned upstream years ago and finally **removed from Ubuntu starting with 25.04**. On Ubuntu 25.04, 25.10, and 26.04 LTS the UI package is simply uninstallable: the old 24.04 `.deb` needs `libicu74`, the pre-2.14 `libxml2`, and the Qt 5.15.13 ABI, all of which are gone.

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

Grab the `.deb` from [Releases](https://github.com/tiratano/gp-tray/releases):

```bash
sudo apt install ./gp-tray_*_all.deb
```

Then log out/in (or run `gp-tray` once). Tested on Ubuntu 26.04 LTS with GNOME; should work on any distro with an AppIndicator-capable tray and the `globalprotect` CLI 6.x.

### Build from source

```bash
git clone https://github.com/tiratano/gp-tray.git
cd gp-tray
./build-deb.sh
sudo apt install ./dist/gp-tray_*_all.deb
```

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
- **No tray icon on GNOME** — make sure the AppIndicator extension is enabled (preinstalled on Ubuntu): `gnome-extensions enable ubuntu-appindicators@ubuntu.com`
- **Connect does nothing** — check that `globalprotect connect --portal <your-portal>` works in a terminal first; gp-tray can't fix portal-side auth issues.

## Trademark notice

GlobalProtect™ and Palo Alto Networks® are trademarks of Palo Alto Networks, Inc. This is an independent, unofficial project, **not affiliated with or endorsed by Palo Alto Networks**. The globe icons are original artwork created for this project (MIT-licensed like everything else here); they are deliberately generic and do not reproduce Palo Alto Networks' logos.

## License

[MIT](LICENSE)
