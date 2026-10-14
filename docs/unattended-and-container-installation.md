# Unattended and container installation

## Non-interactive installer contract

`goowsctl install` supports both interactive selection and fully unattended execution. The same validation and plan resolver are used in either path; unattended mode does not bypass compatibility, package-source, port, Ioncube, or conflict checks.

```bash
# Preview only: makes no changes.
goowsctl plan \
  --web-server nginx \
  --php 8.4 \
  --database postgres17 \
  --tls none \
  --http-port 80 \
  --https-port 443

# Host installation: all selections are explicit.
sudo goowsctl install \
  --non-interactive \
  --web-server apache \
  --php 8.4 \
  --database mysql84 \
  --tls letsencrypt \
  --domain example.com \
  --acme-email ops@example.com \
  --http-port 80 \
  --https-port 443 \
  --accept-source-additions
```

| Parameter | Values | Default in interactive setup |
| --- | --- | --- |
| `--web-server` | `nginx`, `apache` | `nginx` |
| `--php` | `8.3`, `8.4`, `8.5` | `8.3` |
| `--database` | `none`, `mysql84`, `postgres17` | `none` |
| `--tls` | `none`, `letsencrypt`, `self-signed` | `none` |
| `--http-port` / `--https-port` | valid, unoccupied TCP ports | `80` / `443` |
| `--domain` | DNS name | required for `letsencrypt` |
| `--acme-email` | email address | required for `letsencrypt` |
| `--accept-source-additions` | flag | required when PHP/MySQL/PostgreSQL source must be added |
| `--offline-bundle` | absolute bundle path | absent; uses online sources |
| `--profile` | `host`, `container` | `host` |

In non-interactive mode, all required selections must be present. The command fails rather than prompting if a required parameter, a source-addition consent, Ioncube asset, or compatible package candidate is missing. `--database none` is the explicit no-database selection.

An answer file may be used instead of command-line arguments:

```yaml
# install.yaml
profile: host
webServer: nginx
php: "8.4"
database: none
tls: self-signed
httpPort: 80
httpsPort: 443
acceptSourceAdditions: true
```

```bash
sudo goowsctl install --non-interactive --answers /secure/path/install.yaml
```

Environment variables are supported only for secret values such as database passwords and ACME credentials; non-secret topology choices stay visible in arguments or the reviewed answer file. Secrets are never emitted in `plan` output or logs.

## Idempotency and scaling

Every successful invocation stores a normalized selection fingerprint. Repeating the exact request is a no-op after health checks. A changed selection creates a diff and requires `--apply-change`; database replacement, PHP major/minor change, and web-server switch require an explicit migration workflow and can never happen silently.

This makes automation safe for CI, cloud-init, configuration management, and immutable-image builds. A machine or image can always be recreated from the same answer file and selected artifact versions.

## Docker profile

The same selection interface supports a container build profile for rapid horizontal scaling:

```dockerfile
ARG WEB_SERVER=nginx
ARG PHP_VERSION=8.4
ARG DATABASE=none

RUN goowsctl install --non-interactive --profile container \
    --web-server=${WEB_SERVER} \
    --php=${PHP_VERSION} \
    --database=${DATABASE} \
    --tls=none \
    --accept-source-additions
```

`--profile container` is intentionally different from host installation:

- It does not install, enable, or expect systemd.
- It does not change UFW or any host firewall.
- It does not request or renew Let’s Encrypt certificates inside the image. Terminate TLS at an ingress/reverse proxy, or mount externally managed certificates at runtime.
- It does not install a database server in the normal scale-out profile. `--database none` is the default and recommended container value; connect to a managed/external MySQL or PostgreSQL service through runtime configuration.
- It creates a runtime entrypoint/supervision configuration that starts the selected web server and PHP-FPM in the foreground, with signals forwarded correctly.

The installer may allow `mysql84` or `postgres17` for a single-node development container only when `--allow-container-database` is explicit. Such images are not the supported horizontal-scaling architecture because database state must outlive individual web containers.

## Image publication matrix

The Git/Docker release pipeline can publish a controlled matrix of images, for example:

```text
registry.example/inosas/goows:1.0.0.0-nginx-php8.4
registry.example/inosas/goows:1.0.0.0-apache-php8.4
registry.example/inosas/goows:1.0.0.0-nginx-php8.3
```

Every tag is produced from the same signed Git release and carries immutable labels for product version, Git revision, Ubuntu base digest, PHP version, web-server provider, and Ioncube asset digest. A mutable convenience tag such as `nginx-php8.4` may point to the newest approved release, but deployment manifests should pin the immutable version tag or image digest.
