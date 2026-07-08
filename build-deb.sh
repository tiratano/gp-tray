#!/bin/bash
# Build gp-tray_<version>_all.deb into ./dist/
set -euo pipefail
cd "$(dirname "$0")"

PKG=gp-tray
VERSION=$(grep -m1 '^VERSION = ' gp-tray | cut -d'"' -f2)
STAGE="build/${PKG}_${VERSION}_all"

rm -rf build
mkdir -p dist "$STAGE/DEBIAN"

install -Dm755 gp-tray "$STAGE/usr/bin/gp-tray"
for svg in icons/*.svg; do
    install -Dm644 "$svg" "$STAGE/usr/share/icons/hicolor/scalable/apps/$(basename "$svg")"
done
install -Dm644 gp-tray.desktop "$STAGE/usr/share/applications/gp-tray.desktop"
install -Dm644 gp-tray.desktop "$STAGE/etc/xdg/autostart/gp-tray.desktop"
install -Dm644 LICENSE "$STAGE/usr/share/doc/gp-tray/copyright"

cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: net
Priority: optional
Architecture: all
Depends: python3, python3-gi, gir1.2-gtk-3.0, gir1.2-ayatanaappindicator3-0.1 | gir1.2-appindicator3-0.1
Recommends: libnotify-bin
Maintainer: tiratano <yolocodes@gmail.com>
Homepage: https://github.com/tiratano/gp-tray
Description: Tray indicator for the official GlobalProtect Linux CLI
 A tiny AppIndicator that wraps the official globalprotect command-line
 client: connect, disconnect and see the VPN status from your system tray.
 .
 Built because the official GlobalProtect UI package depends on
 libqt5webkit5, which was removed from Ubuntu 25.04 and later.
 Requires the official GlobalProtect CLI package from your organization.
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor || true
fi
EOF
cp "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"
chmod 755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"

dpkg-deb --build --root-owner-group "$STAGE" "dist/${PKG}_${VERSION}_all.deb"
echo "Built dist/${PKG}_${VERSION}_all.deb"
