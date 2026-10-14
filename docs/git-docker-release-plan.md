# Git and Docker release plan

## Purpose

Docker is the repeatable build and package-publishing environment for GOO Web Server. It is not the production runtime of the Ubuntu web server. Production servers install a signed `.deb` from APT or a signed offline bundle.

The same pipeline is shared by GOO and future Inosas web-server installers. Each product supplies its own package metadata, setup manifest, systemd/config templates, dependencies, Ioncube assets, and acceptance tests.

## Release flow

```text
protected, signed Git tag: vMajor.Minor.Build.Revision
                         |
                         v
Docker builder for each Ubuntu target: Jammy / Noble
                         |
                         v
build .deb -> test in clean matching Ubuntu environment
                         |
             +-----------+-----------+
             |                       |
             v                       v
signed APT artifact          signed offline bundle
```

The tag is the sole source for a release. The job fails unless the tag, embedded product version, changelog version, and Debian package version agree. Artifacts are immutable: a published version is never replaced by another build.

## Jobs

1. **Validate:** check schema, dependency/source manifest, Ioncube hashes, and package versioning.
2. **Build:** use pinned Docker builder images to assemble separate `jammy` and `noble` `.deb` artifacts.
3. **Test:** create a clean matching Ubuntu test environment; exercise `system-check`, `plan`, Nginx and Apache selection, PHP-FPM selection, and package removal. Online database/TLS tests use isolated test credentials.
4. **Attest:** produce checksums, SBOM, build provenance, and release manifest.
5. **Sign and publish:** sign package/repository metadata and publish to versioned APT channels plus the matching offline bundle.

## Security rules

- Build images are version-pinned and rebuilt for security updates; package builds record their image digest.
- Git main and release tags are protected; publishing can be triggered only from an approved signed tag.
- Private signing keys, package-repository credentials, ACME test credentials, and database test passwords are injected by the CI secret store. They are never committed to Git, copied to Docker layers, or added to offline bundles.
- A release publication requires verified tests for both target Ubuntu channels. A target failure prevents publication for that target.
- Builder Docker images may be published to a container registry for reuse, but no production server uses them as a runtime image.

## Product contract

Every product adopts the pipeline by providing:

```text
packaging/debian/       control metadata and maintainer-script templates
release/manifest.yaml   supported Ubuntu releases, APT sources, package constraints
systemd/                unit, tmpfiles, logrotate templates
tests/                  target-specific smoke and acceptance tests
assets/                 signed/checksummed offline inputs such as Ioncube loaders
```

For GOO, the release manifest also resolves selected Nginx/Apache, PHP-FPM 8.3/8.4/8.5, MySQL 8.4 LTS, PostgreSQL 17, and Ioncube NTS asset compatibility.
