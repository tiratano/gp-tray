# gp-tray

[English](README.md) | **한국어**

**공식 GlobalProtect™ Linux CLI**를 위한 초경량 시스템 트레이 인디케이터 — 터미널 없이 트레이에서 VPN 연결·해제·상태 확인. Qt 없음, WebKit 없음, `libqt5webkit5` 없음.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/flow-dark.svg">
    <img alt="gp-tray 동작 흐름: 트레이의 회색 지구본 → Connect… 후 포털 주소 입력 → 브라우저에서 SAML 로그인 → 초록 지구본, 연결 완료" src="docs/flow-light.svg" width="880">
  </picture>
</p>

## 왜 만들었나

Linux용 공식 GlobalProtect **UI** 패키지(`GlobalProtect_UI_deb`, 6.2.9 버전까지)는 **libqt5webkit5**를 `Pre-Depends`로 요구합니다 — [Palo Alto 공식 설치 가이드도 `apt-get install libqt5webkit5`를 먼저 하라고 안내](https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA14u0000004NoDCAU)하죠. 그런데 QtWebKit은 [업스트림에서 수년 전에 개발이 중단](https://github.com/qtwebkit/qtwebkit)됐고(마지막 릴리스: 5.212 alpha, 2020년), 결국 **Ubuntu 25.04부터 저장소에서 제거**됐습니다 — [Ubuntu 24.04 패키지 페이지](https://packages.ubuntu.com/noble/libqt5webkit5)와 [Ubuntu 26.04 페이지](https://packages.ubuntu.com/resolute/libqt5webkit5)를 비교해 보세요. [같은 문제를 겪은 다른 사용자의 Ask Ubuntu 질문](https://askubuntu.com/q/1554893)도 있습니다.

그래서 Ubuntu 25.04, 25.10, 26.04 LTS에서 UI 패키지는 설치 자체가 불가능합니다. 24.04용 `.deb`를 억지로 가져와도 안 됩니다: `libicu74`, 2.14 이전 `libxml2`, Qt 5.15.13 ABI가 필요한데 전부 사라졌거든요.

다행히 공식 **CLI 전용** 패키지(`GlobalProtect_deb`)는 최신 Ubuntu에서 완벽하게 동작합니다. UI가 하던 일은 사실 이 두 명령이 전부입니다:

```bash
globalprotect connect --portal vpn.example.com
globalprotect disconnect
```

gp-tray는 이 두 명령을 감싸는 아주 작은 AppIndicator(GTK 3 + Python, 약 300줄)일 뿐입니다. 익숙한 트레이 아이콘 워크플로를 되돌려 드려요.

## 기능

- 연결 안 됨 상태에서는 회색 지구본으로 트레이에 대기
- **Connect…** 를 누르면 포털 주소 입력 창이 열리고(다음부터 기억됨), `globalprotect connect --portal <주소>`를 실행 — SAML 포털이면 기본 브라우저에서 로그인이 열립니다
- **Disconnect** 는 `globalprotect disconnect` 실행
- 5초마다 `globalprotect show --status`를 폴링해서 아이콘 갱신: 회색(미연결), 노랑(연결 중), 초록 ✓(연결됨), 빨강 ✗(GlobalProtect 서비스 중단)
- 트레이 아이콘 **가운데 클릭**으로 빠른 연결/해제
- 로그인 시 자동 시작 (XDG autostart)

## 하지 않는 것

gp-tray는 **VPN 클라이언트가 아닙니다.** 터널 코드도, 인증 코드도 없으며, 자격 증명을 절대 다루지 않습니다. 별도로 설치된 공식 `globalprotect` CLI를 호출만 합니다(소속 조직에서 제공하는 `PanGPLinux.tgz`의 `GlobalProtect_deb-*.deb`를 설치하세요).

공식 CLI를 구할 수 없다면 완전한 오픈소스 클라이언트인 [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect)를 참고하세요.

## 설치

[Releases](https://github.com/tiratano/gp-tray/releases)에서 `.deb`를 받아서:

```bash
sudo apt install ./gp-tray_*_all.deb
```

그다음 로그아웃/로그인하거나 `gp-tray`를 한 번 실행하세요. Ubuntu 26.04 LTS(GNOME)에서 테스트했으며, AppIndicator를 지원하는 트레이와 `globalprotect` CLI 6.x가 있는 배포판이라면 동작합니다.

### 소스에서 빌드

```bash
git clone https://github.com/tiratano/gp-tray.git
cd gp-tray
./build-deb.sh
sudo apt install ./dist/gp-tray_*_all.deb
```

## 문제 해결

- **"GlobalProtect service unavailable" (빨강 ✗)** — GlobalProtect 데몬 또는 사용자 에이전트가 실행 중이 아닙니다:
  ```bash
  sudo systemctl restart gpd
  systemctl --user restart gpa
  ```
  팁: 일부 시스템에서는 사용자 에이전트(`PanGPA`)가 로그인 직후 조용히 죽어서 CLI 자체가 "Cannot connect to local gpd service" 에러를 냅니다. 자동 재시작을 걸어두면 CLI와 gp-tray가 모두 해결됩니다:
  ```bash
  mkdir -p ~/.config/systemd/user/gpa.service.d
  printf '[Service]\nRestart=always\nRestartSec=3\n' > ~/.config/systemd/user/gpa.service.d/override.conf
  systemctl --user daemon-reload && systemctl --user restart gpa
  ```
- **GNOME에서 트레이 아이콘이 안 보임** — AppIndicator 확장이 켜져 있는지 확인하세요(Ubuntu에는 기본 설치): `gnome-extensions enable ubuntu-appindicators@ubuntu.com`
- **Connect를 눌러도 반응 없음** — 먼저 터미널에서 `globalprotect connect --portal <포털주소>`가 되는지 확인하세요. 포털 쪽 인증 문제는 gp-tray가 해결할 수 없습니다.

## 상표 고지

GlobalProtect™ 및 Palo Alto Networks®는 Palo Alto Networks, Inc.의 상표입니다. 이 프로젝트는 독립적인 비공식 프로젝트이며, **Palo Alto Networks와 무관하고 어떠한 보증도 받지 않았습니다.** 지구본 아이콘은 이 프로젝트를 위해 새로 그린 창작물로(다른 모든 것과 같이 MIT 라이선스), 의도적으로 일반적인 형태로 만들었으며 Palo Alto Networks의 로고를 복제하지 않았습니다.

## 라이선스

[MIT](LICENSE)
