# GOO Web Server — Ubuntu Edition

Ubuntu Server 22.04 LTS and newer releases for the GOO Web Server installer.

This workspace currently contains product planning only. Read [the installer plan](docs/ubuntu-installer-plan.md) and place supplied Ioncube archives in `assets/ioncube/nts/` as described there.
# GOO Web Server for Ubuntu

GOO Web Server is an Ubuntu-oriented web-server stack installer from Inosas. It provides a consistent, versioned installation path for PHP-FPM applications, with a choice of Nginx or Apache and optional database services.

> **Current status: test build.** The project is being validated on Ubuntu 22.04 LTS and newer. Review the generated installation plan before applying it to a server.

## License

GOO Web Server source code is licensed under the **Apache License 2.0**. Third-party component notices, distribution conditions, and the release checklist for bundled SQLSRV and ionCube assets are all maintained in the single [LICENSE.md](LICENSE.md) document.

## Highlights

- Ubuntu 22.04 LTS and newer on `amd64` / `x86_64`
- macOS on Apple Silicon (`arm64`) — planned; Intel macOS is not a target
- Choose **Nginx** or **Apache**
- PHP-FPM **8.3** by default; PHP **8.4** and **8.5** selectable
- Optional **MySQL 8.4 LTS** or **PostgreSQL 17**
- Optional Microsoft SQL Server PHP drivers (`sqlsrv` and `pdo_sqlsrv`) for matching NTS PHP versions
- A safe plan-first workflow: nothing changes until `--apply` is supplied
- Script-friendly, unattended installation for container and automation use
- Versioned Debian packages and GitHub Releases

## Current release

| Item | Value |
| --- | --- |
| Product version | `1.0.2610.2` |
| Debian package | `goo-web-server_1.0.2610.2_amd64.deb` |
| Supported platform | Ubuntu 22.04 LTS or newer, `amd64`; macOS Apple Silicon, `arm64` (planned) |

Download the package from the [Releases](https://github.com/inosascom/goowebserver/releases) page.

## Windows edition

The Windows edition of GOO Web Server is distributed through the Microsoft Store and as MSIX and EXE installer packages on [SourceForge](https://sourceforge.net/projects/goo-web-server/). This repository contains the cross-platform installer work; use the Windows distribution channel for Windows installations.

## Quick start

Download the Debian package on the target Ubuntu server, then install it:

```bash
sudo apt update
sudo apt install ./goo-web-server_1.0.2610.2_amd64.deb
goowsctl system-check
```

Review an Nginx + PHP 8.4 installation before making changes:

```bash
goowsctl plan \
  --web-server nginx \
  --php 8.4 \
  --database none \
  --tls none \
  --sqlsrv auto \
  --non-interactive
```

If the plan is correct, apply it:

```bash
sudo goowsctl install \
  --web-server nginx \
  --php 8.4 \
  --database none \
  --tls none \
  --sqlsrv auto \
  --non-interactive \
  --accept-source-additions \
  --accept-microsoft-eula \
  --apply
```

`--accept-source-additions` acknowledges the verified third-party APT repositories required for the selected PHP and database packages. `--accept-microsoft-eula` is required only when SQL Server PHP drivers are enabled.

## Installation choices

### Web server and PHP

```bash
# Nginx + PHP 8.5
sudo goowsctl install --web-server nginx --php 8.5 --database none --tls none \
  --sqlsrv disabled --non-interactive --accept-source-additions --apply

# Apache + PHP 8.3 + PostgreSQL 17
sudo goowsctl install --web-server apache --php 8.3 --database postgres17 --tls none \
  --sqlsrv disabled --non-interactive --accept-source-additions --apply

# Nginx + PHP 8.4 + MySQL 8.4 LTS
sudo goowsctl install --web-server nginx --php 8.4 --database mysql84 --tls none \
  --sqlsrv disabled --non-interactive --accept-source-additions --apply
```

The default web document root planned for the next installer milestone is `/var/www`. The local GOO management console will be exposed at `http://localhost/goows` and its application files will be isolated under `/var/www/goows`.

## Unattended and container use

All choices can be passed as arguments, allowing repeatable installs in CI or image builds. Use `--profile container` for a container-oriented plan; it omits host-only actions such as systemd, firewall and ACME configuration.

```bash
goowsctl plan --web-server nginx --php 8.4 --database none --tls none \
  --sqlsrv disabled --profile container --non-interactive
```

## SQL Server PHP drivers

When compatible bundled assets are present, `--sqlsrv auto` enables `sqlsrv` and `pdo_sqlsrv` automatically. The installer validates their SHA-256 manifests, installs Microsoft ODBC Driver 18 and validates the loaded PHP modules. Select `--sqlsrv disabled` to explicitly omit them.

## Release conventions

Every release uses one common version:

```text
Git tag:        v1.0.2610.2
Product:        1.0.2610.2
Debian package: goo-web-server_1.0.2610.2_amd64.deb
```

For quick testing from a private GitHub release:

```bash
gh auth login
gh release download v1.0.2610.2 \
  --repo inosascom/goowebserver \
  --pattern 'goo-web-server_1.0.2610.2_amd64.deb'
```

## Roadmap

- Interactive setup wizard for installations without command-line arguments
- `http://localhost/goows` management console
- Online and offline registration compatible with the existing GOO Web Server licensing contract
- Managed Nginx and Apache virtual-host configuration
- Offline installation bundle
- Container images and automated release pipeline

## Important notes

- This is an early test release; use a disposable Ubuntu VM or WSL instance during validation.
- Back up existing MySQL or PostgreSQL deployments before use. Automatic database migration is intentionally not performed.
- Do not publish license secrets, customer licenses, signing keys or other private materials in this repository or its release assets.
- Licensing, third-party notices and release gates are in [LICENSE.md](LICENSE.md).
