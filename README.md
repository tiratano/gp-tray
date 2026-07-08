# gp-tray

<details>
<summary><b>🇰🇷 한국어로 보기 (expand for Korean)</b></summary>

---

**공식 GlobalProtect™ Linux CLI**를 위한 초경량 시스템 트레이 인디케이터 — 터미널 없이 트레이에서 VPN 연결·해제·상태 확인. Qt 없음, WebKit 없음, `libqt5webkit5` 없음.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/flow-dark.svg">
    <img alt="gp-tray 동작 흐름: 트레이의 회색 지구본 → Connect… 후 포털 주소 입력 → 브라우저에서 SAML 로그인 → 초록 지구본, 연결 완료" src="docs/flow-light.svg" width="880">
  </picture>
</p>

> **SAML이 뭔가요?** 회사 VPN 포털 대부분이 쓰는 SSO(통합 로그인) 표준입니다. VPN 클라이언트에 비밀번호를 입력하는 대신 기본 브라우저에 회사 로그인 페이지(주로 MFA 포함)가 열리고, 로그인이 끝나면 포털이 일회성 인증 정보(prelogin cookie)를 클라이언트에 전달해 터널이 연결됩니다. gp-tray는 자격 증명을 전혀 다루지 않습니다.

### 왜 만들었나

Linux용 공식 GlobalProtect **UI** 패키지(`GlobalProtect_UI_deb`, 6.2.9 버전까지)는 **libqt5webkit5**를 `Pre-Depends`로 요구합니다 — [Palo Alto 공식 설치 가이드도 `apt-get install libqt5webkit5`를 먼저 하라고 안내](https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA14u0000004NoDCAU)하죠. 그런데 QtWebKit은 [업스트림에서 수년 전에 개발이 중단](https://github.com/qtwebkit/qtwebkit)됐고(마지막 릴리스: 5.212 alpha, 2020년), 결국 **Ubuntu 25.04부터 저장소에서 제거**됐습니다 — [Ubuntu 24.04 패키지 페이지](https://packages.ubuntu.com/noble/libqt5webkit5)와 [Ubuntu 26.04 페이지](https://packages.ubuntu.com/resolute/libqt5webkit5)를 비교해 보세요. [같은 문제를 겪은 다른 사용자의 Ask Ubuntu 질문](https://askubuntu.com/q/1554893)도 있습니다.

그래서 Ubuntu 25.04, 25.10, 26.04 LTS에서 UI 패키지는 설치 자체가 불가능합니다. 24.04용 `.deb`를 억지로 가져와도 안 됩니다: `libicu74`, 2.14 이전 `libxml2`, Qt 5.15.13 ABI가 필요한데 전부 사라졌거든요.

다행히 공식 **CLI 전용** 패키지(`GlobalProtect_deb`)는 최신 Ubuntu에서 완벽하게 동작합니다. UI가 하던 일은 사실 이 두 명령이 전부입니다:

```bash
globalprotect connect --portal vpn.example.com
globalprotect disconnect
```

gp-tray는 이 두 명령을 감싸는 아주 작은 AppIndicator(GTK 3 + Python, 약 300줄)일 뿐입니다.

### 기능

- 연결 안 됨 상태에서는 회색 지구본으로 트레이에 대기
- **Connect…** 를 누르면 포털 주소 입력 창이 열리고(다음부터 기억됨), `globalprotect connect --portal <주소>`를 실행 — SAML 포털이면 기본 브라우저에서 로그인이 열립니다
- **Disconnect** 는 `globalprotect disconnect` 실행
- 5초마다 상태를 폴링해서 아이콘 갱신: 회색(미연결), 노랑(연결 중), 초록 ✓(연결됨), 빨강 ✗(GlobalProtect 서비스 중단)
- 트레이 아이콘 **가운데 클릭**으로 빠른 연결/해제
- 로그인 시 자동 시작 (XDG autostart)

gp-tray는 **VPN 클라이언트가 아닙니다.** 터널 코드도, 인증 코드도 없으며, 별도로 설치된 공식 `globalprotect` CLI를 호출만 합니다(소속 조직에서 제공하는 `PanGPLinux.tgz`의 `GlobalProtect_deb-*.deb`를 설치하세요). 공식 CLI를 구할 수 없다면 완전한 오픈소스 클라이언트인 [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect)를 참고하세요.

### 설치

한 줄이면 됩니다 (최신 릴리스 .deb를 받아 apt로 설치):

```bash
wget -qO- https://raw.githubusercontent.com/tiratano/gp-tray/main/install.sh | bash
```

스크립트를 파이프로 바로 실행하는 게 꺼려진다면 [Releases](https://github.com/tiratano/gp-tray/releases)에서 `.deb`를 직접 받아 `sudo apt install ./gp-tray_*_all.deb` 하거나, 소스를 클론해서 `./build-deb.sh` 후 설치하면 됩니다.

**아니면 AI 에이전트에게 시키세요.** Claude Code, Cursor 등 셸을 쓸 수 있는 에이전트에 이대로 붙여넣기:

> https://github.com/tiratano/gp-tray 의 최신 릴리스 .deb를 받아서 apt로 설치해줘. 공식 `globalprotect` CLI가 설치되어 있는지도 확인하고, 없으면 회사에서 GlobalProtect_deb 패키지를 받아야 한다고 알려줘. 마지막으로 `gp-tray`를 실행해서 트레이 아이콘을 띄워줘.

### 문제 해결

- **"GlobalProtect service unavailable" (빨강 ✗)** — GlobalProtect 데몬/에이전트가 죽어 있습니다: `sudo systemctl restart gpd && systemctl --user restart gpa`. 일부 시스템에서는 사용자 에이전트(`PanGPA`)가 로그인 직후 조용히 죽어서 CLI 자체가 "Cannot connect to local gpd service" 에러를 냅니다. 자동 재시작을 걸어두면 근본 해결됩니다:
  ```bash
  mkdir -p ~/.config/systemd/user/gpa.service.d
  printf '[Service]\nRestart=always\nRestartSec=3\n' > ~/.config/systemd/user/gpa.service.d/override.conf
  systemctl --user daemon-reload && systemctl --user restart gpa
  ```
- **GNOME에서 트레이 아이콘이 안 보임** — `gnome-extensions enable ubuntu-appindicators@ubuntu.com`
- **Connect를 눌러도 반응 없음** — 먼저 터미널에서 `globalprotect connect --portal <포털주소>`가 되는지 확인하세요.

### 상표 고지 / 라이선스

GlobalProtect™ 및 Palo Alto Networks®는 Palo Alto Networks, Inc.의 상표입니다. 이 프로젝트는 독립적인 비공식 프로젝트로 **Palo Alto Networks와 무관합니다.** 지구본 아이콘은 이 프로젝트를 위해 새로 그린 창작물입니다. 라이선스: [MIT](LICENSE)

---

</details>

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
- **No tray icon on GNOME** — make sure the AppIndicator extension is enabled (preinstalled on Ubuntu): `gnome-extensions enable ubuntu-appindicators@ubuntu.com`
- **Connect does nothing** — check that `globalprotect connect --portal <your-portal>` works in a terminal first; gp-tray can't fix portal-side auth issues.

## Trademark notice

GlobalProtect™ and Palo Alto Networks® are trademarks of Palo Alto Networks, Inc. This is an independent, unofficial project, **not affiliated with or endorsed by Palo Alto Networks**. The globe icons are original artwork created for this project (MIT-licensed like everything else here); they are deliberately generic and do not reproduce Palo Alto Networks' logos.

## License

[MIT](LICENSE)
