# Installer milestone 1: safe online foundation

This milestone implements `cmd/goowsctl`, a dependency-free Bash CLI intended for Ubuntu. It is the first executable part of the installer and is safe to review on any platform.

## Available now

```bash
./cmd/goowsctl system-check
./cmd/goowsctl plan --web-server nginx --php 8.4 --database none --tls none --non-interactive
./cmd/goowsctl plan --web-server apache --php 8.5 --database postgres17 --tls self-signed --non-interactive
```

`plan` makes no changes. `install` refuses to proceed without `--apply`, root privileges, and `--accept-source-additions`. With all three conditions satisfied, it verifies the pinned source-key fingerprint before adding a PHP, PGDG, or MySQL source; installs only the selected packages; validates the supplied Ioncube loader checksum; validates PHP-FPM and web-server configuration; and writes restricted installation state.

## Next implementation increment

Implement rendered Nginx/Apache virtual-host configuration, management service/unit, TLS, UFW ownership tracking, rollback transaction handling, and online license activation. Offline bundle creation remains explicitly deferred.
