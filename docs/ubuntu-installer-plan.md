# Ubuntu installer plan

## Supported platform

The `inosas-goows` Debian package supports Ubuntu Server 22.04 LTS and later approved Ubuntu releases on `amd64`. It is a single product package; it does not bundle a separate package for every Ubuntu release. A signed compatibility manifest binds each Ubuntu codename to permitted package sources, package names, and PHP availability. An unknown future Ubuntu release is never assumed compatible: `system-check` reports it as unsupported until a signed manifest update enables it.

The product version remains `Major.Minor.Build.Revision`; the Debian package form is, for example, `1.0.0.0-1`.

## Installer choices

| Screen / CLI option | Default | Available options |
| --- | --- | --- |
| Web server | Nginx | Nginx, Apache HTTP Server |
| PHP execution | PHP-FPM 8.3 | PHP-FPM 8.3, 8.4, 8.5 |
| Database | No database | No database, MySQL 8.4 LTS, PostgreSQL 17 |
| TLS | No TLS | None, Let’s Encrypt, self-signed |
| Network | 80 and 443 | explicitly selected HTTP/HTTPS ports |
| Delivery | Online | Online or an explicitly versioned offline bundle |

Apache uses `proxy_fcgi`/`setenvif` with PHP-FPM; `mod_php` is out of scope. Both web-server providers render a dedicated virtual host, validate configuration before reload, and never overwrite unmanaged sites.

The package installation itself is non-interactive (`apt install inosas-goows`). The first-run installer is explicitly selection-driven: `goowsctl install` presents the same choices interactively, while automation can provide them as command-line options or a reviewed answer file. This keeps APT upgrades safe and makes unattended installation reproducible.

### Selection resolution

After the operator confirms selections, the installer creates an immutable installation plan:

| Selection | Planned packages/actions |
| --- | --- |
| Nginx | `nginx`, selected `phpX.Y-fpm`, managed Nginx site/upstream snippet |
| Apache | `apache2`, `libapache2-mod-fcgid`, selected `phpX.Y-fpm`, managed `proxy_fcgi` virtual-host snippet |
| PHP 8.3/8.4/8.5 | matching FPM package plus required extensions and the matching supplied Ioncube NTS loader |
| MySQL 8.4 LTS | trusted MySQL APT source plus selected MySQL server/client packages |
| PostgreSQL 17 | trusted PGDG APT source plus PostgreSQL 17 server/client packages |
| TLS | ACME client and renewal configuration, or locally generated self-signed material |

Only selected providers are installed. The installer rejects conflicting selections or pre-existing unmanaged web/database services before changing the host, unless the operator chooses a later, explicit migration workflow.

## PHP-FPM source and update policy

PHP 8.3 is preselected. PHP 8.4 and 8.5 are opt-in choices. The installer discovers the newest **patch version inside the operator-selected major/minor series** through APT metadata, then pins the selected series in its state. It must never silently switch 8.3 to 8.4 or 8.5 merely because a newer major/minor exists.

For each selected PHP series the installer performs these checks in order:

1. Read the Ubuntu codename and the signed GOO compatibility manifest.
2. Query currently configured APT sources for the requested `phpX.Y-fpm` package.
3. If absent, offer the approved PHP source in online mode only. Initial policy is the Ondřej Surý PHP PPA, which publishes co-installable PHP releases for current Ubuntu LTS versions. The installer adds it using a pinned signing-key fingerprint and a `signed-by` keyring; it does not use deprecated `apt-key`.
4. Refresh APT metadata, resolve the exact candidate version, install it, and record package version, source, and key fingerprint.
5. Reject the selection if the exact series, matching CLI/extensions, or required Ioncube payload is unavailable.

The approved repository/key identity is a release-controlled compatibility-manifest value, not a hard-coded installer constant. This lets a future signed manifest change sources without making the installer trust arbitrary repositories. The PPA publishes co-installable PHP packages for current LTS releases and provides its fingerprint publicly. [PHP PPA reference](https://launchpad.net/~ondrej/%2Barchive/ubuntu/php/%2Bindex?direction=backwards&memo=225)

## Database providers (online only)

Database setup is optional. It is offered only in online mode because neither external repository is embedded in the first offline bundle.

### MySQL 8.4 LTS

The MySQL provider installs the official MySQL APT configuration package only after validating its release signature/key and the compatibility manifest. It enables the `mysql-8.4-lts` component for the detected Ubuntu codename, refreshes package metadata, installs the selected server/client packages, and records the source. Existing MySQL/MariaDB/fork installations stop the flow and require an explicit migration path; no replacement or downgrade is automatic. MySQL documents that its APT repository provides the 8.4 LTS channel and that native package replacements need care. [MySQL APT documentation](https://dev.mysql.com/doc/refman/8.4/en/linux-installation-apt-repo.html)

### PostgreSQL 17

The PostgreSQL provider adds the official PGDG APT repository using its supported keyring mechanism, validates the repository against the detected Ubuntu codename, then installs `postgresql-17` and selected client/contrib packages. Existing PostgreSQL clusters are detected and preserved; a major upgrade is a separate operator-approved action. PGDG publishes a PostgreSQL 17 distribution channel for Jammy. [PGDG package index](https://apt.postgresql.org/pub/repos/apt/dists/jammy-pgdg/17/)

## Ioncube NTS input contract

Place the supplied Ioncube NTS loaders here, outside generated build directories:

```text
assets/
  ioncube/
    nts/
      8.3/
        ioncube_loader_lin_8.3.so
        SHA256SUMS
      8.4/
        ioncube_loader_lin_8.4.so
        SHA256SUMS
      8.5/
        ioncube_loader_lin_8.5.so
        SHA256SUMS
```

`SHA256SUMS` must contain the loader filename and digest. If you supply a vendor signature, place it beside the loader as `.asc`; the installer will verify it when a trusted public key is added to the manifest. The installer accepts the supplied direct loader and copies only the matching NTS loader for the selected PHP series and `amd64` into the PHP extension directory returned by `php-config --extension-dir`; it then writes a version-specific `20-ioncube.ini` that precedes normal extensions. A future signed archive format may also be supported, but it is not required for these files.

It validates all of the following before enabling PHP-FPM: archive digest, loader architecture, NTS compatibility, loader PHP series compatibility, readable file ownership/mode, `php -v`/module load result, and `php-fpmX.Y -t`. An incompatible or missing loader fails before any PHP-FPM reload. Ioncube files are product-provided input, not fetched from an unverified URL.

## Filesystem and services

```text
/opt/inosas/goows       immutable installer binaries and templates
/etc/inosas/goows       installer state, selected-provider config, credentials references
/var/lib/inosas/goows   transactions, backups and migration markers
/var/log/inosas/goows   installer and manager logs
inosas-goows.service    manager service, running as the goows system account
```

The selected web server and PHP-FPM retain their native Ubuntu systemd service names. The installer owns only its marked virtual-host/pool/config snippets and produces a resource ownership inventory for removal.

## Safety, upgrade, and removal

- `system-check` and `plan` are read-only and show selected source, exact candidate package versions, configuration files, service actions, and UFW changes.
- Before mutation, the installer requires explicit confirmation of repository additions, selected PHP series, database provider, firewall ports, and TLS behavior.
- Standard uninstall removes GOO binaries, managed snippets, and its systemd manager; it preserves web-server packages, databases, `/etc`, `/var/lib`, logs, certificates, and backups.
- `purge` is a separate confirmed operation. It creates a timestamped backup first and never deletes a database cluster automatically.
- Upgrade preserves administrator configuration via Debian `conffiles`, snapshots GOO state, validates Nginx/Apache and PHP-FPM before reload, and leaves diagnostics on failure.

## Milestones

1. Implement a read-only Ubuntu preflight and selection resolver for Nginx/Apache, PHP 8.3/8.4/8.5, and database choice.
2. Implement APT source/key management and `plan` output with exact packages; test Jammy and the newest supported Ubuntu image.
3. Implement Nginx and Apache PHP-FPM renderers and Ioncube validation.
4. Implement optional MySQL 8.4 LTS and PostgreSQL 17 providers.
5. Package as a signed `.deb`, then add offline bundles for each supported Ubuntu release.
