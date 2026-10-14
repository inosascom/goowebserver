#!/usr/bin/env bash
set -euo pipefail

readonly PACKAGE=goo-web-server
readonly VERSION=1.0.2610.2
readonly ARCH=amd64
readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly BUILD_ROOT="${TMPDIR:-/tmp}/goo-web-server-debian-test-${UID}"
readonly STAGE="${BUILD_ROOT}/${PACKAGE}_${VERSION}_${ARCH}"
readonly OUTPUT="${ROOT}/dist/${PACKAGE}_${VERSION}_${ARCH}.deb"

require_file() { [[ -f "$1" ]] || { printf 'Missing required file: %s\n' "$1" >&2; exit 2; }; }

rm -rf "$BUILD_ROOT"
mkdir -p "$STAGE/DEBIAN" "$STAGE/usr/bin" "$STAGE/usr/share/doc/$PACKAGE" "$STAGE/opt/inosas/goows/assets" "$STAGE/etc/inosas/goows"

require_file "$ROOT/cmd/goowsctl"
require_file "$ROOT/config/goows.conf"
require_file "$ROOT/LICENSE.md"

install -m 0755 "$ROOT/cmd/goowsctl" "$STAGE/usr/bin/goowsctl"
install -m 0644 "$ROOT/config/goows.conf" "$STAGE/etc/inosas/goows/goows.conf"
install -m 0644 "$ROOT/LICENSE.md" "$STAGE/usr/share/doc/$PACKAGE/LICENSE.md"
cp -a "$ROOT/assets/ioncube" "$STAGE/opt/inosas/goows/assets/"
cp -a "$ROOT/assets/sqlsrv" "$STAGE/opt/inosas/goows/assets/"
find "$STAGE/opt/inosas/goows/assets" -type d -exec chmod 0755 {} +
find "$STAGE/opt/inosas/goows/assets" -type f -exec chmod 0644 {} +

# Test-only checksum manifests make the supplied loader inputs verifiable after packaging.
for series in 8.3 8.4 8.5; do
  loader="$STAGE/opt/inosas/goows/assets/ioncube/nts/$series/ioncube_loader_lin_${series}.so"
  require_file "$loader"
  (cd "$(dirname "$loader")" && sha256sum "$(basename "$loader")" > SHA256SUMS)
done

cat > "$STAGE/DEBIAN/control" <<EOF
Package: ${PACKAGE}
Version: ${VERSION}
Section: web
Priority: optional
Architecture: ${ARCH}
Maintainer: Inosas <support@inosas.example>
Depends: bash (>= 5), ca-certificates
Description: GOO Web Server Ubuntu installer (test build)
 Test package containing the GOO Web Server online installer and required
 PHP extension inputs. It does not provision web services
 until goowsctl install --apply is invoked explicitly.
EOF

cat > "$STAGE/DEBIAN/conffiles" <<'EOF'
/etc/inosas/goows/goows.conf
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
case "$1" in
  configure)
    install -d -m 0755 /opt/inosas/goows /var/lib/inosas/goows /var/log/inosas/goows
    if ! getent group goows >/dev/null 2>&1; then addgroup --system goows; fi
    if ! id -u goows >/dev/null 2>&1; then adduser --system --ingroup goows --home /var/lib/inosas/goows --no-create-home --shell /usr/sbin/nologin goows; fi
    chown goows:goows /var/lib/inosas/goows /var/log/inosas/goows
    ;;
esac
EOF

cat > "$STAGE/DEBIAN/prerm" <<'EOF'
#!/bin/sh
set -e
# Product data, logs, configuration and licenses are intentionally retained.
exit 0
EOF
chmod 0755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/prerm"

mkdir -p "$(dirname "$OUTPUT")"
dpkg-deb --build --root-owner-group "$STAGE" "$OUTPUT"
dpkg-deb --info "$OUTPUT"
dpkg-deb --contents "$OUTPUT"
printf 'Created test package: %s\n' "$OUTPUT"
